import 'package:flutter/material.dart';

// --- URLS E HEADERS ---
//const String urlBase = 'http://localhost:3000';
const String urlBase = 'https://roleapp-cloud.onrender.com';
const Map<String, String> defaultHeaders = {"Content-Type": "application/json"};

// --- CORES DA MARCA ---
const Color kPrimaryColor = Color(0xFF1D4F90);
const Color kSecondaryColor = Color(0xFF31B152);
const Color kBgLight = Color(0xFFF4F7FA);
const Color kBgDark = Color(0xFF121212);

// --- TEMA ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// --- FUNÇÕES ÚTEIS ---
String formatarDistancia(dynamic dist) {
  int metros = dist is int ? dist : int.tryParse(dist.toString()) ?? 0;
  return metros >= 1000
      ? "${(metros / 1000).toStringAsFixed(1)} km"
      : "$metros m";
}
