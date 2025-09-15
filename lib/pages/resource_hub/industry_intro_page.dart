import 'package:aspire_edge_404_notfound/constants/industries.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import '../data/industry_meta.dart';

class IndustryIntroPage extends StatefulWidget {
  const IndustryIntroPage({super.key});

  @override
  State<IndustryIntroPage> createState() => _IndustryIntroPageState();
}

class _IndustryIntroPageState extends State<IndustryIntroPage> {
  final _pageCtrl = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;

    String receivedTitle;
    if (routeArgs is Map && routeArgs['industry'] is String) {
      receivedTitle = (routeArgs['industry'] as String).trim();
    } else if (routeArgs is String) {
      receivedTitle = routeArgs.trim();
    } else {
      receivedTitle = 'Information Technology';
    }

    final entry = industryMeta.entries.firstWhere(
          (e) =>
      e.key.toLowerCase() == receivedTitle.toLowerCase() ||
          ((e.value['title'] as String).toLowerCase() ==
              receivedTitle.toLowerCase()),
      orElse: () => industryMeta.entries.first,
    );

    final meta = entry.value;
    final industryTitle = meta['title'] as String;
    final accent = meta['color'] as Color;
    final banner = meta['banner'] as String;
    final stats = (meta['stats'] as List).cast<String>();
    final skills = (meta['skills'] as List).cast<String>();
    final roles = (meta['roles'] as List).cast<String>();
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _BannerHero(imageUrl: banner, title: industryTitle, accent: accent),
          const SizedBox(height: 12),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                _StatsSlide(
                  stats: stats,
                  accent: accent,
                  lottieUrl: meta['lottieStats'] as String?,
                ),
                _SkillsSlide(
                  skills: skills,
                  accent: accent,
                  lottieUrl: meta['lottieSkills'] as String?,
                ),
                _RolesSlide(
                  roles: roles,
                  accent: accent,
                  lottieUrl: meta['lottieRoles'] as String?,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? accent : accent.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final id = industryByName(industryTitle)?.id;
                  Navigator.pushNamed(
                    context,
                    "/career_bank",
                    arguments: {
                      "industry": industryTitle,
                      "industryId": id,
                    },
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: Text("View career list in $industryTitle"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerHero extends StatelessWidget {
  final String imageUrl;
  final String title;
  final Color accent;
  const _BannerHero({
    required this.imageUrl,
    required this.title,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.5)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.explore, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Overview • $title",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StatsSlide extends StatelessWidget {
  final List<String> stats;
  final Color accent;
  final String? lottieUrl;
  const _StatsSlide({
    required this.stats,
    required this.accent,
    this.lottieUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _SlideCard(
      title: "Trends & Statistics",
      accent: accent,
      lottieUrl: lottieUrl,
      children: stats
          .map((s) => ListTile(
        leading: Icon(Icons.check_circle, color: accent),
        title: Text(s),
      ))
          .toList(),
    );
  }
}

class _SkillsSlide extends StatelessWidget {
  final List<String> skills;
  final Color accent;
  final String? lottieUrl;
  const _SkillsSlide({
    required this.skills,
    required this.accent,
    this.lottieUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _SlideCard(
      title: "Key Skills",
      accent: accent,
      lottieUrl: lottieUrl,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map((e) => Chip(
            label: Text(e),
            backgroundColor: accent.withOpacity(0.1),
          ))
              .toList(),
        )
      ],
    );
  }
}

class _RolesSlide extends StatelessWidget {
  final List<String> roles;
  final Color accent;
  final String? lottieUrl;
  const _RolesSlide({
    required this.roles,
    required this.accent,
    this.lottieUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _SlideCard(
      title: "Featured Roles",
      accent: accent,
      lottieUrl: lottieUrl,
      children: roles
          .map((r) => ListTile(
        leading: Icon(Icons.tag, color: accent),
        title: Text(r),
      ))
          .toList(),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final String title;
  final Color accent;
  final List<Widget> children;
  final String? lottieUrl;

  const _SlideCard({
    required this.title,
    required this.accent,
    required this.children,
    this.lottieUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.star, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ]),
                const SizedBox(height: 10),

                if (lottieUrl != null && lottieUrl!.isNotEmpty)
                  Center(
                    child: lottieUrl!.startsWith('assets/')
                        ? Lottie.asset(
                      lottieUrl!,
                      height: 120,
                      repeat: true,
                      fit: BoxFit.contain,
                    )
                        : Lottie.network(
                      lottieUrl!,
                      height: 120,
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),

                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
