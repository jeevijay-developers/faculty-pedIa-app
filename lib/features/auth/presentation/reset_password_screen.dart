import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../providers/auth_provider.dart';

// ── Design tokens (monochromatic Blue-600) ─────────────────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

const kSurface = Colors.white;
const kSurfaceDark = Color(0xFF1E293B);
const kBgLight = Color(0xFFF8FAFC);
const kBgDark = Color(0xFF0F172A);
const kText1Light = Color(0xFF0F172A);
const kText2Light = Color(0xFF64748B);
const kText3Light = Color(0xFF94A3B8);
const kText1Dark = Colors.white;
const kText2Dark = Color(0xFF94A3B8);
const kDivLight = Color(0xFFF1F5F9);

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String userType;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.userType,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // OTP individual digit controllers (6 boxes)
  final List<TextEditingController> _otpDigitCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  // entrance animation
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    for (final c in _otpDigitCtrl) c.dispose();
    for (final f in _otpFocus) f.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String get _otp => _otpDigitCtrl.map((c) => c.text).join();

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authStateProvider.notifier).resetPassword(
          email: widget.email,
          userType: widget.userType,
          otp: _otp,
          newPassword: _passwordCtrl.text.trim(),
        );
    if (ok && mounted) {
      AppSnackbar.success(context, 'Password reset successfully.');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        AppSnackbar.error(context, next.error!);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // top bar
                _buildTopBar(context, isDark),

                // scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),

                          // icon
                          Center(child: _buildIcon()),

                          const SizedBox(height: 24),

                          // heading
                          Center(
                            child: Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark ? kText1Dark : kText1Light,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Enter the 6-digit code sent to',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? kText2Dark : kText2Light,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // email pill
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isDark ? kSurfaceDark : kPrimaryBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kPrimaryMid),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.mail_outline_rounded,
                                      size: 13, color: kPrimary),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.email,
                                    style: const TextStyle(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── OTP boxes ──────────────────────────────
                          _buildOtpLabel(isDark),
                          const SizedBox(height: 12),
                          _buildOtpRow(isDark),

                          const SizedBox(height: 24),

                          // ── Password fields card ────────────────────
                          _buildPasswordCard(isDark),

                          const SizedBox(height: 28),

                          // ── CTA ────────────────────────────────────
                          GestureDetector(
                            onTap: authState.isLoading ? null : _handleReset,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: authState.isLoading
                                    ? kPrimary.withOpacity(0.7)
                                    : kPrimary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimary.withOpacity(0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: authState.isLoading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock_reset_rounded,
                                            color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Reset Password',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // back to login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Remember your password? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? kText2Dark : kText2Light,
                                  )),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text('Sign In',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? kText1Dark : kText1Light, size: 16),
        ),
      ),
    );
  }

  // ── Icon ──────────────────────────────────────────────────────────────────
  Widget _buildIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.lock_outline_rounded,
            color: Colors.white, size: 38),
      ),
    );
  }

  // ── OTP label ─────────────────────────────────────────────────────────────
  Widget _buildOtpLabel(bool isDark) {
    return Row(
      children: [
        Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: isDark ? kText1Dark : kText1Light,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimaryMid),
          ),
          child: const Text('6 digits',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              )),
        ),
      ],
    );
  }

  // ── OTP 6-box row ─────────────────────────────────────────────────────────
  Widget _buildOtpRow(bool isDark) {
    return FormField<String>(
      validator: (_) {
        if (_otp.length != 6) return 'Please enter the complete 6-digit OTP';
        return null;
      },
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _otpBox(i, isDark)),
          ),
          if (field.hasError) ...[
            const SizedBox(height: 6),
            Text(field.errorText!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
          ],
        ],
      ),
    );
  }

  Widget _otpBox(int index, bool isDark) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextFormField(
        controller: _otpDigitCtrl[index],
        focusNode: _otpFocus[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: isDark ? kText1Dark : kText1Light,
          letterSpacing: -0.5,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? kSurfaceDark : kSurface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.08) : kDivLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.08) : kDivLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _otpFocus[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _otpFocus[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  // ── Password card ─────────────────────────────────────────────────────────
  Widget _buildPasswordCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New password
          _label('New Password', isDark),
          const SizedBox(height: 8),
          _field(
            controller: _passwordCtrl,
            hint: 'Create a new password',
            icon: Icons.lock_outline_rounded,
            isDark: isDark,
            obscureText: _obscurePass,
            textInputAction: TextInputAction.next,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePass = !_obscurePass),
              child: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: isDark ? kText2Dark : kText3Light,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please enter a new password';
              }
              if (v.length < 8) return 'At least 8 characters required';
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Confirm password
          _label('Confirm Password', isDark),
          const SizedBox(height: 8),
          _field(
            controller: _confirmCtrl,
            hint: 'Re-enter the new password',
            icon: Icons.lock_reset_rounded,
            isDark: isDark,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: isDark ? kText2Dark : kText3Light,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please confirm your password';
              }
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _label(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? kText2Dark : kText2Light,
          letterSpacing: -0.1,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: isDark ? Colors.white.withOpacity(0.08) : kDivLight,
      ),
    );
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      validator: validator,
      style: TextStyle(fontSize: 14, color: isDark ? kText1Dark : kText1Light),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(fontSize: 14, color: isDark ? kText2Dark : kText3Light),
        prefixIcon: Icon(icon, size: 19, color: kPrimary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : kBgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
      ),
    );
  }
}
