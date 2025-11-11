import 'package:flutter/material.dart';
class AuthFormField extends StatelessWidget{
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData iconData;
  final String ? Function(String?)? validator;
  const AuthFormField({
    Key ? key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    required this.iconData,
    this.validator,

}): super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator:validator,
        decoration: InputDecoration(
          prefixIcon: Icon(iconData, color: Colors.grey[600]),
          hintText: hintText,
          filled:true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color:Colors.teal),
        ),
    ),
    ),
    );
  }
}