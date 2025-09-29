import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ModernImageEvents extends StatefulWidget {
  final Function(List<String>) onImagesChanged;

  const ModernImageEvents({super.key, required this.onImagesChanged});

  @override
  State<ModernImageEvents> createState() => _ModernImageEventsState();
}

class _ModernImageEventsState extends State<ModernImageEvents> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  List<String> _imageUrls = [];
  bool _isUploading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return;

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showSnackBar('Du musst eingeloggt sein', isError: true);
        return;
      }

      setState(() => _isUploading = true);

      for (final image in images) {
        if (_imageUrls.length >= 5) {
          _showSnackBar('Maximal 5 Bilder erlaubt');
          break;
        }

        final file = File(image.path);
        final fileExt = image.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final uploadPath = 'events/$userId/$fileName';

        try {
          await Supabase.instance.client.storage
              .from('images')
              .upload(uploadPath, file, fileOptions: const FileOptions(upsert: true));

          final publicUrl = Supabase.instance.client.storage
              .from('images')
              .getPublicUrl(uploadPath);

          setState(() {
            _imageUrls.add(publicUrl);
          });

          widget.onImagesChanged(_imageUrls);
        } catch (e) {
          _showSnackBar('Fehler beim Hochladen: $e', isError: true);
        }
      }

      if (_imageUrls.isNotEmpty) {
        _showSnackBar('Bilder erfolgreich hochgeladen!');
      }
    } catch (e) {
      _showSnackBar('Fehler beim Auswählen der Bilder: $e', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage(int index) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final url = _imageUrls[index];
      final storageBaseUrl = Supabase.instance.client.storage.from('images').getPublicUrl('');
      final filePath = url.replaceFirst(storageBaseUrl, '');

      await Supabase.instance.client.storage.from('images').remove([filePath]);

      setState(() {
        _imageUrls.removeAt(index);
      });

      widget.onImagesChanged(_imageUrls);
      _showSnackBar('Bild erfolgreich gelöscht');
    } catch (e) {
      _showSnackBar('Fehler beim Löschen: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: _isUploading ? null : _pickAndUploadImage,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isUploading
                  ? [Colors.grey, Colors.grey.shade400]
                  : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isUploading)
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                )
              else ...[
                const Icon(
                  Icons.add_photo_alternate,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bilder\nhinzufügen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(String imageUrl, int index) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, color: Colors.grey),
                );
              },
            ),
          ),
          
          // Delete Button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _deleteImage(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          
          // Image Counter
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Event-Bilder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const Spacer(),
              if (_imageUrls.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_imageUrls.length}/5',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Teile Bilder von deinem Event (optional)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 140,
            child: _imageUrls.isEmpty
                ? Center(child: _buildAddButton())
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._imageUrls.asMap().entries.map((entry) {
                        final index = entry.key;
                        final imageUrl = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            right: 16,
                            left: index == 0 ? 0 : 0,
                          ),
                          child: _buildImageTile(imageUrl, index),
                        );
                      }).toList(),
                      
                      if (_imageUrls.length < 5)
                        Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: _buildAddButton(),
                        ),
                    ],
                  ),
          ),
          
          if (_imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tipp: Das erste Bild wird als Hauptbild verwendet.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}