import 'package:flutter/material.dart';
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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _emailSent = false;

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
    _emailCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authStateProvider.notifier).forgotPassword(
          email: _emailCtrl.text.trim(),
          userType: 'student',
        );
    if (success && mounted) {
      setState(() => _emailSent = true);
      // replay animation for the success view
      _fadeCtrl
        ..reset()
        ..forward();
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
                // ── Top bar ────────────────────────────────────────────
                _buildTopBar(context, isDark),

                // ── Scrollable body ────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: _emailSent
                        ? _buildSuccessView(context, isDark)
                        : _buildFormView(context, authState, isDark),
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
      child: Row(
        children: [
          GestureDetector(
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
        ],
      ),
    );
  }

  // ── Form view ─────────────────────────────────────────────────────────────
  Widget _buildFormView(
      BuildContext context, AuthState authState, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // icon tile
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: Colors.white, size: 38),
            ),
          ),

          const SizedBox(height: 28),

          // heading
          Center(
            child: Text(
              'Forgot Password?',
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
              'Enter your email and we\'ll send you\nOTP to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: isDark ? kText2Dark : kText2Light,
              ),
            ),
          ),

          const SizedBox(height: 36),

          // form card
          Container(
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
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? kText2Dark : kText2Light,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSubmit(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? kText1Dark : kText1Light,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? kText2Dark : kText3Light,
                    ),
                    prefixIcon: const Icon(Icons.mail_outline_rounded,
                        size: 19, color: kPrimary),
                    filled: true,
                    fillColor:
                        isDark ? Colors.white.withOpacity(0.04) : kBgLight,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color:
                            isDark ? Colors.white.withOpacity(0.08) : kDivLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color:
                            isDark ? Colors.white.withOpacity(0.08) : kDivLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kPrimary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFEF4444), width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFEF4444), width: 1.5),
                    ),
                    errorStyle:
                        const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CTA button
          GestureDetector(
            onTap: authState.isLoading ? null : _handleSubmit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color:
                    authState.isLoading ? kPrimary.withOpacity(0.7) : kPrimary,
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
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Send Reset OTP',
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

          const SizedBox(height: 24),

          // back to login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? kText2Dark : kText2Light,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Success view ──────────────────────────────────────────────────────────
  Widget _buildSuccessView(BuildContext context, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 48),

        // animated success icon
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimary, kPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                color: Colors.white, size: 44),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? kText1Dark : kText1Light,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We\'ve sent reset instructions to',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? kText2Dark : kText2Light,
          ),
        ),
        const SizedBox(height: 6),
        // email pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kPrimaryBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimaryMid),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mail_outline_rounded, size: 14, color: kPrimary),
              const SizedBox(width: 6),
              Text(
                _emailCtrl.text.trim(),
                style: const TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // info card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _stepRow(
                icon: Icons.inbox_rounded,
                text: 'Check your inbox for the OTP email',
                isDark: isDark,
              ),
              _divider(isDark),
              _stepRow(
                icon: Icons.link_rounded,
                text: ' Open the mail and verify the OTP code',
                isDark: isDark,
              ),
              _divider(isDark),
              _stepRow(
                icon: Icons.lock_open_rounded,
                text: 'Create a new strong password',
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Continue button
        GestureDetector(
          onTap: () => context.push(
            '/reset-password',
            extra: {
              'email': _emailCtrl.text.trim(),
              'userType': 'student',
            },
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_reset_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Continue to Reset',
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

        const SizedBox(height: 12),

        // try again
        GestureDetector(
          onTap: () {
            setState(() => _emailSent = false);
            _fadeCtrl
              ..reset()
              ..forward();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? kSurfaceDark : kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
              ),
            ),
            child: Center(
              child: Text(
                'Didn\'t receive email? Try again',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? kText2Dark : kText2Light,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _stepRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimary, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? kText2Dark : kText2Light,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        color: isDark ? Colors.white.withOpacity(0.07) : kDivLight,
      );
}
