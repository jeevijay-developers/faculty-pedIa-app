import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

// ── Data ───────────────────────────────────────────────────────────────────────
class _ContactMethod {
  final IconData icon;
  final String title, detail, description;
  final List<_Action> actions;
  const _ContactMethod({
    required this.icon,
    required this.title,
    required this.detail,
    required this.description,
    required this.actions,
  });
}

class _Action {
  final String label, url;
  final bool outline;
  final IconData? icon;
  const _Action(
      {required this.label,
      required this.url,
      this.outline = false,
      this.icon});
}

class _SocialLink {
  final String label, url;
  final IconData icon;
  const _SocialLink(
      {required this.label, required this.url, required this.icon});
}

const _contactMethods = [
  _ContactMethod(
    icon: Icons.phone_in_talk_rounded,
    title: 'Call Us',
    detail: '+91 9509933693',
    description:
        'Available for educator onboarding, technical support, and partnership inquiries.',
    actions: [
      _Action(
          label: 'Call Now',
          url: 'tel:+919509933693',
          icon: Icons.call_rounded),
      _Action(
          label: 'WhatsApp',
          url: 'https://wa.me/919509933693',
          outline: true,
          icon: Icons.chat_rounded),
    ],
  ),
  _ContactMethod(
    icon: Icons.mail_outline_rounded,
    title: 'Email Us',
    detail: 'facultypedia02@gmail.com',
    description: 'We typically respond within 24 hours on all working days.',
    actions: [
      _Action(
          label: 'Send Email',
          url: 'mailto:facultypedia02@gmail.com',
          icon: Icons.send_rounded),
    ],
  ),
  _ContactMethod(
    icon: Icons.language_rounded,
    title: 'Website',
    detail: 'www.FacultyPedia.com',
    description: 'Explore courses, educators, and everything FacultyPedia.',
    actions: [
      _Action(
          label: 'Visit Website',
          url: 'https://www.FacultyPedia.com',
          icon: Icons.open_in_new_rounded),
    ],
  ),
];

const _socialLinks = [
  _SocialLink(
      label: 'Facebook',
      url: 'https://facebook.com/facultypedia',
      icon: FontAwesomeIcons.facebookF),
  _SocialLink(
      label: 'Instagram',
      url: 'https://instagram.com/facultypedia',
      icon: FontAwesomeIcons.instagram),
  _SocialLink(
      label: 'YouTube',
      url: 'https://youtube.com/facultypedia',
      icon: FontAwesomeIcons.youtube),
  _SocialLink(
      label: 'LinkedIn',
      url: 'https://linkedin.com/company/facultypedia',
      icon: FontAwesomeIcons.linkedinIn),
];

const _commitments = [
  _CommitmentItem(Icons.bolt_rounded, 'Fast Response'),
  _CommitmentItem(Icons.handshake_rounded, 'Transparent Communication'),
  _CommitmentItem(Icons.support_agent_rounded, 'Dedicated Support'),
  _CommitmentItem(Icons.verified_user_rounded, 'Secure Assistance'),
];

class _CommitmentItem {
  final IconData icon;
  final String label;
  const _CommitmentItem(this.icon, this.label);
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
          // ── Hero AppBar ──────────────────────────────────────────────
          _buildSliverAppBar(context, isDark),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                children: [
                  // contact cards
                  _sectionLabel('GET IN TOUCH', 'Reach Out To Us', isDark),
                  const SizedBox(height: 16),
                  ...(_contactMethods
                      .map((m) => _ContactCard(data: m, isDark: isDark))),

                  const SizedBox(height: 28),

                  // educator + partnership
                  _sectionLabel('FOR EDUCATORS', 'Join Our Platform', isDark),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _EducatorCard(isDark: isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _PartnershipCard(isDark: isDark)),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // commitments
                  _sectionLabel('OUR PROMISE', 'What You Can Expect', isDark),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _commitments.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemBuilder: (_, i) =>
                        _CommitmentCard(item: _commitments[i], isDark: isDark),
                  ),

                  const SizedBox(height: 28),

                  // social links
                  _sectionLabel('CONNECT WITH US', 'Follow Us', isDark),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _socialLinks
                        .map((s) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: _SocialButton(link: s, isDark: isDark),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 28),

                  // closing CTA
                  _buildClosingCta(),
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
      expandedHeight: 220,
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
            // decorative circles
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
                  // badge pill
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
                        Icon(Icons.support_agent_rounded,
                            color: Colors.white, size: 13),
                        SizedBox(width: 6),
                        Text('Help & Support',
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
                    'We\'re Here\nFor You',
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
                    'Reach out anytime — we respond fast.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Closing CTA ───────────────────────────────────────────────────────────
  Widget _buildClosingCta() {
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
            right: -20,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              const Text(
                'Have a question or idea?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ready to scale your teaching?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We are just one call or email away.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),

              // divider
              Divider(height: 1, color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 20),

              // buttons
              Row(
                children: [
                  Expanded(
                    child: _ctaBtn(
                      label: 'Call Now',
                      icon: Icons.call_rounded,
                      filled: true,
                      onTap: () => _launch('tel:+919509933693'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ctaBtn(
                      label: 'Send Email',
                      icon: Icons.mail_outline_rounded,
                      filled: false,
                      onTap: () => _launch('mailto:facultypedia02@gmail.com'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // tagline pill
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
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctaBtn({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? Colors.transparent : Colors.white.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? kPrimary : Colors.white),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? kPrimary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: isDark ? kText1Dark : kText1Light,
          ),
        ),
      ],
    );
  }
}

// ── Contact card ───────────────────────────────────────────────────────────────
class _ContactCard extends StatefulWidget {
  final _ContactMethod data;
  final bool isDark;
  const _ContactCard({required this.data, required this.isDark});

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(d.icon, color: kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark ? kText1Dark : kText1Light,
                            )),
                        const SizedBox(height: 2),
                        Text(d.detail,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                d.description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? kText2Dark : kText2Light,
                ),
              ),
              const SizedBox(height: 14),

              // divider
              Divider(
                height: 1,
                color: isDark ? Colors.white.withOpacity(0.07) : kDivLight,
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    d.actions.map((a) => _ActionButton(action: a)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final _Action action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final bg = action.outline ? kPrimaryBg : kPrimary;
    final fg = action.outline ? kPrimary : Colors.white;
    final bdr = action.outline ? kPrimaryMid : Colors.transparent;

    return GestureDetector(
      onTap: () => HelpScreen._launch(action.url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bdr),
          boxShadow: action.outline
              ? []
              : [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (action.icon != null) ...[
              Icon(action.icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(action.label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Educator card ──────────────────────────────────────────────────────────────
class _EducatorCard extends StatelessWidget {
  final bool isDark;
  const _EducatorCard({required this.isDark});

  static const _bullets = [
    'Launch live courses',
    'Create test series',
    '1-to-1 paid mentorship',
    'Host webinars',
    'Upload recorded courses',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kPrimaryBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryMid,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : kSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cast_for_education_rounded,
                    color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('For Educators',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? kText1Dark : kText1Light,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Interested in:',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? kText2Dark : kText2Light,
              )),
          const SizedBox(height: 8),
          ..._bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.white.withOpacity(0.06) : kSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: kPrimary, size: 11),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(b,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? kText2Dark : kText2Light,
                          )),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryMid,
              ),
            ),
            child: Text(
              'Our onboarding team will guide you step-by-step.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? kText2Dark : kText2Light,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Partnership card ───────────────────────────────────────────────────────────
class _PartnershipCard extends StatelessWidget {
  final bool isDark;
  const _PartnershipCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handshake_rounded,
                    color: kPrimary, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Partnerships',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? kText1Dark : kText1Light,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'For institute tie-ups, academic partnerships, or growth collaborations, email us with:',
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: isDark ? kText2Dark : kText2Light,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : kPrimaryBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kPrimaryMid),
            ),
            child: const Text(
              'Partnership Inquiry - FacultyPedia',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => HelpScreen._launch(
              'mailto:facultypedia02@gmail.com?subject=Partnership%20Inquiry%20-%20FacultyPedia',
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text('Send Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Commitment card ────────────────────────────────────────────────────────────
class _CommitmentCard extends StatelessWidget {
  final _CommitmentItem item;
  final bool isDark;
  const _CommitmentCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: kPrimary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? kText1Dark : kText1Light,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Social button ──────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final _SocialLink link;
  final bool isDark;
  const _SocialButton({required this.link, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HelpScreen._launch(link.url),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FaIcon(link.icon, size: 20, color: kPrimary),
      ),
    );
  }
}
