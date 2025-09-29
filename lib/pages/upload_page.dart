import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyUpload extends StatefulWidget {
  const MyUpload({super.key});

  @override
  State<MyUpload> createState() => _MyUploadState();
}

class _MyUploadState extends State<MyUpload> {
  File? _imageFile;
  final captionController = TextEditingController();

  // Bild auswählen
  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  // Bild hochladen
  Future uploadImage() async {
    if (_imageFile == null) return;

    final caption = captionController.text;
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = 'uploads/$fileName.jpg';

    try {
      await Supabase.instance.client.storage
          .from('images')
          .upload(path, _imageFile!);

      final imageUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(path);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Kein Benutzer eingeloggt');
      }

      final userId = user.id;

      await Supabase.instance.client.from('posts').insert({
        'image_url': imageUrl,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'caption': caption,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🏋️‍♂️ Bild erfolgreich hochgeladen!')),
      );

      setState(() {
        _imageFile = null;
        captionController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Hochladen: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      'Hochladen',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        color: colors.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Teile dein Training mit der Community',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Upload Card
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      _imageFile!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colors.outline,
                                        width: 2,
                                      ),
                                      color: colors.surfaceVariant,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "📷 Kein Bild ausgewählt",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: colors.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: captionController,
                              decoration: InputDecoration(
                                labelText: 'Workout Beschreibung',
                                hintText: 'z. B. „Leg Day – 100kg Squats“',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: pickImage,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.image_outlined),
                                  label: const Text("Bild auswählen"),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: uploadImage,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    backgroundColor: colors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.cloud_upload_outlined),
                                  label: const Text("Hochladen"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Branding oben links
              Positioned(
                top: 20,
                left: 30,
                child: Text(
                  'tgthr.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colors.inversePrimary,
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
