import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import '../chatbox/services/team_service.dart';
import '../chatbox/models/team_member.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const LatLng _officeLatLng = LatLng(10.807730, 106.660864);

  @override
  Widget build(BuildContext context) {
    // Nếu getTeamMembers() là static
    final team = TeamService.getTeamMembers();
    // Nếu không static thì sửa: final team = TeamService().getTeamMembers();

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("About Us")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Lottie.asset("assets/lottie/welcome.json", height: 200),
                  const SizedBox(height: 20),
                  const Text(
                    "About Us",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "AspireEdge is a cross-platform career guidance application developed by Team 404 Not Found. "
                "Our mission is to help students, graduates, and professionals explore their career paths, "
                "build skills, and get inspired by success stories.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Meet Our Team",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                childAspectRatio: 0.8,
                physics: const NeverScrollableScrollPhysics(),
                children: team
                    .map((m) => _TeamMember(
                          name: m.name,
                          email: m.email,
                          avatarUrl: m.avatarUrl,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Our Office",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "21Bis Hau Giang, Ward 4, Tan Binh, Ho Chi Minh City, Vietnam",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: fm.FlutterMap(
                options: fm.MapOptions(
                  initialCenter: _officeLatLng,
                  initialZoom: 16,
                ),
                children: [
                  fm.TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  fm.MarkerLayer(
                    markers: [
                      fm.Marker(
                        point: _officeLatLng,
                        width: 80,
                        height: 80,
                        child: const Icon(Iconsax.location, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Iconsax.sms, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text("team02aptech@gmail.com",
                    style: TextStyle(color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, "/contact_us"),
              icon: const Icon(Iconsax.message),
              label: const Text("Contact Us"),
            ),
            const SizedBox(height: 20),
            const Text(
              "Dream Big. Work Smart. Aspire with Edge.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String email;
  final String avatarUrl;

  const _TeamMember({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 170,
        child: Column(
          children: [
            ClipOval(
              child: Image.network(
                avatarUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Iconsax.user, size: 28, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
