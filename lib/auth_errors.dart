import 'package:firebase_auth/firebase_auth.dart';

/// Firebase এর ইংরেজি error কে সহজ বাংলা বার্তায় বদলায়।
String authErrorMessage(Object e,
    {String fallback = 'কিছু একটা সমস্যা হয়েছে, আবার চেষ্টা করুন'}) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'এই ইমেইলে আগেই অ্যাকাউন্ট খোলা আছে';
      case 'invalid-email':
        return 'ইমেইল সঠিক নয়';
      case 'weak-password':
        return 'পাসওয়ার্ড দুর্বল — কমপক্ষে ৬ অক্ষর দিন';
      case 'user-not-found':
        return 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই';
      case 'wrong-password':
      case 'invalid-credential':
        return 'ইমেইল বা পাসওয়ার্ড ভুল';
      case 'too-many-requests':
        return 'অনেকবার চেষ্টা করা হয়েছে, কিছুক্ষণ পরে চেষ্টা করুন';
      case 'network-request-failed':
        return 'ইন্টারনেট সংযোগ নেই';
    }
  }
  final s = e.toString();
  if (s.contains('permission-denied')) {
    return 'অনুমতি নেই — সাপোর্টে যোগাযোগ করুন';
  }
  if (s.contains('network')) return 'ইন্টারনেট সংযোগ নেই';
  return fallback;
}
