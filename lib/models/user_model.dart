import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  const UserModel({required this.id, required this.email, required this.name});
  final String id, email, name;
  factory UserModel.fromAuth(User user) => UserModel(
    id: user.uid,
    email: user.email ?? '',
    name: user.displayName ?? user.email?.split('@').first ?? '',
  );
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    User user,
  ) {
    final data = doc.data() ?? {};
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name:
          data['name'] as String? ??
          user.displayName ??
          user.email?.split('@').first ??
          '',
    );
  }
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
