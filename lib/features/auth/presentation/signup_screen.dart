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

// ── Step model ─────────────────────────────────────────────────────────────────
class _Step {
  final String label;
  final IconData icon;
  const _Step(this.label, this.icon);
}

const _steps = [
  _Step('Personal', Icons.person_rounded),
  _Step('Academic', Icons.school_rounded),
  _Step('Security', Icons.lock_rounded),
];

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

  final PageController _pageCtrl = PageController();
  int _currentStep = 0;

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String? _selectedClass;
  String? _selectedSpec;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

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
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_formKeys[_currentStep].currentState!.validate()) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageCtrl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _handleSignup();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageCtrl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  Future<void> _handleSignup() async {
    final auth = ref.read(authStateProvider);
    if (auth.isLoading) return;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        AppSnackbar.error(context, next.error!);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary, kPrimaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildHeroHeader(isDark),
                        _buildStepProgress(isDark, onColorBackground: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildPersonalStep(isDark),
                        _buildAcademicStep(isDark),
                        _buildSecurityStep(isDark),
                      ],
                    ),
                  ),
                  _buildBottomNav(context, isDark, authState.isLoading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero header ───────────────────────────────────────────────────────────
  Widget _buildHeroHeader(bool isDark) {
    final subtitles = [
      'Tell us who you are',
      'Set your learning goals',
      'Secure your account',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _prevStep,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Step ${_currentStep + 1} of 3',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Create your\nStudent Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitles[_currentStep],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step progress ─────────────────────────────────────────────────────────
  Widget _buildStepProgress(bool isDark, {bool onColorBackground = false}) {
    return Container(
      color: onColorBackground
          ? Colors.transparent
          : (isDark ? kSurfaceDark : kSurface),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          final isLast = i == _steps.length - 1;
          final activeColor = onColorBackground ? Colors.white : kPrimary;
          final activeIconColor =
              onColorBackground ? kPrimaryDark : Colors.white;
          final inactiveColor = onColorBackground
              ? Colors.white.withOpacity(0.55)
              : (isDark ? kText2Dark : kText3Light);
          final surfaceColor = onColorBackground
              ? Colors.white.withOpacity(0.18)
              : (isDark ? Colors.white.withOpacity(0.06) : kDivLight);
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDone || isActive ? activeColor : surfaceColor,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: (onColorBackground
                                        ? Colors.black
                                        : kPrimary)
                                    .withOpacity(0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(Icons.check_rounded,
                            color: activeIconColor, size: 16)
                        : Icon(_steps[i].icon,
                            color: isActive ? activeIconColor : inactiveColor,
                            size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _steps[i].label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                    color: isActive || isDone ? activeColor : inactiveColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        height: 2,
                        decoration: BoxDecoration(
                          color: i < _currentStep
                              ? activeColor
                              : (onColorBackground
                                  ? Colors.white.withOpacity(0.25)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : kDivLight)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: Personal ──────────────────────────────────────────────────────
  Widget _buildPersonalStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _formKeys[0],
        child: _sectionCard(
          isDark: isDark,
          children: [
            _fieldLabel('Full Name', isDark),
            _buildField(
                controller: _nameCtrl,
                hint: 'Enter your full name',
                icon: Icons.badge_outlined,
                isDark: isDark,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter your name' : null),
            const SizedBox(height: 18),
            _fieldLabel('Username', isDark),
            _buildField(
                controller: _usernameCtrl,
                hint: 'e.g. aman_verma',
                icon: Icons.alternate_email_rounded,
                isDark: isDark,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Please enter a username';
                  if (val.length < 3 || val.length > 30)
                    return 'Must be 3–30 characters';
                  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(val))
                    return 'Lowercase, numbers & underscores only';
                  return null;
                }),
            const SizedBox(height: 18),
            _fieldLabel('Email Address', isDark),
            _buildField(
                controller: _emailCtrl,
                hint: 'Enter your email',
                icon: Icons.mail_outline_rounded,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                    return 'Invalid email address';
                  return null;
                }),
            const SizedBox(height: 18),
            _fieldLabel('Mobile Number', isDark),
            _buildField(
                controller: _mobileCtrl,
                hint: '+91 XXXXXXXXXX',
                icon: Icons.phone_iphone_rounded,
                isDark: isDark,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: (v) => v == null || v.isEmpty
                    ? 'Please enter mobile number'
                    : null),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Academic ──────────────────────────────────────────────────────
  Widget _buildAcademicStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              isDark: isDark,
              children: [
                _fieldLabel('Current Class', isDark),
                _buildDropdown<String>(
                  value: _selectedClass,
                  hint: 'Select your class',
                  icon: Icons.class_outlined,
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
                const SizedBox(height: 18),
                _fieldLabel('Target Exam', isDark),
                _buildDropdown<String>(
                  value: _selectedSpec,
                  hint: 'Select target exam',
                  icon: Icons.emoji_events_outlined,
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
              ],
            ),
            const SizedBox(height: 16),
            // quick select chips
            Row(
              children: [
                Expanded(
                    child: _examChip('IIT-JEE', Icons.science_rounded, isDark)),
                const SizedBox(width: 10),
                Expanded(
                    child: _examChip(
                        'NEET', Icons.medical_services_rounded, isDark)),
                const SizedBox(width: 10),
                Expanded(
                    child: _examChip('CBSE', Icons.school_rounded, isDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _examChip(String name, IconData icon, bool isDark) {
    final isSelected = _selectedSpec == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedSpec = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : (isDark ? kSurfaceDark : kSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? kPrimary
                : (isDark ? Colors.white.withOpacity(0.06) : kDivLight),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: kPrimary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 22,
                color: isSelected
                    ? Colors.white
                    : (isDark ? kText2Dark : kText3Light)),
            const SizedBox(height: 6),
            Text(name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? kText2Dark : kText2Light),
                )),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Security ──────────────────────────────────────────────────────
  Widget _buildSecurityStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // tip card
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? kSurfaceDark : kPrimaryBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPrimaryMid),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : kSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: kPrimary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use at least 6 characters with letters and numbers for a strong password.',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: isDark ? kText2Dark : kText2Light),
                    ),
                  ),
                ],
              ),
            ),
            _sectionCard(
              isDark: isDark,
              children: [
                _fieldLabel('Password', isDark),
                _buildField(
                  controller: _passwordCtrl,
                  hint: 'Create a strong password',
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
                        color: isDark ? kText2Dark : kText3Light),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please enter a password';
                    if (v.length < 6) return 'Min 6 characters required';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _fieldLabel('Confirm Password', isDark),
                _buildField(
                  controller: _confirmPasswordCtrl,
                  hint: 'Re-enter your password',
                  icon: Icons.lock_reset_rounded,
                  isDark: isDark,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    child: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: isDark ? kText2Dark : kText3Light),
                  ),
                  validator: (v) =>
                      v != _passwordCtrl.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context, bool isDark, bool isLoading) {
    final isLast = _currentStep == 2;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        border: Border(
            top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
                width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isLoading ? null : _nextStep,
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
                      offset: const Offset(0, 5))
                ],
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white))))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isLast ? 'Create Account' : 'Continue',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.2)),
                        const SizedBox(width: 8),
                        Icon(
                            isLast
                                ? Icons.check_circle_outline_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ',
                  style: TextStyle(
                      fontSize: 13, color: isDark ? kText2Dark : kText2Light)),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text('Sign In',
                    style: TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────
  Widget _sectionCard({required bool isDark, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────
Widget _fieldLabel(String label, bool isDark) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? kText2Dark : kText2Light,
              letterSpacing: -0.1)),
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
    borderSide:
        BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : kDivLight),
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
          borderSide: const BorderSide(color: kPrimary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
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
    borderSide:
        BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : kDivLight),
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
          borderSide: const BorderSide(color: kPrimary, width: 1.5)),
    ),
  );
}
