import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String id;
  final String nom;
  final String role;
  final String email;
  final String? photoUrl;
  final bool isAdmin;
  final bool isAvailable;
  final int activeTasksCount;
  final String accessCode; // Code d'accès simplifié

  TeamMember({
    required this.id,
    required this.nom,
    required this.role,
    required this.email,
    this.photoUrl,
    this.isAdmin = false,
    this.isAvailable = true,
    this.activeTasksCount = 0,
    required this.accessCode,
  });

  String get initials {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  String get roleLabel {
    if (isAdmin) return 'Admin';
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'editeur':
        return 'Éditeur';
      case 'membre':
        return 'Membre';
      default:
        return role;
    }
  }

  factory TeamMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamMember(
      id: doc.id,
      nom: data['nom'] ?? '',
      role: data['role'] ?? 'membre',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      isAdmin: data['isAdmin'] ?? false,
      isAvailable: data['isAvailable'] ?? true,
      activeTasksCount: data['activeTasksCount'] ?? 0,
      accessCode: data['accessCode'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'role': role,
      'email': email,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'isAvailable': isAvailable,
      'activeTasksCount': activeTasksCount,
      'accessCode': accessCode,
    };
  }

  TeamMember copyWith({
    String? id,
    String? nom,
    String? role,
    String? email,
    String? photoUrl,
    bool? isAdmin,
    bool? isAvailable,
    int? activeTasksCount,
    String? accessCode,
  }) {
    return TeamMember(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      role: role ?? this.role,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isAvailable: isAvailable ?? this.isAvailable,
      activeTasksCount: activeTasksCount ?? this.activeTasksCount,
      accessCode: accessCode ?? this.accessCode,
    );
  }
}
