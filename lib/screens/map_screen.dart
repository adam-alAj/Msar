import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/checkpoint.dart';
import '../models/checkpoint_status.dart';
import '../models/governorate.dart';
import '../providers/governorate_provider.dart';
import '../services/auth_service.dart';
import '../services/checkpoint_service.dart';
import '../services/favorites_service.dart';
import '../services/location_permission_service.dart';
import '../services/tile_cache_service.dart';
import '../services/vote_queue_service.dart';
import '../services/widget_bridge_service.dart';
import '../utils/app_icons.dart';
import '../utils/constants.dart';
import '../widgets/checkpoint_marker.dart';
import '../widgets/checkpoint_card.dart';
import '../widgets/checkpoint_search_bar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/freshness_indicator.dart';
import '../widgets/map_legend.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/location_permission_sheet.dart';
import 'checkpoint_detail_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final CheckpointService _checkpointService = CheckpointService();
  final AuthService _authService = AuthService();

  List<Checkpoint> _allCheckpoints = [];
  List<Checkpoint> _filteredCheckpoints = [];
  Map<String, CheckpointStatus> _statuses = {};

  String? _selectedRegion;
  bool _isAdmin = false;
  bool _isLoading = true;
  bool _isLoadingStatuses = false;
  String? _errorMessage;

  final MapController _mapController = MapController();
  final LocationPermissionService _locationPermService = LocationPermissionService();
  late TabController _tabController;
  int _selectedTabIndex = 0;
  LatLng? _userLocation;

  StreamSubscription<List<Checkpoint>>? _checkpointSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Search state
  String _searchQuery = '';

  // Auto-refresh state
  Timer? _autoRefreshTimer;
  DateTime? _lastStatusUpdate;
  int _offlineSkipCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _checkAdmin();
    _subscribeToCheckpoints();
    _startAutoRefresh();
    VoteQueueService().init();
    FavoritesService().listen();
    FavoritesService().favorites.addListener(_onFavoritesChanged);
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) setState(() => _isOffline = offline);
    });
    // Auto-detect governorate after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromGovernorate());
  }

  bool _governorateInitialized = false;

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _updateHomeWidget() {
    final sorted = List<Checkpoint>.from(_allCheckpoints);
    if (_userLocation != null) {
      sorted.sort((a, b) {
        final dA = _haversineKm(_userLocation!.latitude, _userLocation!.longitude, a.latitude, a.longitude);
        final dB = _haversineKm(_userLocation!.latitude, _userLocation!.longitude, b.latitude, b.longitude);
        return dA.compareTo(dB);
      });
    }
    final nearest = sorted.take(3).map((cp) {
      final dist = _userLocation != null
          ? _haversineKm(_userLocation!.latitude, _userLocation!.longitude, cp.latitude, cp.longitude)
          : 0.0;
      final status = _statuses[cp.id];
      final worstStatus = _worstStatusOf(status);
      return {
        'id': cp.id,
        'name': cp.name,
        'lat': cp.latitude,
        'lng': cp.longitude,
        'distance': dist < 1.0 ? '${(dist * 1000).toInt()} م' : '${dist.toStringAsFixed(1)} كم',
        'status': worstStatus,
      };
    }).toList();
    WidgetBridgeService.updateWidgetData(nearest);
  }

  String _worstStatusOf(CheckpointStatus? status) {
    if (status == null) return 'OPEN';
    const priority = {'OPEN': 0, 'CROWDED': 1, 'CLOSED': 2};
    final e = priority[status.entrance.status] ?? 0;
    final x = priority[status.exit.status] ?? 0;
    return e >= x ? status.entrance.status : status.exit.status;
  }

  void _syncFromGovernorate() {
    final govProvider = context.read<GovernorateProvider>();
    govProvider.addListener(_onGovernorateChanged);
    // If already detected, apply immediately
    if (govProvider.current != null && !_governorateInitialized) {
      _applyGovernorateDefaults(govProvider);
    }
  }

  void _onGovernorateChanged() {
    if (!mounted) return;
    final govProvider = context.read<GovernorateProvider>();
    // Only apply defaults on first detection
    _applyGovernorateDefaults(govProvider);
    // Always update user location for the blue dot
    if (govProvider.userPosition != null && govProvider.userPosition != _userLocation) {
      setState(() => _userLocation = govProvider.userPosition);
    }
    // Show boundary crossing prompt
    if (govProvider.pendingBoundaryCrossing != null) {
      _showBoundaryCrossingPrompt(govProvider);
    }
  }

  void _applyGovernorateDefaults(GovernorateProvider govProvider) {
    if (_governorateInitialized) return;
    final gov = govProvider.current;
    if (gov == null) return;
    _governorateInitialized = true;
    setState(() {
      _selectedRegion = gov.nameAr;
      _userLocation = govProvider.userPosition;
    });
    _applyFilter();
    // Auto-center map on governorate center (privacy: not exact user location)
    try { _mapController.move(gov.center, 13.0); } catch (_) {}
  }

  void _showBoundaryCrossingPrompt(GovernorateProvider govProvider) {
    final pending = govProvider.pendingBoundaryCrossing!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('هل تريد التبديل إلى محافظة ${pending.nameAr}؟'),
        action: SnackBarAction(
          label: 'تبديل',
          onPressed: () {
            govProvider.acceptBoundaryCrossing();
            setState(() => _selectedRegion = pending.nameAr);
            _applyFilter();
            try { _mapController.move(pending.center, 13.0); } catch (_) {}
          },
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _checkpointSub?.cancel();
    _connectivitySub?.cancel();
    _tabController.dispose();
    FavoritesService().favorites.removeListener(_onFavoritesChanged);
    try { context.read<GovernorateProvider>().removeListener(_onGovernorateChanged); } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
      // Immediate refresh on resume if stale (>5 min)
      if (_lastStatusUpdate != null &&
          DateTime.now().difference(_lastStatusUpdate!).inMinutes >= 5) {
        _serverRefreshWithDiff();
      }
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => _onAutoRefreshTick());
  }

  void _onAutoRefreshTick() {
    if (_isOffline) {
      _offlineSkipCount++;
      debugPrint('⏭ Auto-refresh skipped (offline, count: $_offlineSkipCount)');
      return;
    }
    _serverRefreshWithDiff();
  }

  /// Pull-to-refresh handler: forces server source, shows offline message if needed.
  Future<void> _pullToRefresh() async {
    if (_isOffline) {
      if (!mounted) return;
      final staleness = _lastStatusUpdate != null
          ? DateTime.now().difference(_lastStatusUpdate!).inMinutes
          : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد اتصال — البيانات المحفوظة منذ $staleness دقيقة')),
      );
      return;
    }
    await _serverRefreshWithDiff();
  }

  /// Server-source refresh with smart diffing for change notifications.
  Future<void> _serverRefreshWithDiff() async {
    if (_allCheckpoints.isEmpty || !mounted) return;
    setState(() => _isLoadingStatuses = true);
    try {
      final ids = _allCheckpoints.map((c) => c.id).toList();
      final newStatuses = await _checkpointService.getAllCheckpointStatuses(
        ids,
        options: const GetOptions(source: Source.server),
      );
      if (!mounted) return;

      // Smart diff: detect changes
      final changes = <String>[];
      newStatuses.forEach((id, newStatus) {
        final old = _statuses[id];
        if (old == null) return;
        if (old.entrance.status != newStatus.entrance.status ||
            old.exit.status != newStatus.exit.status) {
          final cp = _allCheckpoints.where((c) => c.id == id).firstOrNull;
          if (cp != null) {
            final dir = old.entrance.status != newStatus.entrance.status ? 'داخل' : 'خارج';
            final newSt = old.entrance.status != newStatus.entrance.status
                ? _localizeStatus(newStatus.entrance.status)
                : _localizeStatus(newStatus.exit.status);
            changes.add('${cp.name} ($dir) → $newSt');
          }
        }
      });

      setState(() {
        _statuses = newStatuses;
        _isLoadingStatuses = false;
        _lastStatusUpdate = DateTime.now();
        _offlineSkipCount = 0;
      });

      _updateHomeWidget();

      // Show change notification only if there are actual changes
      if (changes.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(AppIcons.notification, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('تغيّر: ${changes.first}', style: const TextStyle(fontSize: 13))),
              ],
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 Server refresh failed: $e');
      if (mounted) setState(() => _isLoadingStatuses = false);
    }
  }

  String _localizeStatus(String status) {
    switch (status) {
      case 'OPEN': return 'سالك';
      case 'CROWDED': return 'أزمة';
      case 'CLOSED': return 'مغلق';
      default: return status;
    }
  }

  void _checkAdmin() async {
    try {
      final admin = await _authService.isAdmin();
      if (mounted) setState(() => _isAdmin = admin);
    } catch (_) {}
  }

  void _subscribeToCheckpoints() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _checkpointSub?.cancel();
    _checkpointSub = (_checkpointService.getCheckpoints() as Stream<List<Checkpoint>>).listen(
      (checkpoints) async {
        if (!mounted) return;
        _allCheckpoints = checkpoints;
        _applyFilter();

        if (checkpoints.isNotEmpty) {
          await _loadAllStatuses(checkpoints.map((c) => c.id).toList());
        }

        if (mounted) setState(() => _isLoading = false);
      },
      onError: (error) {
        debugPrint('🔴 Firestore error: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (_allCheckpoints.isEmpty) {
              _errorMessage = 'فشل تحميل البيانات. تأكد من اتصالك بالإنترنت';
            }
          });
        }
      },
    );
  }

  Future<void> _loadAllStatuses(List<String> ids) async {
    if (!mounted) return;
    setState(() => _isLoadingStatuses = true);
    try {
      final statuses = await _checkpointService.getAllCheckpointStatuses(ids);
      if (mounted) {
        setState(() {
          _statuses = statuses;
          _isLoadingStatuses = false;
          _lastStatusUpdate = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error loading statuses: $e');
      if (mounted) setState(() => _isLoadingStatuses = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredCheckpoints = _selectedRegion == null
          ? List.from(_allCheckpoints)
          : _allCheckpoints.where((cp) => cp.region == _selectedRegion).toList();
    });
  }

  void _selectRegion(String? region) {
    setState(() => _selectedRegion = region);
    _applyFilter();
    if (region != null) {
      context.read<GovernorateProvider>().setManual(region);
      final gov = Governorate.all.where((g) => g.nameAr == region).firstOrNull;
      if (gov != null) {
        try { _mapController.move(gov.center, 13.0); } catch (_) {}
      }
    }
  }

  Future<void> _refreshStatuses() async {
    await _serverRefreshWithDiff();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildRegionDrawer(colorScheme, isDark),
      body: Container(
        color: colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(colorScheme, isDark),
              _buildTabBar(colorScheme, isDark),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isLoading
                      ? _buildLoadingState(colorScheme)
                      : _errorMessage != null && _filteredCheckpoints.isEmpty
                          ? _buildErrorState(colorScheme)
                          : _selectedTabIndex == 0
                              ? _buildMapView(isDark)
                              : _selectedTabIndex == 1
                                  ? _buildListView()
                                  : _buildFavoritesView(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton(
            heroTag: 'locationFab',
            onPressed: _onLocationFabPressed,
            backgroundColor: colorScheme.primaryContainer,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(
                _userLocation != null ? AppIcons.myLocation : AppIcons.locationSearching,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          )
          : null,
    );
  }

  Widget _buildRegionDrawer(ColorScheme colorScheme, bool isDark) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(AppIcons.filter, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 20),
                const Text(
                  'تصفية حسب المنطقة',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر منطقة لعرض الحواجز فيها',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerRegionTile(null, 'جميع المناطق', AppIcons.globe, colorScheme.primary, colorScheme),
                const Divider(height: 1),
                ...AppConstants.regions.map((r) =>
                    _buildDrawerRegionTile(r, r, AppIcons.place, colorScheme.primary, colorScheme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerRegionTile(String? region, String label, IconData icon, Color iconColor, ColorScheme colorScheme) {
    final isSelected = _selectedRegion == region;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.1) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isSelected ? iconColor : colorScheme.onSurfaceVariant, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? iconColor : colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.2), shape: BoxShape.circle),
              child: Directionality(textDirection: TextDirection.ltr, child: Icon(AppIcons.check, color: iconColor, size: 18)),
            )
          : null,
      tileColor: isSelected ? iconColor.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        _selectRegion(region);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildModernAppBar(ColorScheme colorScheme, bool isDark) {
    final user = _authService.currentUser;
    final userName = user?.displayName ?? user?.phoneNumber ?? 'مسار';
    final photoUrl = user?.photoURL;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          // Top row: user avatar + name + actions
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, size: 20, color: colorScheme.primary))
                        : Icon(Icons.person, size: 20, color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(userName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (_isLoadingStatuses)
                      Row(children: [
                        SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(colorScheme.primary))),
                        const SizedBox(width: 4),
                        Text('جارٍ التحديث...', style: TextStyle(fontSize: 10, color: colorScheme.primary)),
                      ])
                    else
                      FreshnessIndicator(lastUpdated: _lastStatusUpdate, onTap: _pullToRefresh),
                  ],
                ),
              ),
              _buildActionIcon(AppIcons.refresh, _isLoadingStatuses ? null : _refreshStatuses, colorScheme),
              const SizedBox(width: 6),
              _buildActionIcon(AppIcons.settings, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())), colorScheme),
              const SizedBox(width: 6),
              _buildActionIcon(AppIcons.logout, () async {
                await _authService.signOut();
                if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }, colorScheme),
            ],
          ),
          const SizedBox(height: 10),
          // Search bar + location filter
          Row(
            children: [
              Expanded(
                child: CheckpointSearchBar(
                  mode: _selectedTabIndex == 0 ? SearchMode.map : SearchMode.list,
                  checkpoints: _allCheckpoints,
                  statuses: _statuses,
                  onChanged: (query) => setState(() => _searchQuery = query),
                  onCheckpointSelected: _onSearchCheckpointSelected,
                  onClear: () => setState(() => _searchQuery = ''),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openDrawer,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(AppIcons.location, size: 18, color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback? onTap, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Directionality(textDirection: TextDirection.ltr, child: Icon(icon, size: 17, color: onTap == null ? colorScheme.onSurfaceVariant.withOpacity(0.4) : colorScheme.onSurfaceVariant)),
      ),
    );
  }

  void _onSearchCheckpointSelected(Checkpoint cp) {
    // Fly to checkpoint on map
    try {
      _mapController.move(LatLng(cp.latitude, cp.longitude), 14.5);
    } catch (_) {}
    // Switch to map tab if on list
    if (_selectedTabIndex != 0) {
      _tabController.animateTo(0);
      setState(() => _selectedTabIndex = 0);
    }
  }

  Widget _buildTabBar(ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 42,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (i) => setState(() => _selectedTabIndex = i),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        indicatorPadding: const EdgeInsets.all(3),
        tabs: const [
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(AppIcons.map, size: 16), SizedBox(width: 6), Text('الخريطة')])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(AppIcons.list, size: 16), SizedBox(width: 6), Text('القائمة')])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.favorite, size: 16), SizedBox(width: 6), Text('المفضلة')])),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return _selectedTabIndex == 0
        ? const MapSkeleton()
        : const CheckpointListSkeleton();
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.wifiOff, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _subscribeToCheckpoints,
            icon: const Icon(AppIcons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(bool isDark) {
    if (_filteredCheckpoints.isEmpty) return _buildEmptyState(true);

    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final mapWidget = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: AppConstants.defaultLocation,
        initialZoom: AppConstants.defaultZoom,
        minZoom: 7.0,
        maxZoom: 15.0,
        onLongPress: (_, latLng) {
          if (_isAdmin) _showAddCheckpointDialog(position: latLng);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
          userAgentPackageName: 'com.msar.checkpoint_app',
          maxNativeZoom: 18,
          keepBuffer: 4,
          tileProvider: CachedTileProvider(
            store: TileCacheService.store,
          ),
        ),
        MarkerLayer(
          markers: _buildMarkers(),
          rotate: false,
        ),
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );

    Widget map = mapWidget;
    if (isDark) {
      map = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          1.3, 0, 0, 0, 30,
          0, 1.3, 0, 0, 30,
          0, 0, 1.3, 0, 30,
          0, 0, 0, 1, 0,
        ]),
        child: mapWidget,
      );
    }

    return Stack(
      children: [
        map,
        if (_selectedRegion != null)
          PositionedDirectional(
            top: 12,
            start: 12,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(20),
              child: Chip(
                avatar: Icon(AppIcons.gpsFixed, size: 14, color: Theme.of(context).colorScheme.primary),
                label: Text(_selectedRegion!, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(AppIcons.close, size: 14),
                onDeleted: () {
                  _selectRegion(null);
                  context.read<GovernorateProvider>().setManual(null);
                  try { _mapController.move(AppConstants.defaultLocation, AppConstants.defaultZoom); } catch (_) {}
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        const PositionedDirectional(
          bottom: 16,
          start: 16,
          child: MapLegend(),
        ),
        if (_isAdmin)
          PositionedDirectional(
            top: 8,
            end: 12,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '💡 اضغط مطولاً لإضافة حاجز',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.white.withOpacity(0.8), blurRadius: 8),
                      Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 16),
                    ],
                  ),
                ),
            ),
          ),
        if (_isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(AppIcons.wifiOff, size: 18, color: Theme.of(context).colorScheme.onError),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'لا يوجد اتصال بالإنترنت — البيانات المخزنة مؤقتاً',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onError),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListView() {
    if (_filteredCheckpoints.isEmpty && _searchQuery.isEmpty) return _buildEmptyState(false);

    // Apply search filter
    final searchFiltered = _searchQuery.isEmpty
        ? _filteredCheckpoints
        : _filteredCheckpoints.where((cp) => cp.name.contains(_searchQuery) || cp.region.contains(_searchQuery)).toList();

    // Empty search results
    if (searchFiltered.isEmpty && _searchQuery.isNotEmpty) {
      return EmptyStateView.noSearchResults(_searchQuery);
    }

    // Sort by distance, favorites first
    final sorted = List<Checkpoint>.from(searchFiltered);
    final favs = FavoritesService().favorites.value;
    sorted.sort((a, b) {
      final aFav = favs.contains(a.id) ? 0 : 1;
      final bFav = favs.contains(b.id) ? 0 : 1;
      if (aFav != bFav) return aFav.compareTo(bFav);
      if (_userLocation != null) {
        final dA = _haversineKm(_userLocation!.latitude, _userLocation!.longitude, a.latitude, a.longitude);
        final dB = _haversineKm(_userLocation!.latitude, _userLocation!.longitude, b.latitude, b.longitude);
        return dA.compareTo(dB);
      }
      return 0;
    });

    return RefreshIndicator(
      onRefresh: _pullToRefresh,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final cp = sorted[index];
          return CheckpointCard(
            checkpoint: cp,
            status: _statuses[cp.id],
            onTap: () => _openDetail(cp),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesView() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesService().favorites,
      builder: (context, favs, _) {
        final favCheckpoints = _filteredCheckpoints.where((cp) => favs.contains(cp.id)).toList();
        if (favCheckpoints.isEmpty) {
          return EmptyStateView.noFavorites();
        }
        return RefreshIndicator(
          onRefresh: _pullToRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: favCheckpoints.length,
            itemBuilder: (context, index) {
              final cp = favCheckpoints[index];
              return CheckpointCard(
                checkpoint: cp,
                status: _statuses[cp.id],
                onTap: () => _openDetail(cp),
              );
            },
          ),
        );
      },
    );
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Widget _buildEmptyState(bool isMap) {
    return EmptyStateView.noCheckpoints(
      onClearFilter: _selectedRegion != null ? () => _selectRegion(null) : null,
    );
  }

  Future<void> _onLocationFabPressed() async {
    final status = await _locationPermService.checkStatus();

    if (status == LocationResult.granted) {
      await _moveToUserLocation();
      return;
    }

    if (!mounted) return;

    final bool proceed = await LocationPermissionSheet.show(
      context,
      isDeniedForever: status == LocationResult.deniedForever,
      isServiceDisabled: status == LocationResult.serviceDisabled,
    );

    if (!proceed) return;

    if (status == LocationResult.deniedForever) {
      await _locationPermService.openSettings();
      return;
    }
    if (status == LocationResult.serviceDisabled) {
      await _locationPermService.openLocationSettings();
      return;
    }

    // denied — request system dialog
    final result = await _locationPermService.request();
    if (result == LocationResult.granted) {
      await _moveToUserLocation();
    }
  }

  Future<void> _moveToUserLocation() async {
    try {
      final pos = await _locationPermService.getPosition();
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _userLocation = target);
      _mapController.move(target, 14.0);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديد الموقع. تأكد من تفعيل GPS.')),
        );
      }
    }
  }

  List<Marker> _buildMarkers() {
    final favs = FavoritesService().favorites.value;
    return _filteredCheckpoints.map((cp) {
      final isFav = favs.contains(cp.id);
      return Marker(
        point: LatLng(cp.latitude, cp.longitude),
        width: isFav ? 140 : 120,
        height: isFav ? 90 : 76,
        child: CheckpointMarker(
          checkpoint: cp,
          status: _statuses[cp.id],
          isFavorite: isFav,
          onTap: () => _openDetail(cp),
        ),
      );
    }).toList();
  }

  void _openDetail(Checkpoint checkpoint) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CheckpointDetailScreen(checkpoint: checkpoint))).then((_) => _refreshStatuses());
  }

  void _showAddCheckpointDialog({LatLng? position}) {
    final nameController = TextEditingController();
    String? selectedRegion;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('إضافة حاجز جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الحاجز', hintText: 'مثال: حاجز قلنديا', border: OutlineInputBorder(), prefixIcon: Icon(AppIcons.location)),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRegion,
                decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder(), prefixIcon: Icon(AppIcons.place)),
                items: AppConstants.regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setDialogState(() => selectedRegion = v),
              ),
              if (position != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📍 موقع الحاجز:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('خط العرض: ${position.latitude.toStringAsFixed(6)}\nخط الطول: ${position.longitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسم الحاجز'), backgroundColor: Colors.orange));
                return;
              }
              if (selectedRegion == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المنطقة'), backgroundColor: Colors.orange));
                return;
              }
              if (position == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء الضغط مطولاً على الخريطة لتحديد موقع الحاجز'), backgroundColor: Colors.orange));
                return;
              }
              final newCheckpoint = Checkpoint(
                id: '',
                name: nameController.text.trim(),
                region: selectedRegion!,
                latitude: position.latitude,
                longitude: position.longitude,
                createdBy: _authService.currentUser?.uid,
                createdAt: DateTime.now(),
              );
              try {
                await _checkpointService.addCheckpoint(newCheckpoint);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ تم إضافة "${nameController.text.trim()}" بنجاح'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ فشل الإضافة: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
      ),
    );
  }
}
