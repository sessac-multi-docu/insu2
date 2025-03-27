import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // 라이트 모드 색상
  static const Color lightBackground = CupertinoColors.systemBackground;
  static const Color lightSurface = CupertinoColors.systemBackground;
  static const Color lightPrimary = CupertinoColors.activeBlue;
  static const Color lightSecondary = CupertinoColors.systemGrey;
  static const Color lightSidebarBackground = Color(0xFFF5F5F7);
  static const Color lightTextPrimary = CupertinoColors.black;
  static const Color lightTextSecondary = CupertinoColors.systemGrey;
  static const Color lightDivider = CupertinoColors.systemGrey5;
  static const Color lightCardBackground = CupertinoColors.white;

  // 다크 모드 색상
  static const Color darkBackground = Color(0xFF1E1E28);
  static const Color darkSurface = Color(0xFF2A2A35);
  static const Color darkPrimary = Color(0xFF10A37F);  // ChatGPT 브랜드 색상
  static const Color darkSecondary = CupertinoColors.systemGrey2;
  static const Color darkSidebarBackground = Color(0xFF202123);  // ChatGPT 사이드바 배경색
  static const Color darkTextPrimary = CupertinoColors.white;
  static const Color darkTextSecondary = CupertinoColors.systemGrey;
  static const Color darkDivider = Color(0xFF444654);
  static const Color darkCardBackground = Color(0xFF2A2A35);

  // 공용 색상
  static const Color userBubbleColor = Color(0xFFF1F5F9);  // 사용자 메시지 배경(라이트)
  static const Color botBubbleColorLight = CupertinoColors.white;  // 봇 메시지 배경(라이트)
  static const Color botBubbleColorDark = Color(0xFF444654);  // 봇 메시지 배경(다크)
  static const Color userBubbleColorDark = Color(0xFF343541);  // 사용자 메시지 배경(다크)

  // CupertinoThemeData 생성 함수 (라이트 모드)
  static CupertinoThemeData getCupertinoThemeLight() {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,
      barBackgroundColor: lightBackground,
      textTheme: CupertinoTextThemeData(
        primaryColor: lightTextPrimary,
        textStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 16,
          fontFamily: 'SF Pro Text',
        ),
      ),
    );
  }

  // CupertinoThemeData 생성 함수 (다크 모드)
  static CupertinoThemeData getCupertinoThemeDark() {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      barBackgroundColor: darkSurface,
      textTheme: CupertinoTextThemeData(
        primaryColor: darkTextPrimary,
        textStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 16,
          fontFamily: 'SF Pro Text',
        ),
      ),
    );
  }

  // ThemeData 생성 함수 (라이트 모드)
  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        background: lightBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Text',
        ),
      ),
      cardTheme: const CardTheme(
        color: lightCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 0.5,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: lightTextPrimary,
          fontSize: 16,
          fontFamily: 'SF Pro Text',
        ),
        bodyMedium: TextStyle(
          color: lightTextPrimary,
          fontSize: 14,
          fontFamily: 'SF Pro Text',
        ),
        titleLarge: TextStyle(
          color: lightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'SF Pro Display',
        ),
        titleMedium: TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Text',
        ),
        labelMedium: TextStyle(
          color: lightTextSecondary,
          fontSize: 13,
          fontFamily: 'SF Pro Text',
        ),
      ),
      iconTheme: const IconThemeData(
        color: lightTextPrimary,
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
    );
  }

  // ThemeData 생성 함수 (다크 모드)
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        background: darkBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Text',
        ),
      ),
      cardTheme: const CardTheme(
        color: darkCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 0.5,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: darkTextPrimary,
          fontSize: 16,
          fontFamily: 'SF Pro Text',
        ),
        bodyMedium: TextStyle(
          color: darkTextPrimary,
          fontSize: 14,
          fontFamily: 'SF Pro Text',
        ),
        titleLarge: TextStyle(
          color: darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'SF Pro Display',
        ),
        titleMedium: TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Text',
        ),
        labelMedium: TextStyle(
          color: darkTextSecondary,
          fontSize: 13,
          fontFamily: 'SF Pro Text',
        ),
      ),
      iconTheme: const IconThemeData(
        color: darkTextPrimary,
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
    );
  }

  // 모드에 따른 메시지 버블 색상 반환
  static Color getUserBubbleColor(bool isDarkMode) {
    return isDarkMode ? userBubbleColorDark : userBubbleColor;
  }

  static Color getBotBubbleColor(bool isDarkMode) {
    return isDarkMode ? botBubbleColorDark : botBubbleColorLight;
  }
} 