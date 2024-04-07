import 'package:flutter/material.dart';

const accentColor = Colors.lime, highlightColor = Colors.amber;

final theme = ThemeData.dark(useMaterial3: true).copyWith(
  highlightColor: highlightColor,
  textSelectionTheme: const TextSelectionThemeData(
    selectionColor: accentColor,
    cursorColor: accentColor,
    selectionHandleColor: accentColor,
  ),
  colorScheme: ThemeData.dark().colorScheme.copyWith(
        onSurface: Colors.grey[100],
        primary: accentColor,
        secondary: accentColor,
      ),
  appBarTheme: AppBarTheme(
    iconTheme: const IconThemeData(color: accentColor),
    titleTextStyle: TextStyle(color: Colors.grey[100], fontSize: 24),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    foregroundColor: Colors.black,
    backgroundColor: accentColor,
    shape: CircleBorder(),
    iconSize: 42,
    sizeConstraints: BoxConstraints.tightFor(width: 80, height: 80),
  ),
  cardTheme: const CardTheme(
    shape: cardShape,
    elevation: 4,
    margin: EdgeInsets.fromLTRB(4, 4, 4, 0),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  timePickerTheme: const TimePickerThemeData(),
  buttonTheme: ButtonThemeData(
    minWidth: 36,
    padding: EdgeInsets.zero,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: accentColor),
  ),
  listTileTheme: const ListTileThemeData(
    shape: cardShape,
  ),
  iconTheme: const IconThemeData(size: 32.0),
);

const cardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(16.0),
    topRight: Radius.circular(16.0),
    bottomLeft: Radius.circular(4.0),
    bottomRight: Radius.circular(4.0),
  ),
);
