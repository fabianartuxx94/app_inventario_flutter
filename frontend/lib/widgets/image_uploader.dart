import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';

class ImageUploader extends StatefulWidget {
  final Function(String)? onImageUploaded;
  final String? currentImageUrl;

  const ImageUploader({super.key, this.onImageUploaded, this.currentImageUrl});

  @override
  // ignore: library_private_types_in_public_api
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.currentImageUrl;
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      setState(() => _isUploading = true);

      final imageFile = source == ImageSource.camera
          ? await UploadService.takePhoto()
          : await UploadService.pickImage();

      if (imageFile != null) {
        final result = await UploadService.uploadImage(imageFile);

        if (result['success'] == true) {
          setState(() => _imageUrl = result['imageUrl']);
          widget.onImageUploaded?.call(result['imageUrl']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Vista previa de imagen
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF474554)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isUploading
              ? const Center(child: CircularProgressIndicator())
              : _imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'http://localhost:5000$_imageUrl',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 50);
                    },
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo, size: 50, color: Color(0xFFaca9bb)),
                    SizedBox(height: 8),
                    Text(
                      'Sin imagen',
                      style: TextStyle(color: Color(0xFFaca9bb)),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Botones de acción
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading
                  ? null
                  : () => _pickAndUploadImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galería'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0948d6),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isUploading
                  ? null
                  : () => _pickAndUploadImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Cámara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF474554),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
