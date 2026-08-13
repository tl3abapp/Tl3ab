import 'package:flutter/material.dart';

bool appIsArabic(String languageCode) {
  return languageCode.toLowerCase().startsWith('ar');
}

TextDirection appDirection(String languageCode) {
  return appIsArabic(languageCode) ? TextDirection.rtl : TextDirection.ltr;
}

Locale appLocale(String languageCode) {
  return appIsArabic(languageCode) ? const Locale('ar') : const Locale('en');
}

String appText(String languageCode, String english, String arabic) {
  return appIsArabic(languageCode) ? arabic : english;
}
