import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

const CLOUDINARY_CLOUD_NAME = 'dtcxoncos';
const CLOUDINARY_UPLOAD_PRESET = 'flutter_uploads_chatapp';


class MessageInput extends StatefulWidget {
  final Function(String text, {String? imageUrl}) onSendPressed;

  const MessageInput({
    Key? key,
    required this.onSendPressed,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _messageController = TextEditingController();
  File? _selectedImage;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      setState(() { _isSending = true; }); // Bắt đầu gửi
      final cloudinary = CloudinaryPublic(CLOUDINARY_CLOUD_NAME, CLOUDINARY_UPLOAD_PRESET);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, folder: 'chatImg_ChatApp'),
      );
      return response.secureUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi upload ảnh: ${e.toString()}'), backgroundColor: Colors.red),
      );
      return null;
    } finally {
      setState(() { _isSending = false; });
    }
  }

  void _sendChatMessage() async {
    final String text = _messageController.text.trim();
    String? imageUrl;

    if (_selectedImage != null) {
      imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      if (imageUrl == null) {
        return;
      }
    }

    if (text.isEmpty && imageUrl == null) {
      return;
    }

    widget.onSendPressed(text, imageUrl: imageUrl);
    _messageController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (_selectedImage != null)
            Stack(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null; // Hủy chọn ảnh
                      });
                    },
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

          Row(
            children: [
              IconButton(
                icon: Icon(Icons.image, color: Colors.teal[700]),
                onPressed: _isSending ? null : _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              const SizedBox(width: 8.0),
              _isSending
                  ? CircularProgressIndicator(color: Colors.teal)
                  : FloatingActionButton(
                onPressed: _sendChatMessage,
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                elevation: 0,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}