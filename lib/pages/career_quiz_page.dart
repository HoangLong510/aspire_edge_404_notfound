import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- PHẦN: TRANG BẮT ĐẦU QUIZ (render *bên trong body* – không dùng Scaffold/AppBar) ---
class CareerQuizPage extends StatefulWidget {
  const CareerQuizPage({super.key});

  @override
  State<CareerQuizPage> createState() => _CareerQuizPageState();
}

class _CareerQuizPageState extends State<CareerQuizPage>
    with SingleTickerProviderStateMixin {
  String? _userTier; // tier người dùng từ Firestore
  bool _loading = true; // trạng thái loading khi fetch tier
  String? _error; // lỗi nếu có

  late final AnimationController _fadeIn; // animation vào màn

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fetchUserTier();
  }

  // --- PHẦN: LẤY TIER TỪ FIRESTORE ---
  Future<void> _fetchUserTier() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _userTier = 'guest';
          _loading = false;
        });
        _fadeIn.forward();
        return;
      }

      final snapshot =
          await FirebaseFirestore.instance.collection('Users').doc(uid).get();

      setState(() {
        // (quan trọng) field 'tier' viết thường
        _userTier = snapshot.data()?['Tier'] ?? 'user';
        _loading = false;
      });
      _fadeIn.forward();
    } catch (e) {
      setState(() {
        _userTier = 'user';
        _loading = false;
        _error = 'Failed to load your role. Please try again.';
      });
      _fadeIn.forward();
    }
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    super.dispose();
  }

  // --- PHẦN: DECORATION BACKGROUND (gradient + blobs nhẹ) ---
  Widget _buildBackground(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Stack(
      children: [
        // gradient nền
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withOpacity(0.12),
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
        // blob 1
        Positioned(
          top: -60,
          left: -40,
          child: _Blob(color: primary.withOpacity(0.15), size: 180),
        ),
        // blob 2
        Positioned(
          bottom: -50,
          right: -30,
          child: _Blob(color: primary.withOpacity(0.10), size: 220),
        ),
      ],
    );
  }

  // --- PHẦN: CARD CHÍNH Ở GIỮA ---
  Widget _buildCenterCard(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    // Khi loading: hiển thị skeleton
    if (_loading) {
      return _SkeletonCard();
    }

    // Khi lỗi: hiển thị lỗi + retry
    if (_error != null) {
      return _GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 40),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchUserTier,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Trạng thái bình thường
    return FadeTransition(
      opacity: _fadeIn,
      child: _GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // icon lock/quiz
            CircleAvatar(
              radius: 28,
              backgroundColor: primary.withOpacity(0.10),
              child: Icon(Icons.quiz_outlined, color: primary, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'Career Orientation Quiz',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Discover strengths and suitable career clusters in ~10 minutes.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // điểm nhấn thông tin nhỏ
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: const [
                _ChipInfo(icon: Icons.timer_outlined, label: '20 questions'),
                _ChipInfo(icon: Icons.check_circle_outline, label: 'Instant result'),
                _ChipInfo(icon: Icons.security_outlined, label: 'Private & secure'),
              ],
            ),

            const SizedBox(height: 22),

            // Start Quiz
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/quiz'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Start Quiz',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Gợi ý cho admin (ẩn với user)
            if (_userTier == 'admin')
              Text(
                'Admin tools available (gear icon).',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  // --- PHẦN: NÚT BÁNH RĂNG (FLOAT) CHO ADMIN Ở GÓC PHẢI ---
  Widget _buildAdminGear(BuildContext context) {
    if (_loading || _userTier != 'admin') return const SizedBox.shrink();
    return Positioned(
      top: 8,
      right: 8,
      child: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Material(
          color: Colors.transparent,
          child: Tooltip(
            message: 'Quiz Management',
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => Navigator.of(context).pushNamed('/quiz_management'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.settings,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- PHẦN: BUILD (trả về nội dung *bên trong body*) ---
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(context),
        // nội dung giữa
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _buildCenterCard(context),
            ),
          ),
        ),
        // gear admin
        _buildAdminGear(context),
      ],
    );
  }
}

// ======= WIDGETS PHỤ (ghi chú tiếng Việt) =======

// Card kính mờ + viền gradient nhẹ
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white.withOpacity(0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Skeleton loading (đã fix overflow bằng Wrap)
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget bar({double h = 16, double w = 120}) => _ShimmerBox(height: h, width: w);

    return _GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ShimmerCircle(size: 56),
          const SizedBox(height: 12),
          bar(h: 20, w: 220),
          const SizedBox(height: 8),
          bar(w: 260),
          const SizedBox(height: 18),
          // dùng Wrap để tự xuống dòng nếu thiếu ngang -> không overflow
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: const [
              _ShimmerBox(height: 28, width: 120),
              _ShimmerBox(height: 28, width: 140),
              _ShimmerBox(height: 28, width: 120),
            ],
          ),
          const SizedBox(height: 22),
          const _ShimmerBox(height: 52, width: double.infinity),
        ],
      ),
    );
  }
}

// Hiệu ứng shimmer tối giản (không dùng package ngoài)
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.height, required this.width});
  final double height;
  final double width;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _c.value * 2, 0),
              end: const Alignment(1.0, 0),
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        height: size,
        width: size,
        child: const _ShimmerBox(height: double.infinity, width: double.infinity),
      ),
    );
  }
}

// Chip thông tin nhỏ
class _ChipInfo extends StatelessWidget {
  const _ChipInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Blob nền tròn mờ
class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(size)),
    );
  }
}
