import 'package:flutter/material.dart';

const accentColor = Colors.lime;

final theme = ThemeData.dark().copyWith(
  highlightColor: Colors.amber,
  textSelectionTheme: const TextSelectionThemeData(
    selectionColor: accentColor,
    cursorColor: accentColor,
    selectionHandleColor: accentColor,
  ),
  colorScheme: ThemeData.dark().colorScheme.copyWith(
        onSurface: accentColor[50],
        primary: accentColor,
        secondary: accentColor,
      ),
  appBarTheme: AppBarTheme(
    iconTheme: const IconThemeData(color: accentColor),
    titleTextStyle: TextStyle(color: Colors.grey[100], fontSize: 24),
  ),
  floatingActionButtonTheme:
      const FloatingActionButtonThemeData(backgroundColor: accentColor),
  cardTheme: const CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
          bottomLeft: Radius.circular(4.0),
          bottomRight: Radius.circular(4.0),
        ),
      ),
      elevation: 4,
      margin: EdgeInsets.fromLTRB(4, 4, 4, 0)),
  buttonTheme: ButtonThemeData(
    minWidth: 36,
    padding: EdgeInsets.zero,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: accentColor),
  ),
  iconTheme: const IconThemeData(size: 42.0),
);
