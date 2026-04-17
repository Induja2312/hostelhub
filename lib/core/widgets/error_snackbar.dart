import 'package:flutter/material.dart';
import '../utils/helpers.dart';

// While helpers.dart handles standard generic snackbars,
// this class wraps throwing specific error types or custom UI error bars if needed.
class ErrorSnackBar {
  static void show(BuildContext context, String message) {
    Helpers.showSnackBar(context, message, isError: true);
  }

  static void showSuccess(BuildContext context, String message) {
    Helpers.showSnackBar(context, message, isError: false);
  }
}
