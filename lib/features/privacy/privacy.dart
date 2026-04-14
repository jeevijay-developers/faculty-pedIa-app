import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

// ── Data models ────────────────────────────────────────────────────────────────
class _PrivacySection {
  final String number;
  final IconData icon;
  final String title;
  final String? intro, paragraph, highlight;
  final List<String>? items;
  final List<_Subsection>? subsections;
  final _Callout? callout;

  const _PrivacySection({
    required this.number,
    required this.icon,
    required this.title,
    this.intro,
    this.paragraph,
    this.highlight,
    this.items,
    this.subsections,
    this.callout,
  });
}

class _Subsection {
  final String label;
  final List<String> items;
  const _Subsection({required this.label, required this.items});
}

class _Callout {
  final String type, text;
  const _Callout({required this.type, required this.text});
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // consent banner
                  _buildConsentBanner(),
                  const SizedBox(height: 20),

                  // quick nav chips
                  _buildQuickNav(isDark),
                  const SizedBox(height: 24),

                  // policy sections
                  ..._sections
                      .map((s) => _SectionCard(section: s, isDark: isDark)),

                  const SizedBox(height: 8),

                  // contact
                  _sectionLabel('SECTION 14', 'Contact Information', isDark),
                  const SizedBox(height: 16),
                  _buildContactRow(isDark),

                  const SizedBox(height: 28),

                  // declaration
                  _buildDeclaration(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      elevation: 0,
      backgroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.privacy_tip_rounded,
                            color: Colors.white, size: 13),
                        SizedBox(width: 6),
                        Text('Privacy & Data Protection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FacultyPedia · Data Protection Statement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // info pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _heroPill(Icons.language_rounded, 'www.facultypedia.com'),
                      const SizedBox(width: 8),
                      _heroPill(Icons.place_rounded, 'Kota, Rajasthan'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ── Consent banner ────────────────────────────────────────────────────────
  Widget _buildConsentBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'By accessing or using the Platform, you consent to the practices described in this Privacy Policy.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick nav ─────────────────────────────────────────────────────────────
  Widget _buildQuickNav(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TABLE OF CONTENTS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? kText2Dark : kText3Light,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sections
              .map((s) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? kSurfaceDark : kSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDark ? Colors.white.withOpacity(0.06) : kDivLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.number,
                            style: const TextStyle(
                              color: kPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(width: 5),
                        Text(s.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? kText2Dark : kText2Light,
                            )),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── Contact row ───────────────────────────────────────────────────────────
  Widget _buildContactRow(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ContactTile(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: 'support@facultypedia.com',
                onTap: () => _launch('mailto:support@facultypedia.com'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ContactTile(
                icon: Icons.phone_iphone_rounded,
                label: 'Phone',
                value: '+91 9509933693',
                onTap: () => _launch('tel:+919509933693'),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ContactTile(
          icon: Icons.place_rounded,
          label: 'Address',
          value: 'Kota, Rajasthan, India',
          onTap: null,
          isDark: isDark,
        ),
      ],
    );
  }

  // ── Declaration card ──────────────────────────────────────────────────────
  Widget _buildDeclaration() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              // icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'Declaration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By using FacultyPedia, you acknowledge that:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 16),
              _declBullet('You have read and understood this Privacy Policy.'),
              const SizedBox(height: 10),
              _declBullet(
                  'You consent to the collection and processing of your data as described.'),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Text(
                  'Empowering Educators · Educating India',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _declBullet(String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_rounded, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.5)),
          ),
        ],
      );

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String badge, String title, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimaryMid),
          ),
          child: Text(badge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: kPrimary,
                letterSpacing: 1.2,
              )),
        ),
        const SizedBox(height: 8),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: isDark ? kText1Dark : kText1Light,
            )),
      ],
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final _PrivacySection section;
  final bool isDark;
  const _SectionCard({required this.section, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = section;
    final isDark = this.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : kPrimaryBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : kSurface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: kPrimaryMid),
                  ),
                  child: Icon(s.icon, color: kPrimary, size: 18),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kPrimaryMid),
                  ),
                  child: Text(s.number,
                      style: const TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? kText1Dark : kText1Light,
                      )),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.intro != null) ...[
                  Text(s.intro!,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? kText2Dark : kText2Light,
                      )),
                  const SizedBox(height: 10),
                ],
                if (s.paragraph != null) ...[
                  Text(s.paragraph!,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? kText2Dark : kText2Light,
                      )),
                  const SizedBox(height: 10),
                ],

                // subsections
                if (s.subsections != null)
                  ...s.subsections!.map((sub) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : kBgLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : kDivLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sub.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? kText1Dark : kText1Light,
                                )),
                            const SizedBox(height: 8),
                            ...sub.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _bullet(item, isDark),
                                )),
                          ],
                        ),
                      )),

                // flat items
                if (s.subsections == null && s.items != null)
                  ...s.items!.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _bullet(item, isDark),
                      )),

                // highlight pill
                if (s.highlight != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimaryMid),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place_rounded,
                            size: 14, color: kPrimary),
                        const SizedBox(width: 6),
                        Text(s.highlight!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            )),
                      ],
                    ),
                  ),
                ],

                // callout
                if (s.callout != null) ...[
                  const SizedBox(height: 10),
                  _CalloutBox(callout: s.callout!, isDark: isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text, bool isDark) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration:
                const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: isDark ? kText2Dark : kText2Light,
                )),
          ),
        ],
      );
}

// ── Callout box ────────────────────────────────────────────────────────────────
class _CalloutBox extends StatelessWidget {
  final _Callout callout;
  final bool isDark;
  const _CalloutBox({required this.callout, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isWarning = callout.type == 'warning';
    final bgColor = isWarning
        ? (isDark
            ? const Color(0xFFFEF3C7).withOpacity(0.1)
            : const Color(0xFFFEF3C7))
        : (isDark ? Colors.white.withOpacity(0.04) : kPrimaryBg);
    final bdColor = isWarning ? const Color(0xFFFCD34D) : kPrimaryMid;
    final icon =
        isWarning ? Icons.warning_amber_rounded : Icons.info_outline_rounded;
    final iconColor = isWarning ? const Color(0xFFD97706) : kPrimary;
    final textColor = isWarning
        ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E))
        : (isDark ? kText2Dark : kText2Light);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(callout.text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: textColor,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Contact tile ───────────────────────────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  final bool isDark;
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: kPrimary, size: 18),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? kText2Dark : kText3Light,
                )),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: onTap != null
                      ? kPrimary
                      : (isDark ? kText1Dark : kText1Light),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Sections data ──────────────────────────────────────────────────────────────
const _sections = [
  _PrivacySection(
    number: '01',
    icon: Icons.storage_rounded,
    title: 'Information We Collect',
    subsections: [
      _Subsection(label: '1.1 Personal Information', items: [
        'Full name',
        'Email address',
        'Mobile number',
        'Profile photo',
        'Address (if provided)',
        'Government ID (for verification)',
        'Bank account details (for Educator payouts)',
      ]),
      _Subsection(label: '1.2 Educational Information', items: [
        'Courses enrolled',
        'Academic preferences',
        'Course progress',
        'Test results',
      ]),
      _Subsection(label: '1.3 Payment Information', items: [
        'Transaction details',
        'Billing details',
        'UPI / Card transaction reference',
      ]),
      _Subsection(label: '1.4 Technical Data', items: [
        'IP address',
        'Device type',
        'Browser type',
        'Login time and activity',
        'Cookies and usage analytics',
      ]),
    ],
    callout: _Callout(
        type: 'warning',
        text:
            'FacultyPedia does not store debit/credit card details directly. Payments are processed via secure third-party payment gateways.'),
  ),
  _PrivacySection(
    number: '02',
    icon: Icons.settings_rounded,
    title: 'How We Use Your Information',
    intro: 'We use collected data for:',
    items: [
      'Creating and managing user accounts',
      'Processing course enrollments and payments',
      'Issuing Educator payouts',
      'Providing customer support',
      'Sending course notifications and updates',
      'Improving platform functionality',
      'Preventing fraud and unauthorized access',
      'Legal compliance',
    ],
    callout: _Callout(
        type: 'info', text: 'We do not sell personal data to third parties.'),
  ),
  _PrivacySection(
    number: '03',
    icon: Icons.payments_rounded,
    title: 'Educator Financial Data',
    intro: 'Educators provide bank details for payout processing.',
    items: [
      'Bank information is stored securely.',
      'Payouts are issued as per Terms and Conditions (after 30 days of course start date).',
      'FacultyPedia may temporarily hold payouts in case of disputes or student complaints.',
    ],
  ),
  _PrivacySection(
    number: '04',
    icon: Icons.lock_rounded,
    title: 'Intellectual Property and Content Ownership',
    items: [
      'Study materials, videos, and tests uploaded by Educators remain their intellectual property.',
      'FacultyPedia does not claim ownership.',
      'FacultyPedia will not use or sell such content for promotional purposes without written consent of the Educator.',
    ],
  ),
  _PrivacySection(
    number: '05',
    icon: Icons.share_rounded,
    title: 'Data Sharing and Disclosure',
    intro: 'We may share information only in the following cases:',
    items: [
      'With payment gateways for transaction processing',
      'With government authorities if legally required',
      'To comply with court orders',
      'To prevent fraud or illegal activity',
    ],
    callout: _Callout(
        type: 'info',
        text:
            'We do not share personal information with advertisers for commercial sale.'),
  ),
  _PrivacySection(
    number: '06',
    icon: Icons.visibility_rounded,
    title: 'Student Conduct and Monitoring',
    intro: 'To maintain discipline and quality:',
    items: [
      'Live sessions may be monitored for safety and compliance.',
      'Chat records may be reviewed in case of complaints.',
      'Accounts may be suspended for misconduct.',
    ],
  ),
  _PrivacySection(
    number: '07',
    icon: Icons.security_rounded,
    title: 'Data Security',
    intro:
        'We implement reasonable administrative, technical, and physical safeguards to protect your information.',
    paragraph:
        'However, no digital platform can guarantee 100% security. Users are advised to:',
    items: [
      'Keep login credentials confidential.',
      'Not share OTPs.',
      'Use strong passwords.',
    ],
  ),
  _PrivacySection(
    number: '08',
    icon: Icons.cookie_rounded,
    title: 'Cookies Policy',
    intro: 'FacultyPedia uses cookies to:',
    items: [
      'Improve user experience',
      'Store login sessions',
      'Analyze traffic',
    ],
    callout: _Callout(
        type: 'info',
        text:
            'Users may disable cookies via browser settings, but some features may not function properly.'),
  ),
  _PrivacySection(
    number: '09',
    icon: Icons.schedule_rounded,
    title: 'Data Retention',
    intro: 'We retain user data:',
    items: [
      'As long as the account is active',
      'As required for legal or financial compliance',
      'For dispute resolution',
    ],
    callout: _Callout(
        type: 'info',
        text:
            'Users may request account deletion subject to legal obligations.'),
  ),
  _PrivacySection(
    number: '10',
    icon: Icons.child_care_rounded,
    title: 'Minor Users',
    intro: 'If a Student is under 18 years:',
    items: [
      'Registration must be done under parental supervision.',
      'Parent or guardian consent may be required.',
    ],
  ),
  _PrivacySection(
    number: '11',
    icon: Icons.public_rounded,
    title: 'Jurisdiction and Legal Compliance',
    intro: 'This Privacy Policy shall be governed by:',
    items: [
      'Laws of India',
      'Information Technology Act, 2000',
      'Applicable data protection regulations',
    ],
    highlight: 'Kota, Rajasthan, India',
  ),
  _PrivacySection(
    number: '12',
    icon: Icons.refresh_rounded,
    title: 'Changes to Privacy Policy',
    items: [
      'FacultyPedia reserves the right to modify this Privacy Policy at any time.',
      'Users will be notified of significant changes via email or platform notification.',
      'Continued use of the Platform constitutes acceptance of updated policies.',
    ],
  ),
  _PrivacySection(
    number: '13',
    icon: Icons.verified_user_rounded,
    title: 'Your Rights',
    intro: 'You have the right to:',
    items: [
      'Access your personal data',
      'Correct inaccurate data',
      'Request deletion (subject to legal compliance)',
      'Withdraw consent',
    ],
    callout: _Callout(
        type: 'info',
        text:
            'For any privacy-related concerns, contact us using the details below.'),
  ),
];
