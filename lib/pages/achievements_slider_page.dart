import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementsSliderPage extends StatefulWidget {
  const AchievementsSliderPage({super.key});

  @override
  State<AchievementsSliderPage> createState() => _AchievementsSliderPageState();
}

class _AchievementsSliderPageState extends State<AchievementsSliderPage> {
  final _controller = PageController();
  int _index = 0;
  bool _loading = true;

  late List<_SlideData> _slides;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Meta')
          .doc('AppStats')
          .get();

      final data = snap.data() ?? {};
      final totalUsers = (data['total_users'] ?? 12000).toString();
      final successStories = (data['success_stories'] ?? 2700).toString();
      final jobRate = (((data['job_placement_rate'] ?? 0.86) as num) * 100).toStringAsFixed(0) + '%';
      final avgDays = (data['avg_time_to_job_days'] ?? 45).toString();
      final resources = (data['active_resources'] ?? 870).toString();

      _slides = [
        _SlideData(
          icon: Icons.military_tech_rounded,
          title: 'Success Stories',
          value: successStories,
          caption: 'Learners who landed roles after using AspireEdge.',
        ),
        _SlideData(
          icon: Icons.people_alt_rounded,
          title: 'Community',
          value: totalUsers,
          caption: 'Active users growing every day.',
        ),
        _SlideData(
          icon: Icons.work_outline_rounded,
          title: 'Job Placement Rate',
          value: jobRate,
          caption: 'Users getting a role after completing tracks.',
        ),
        _SlideData(
          icon: Icons.timer_outlined,
          title: 'Average Time to Job',
          value: '$avgDays days',
          caption: 'From starting track to first offer.',
        ),
        _SlideData(
          icon: Icons.video_library_rounded,
          title: 'Learning Resources',
          value: resources,
          caption: 'Blogs, videos, mock interviews & more.',
        ),
      ];
    } catch (_) {
      _slides = [
        _SlideData(
          icon: Icons.military_tech_rounded,
          title: 'Success Stories',
          value: '2,700+',
          caption: 'Learners who landed roles after using AspireEdge.',
        ),
        _SlideData(
          icon: Icons.people_alt_rounded,
          title: 'Community',
          value: '12,000+',
          caption: 'Active users growing every day.',
        ),
        _SlideData(
          icon: Icons.work_outline_rounded,
          title: 'Job Placement Rate',
          value: '86%',
          caption: 'Users getting a role after completing tracks.',
        ),
        _SlideData(
          icon: Icons.timer_outlined,
          title: 'Average Time to Job',
          value: '45 days',
          caption: 'From starting track to first offer.',
        ),
        _SlideData(
          icon: Icons.video_library_rounded,
          title: 'Learning Resources',
          value: '870+',
          caption: 'Blogs, videos, mock interviews & more.',
        ),
      ];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSkip() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }

  void _onNext() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _onSkip();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _onSkip,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final s = _slides[i];
                    return _SlideCard(data: s);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _DotsIndicator(length: _slides.length, index: _index),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _index == _slides.length - 1 ? 'Start' : 'Next',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String value;
  final String caption;

  _SlideData({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
  });
}

class _SlideCard extends StatelessWidget {
  final _SlideData data;
  const _SlideCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.1), primary.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 72, color: primary),
          const SizedBox(height: 18),
          Text(
            data.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            data.caption,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int length;
  final int index;
  const _DotsIndicator({required this.length, required this.index});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 22 : 8,
          decoration: BoxDecoration(
            color: active ? primary : primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
