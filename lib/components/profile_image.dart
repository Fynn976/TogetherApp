
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileImage extends StatefulWidget {
  const ProfileImage({super.key});

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
  }

  Future<void> _loadAvatarUrl() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await Supabase.instance.client
        .from('profiles')
        .select('avatar_url')
        .eq('id', userId)
        .single();

    setState(() {
      avatarUrl = response['avatar_url'];
    });
  }

 Future<void> _pickAndUploadImage() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);
  if (image == null) {
    print('❌ Kein Bild ausgewählt');
    return;
  }

  final userId = Supabase.instance.client.auth.currentUser?.id;
  final file = File(image.path);
  final fileExt = image.path.split('.').last;
  final fileName = '$userId.$fileExt';

  print('📤 Lade Datei hoch: $fileName');

  final uploadResponse = await Supabase.instance.client.storage
      .from('avatars')
      .upload('$fileName', file, fileOptions: const FileOptions(upsert: true));

  print('✅ Upload abgeschlossen: $uploadResponse');

  final newUrl = Supabase.instance.client.storage
      .from('avatars')
      .getPublicUrl('$fileName');

  print('🌐 Neue Avatar-URL: $newUrl');

  await Supabase.instance.client.from('profiles').upsert({
    'id': userId,
    'avatar_url': newUrl,
  });

  print('✅ Profil aktualisiert in Supabase');

  setState(() {
    avatarUrl = newUrl;
  });
}


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Profilbild ändern',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontWeight: FontWeight.w500,
            )),
            content: Text('Möchten Sie ein neues Profilbild auswählen?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontWeight: FontWeight.w400,
            )),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage();
                },
                child: Text('Ja',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.w900,
                )),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Nein',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontWeight: FontWeight.w900,
                  )),
              ),
            ],
          ),
        );
      },
      
      child: CircleAvatar(
        radius: 50,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null
            ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.inversePrimary)
            : null,
      ),
    );
  }
}
