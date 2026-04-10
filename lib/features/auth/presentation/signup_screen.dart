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

// ── Root screen ────────────────────────────────────────────────────────────────
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ─────────────────────────────────────────────
                _buildTopBar(context, isDark),

                // ── Brand block ─────────────────────────────────────────
                _buildBrandBlock(isDark),

                const SizedBox(height: 20),

                // ── Student signup ──────────────────────────────────────
                const SizedBox(height: 4),
                Expanded(
                  child: _StudentSignupForm(isDark: isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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

  Widget _buildBrandBlock(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: isDark ? kText1Dark : kText1Light,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Join thousands of learners',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? kText2Dark : kText2Light,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared field helpers ───────────────────────────────────────────────────────
Widget _fieldLabel(String label, bool isDark) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? kText2Dark : kText2Light,
          letterSpacing: -0.1,
        ),
      ),
    );

Widget _buildField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  required bool isDark,
  bool obscureText = false,
  int maxLines = 1,
  TextInputType? keyboardType,
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
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    maxLines: maxLines,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

Widget _buildDropdown<T>({
  required T? value,
  required String hint,
  required IconData icon,
  required List<DropdownMenuItem<T>> items,
  required void Function(T?) onChanged,
  required bool isDark,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: isDark ? Colors.white.withOpacity(0.08) : kDivLight,
    ),
  );

  return DropdownButtonFormField<T>(
    value: value,
    items: items,
    onChanged: onChanged,
    style: TextStyle(fontSize: 14, color: isDark ? kText1Dark : kText1Light),
    dropdownColor: isDark ? kSurfaceDark : kSurface,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(fontSize: 14, color: isDark ? kText2Dark : kText3Light),
      prefixIcon: Icon(icon, size: 19, color: kPrimary),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.04) : kBgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
    ),
  );
}

Widget _buildCTAButton({
  required String text,
  required bool isLoading,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: isLoading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: isLoading ? kPrimary.withOpacity(0.7) : kPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    )),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
    ),
  );
}

Widget _buildLoginRow(BuildContext context, bool isDark) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Already have an account? ',
        style:
            TextStyle(fontSize: 14, color: isDark ? kText2Dark : kText2Light),
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
  );
}

// ── Student signup form ────────────────────────────────────────────────────────
class _StudentSignupForm extends ConsumerStatefulWidget {
  final bool isDark;
  const _StudentSignupForm({required this.isDark});

  @override
  ConsumerState<_StudentSignupForm> createState() => _StudentSignupFormState();
}

class _StudentSignupFormState extends ConsumerState<_StudentSignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _selectedClass;
  String? _selectedSpec;

  static const _classes = [
    'class-6th',
    'class-7th',
    'class-8th',
    'class-9th',
    'class-10th',
    'class-11th',
    'class-12th',
    'dropper',
  ];
  static const _specs = ['IIT-JEE', 'NEET', 'CBSE'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final success = await ref.read(authStateProvider.notifier).signupStudent(
          name: _nameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          email: email,
          password: _passwordCtrl.text,
          mobileNumber: _mobileCtrl.text.trim(),
          specialization: _selectedSpec,
          academicClass: _selectedClass,
        );
    if (success && mounted) {
      AppSnackbar.success(context, 'OTP sent to your email.');
      context.push('/verify-email', extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = widget.isDark;

    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        AppSnackbar.error(context, next.error!);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full Name
            _fieldLabel('Full Name', isDark),
            _buildField(
              controller: _nameCtrl,
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
              isDark: isDark,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),

            // Email
            _fieldLabel('Email Address', isDark),
            _buildField(
              controller: _emailCtrl,
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                  return 'Invalid email address';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Username
            _fieldLabel('Username', isDark),
            _buildField(
              controller: _usernameCtrl,
              hint: 'e.g. aman_verma',
              icon: Icons.alternate_email_rounded,
              isDark: isDark,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Please enter a username';
                if (value.length < 3 || value.length > 30) {
                  return 'Username must be 3-30 characters';
                }
                if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                  return 'Use lowercase letters, numbers, and underscores';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mobile
            _fieldLabel('Mobile Number', isDark),
            _buildField(
              controller: _mobileCtrl,
              hint: 'Enter your mobile number',
              icon: Icons.phone_outlined,
              isDark: isDark,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter mobile number' : null,
            ),
            const SizedBox(height: 16),

            // Class
            _fieldLabel('Class', isDark),
            _buildDropdown<String>(
              value: _selectedClass,
              hint: 'Select your class',
              icon: Icons.school_outlined,
              isDark: isDark,
              onChanged: (v) => setState(() => _selectedClass = v),
              items: _classes
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.replaceAll('-', ' ').toUpperCase(),
                            style: TextStyle(
                                fontSize: 14,
                                color: isDark ? kText1Dark : kText1Light)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Exam preparation
            _fieldLabel('Exam Preparation', isDark),
            _buildDropdown<String>(
              value: _selectedSpec,
              hint: 'Select your exam',
              icon: Icons.menu_book_outlined,
              isDark: isDark,
              onChanged: (v) => setState(() => _selectedSpec = v),
              items: _specs
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 14,
                                color: isDark ? kText1Dark : kText1Light)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Password
            _fieldLabel('Password', isDark),
            _buildField(
              controller: _passwordCtrl,
              hint: 'Create a password',
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
                if (v == null || v.isEmpty) return 'Please enter a password';
                if (v.length < 6) return 'Min 6 characters required';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            _fieldLabel('Confirm Password', isDark),
            _buildField(
              controller: _confirmPasswordCtrl,
              hint: 'Re-enter your password',
              icon: Icons.lock_outline_rounded,
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
              validator: (v) =>
                  v != _passwordCtrl.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 28),

            // CTA
            _buildCTAButton(
              text: 'Create Student Account',
              isLoading: authState.isLoading,
              onTap: _handleSignup,
            ),
            const SizedBox(height: 20),

            _buildLoginRow(context, isDark),
          ],
        ),
      ),
    );
  }
}
