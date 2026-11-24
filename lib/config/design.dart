import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/widgets/loader_widget.dart';
import '/resources/widgets/logo_widget.dart';
import 'package:google_fonts/google_fonts.dart';

final class DesignConfig {
  static final TextStyle appFont = GoogleFonts.montserrat();

  static final Widget logo = const Logo();

  static final Widget loader = const Loader();

  static const FormFieldStyle formFieldStyle = FormFieldStyle.filled();
}
