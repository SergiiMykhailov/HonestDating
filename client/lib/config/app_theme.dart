import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';

abstract final class AppTheme {
  static const CupertinoThemeData cupertino = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.coral,
    primaryContrastingColor: AppColors.canvas,
    scaffoldBackgroundColor: AppColors.canvas,
    barBackgroundColor: AppColors.canvas,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(color: AppColors.ink, fontSize: 16),
      navTitleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
