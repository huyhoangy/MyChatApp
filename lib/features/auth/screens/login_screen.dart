import 'package:flutter/material.dart';
import '../widgets/auth_form_field.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../chat/screens/chat_screen.dart';
class LoginScreen extends StatefulWidget
{
  const LoginScreen({Key ? key}) : super(key: key);
  @override
  _LoginScreenState createState()=> _LoginScreenState();

}
class _LoginScreenState extends State<LoginScreen>
{
  final _emailController =TextEditingController();
  final _passwordController =TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading =false;

  void _login() async {
    if (!_formKey.currentState!.validate()) {
     return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });
    try{
      // goi firebase auth de login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if(context.mounted){
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const ChatScreen(),
        ));
      }
    } on FirebaseAuthException catch(e){
      String message =' da xay ra loi';
      // 'invalid-credential' là lỗi chung cho sai email hoặc sai mật khẩu
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
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
  void _goToRegister() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const RegisterScreen(),
    ));
  }
  @override
  Widget build (BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child :Form(
                key:_formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      size: 100,
                      color: Colors.teal[700],

                    ),
                    const SizedBox(height:  30),
                    Text('chao mung tro lai'
                    ,style: TextStyle(
                        fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],

                      ),),
                    const SizedBox(height: 10),
                    const Text (
                      'Dang nhap de tro chuyen',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      ),
                    const SizedBox(height: 40),
                    AuthFormField(
                      controller: _emailController,
                      hintText: 'Email',
                      iconData: Icons.email_rounded,
                      validator: (value){
                        if(value == null || value.isEmpty || !value.contains('@')){
                          return 'Vui long nhap email';
                        }
                        return null;
                      },
                    ),
                    AuthFormField(
                      controller: _passwordController,
                      hintText: 'Password',
                      iconData: Icons.lock_rounded,
                      obscureText: true,
                      validator: (value){
                        if(value == null || value.isEmpty || value.length < 6){
                          return 'Vui long nhap mat khau co it nhat 6 ki tu';

                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _isLoading ? const CircularProgressIndicator(color: Colors.teal,)
                    :
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[600],
                            foregroundColor: Colors.white,
                            shape:RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            'Dang nhap',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),

                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row (
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chua co tai khoan ? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: _goToRegister,
                          child: const Text (
                            'Dang ky ngay',
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            )
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            )
          ))
    );
  }
}

