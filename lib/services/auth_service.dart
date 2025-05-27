import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Пример с Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _rememberMeKey = 'remember_me';
  static const String _userEmailKey = 'user_email';

  // Проверка сохраненного состояния входа
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final user = _auth.currentUser;
    
    return rememberMe && user != null;
  }

  // Метод для входа
  Future<String?> loginUser(String email, String password, {bool rememberMe = false}) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Сохраняем состояние входа и email пользователя
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_rememberMeKey, rememberMe);
        if (rememberMe) {
          await prefs.setString(_userEmailKey, email);
        } else {
          await prefs.remove(_userEmailKey);
        }
        return null;
      }
      return 'Login failed';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Метод для регистрации
  Future<String?> registerUser(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;  // Успешная регистрация
    } catch (e) {
      return 'Ошибка регистрации: ${e.toString()}';  // Ошибка при регистрации
    }
  }

  // Метод для выхода
  Future<void> logoutUser() async {
    await _auth.signOut();
    // Очищаем сохраненные данные
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_userEmailKey);
  }

  // Получение сохраненного email
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }
}
