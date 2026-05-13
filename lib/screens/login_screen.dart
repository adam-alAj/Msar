import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/skeleton_loaders.dart';
import 'map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;
  String? _verificationId;
  bool _otpSent = false;
  String _selectedCode = '+970';

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  void _goToMap() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MapScreen()));
  }

  String get _fullPhoneNumber => '$_selectedCode${_phoneController.text.trim()}';
  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _loginWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _authService.signInWithGoogle();
      if (res != null && mounted) _goToMap();
      else setState(() => _error = 'فشل تسجيل الدخول');
    } catch (_) {
      setState(() => _error = 'حدث خطأ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOTP() async {
    final number = _phoneController.text.trim();
    if (number.isEmpty) { setState(() => _error = 'أدخل رقم الهاتف'); return; }
    setState(() { _loading = true; _error = null; });
    await _authService.sendOTP(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (verificationId) {
        setState(() { _verificationId = verificationId; _otpSent = true; _loading = false; });
        Future.delayed(const Duration(milliseconds: 100), () => _otpFocusNodes[0].requestFocus());
      },
      onError: (error) { setState(() { _error = error; _loading = false; }); },
      onAutoVerified: (_) { if (mounted) _goToMap(); },
    );
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null) return;
    final otp = _otpCode;
    if (otp.length < 6) { setState(() => _error = 'أدخل رمز التحقق كاملاً'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _authService.verifyOTP(verificationId: _verificationId!, otp: otp);
      if (res != null && mounted) _goToMap();
    } catch (e) {
      setState(() => _error = e is String ? e : 'رمز خاطئ، حاول مرة أخرى');
      for (final c in _otpControllers) c.clear();
      _otpFocusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildOtpBox(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary, height: 1.0),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) _otpFocusNodes[index + 1].requestFocus();
          else if (val.isEmpty && index > 0) _otpFocusNodes[index - 1].requestFocus();
          if (_otpCode.length == 6) { FocusScope.of(context).unfocus(); _verifyOTP(); }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 28, right: 28, top: 0, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 10))],
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.asset('assets/image.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(height: 26),

                  // Title
                  Text('مسار', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: -1)),
                  const SizedBox(height: 10),
                  Text('تابع أخبار الطرق بدقة عالية وسهولة تامة', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withOpacity(0.55), height: 1.4)),

                  const Spacer(flex: 1),

                  // Error
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600)),
                    ),

                  // Phone input
                  if (!_otpSent) ...[
                    Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCode,
                              onChanged: (val) => setState(() => _selectedCode = val!),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              borderRadius: BorderRadius.circular(14),
                              items: const [
                                DropdownMenuItem(value: '+970', child: Text('🇵🇸  +970', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                DropdownMenuItem(value: '+972', child: Text('🇮🇱  +972', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: colorScheme.outline.withOpacity(0.2)),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: '591234567',
                                hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.35)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text('أدخل الرمز المرسل إلى $_fullPhoneNumber', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, _buildOtpBox)),
                  ],

                  const SizedBox(height: 12),

                  // Send OTP button
                  if (!_otpSent)
                    GestureDetector(
                      onTap: _loading ? null : _sendOTP,
                      child: Container(
                        height: 58, width: double.infinity,
                        decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(14)),
                        child: Center(
                          child: _loading
                              ? SkeletonShimmer(child: Container(height: 20, width: 100, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))))
                              : Text('إرسال رمز التحقق', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onPrimary)),
                        ),
                      ),
                    ),

                  if (_otpSent)
                    Column(
                      children: [
                        if (_loading) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: SkeletonShimmer(child: SkeletonBone(width: 140, height: 14))),
                        TextButton(
                          onPressed: () => setState(() { _otpSent = false; _verificationId = null; for (final c in _otpControllers) c.clear(); _error = null; }),
                          child: Text('تغيير رقم الهاتف', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.3))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('أو', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)))),
                      Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.3))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Google button
                  GestureDetector(
                    onTap: _loading ? null : _loginWithGoogle,
                    child: Container(
                      height: 58, width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 26, height: 26, child: Image.asset('assets/google.webp', fit: BoxFit.contain)),
                          const SizedBox(width: 12),
                          Text('تسجيل الدخول باستخدام Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text('بمساهمتك يتم تحسين تجربة التنقل داخل المنطقة', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.4), height: 1.5)),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
