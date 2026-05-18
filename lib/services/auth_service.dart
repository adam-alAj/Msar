import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ================= GOOGLE SIGN IN =================
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ User cancelled sign-in');
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      await _saveUserToFirestore(userCredential);
      return userCredential;
    } catch (e) {
      debugPrint('🔴 Google login error: $e');
      rethrow;
    }
  }

  // ================= PHONE AUTH - SEND OTP =================
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(UserCredential credential) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCredential =
              await _auth.signInWithCredential(credential);
          await _saveUserToFirestore(userCredential);
          onAutoVerified(userCredential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('🔴 Phone auth error: ${e.code} — ${e.message}');
          onError(_arabicError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ OTP sent');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⚠️ Auto retrieval timeout');
        },
      );
    } catch (e) {
      debugPrint('🔴 sendOTP error: $e');
      onError('حدث خطأ، حاول مرة أخرى');
    }
  }

  // ================= PHONE AUTH - VERIFY OTP =================
  Future<UserCredential?> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      await _saveUserToFirestore(userCredential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('🔴 verifyOTP error: ${e.code}');
      throw _arabicError(e.code); // 👈 throw Arabic string instead
    }
  }

  // ================= ARABIC ERROR MESSAGES =================
  String _arabicError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صحيح، تأكد من الرقم وحاول مرة أخرى';
      case 'too-many-requests':
        return 'تم إرسال رمز التحقق كثيراً، حاول لاحقاً';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح، حاول مرة أخرى';
      case 'session-expired':
        return 'انتهت صلاحية الرمز، أعد إرسال رمز التحقق';
      case 'quota-exceeded':
        return 'تم تجاوز الحد المسموح، حاول لاحقاً';
      case 'user-disabled':
        return 'هذا الحساب موقوف، تواصل مع الدعم';
      case 'missing-phone-number':
        return 'أدخل رقم الهاتف';
      case 'sms-blocked':
        return 'لا يمكن إرسال رسالة SMS إلى هذا الرقم';
      default:
        return 'حدث خطأ، تحقق من الرقم وحاول مرة أخرى';
    }
  }

  // ================= SHARED =================
  Future<void> _saveUserToFirestore(UserCredential userCredential) async {
    final docRef = _firestore.collection('users').doc(userCredential.user!.uid);
    final doc = await docRef.get();
    final data = <String, dynamic>{
      'email': userCredential.user!.email,
      'name': userCredential.user!.displayName,
      'photoUrl': userCredential.user!.photoURL,
      'phone': userCredential.user!.phoneNumber,
      'lastLogin': FieldValue.serverTimestamp(),
    };
    // Only set isAdmin to false for new users
    if (!doc.exists) {
      data['isAdmin'] = false;
    }
    await docRef.set(data, SetOptions(merge: true));
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc =
        await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['isAdmin'] ?? false;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}