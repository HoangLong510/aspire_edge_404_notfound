import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  static const LatLng _officeLatLng = LatLng(10.807730, 106.660864);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ==== Hero Header (nền trắng + logo to) ====
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757581315/image-Photoroom_vrxff8.png",
                    height: 200, // 👈 logo to hơn
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "About Us",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==== Description ====
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
            const Divider(),

            // ==== Team Photo ====
            const Text(
              "Meet Our Team",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757581755/z6993755783890_21c967a2b84e93eb796395f6174186b8_wgnmaa.jpg",
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // ==== Members (Grid 2 cột) ====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                childAspectRatio: 0.8,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _TeamMember(
                    name: "Hoàng Gia Huy",
                    email: "huypg7645@gmail.com",
                    avatarUrl:
                        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582257/huy_zxzl6e.jpg",
                  ),
                  _TeamMember(
                    name: "Trần Nhật Linh",
                    email: "nhatlinh3b122@gmail.com",
                    avatarUrl:
                        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582259/linh_mjmqyv.jpg",
                  ),
                  _TeamMember(
                    name: "Nguyễn Trần Hoàng Long",
                    email: "hoanglongnguyen0510@gmail.com",
                    avatarUrl:
                        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582261/long_pbab33.jpg",
                  ),
                  _TeamMember(
                    name: "Nguyễn Anh Quân",
                    email: "quan@gmail.com",
                    avatarUrl:
                        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582260/qu%C3%A2n_w8nrqr.jpg",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // ==== Office ====
            const Text(
              "Our Office",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "21Bis Hau Giang, Ward 4, Tan Binh, Ho Chi Minh City, Vietnam",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // ==== OpenStreetMap ====
            SizedBox(
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _officeLatLng,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _officeLatLng,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==== Email ====
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.email_outlined, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(
                  "team02aptech@gmail.com",
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==== Contact Us Button ====
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, "/contact_us");
              },
              icon: const Icon(Icons.mail_outline),
              label: const Text("Contact Us"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==== Slogan ====
            const Text(
              "✨ Dream Big. Work Smart. Aspire with Edge. ✨",
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 170,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 35),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueGrey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
