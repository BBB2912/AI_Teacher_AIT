import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:flutter/material.dart';

class ImageInput extends StatefulWidget {
  const ImageInput({super.key,required this.onselectedImage});
  final void Function(File image) onselectedImage;
  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  File? _selectedImage;

  void _pickImage() async {
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 100,
    );
    if (pickedImage == null) return;
    final image = File(pickedImage.path);
    final filename = path.basename(image.path);
    final copiedImage = await image.copy('${appDir.path}/$filename');
    setState(() {
      _selectedImage = copiedImage;
    });
    widget.onselectedImage(copiedImage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 2,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
            foregroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : null,
            child: Icon(
              Icons.person_4,
              color: Theme.of(context).colorScheme.primary,
              size: 70,
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: _pickImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              foregroundColor: Theme.of(context).colorScheme.secondary,
            ),
          
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_selectedImage != null ? "change" : "Take"),
                Icon(
                  _selectedImage != null ? Icons.add : Icons.camera_alt_outlined,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
