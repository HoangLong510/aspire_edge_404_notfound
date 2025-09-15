import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddStoryPage extends StatefulWidget {
  const AddStoryPage({super.key});

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  File? _bannerImage;
  bool _isSubmitting = false;

  final cloudName = "daxpkqhmd";
  final uploadPreset = "404notfound";

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _bannerImage = File(picked.path));
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final req = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final res = await req.send();
    final resBody = await res.stream.bytesToString();
    if (res.statusCode == 200) {
      final data = jsonDecode(resBody);
      return data["secure_url"];
    } else {
      throw "Cloudinary upload failed: ${res.statusCode}";
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Not logged in";

      if (_titleCtrl.text.trim().isEmpty ||
          _descCtrl.text.trim().isEmpty ||
          _contentCtrl.text.trim().isEmpty) {
        throw "Please fill in all fields";
      }

      String? bannerUrl;
      if (_bannerImage != null) {
        bannerUrl = await _uploadToCloudinary(_bannerImage!);
      }

      final payload = {
        "userId": user.uid,
        "mainTitle": _titleCtrl.text.trim(),
        "subTitle": _descCtrl.text.trim(),
        "content": _contentCtrl.text.trim(),
        "bannerUrl": bannerUrl ?? "",
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection("Stories").add(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Story submitted, pending approval")),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/my_stories',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Share Your Story")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickBanner,
              child: _bannerImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _bannerImage!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: "Short Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: "Full Story Content",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send),
                    label: const Text("Submit Story"),
                  ),
          ],
        ),
      ),
    );
  }
}
