import 'package:flutter/material.dart';

const colorPrimary = Colors.black87;
final colorPrimaryLight = Colors.black38;
final colorPrimarySuperLight = Colors.grey[100];
final separatorColor = Colors.grey[200];
const textColorPrimary = Colors.black87;
const textColorSecondary = Colors.black38;

final appTheme = ThemeData(
  primaryColor: const Color(0xFF313131),
  accentColor: colorPrimaryLight,
  highlightColor: colorPrimarySuperLight,
  textSelectionColor: colorPrimary,
);

const textStyleTitle = const TextStyle(
  color: textColorPrimary,
  fontSize: 36.0,
  fontWeight: FontWeight.bold,
  fontFamily: "Comfortaa",
);

const textStyleSubtitle = const TextStyle(
  color: textColorSecondary,
  fontSize: 14.0,
  letterSpacing: 1.1,
);

const textStyleBody = const TextStyle(
  fontSize: 16.0,
  color: colorPrimary,
);

const textStyleSecondary = TextStyle(
  color: textColorSecondary,
  fontSize: 14.0,
  height: 1.1,
);
