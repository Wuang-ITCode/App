import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 🔹 Người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  /// 🔹 Đăng xuất (Firebase + Google)
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // ===========================================================
  // 🔸 EMAIL / PASSWORD
  // ===========================================================

  /// 🔹 Đăng nhập bằng email & password
  Future<UserCredential> signInEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// 🔹 Đăng ký tài khoản mới bằng email & password (không xác minh email)
  Future<UserCredential> registerEmail(String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCred;
  }

  // ===========================================================
  // 🔸 GOOGLE SIGN-IN (tùy chọn)
  // ===========================================================

  /// 🔹 Đăng nhập bằng Google
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Người dùng đã hủy đăng nhập Google');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // ===========================================================
  // 🔸 ALIAS (để tương thích với UI)
  // ===========================================================

  /// 🟢 Alias cho đăng nhập
  Future<UserCredential> signIn(String email, String password) =>
      signInEmail(email, password);

  /// 🟢 Alias cho đăng ký
  Future<UserCredential> signUp(String email, String password) =>
      registerEmail(email, password);
}
