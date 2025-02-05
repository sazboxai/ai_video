class TrainerProfile {
  final String uid;
  final String username;
  final String? photoUrl;
  final String bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerProfile({
    required this.uid,
    required this.username,
    this.photoUrl,
    required this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'photoUrl': photoUrl,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TrainerProfile.fromMap(Map<String, dynamic> map) {
    return TrainerProfile(
      uid: map['uid'],
      username: map['username'],
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
} 