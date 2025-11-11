import 'package:flutter/material.dart';
import '../widgets/auth_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../chat/screens/chat_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading =false;


  void _register() async {
    // TODO: Thêm logic đăng ký Firebase
    if (!_formKey.currentState!.validate()) {
      return;

    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });
    try{
      // tao tai khoan tren firebase
      UserCredential userCredential
      = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if(userCredential.user != null){
        String uid =userCredential.user!.uid;
        String email= userCredential.user!.uid;
        // luu ho so nguoi dung vao CLOUD FIRESTORE
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'displayName': email.split('@')[0], // Tạm lấy tên là phần trước @
          'photoUrl': '', // Sẽ cập nhật sau
          'bio': 'Xin chào, tôi là người mới!', // Tiểu sử mặc định
          'createdAt': Timestamp.now(),
        });
        //chuyen den man hinh chat
        if(context.mounted){
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder:(context)=> const ChatScreen(),
          ));
        }
      }
    } on FirebaseAuthException catch(e){
      // xu ly loi
      String message =' da xay ra loi';
      if(e.code == 'email-already-in-use'){
        message = 'Email da duoc su dung';
      }else if(e.code == 'weak-password'){
        message = 'Mat khau qua ngan';

      }
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
        );
      }
    } catch(e){
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });

  }

  void _goToLogin() {
    Navigator.of(context).pop(); // Quay lại màn hình trước đó (Login)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Nút back
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[800]),
          onPressed: _goToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tiêu đề
                  Text(
                    'Tạo tài khoản',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bắt đầu cuộc trò chuyện của bạn!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Ô Email
                  AuthFormField(
                    controller: _emailController,
                    hintText: 'Email',
                    iconData: Icons.email_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Vui lòng nhập email hợp lệ';
                      }
                      return null;
                    },
                  ),

                  // Ô Mật khẩu
                  AuthFormField(
                    controller: _passwordController,
                    hintText: 'Mật khẩu',
                    obscureText: true,
                    iconData: Icons.lock_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),

                  // Ô Xác nhận Mật khẩu
                  AuthFormField(
                    controller: _confirmPasswordController,
                    hintText: 'Xác nhận mật khẩu',
                    obscureText: true,
                    iconData: Icons.lock_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }

                      if (value != _passwordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Nút Đăng ký
                   _isLoading ? const CircularProgressIndicator(color:Colors.teal,)
                  :SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đăng ký',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Chuyển sang Đăng nhập
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: _goToLogin,
                        child: const Text(
                          'Đăng nhập ngay',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}