import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_editor_plus/options.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image/image.dart' as img;
import 'package:testing_sticker/background_remover_screen.dart';

class StickerPackScreen extends StatefulWidget {
  final String packId;
  final String packName;

  StickerPackScreen({required this.packId, required this.packName});

  @override
  _StickerPackScreenState createState() => _StickerPackScreenState();
}

class _StickerPackScreenState extends State<StickerPackScreen> {
  List<Uint8List?> _imageDataList = List.generate(30, (index) => null);
  List<bool> _isUploading = List.generate(30, (index) => false);

  Future<void> _uploadSticker(Uint8List imageData, int index) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child('stickers/$fileName');
    UploadTask uploadTask = storageRef.putData(imageData);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    String imageUrl = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('packs').doc(widget.packId).collection('stickers').add({
      'name': 'stickerName',
      'image_url': imageUrl,
    });

    setState(() {
      _imageDataList[index] = imageData;
      _isUploading[index] = false;
    });
  }

  void _showBottomSheet(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return BottomSheetContent(
          packId: widget.packId,
          onImageSelected: (Uint8List imageData) async {
            Navigator.pop(context);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BackgroundOptionScreen(
                  imageData: imageData,
                  onImageReady: (Uint8List processedImageData) {
                    _openImageEditor(context, processedImageData, index);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Uint8List _resizeImage(Uint8List data, int width, int height) {
    img.Image? image = img.decodeImage(data);
    img.Image resized = img.copyResize(image!, width: width, height: height);
    return Uint8List.fromList(img.encodePng(resized));
  }

  Future<void> _openImageEditor(BuildContext context, Uint8List imageData, int index) async {
    var editedImageData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Container(
          color: Colors.white,
          child: ImageEditor(

            image: imageData,
            cropOption: const CropOption(
              reversible: false,
            ),
            emojiOption: EmojiOption(),
          ),
        ),
      ),
    );



    if (editedImageData != null) {
      setState(() {
        _isUploading[index] = true;
      });

      Uint8List resizedImageData = _resizeImage(editedImageData, 512, 512);
      _uploadSticker(resizedImageData, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement floating action button logic if needed
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text(widget.packName),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1,
        ),
        itemCount: 30,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              if (_imageDataList[index] != null) {
                _openImageEditor(context, _imageDataList[index]!, index);
              } else {
                _showBottomSheet(context, index);
              }
            },
            child: Container(
              margin: EdgeInsets.all(4.0),
              color: Colors.grey[200],
              child: _isUploading[index]
                  ? Center(child: CircularProgressIndicator())
                  : _imageDataList[index] != null
                  ? Image.memory(
                _imageDataList[index]!,
                fit: BoxFit.cover,
              )
                  : Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

class BottomSheetContent extends StatefulWidget {
  final String packId;
  final Function(Uint8List) onImageSelected;

  BottomSheetContent({required this.packId, required this.onImageSelected});

  @override
  _BottomSheetContentState createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
  final picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      Uint8List imageData = await pickedFile.readAsBytes();
      widget.onImageSelected(imageData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ListTile(
          leading: Icon(Icons.camera),
          title: Text('Take Photo'),
          onTap: () {
            _pickImage(ImageSource.camera);
          },
        ),
        ListTile(
          leading: Icon(Icons.photo_library),
          title: Text('Choose from Gallery'),
          onTap: () {
            _pickImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }
}
