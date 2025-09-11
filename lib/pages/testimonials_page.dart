import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;


class TestimonialsPage extends StatefulWidget {
  const TestimonialsPage({super.key});

  @override
  State<TestimonialsPage> createState() => _TestimonialsPageState();
}

class _TestimonialsPageState extends State<TestimonialsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController storyController = TextEditingController();

  File? avatarFile;
  bool _isSubmitting = false;

  final cloudName = "daxpkqhmd";
  final uploadPreset = "404notfound";

  // Upload ảnh lên Cloudinary
  Future<String?> _uploadAvatar(File file) async {
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["secure_url"];
    }
    return null;
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        avatarFile = File(pickedFile.path);
      });
    }
  }

  Future<void> submitTestimonial() async {
    if (nameController.text.isEmpty || storyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? imageUrl;
    if (avatarFile != null) {
      imageUrl = await _uploadAvatar(avatarFile!);
    }

    await FirebaseFirestore.instance.collection("Testimonials").add({
      "name": nameController.text.trim(),
      "story": storyController.text.trim(),
      "image": imageUrl ??
          "https://res.cloudinary.com/$cloudName/image/upload/v123456789/default_avatar.png",
      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() {
      _isSubmitting = false;
      avatarFile = null;
      nameController.clear();
      storyController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Câu chuyện đã được chia sẻ 🎉")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Câu chuyện thành công")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Testimonials")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text("Chưa có câu chuyện nào"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage:
                              CachedNetworkImageProvider(data["image"]),
                        ),
                        title: Text(
                          data["name"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          data["story"],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickAvatar,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        avatarFile != null ? FileImage(avatarFile!) : null,
                    child: avatarFile == null
                        ? const Icon(Icons.add_a_photo, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      hintText: "Tên của bạn", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: storyController,
                  decoration: const InputDecoration(
                      hintText: "Chia sẻ câu chuyện tích cực...",
                      border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: submitTestimonial,
                        child: const Text("Chia sẻ"),
                      )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
