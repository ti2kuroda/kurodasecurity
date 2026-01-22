import 'package:flutter/material.dart';

class HomeTextFormField extends StatelessWidget {
  final controller;
  final hintText;
  final iconData;
  final validator;
  final textInputType;
  final isSuffixIcon;
  final suffixIconOnPressed;
  final textFormatter;
  final obscureText;
  const HomeTextFormField({
    super.key,
    this.controller,
    this.hintText,
    this.iconData,
    this.validator,
    this.textInputType,
    this.suffixIconOnPressed,
    this.isSuffixIcon,
    this.textFormatter,
    this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;
    // final height = MediaQuery.of(context).size.height;
    return TextFormField(
      controller: controller,
      keyboardType: textInputType,
      inputFormatters: textFormatter == null ? [] : [textFormatter],
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,

        hintStyle: TextStyle(color: Colors.grey[800]),
        prefixIcon: Icon(iconData, color: Theme.of(context).primaryColor),
        suffixIcon: isSuffixIcon == true
            ? IconButton(
                icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                onPressed: suffixIconOnPressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      obscureText: obscureText == true ? true : false,
      style: TextStyle(color: Colors.grey[800]),
      validator: validator,
    );
  }
}
