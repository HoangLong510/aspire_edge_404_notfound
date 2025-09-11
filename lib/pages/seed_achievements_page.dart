import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeedAchievementsPage extends StatefulWidget {
  const SeedAchievementsPage({super.key});

  @override
  State<SeedAchievementsPage> createState() => _SeedAchievementsPageState();
}

class _SeedAchievementsPageState extends State<SeedAchievementsPage> {
  final _formKey = GlobalKey<FormState>();

  final _totalUsersCtl = TextEditingController();
  final _successStoriesCtl = TextEditingController();
  final _jobRatePercentCtl = TextEditingController(); // nhập % (0–100)
  final _avgDaysCtl = TextEditingController();
  final _resourcesCtl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Meta')
          .doc('AppStats')
          .get();

      final data = snap.data();
      if (data != null) {
        _totalUsersCtl.text = (data['total_users'] ?? 0).toString();
        _successStoriesCtl.text = (data['success_stories'] ?? 0).toString();
        final rate = (data['job_placement_rate'] ?? 0.0) as num; // 0.0–1.0
        _jobRatePercentCtl.text = (rate * 100).toStringAsFixed(0);
        _avgDaysCtl.text = (data['avg_time_to_job_days'] ?? 0).toString();
        _resourcesCtl.text = (data['active_resources'] ?? 0).toString();
      } else {
        _useDemoValues();
      }
    } catch (_) {
      _useDemoValues();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useDemoValues() {
    _totalUsersCtl.text = '12000';
    _successStoriesCtl.text = '2700';
    _jobRatePercentCtl.text = '86';
    _avgDaysCtl.text = '45';
    _resourcesCtl.text = '870';
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  String? _reqInt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
    return null;
  }

  String? _reqPercent(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final x = int.tryParse(v.trim());
    if (x == null || x < 0 || x > 100) return '0–100';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final totalUsers = int.parse(_totalUsersCtl.text.trim());
    final successStories = int.parse(_successStoriesCtl.text.trim());
    final jobRate = int.parse(_jobRatePercentCtl.text.trim()) / 100.0; // lưu 0.0–1.0
    final avgDays = int.parse(_avgDaysCtl.text.trim());
    final resources = int.parse(_resourcesCtl.text.trim());

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('Meta')
          .doc('AppStats')
          .set({
        'total_users': totalUsers,
        'success_stories': successStories,
        'job_placement_rate': jobRate,
        'avg_time_to_job_days': avgDays,
        'active_resources': resources,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seeded AppStats successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _previewSlider() {
    Navigator.of(context).pushNamed('/achievements');
  }

  @override
  void dispose() {
    _totalUsersCtl.dispose();
    _successStoriesCtl.dispose();
    _jobRatePercentCtl.dispose();
    _avgDaysCtl.dispose();
    _resourcesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seed Achievements Data',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _totalUsersCtl,
            keyboardType: TextInputType.number,
            decoration: _dec('Total Users', Icons.people_alt_rounded),
            validator: _reqInt,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _successStoriesCtl,
            keyboardType: TextInputType.number,
            decoration: _dec('Success Stories', Icons.military_tech_rounded),
            validator: _reqInt,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _jobRatePercentCtl,
            keyboardType: TextInputType.number,
            decoration: _dec('Job Placement Rate (%)', Icons.work_outline_rounded),
            validator: _reqPercent,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _avgDaysCtl,
            keyboardType: TextInputType.number,
            decoration: _dec('Avg. Time to Job (days)', Icons.timer_outlined),
            validator: _reqInt,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _resourcesCtl,
            keyboardType: TextInputType.number,
            decoration: _dec('Active Resources', Icons.video_library_rounded),
            validator: _reqInt,
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _useDemoValues,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Use Demo Values'),
              ),
              OutlinedButton.icon(
                onPressed: _previewSlider,
                icon: const Icon(Icons.slideshow_rounded),
                label: const Text('Preview Slider'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _saving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }
}
