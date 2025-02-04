import 'package:flutter/material.dart';

enum UserRole {
  trainer,
  user;

  String get title {
    switch (this) {
      case UserRole.trainer:
        return "I'm a Trainer";
      case UserRole.user:
        return "I'm a User";
    }
  }

  String get subtitle {
    switch (this) {
      case UserRole.trainer:
        return "Create and share workout routines";
      case UserRole.user:
        return "Access personalized workouts";
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.trainer:
        return Icons.sports;
      case UserRole.user:
        return Icons.person;
    }
  }
} 