import 'package:flutter/cupertino.dart';

abstract final class AppTheme {
  static const CupertinoThemeData cupertino = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: CupertinoColors.systemPink,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    barBackgroundColor: CupertinoColors.systemBackground,
  );
}
