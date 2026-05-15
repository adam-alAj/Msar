import 'package:flutter/material.dart';
import '../utils/app_icons.dart';

// ─── DOC DATA ─────────────────────────────────────────────────────────────────

class _DocSection {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final List<String>? steps;

  const _DocSection({required this.id, required this.title, required this.icon, required this.description, this.steps});
}

const _lastUpdated = '١٤ مايو ٢٠٢٦';

final _sections = [
  _DocSection(
    id: 'map',
    title: 'عرض الخريطة',
    icon: AppIcons.map,
    description: 'الخريطة هي الواجهة الرئيسية للتطبيق. تعرض جميع الحواجز كدبابيس ملونة حسب حالتها الحالية. الألوان تعكس آخر تصويتات المستخدمين خلال الساعة الماضية.\n\nالأخضر يعني أن الحاجز سالك والمرور طبيعي. البرتقالي يشير إلى ازدحام أو تأخير. الأحمر يعني أن الحاجز مغلق.',
    steps: ['افتح التطبيق — تظهر الخريطة تلقائياً', 'استخدم إصبعين للتكبير والتصغير', 'اضغط على أي دبوس لفتح تفاصيل الحاجز', 'اضغط على زر الموقع لتحديد مكانك على الخريطة'],
  ),
  _DocSection(
    id: 'list',
    title: 'عرض القائمة',
    icon: AppIcons.list,
    description: 'القائمة تعرض جميع الحواجز ككروت مرتبة حسب المسافة من موقعك. كل كرت يعرض اسم الحاجز وحالة كل اتجاه (داخل وخارج) مع نسبة التصويت.\n\nيمكنك سحب القائمة للأسفل لتحديث البيانات يدوياً.',
    steps: ['اضغط على تبويب "القائمة" في أسفل شريط التبويب', 'تصفح الكروت — مرتبة من الأقرب إلى الأبعد', 'اضغط على أي كرت لفتح تفاصيل الحاجز'],
  ),
  _DocSection(
    id: 'search',
    title: 'البحث عن حاجز',
    icon: AppIcons.locationSearching,
    description: 'شريط البحث يعمل بطريقتين حسب التبويب النشط:\n\nفي الخريطة: تظهر قائمة اقتراحات مع نقطة ملونة تدل على حالة كل حاجز. عند اختيار حاجز، تنتقل الخريطة إليه مباشرة.\n\nفي القائمة: تُفلتر الكروت فورياً مع كل حرف تكتبه. يمكنك البحث باسم الحاجز أو اسم المنطقة.',
  ),
  _DocSection(
    id: 'details',
    title: 'تفاصيل الحاجز',
    icon: AppIcons.location,
    description: 'شاشة التفاصيل تعرض كل المعلومات عن حاجز معين:\n\n• شارة "مباشر" الخضراء النابضة تعني أن البيانات تُحدَّث لحظياً\n• بطاقة الإحصائيات تعرض إجمالي التصويتات ووقت آخر تحديث\n• بطاقتا الاتجاه (داخل / خارج) تعرضان الحالة الحالية ونسبة التصويت وعدد الأصوات\n• قسم آراء المسافرين يعرض آخر ٥ تعليقات من الساعة الماضية',
  ),
  _DocSection(
    id: 'voting',
    title: 'نظام التصويت',
    icon: AppIcons.vote,
    description: 'التصويت هو الطريقة التي يُحدِّث بها المجتمع حالة الحواجز. كل تصويت يؤثر على الحالة المعروضة لجميع المستخدمين.\n\nآلية الحساب: تُجمع جميع الأصوات المُرسلة خلال آخر ٦٠ دقيقة. الحالة التي تحصل على أعلى نسبة تصبح الحالة الرسمية المعروضة. في حالة التعادل، تُعطى الأولوية للحالة الأخطر (أزمة > مغلق > سالك).\n\nيمكنك التصويت من أي مكان — لست مضطراً للتواجد قرب الحاجز.',
    steps: ['افتح تفاصيل الحاجز', 'اضغط زر "تصويت"', 'اختر الاتجاه: داخل أو خارج (أو كليهما)', 'اختر الحالة: سالك أو أزمة أو مغلق', 'أضف تعليقاً (اختياري) لوصف الوضع', 'اضغط "إرسال التصويت"'],
  ),
  _DocSection(
    id: 'comments',
    title: 'التعليقات وآراء المسافرين',
    icon: AppIcons.comment,
    description: 'عند التصويت، يمكنك إضافة تعليق نصي يصف الوضع بتفصيل أكثر. التعليقات مجهولة تماماً — لا يظهر اسم الكاتب.\n\nتظهر التعليقات في قسم "آراء المسافرين" على شاشة تفاصيل الحاجز. يُعرض آخر ٥ تعليقات من الساعة الماضية. كل تعليق يحمل شارة تدل على الاتجاه والحالة التي صوّت عليها الكاتب.\n\nاضغط "عرض الكل" لمشاهدة جميع التعليقات السابقة.',
  ),
  _DocSection(
    id: 'regions',
    title: 'تصفية المناطق',
    icon: AppIcons.filter,
    description: 'يمكنك تصفية الحواجز حسب المنطقة لعرض حواجز محافظة معينة فقط. عند فتح التطبيق، يُكتشف موقعك تلقائياً وتُعرض حواجز محافظتك.\n\nالفلتر يبقى نشطاً حتى تزيله يدوياً. عند التحديث التلقائي، تبقى المنطقة المختارة كما هي.',
    steps: ['اضغط أيقونة الموقع في أعلى الشاشة', 'اختر المنطقة من القائمة الجانبية', 'لإزالة الفلتر: اضغط ✕ على شارة المنطقة في الخريطة أو اختر "جميع المناطق"'],
  ),
  _DocSection(
    id: 'settings',
    title: 'الإعدادات',
    icon: AppIcons.settings,
    description: 'من شاشة الإعدادات يمكنك:\n\n• تغيير مظهر التطبيق: شمس (يتبع الشروق والغروب تلقائياً)، نظام (يتبع إعدادات جهازك)، فاتح، أو داكن\n• مسح ذاكرة الخريطة المؤقتة لتحرير مساحة التخزين\n• الوصول إلى المساعدة ودليل الاستخدام',
  ),
  _DocSection(
    id: 'status',
    title: 'حالات الحاجز',
    icon: AppIcons.checkpointOpen,
    description: 'لكل حاجز حالتان منفصلتان — واحدة لكل اتجاه:\n\n🟢 سالك (OPEN): الحاجز مفتوح والمرور يسير بشكل طبيعي بدون تأخير ملحوظ.\n\n🟠 أزمة (CROWDED): هناك ازدحام أو تأخير — قد يكون بسبب تفتيش مكثف أو حجم مرور عالٍ.\n\n🔴 مغلق (CLOSED): الحاجز مغلق بالكامل ولا يمكن العبور منه حالياً.\n\nالحالة تتغير بناءً على تصويتات المستخدمين خلال آخر ٦٠ دقيقة.',
  ),
];

// ─── DOCUMENTATION SCREEN ─────────────────────────────────────────────────────

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {for (final s in _sections) s.id: GlobalKey()};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('دليل الاستخدام'), centerTitle: true),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
        itemCount: _sections.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeader(colorScheme);
          final section = _sections[index - 1];
          return _DocSectionWidget(key: _sectionKeys[section.id], section: section);
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Icon(AppIcons.clock, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text('آخر تحديث: $_lastUpdated', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

// ─── DOC SECTION WIDGET ───────────────────────────────────────────────────────

class _DocSectionWidget extends StatefulWidget {
  final _DocSection section;
  const _DocSectionWidget({super.key, required this.section});

  @override
  State<_DocSectionWidget> createState() => _DocSectionWidgetState();
}

class _DocSectionWidgetState extends State<_DocSectionWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = widget.section;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                  child: Directionality(textDirection: TextDirection.ltr, child: Icon(s.icon, size: 18, color: colorScheme.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(s.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface))),
                Icon(_expanded ? AppIcons.caretUp : AppIcons.caretDown, size: 12, color: colorScheme.onSurfaceVariant),
              ]),
            ),
          ),
          // Body (collapsible)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.description, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.7)),
                        if (s.steps != null) ...[
                          const SizedBox(height: 12),
                          ...s.steps!.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.12), shape: BoxShape.circle),
                                  child: Center(child: Text('${e.key + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colorScheme.primary))),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.value, style: TextStyle(fontSize: 12, color: colorScheme.onSurface, height: 1.5))),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
