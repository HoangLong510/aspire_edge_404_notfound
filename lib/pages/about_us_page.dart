import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  late GoogleMapController mapController;

  final LatLng _officeLocation = const LatLng(10.7837, 106.6520);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ==== Hero Header ====
            Container(
              width: double.infinity,
              height: 220, // cao hơn
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757581315/image-Photoroom_vrxff8.png",
                    height: 140, // logo to hơn
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "About Us",
                    style: TextStyle(
                      fontSize: 32, // chữ to hơn
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

            // ==== Members ====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: const [
                  _TeamMember(
                    name: "Hoàng Gia Huy",
                    role: "Team Leader / Flutter Dev",
                    avatarUrl:
                        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582257/huy_zxzl6e.jpg",
                  ),
                  _TeamMember(
                    name: "Trần Nhật Linh",
                    role: "Backend Engineer",
                    avatarUrl:
                        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582259/linh_mjmqyv.jpg",
                  ),
                  _TeamMember(
                    name: "Nguyễn Trần Hoàng Long",
                    role: "UI/UX Designer",
                    avatarUrl:
                        "https://res.cloudinary.com/daxpkqhmd/image/upload/v1757582261/long_pbab33.jpg",
                  ),
                  _TeamMember(
                    name: "Nguyễn Anh Quân",
                    role: "Database & Cloud",
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

            // Google Map
            SizedBox(
              height: 250,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _officeLocation,
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId("office"),
                    position: _officeLocation,
                    infoWindow: const InfoWindow(
                      title: "AspireEdge Office",
                      snippet: "21Bis Hau Giang, Tan Binh, HCMC",
                    ),
                  ),
                },
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
                Navigator.pushNamed(context, "/contact-us");
              },
              icon: const Icon(Icons.mail_outline),
              label: const Text("Contact Us"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
  final String role;
  final String avatarUrl;

  const _TeamMember({
    required this.name,
    required this.role,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(avatarUrl),
              radius: 45, // avatar to hơn
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              role,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
