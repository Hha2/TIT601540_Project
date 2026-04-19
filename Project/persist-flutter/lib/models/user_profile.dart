import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPremium;
  final int streak;
  final int stabilityScore;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.isPremium = false,
    this.streak = 0,
    this.stabilityScore = 0,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPremium: data['isPremium'] ?? false,
      streak: data['streak'] ?? 0,
      stabilityScore: data['stabilityScore'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'displayName': displayName,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isPremium': isPremium,
        'streak': streak,
        'stabilityScore': stabilityScore,
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPremium,
    int? streak,
    int? stabilityScore,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPremium: isPremium ?? this.isPremium,
        streak: streak ?? this.streak,
        stabilityScore: stabilityScore ?? this.stabilityScore,
      );
}
