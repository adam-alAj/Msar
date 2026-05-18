import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // App bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 20, color: colorScheme.onSurface),
                    ),
                  ),
                  const Spacer(),
                  Text('الملف الشخصي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 32),
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.surface,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null ? Icon(Icons.person, size: 44, color: colorScheme.primary) : null,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                user?.displayName ?? 'مستخدم',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              // Admin badge
              FutureBuilder<bool>(
                future: AuthService().isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text('مسؤول', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                      ]),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 28),
              // Info cards
              _buildInfoCard(Icons.email_rounded, 'البريد الإلكتروني', user?.email ?? 'غير متوفر', colorScheme),
              const SizedBox(height: 12),
              _buildInfoCard(Icons.phone_rounded, 'رقم الهاتف', user?.phoneNumber ?? 'غير متوفر', colorScheme),
              const SizedBox(height: 12),
              _buildInfoCard(Icons.fingerprint_rounded, 'معرّف المستخدم', user?.uid ?? '', colorScheme),
              const SizedBox(height: 12),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final lastLogin = data?['lastLogin'] as Timestamp?;
                  final formatted = lastLogin != null
                      ? '${lastLogin.toDate().day}/${lastLogin.toDate().month}/${lastLogin.toDate().year}'
                      : 'غير متوفر';
                  return _buildInfoCard(Icons.access_time_rounded, 'آخر تسجيل دخول', formatted, colorScheme);
                },
              ),
              const SizedBox(height: 32),
              // Logout button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
