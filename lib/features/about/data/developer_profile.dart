import 'package:flutter/material.dart';

/// A single public link rendered as a button on the About screen.
@immutable
class DeveloperLink {
  const DeveloperLink({
    required this.label,
    required this.url,
    required this.icon,
  });

  final String label;
  final String url;
  final IconData icon;
}

/// ───────────────────────────────────────────────────────────────────────────
///  EDIT ME — this is the developer (you!) shown on the "About" screen.
///  Replace the name, role, bio, photo URL and links with your own.
/// ───────────────────────────────────────────────────────────────────────────
abstract class DeveloperProfile {
  /// Your display name.
  static const String name = 'Arsalan Kaleem';

  /// A short role / title line under your name.
  static const String role = 'Flutter Developer & AI Systems Engineer';

  /// An even shorter tagline shown under the role in the hero.
  static const String headline =
      'Building polished, AI-powered apps with Flutter.';

  /// Optional location line (leave empty to hide).
  static const String location = 'Pakistan';

  /// A couple of sentences about you.
  static const String bio =
      'I design and build polished, AI-powered mobile and web apps with '
      'Flutter. Aestimo is my AI career copilot — it turns your resume into '
      'actionable insights, tailored cover letters, interview prep and a chat '
      'that actually knows your background.';

  /// A direct URL to your profile picture (square images look best).
  /// Leave empty ('') to fall back to your initials.
  static const String photoUrl =
      'https://res.cloudinary.com/dfd2kp7s5/image/upload/v1782696532/ChatGPT_Image_Jun_29_2026_06_27_38_AM_p1zweb.png';

  /// Initials used when [photoUrl] is empty or fails to load.
  static const String initials = 'A';

  /// Short tech/skill tags shown as chips on the About screen.
  static const List<String> focusAreas = [
    'Flutter',
    'Dart',
    'Firebase',
    'Gemini AI',
    'Riverpod',
    'UI/UX',
  ];

  /// Public links shown as buttons. Add, remove or reorder freely.
  /// Use a full URL (https://…) or a mailto:/tel: scheme.
  static const List<DeveloperLink> links = [
    DeveloperLink(
      label: 'GitHub',
      url: 'https://github.com/ArsalanKaleem',
      icon: Icons.code_rounded,
    ),
    DeveloperLink(
      label: 'LinkedIn',
      url: 'www.linkedin.com/in/arsalankaleem',
      icon: Icons.work_outline_rounded,
    ),
    DeveloperLink(
      label: 'Portfolio',
      url: 'https://arsalankaleem.github.io/portfolio/',
      icon: Icons.public_rounded,
    ),
    DeveloperLink(
      label: 'Email',
      url: 'arsalanabbasi.here@gmail.com',
      icon: Icons.mail_outline_rounded,
    ),
  ];
}
