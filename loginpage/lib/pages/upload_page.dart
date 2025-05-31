import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loginpage/components/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyUpload extends StatefulWidget {
  const MyUpload({super.key});

  @override
  State<MyUpload> createState() => _MyUploadState();
}

class _MyUploadState extends State<MyUpload> {
  File?_imageFile;

  // pick image
  Future pickImage() async {
    // picker
    final ImagePicker picker = ImagePicker();

    // pick from gallery
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    // update image preview
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }
  
  // upload image
  Future uploadImage() async {
  if (_imageFile == null) return;

  // generate a unique file name
  final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  final path = 'uploads/$fileName.jpg';

  try {
    // Upload image to Supabase Storage
    await Supabase.instance.client.storage
        .from('images')
        .upload(path, _imageFile!);

    // Get the public image URL
    final imageUrl = Supabase.instance.client.storage
        .from('images')
        .getPublicUrl(path);

    // Get the current user ID
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Kein Benutzer eingeloggt');
    }

    final userId = user.id;

    // Insert image URL and user ID into 'posts' table
    await Supabase.instance.client.from('posts').insert({
      'image_url': imageUrl,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Erfolgsmeldung
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bild erfolgreich hochgeladen!')),
    );

    setState(() {
      _imageFile = null;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fehler beim Hochladen: ${e.toString()}')),
    );
  }
}


  
  
  // upload video



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea( // Sicherer Bereich, um Notches zu berücksichtigen
        child: SingleChildScrollView(
        child: Stack(
          children: [
            // Main content of the page
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 25),

                  // Freunde text
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0, top: 50),
                    child: Row(
                      children: [
                        Text(
                          'Hochladen',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Was machen meine Freunde text
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Row(
                      children: [
                        Text(
                          'Lade neue Inhalte hoch',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 100),

                // Image preview
                _imageFile != null
                  ? Image.file(_imageFile!)
                  : Text('Kein Bild ausgewählt',
                      style: TextStyle(fontSize: 16, 
                      color: Theme.of(context).colorScheme.inversePrimary
                      )
                    ),

                const SizedBox(height: 20),

                // Upload button
                ElevatedButton(
                  onPressed: () {
                    pickImage();
                  },
                  child: Text('Bild auswählen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  
                  ),
                ),

                const SizedBox(height: 20),

                // Upload button
                ElevatedButton(
                  onPressed: () {
                    uploadImage();
                  },
                  child: Text('Bild hochladen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  
                  ),
                ),


                  



                ],
              ),
            ),

           
          


            // "tgthr." text positioned at the top-right corner
            Positioned(
              top: 20,
              left: 30, // Position it to the right side
              child: Text(
                'tgthr.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.inversePrimary,
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