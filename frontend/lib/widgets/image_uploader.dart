import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class ImageUploader extends StatefulWidget {
  final Function(dynamic)? onImageSelected;
  final String? currentImageUrl;
  final String? nombreArticulo;
  final String? marca;
  final String? referencia;

  const ImageUploader({
    super.key,
    this.onImageSelected,
    this.currentImageUrl,
    this.nombreArticulo,
    this.marca,
    this.referencia,
  });

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  String? _imageUrl;
  File? _selectedImage;
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.currentImageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          
          if (!mounted) return;
          
          setState(() {
            _webImageBytes = bytes;
          });
          
          final webImageData = {
            'bytes': bytes,
            'name': pickedFile.name,
            'type': 'web'
          };
          
          widget.onImageSelected?.call(webImageData);
          
          if (kDebugMode) {
            print('📸 Imagen web seleccionada: ${pickedFile.name}');
          }
        } else {
          final imageFile = File(pickedFile.path);
          
          if (!mounted) return;
          
          setState(() {
            _selectedImage = imageFile;
          });
          widget.onImageSelected?.call(imageFile);
          
          if (kDebugMode) {
            print('📸 Imagen seleccionada: ${imageFile.path}');
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📸 Imagen seleccionada - Se subirá al guardar'),
              backgroundColor: Color(0xFFf59e0b),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error seleccionando imagen: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeImage() {
    if (!mounted) return;
    
    setState(() {
      _imageUrl = null;
      _selectedImage = null;
      _webImageBytes = null;
    });
    
    widget.onImageSelected?.call(null);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Imagen removida'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeSelectedImage() {
    if (!mounted) return;
    
    setState(() {
      _selectedImage = null;
      _webImageBytes = null;
    });
    
    widget.onImageSelected?.call(null);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Imagen seleccionada removida'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    } else {
      return '${AppConfig.baseUrl}/$imagePath';
    }
  }

  bool get _isDesktop {
    return !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                       defaultTargetPlatform == TargetPlatform.macOS || 
                       defaultTargetPlatform == TargetPlatform.linux);
  }

  bool get _isMobile {
    return !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                       defaultTargetPlatform == TargetPlatform.iOS);
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImageBytes != null) {
      return Stack(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFf59e0b), width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                _webImageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF2d3748),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 40, color: Colors.red),
                        SizedBox(height: 4),
                        Text('Error', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _removeSelectedImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFf59e0b),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PENDIENTE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!kIsWeb && _selectedImage != null) {
      return Stack(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFf59e0b), width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF2d3748),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 40, color: Colors.red),
                        SizedBox(height: 4),
                        Text('Error', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _removeSelectedImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFf59e0b),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PENDIENTE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Stack(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF10b981), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _getImageUrl(_imageUrl!),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF2d3748),
                    child: const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF2d3748),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 40, color: Colors.red),
                        SizedBox(height: 4),
                        Text('Error', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _removeImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10b981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ACTUAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF474554)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2d3748),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, size: 40, color: Color(0xFFaca9bb)),
          SizedBox(height: 8),
          Text(
            'Sin imagen',
            style: TextStyle(
              color: Color(0xFFaca9bb),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen del Artículo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1a202c),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFf59e0b)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Color(0xFFf59e0b), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'La imagen se subirá al presionar "Actualizar"',
                  style: TextStyle(
                    color: Color(0xFFf59e0b),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        Center(child: _buildImagePreview()),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Seleccionar de Galería'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0948d6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            if (!kIsWeb) const SizedBox(width: 12),
            if (!kIsWeb)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(
                    _isDesktop ? 'Usar Cámara' : 'Tomar Foto',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF474554),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),

        if (kIsWeb) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2f40),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF474554)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFf59e0b), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'En web solo se permite seleccionar archivos',
                  style: TextStyle(
                    color: Color(0xFFaca9bb),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_isDesktop) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2f40),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10b981)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.computer, color: Color(0xFF10b981), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'En escritorio puedes usar la cámara si está disponible',
                  style: TextStyle(
                    color: Color(0xFFaca9bb),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}