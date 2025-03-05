import 'package:flutter/material.dart';
import 'dart:math' as math;

class UserAvatar extends StatelessWidget {
  final String? userId;
  final String? name;
  final double size;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.userId,
    this.name,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a consistent color based on the userId or name
    final Color avatarColor = backgroundColor ?? _generateAvatarColor(userId ?? name ?? '');
    
    // Get initials from name or use a fallback
    final String initials = _getInitials(name);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: avatarColor,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return '?';
    }

    final List<String> nameParts = fullName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '?';
    }
  }

  Color _generateAvatarColor(String seed) {
    // Use a hash of the seed to generate a consistent color
    final int hash = seed.hashCode.abs();
    final math.Random random = math.Random(hash);
    
    // Generate a bright, saturated color
    return HSLColor.fromAHSL(
      1.0,
      random.nextDouble() * 360, // Random hue
      0.8, // High saturation
      0.55, // Medium lightness for good contrast with white text
    ).toColor();
  }
}
