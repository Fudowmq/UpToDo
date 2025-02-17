import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Пример с Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Метод для входа
  Future<String?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;  // Успешный вход
    } catch (e) {
      return 'Ошибка входа: ${e.toString()}';  // Ошибка при входе
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
  Future<void> logout() async {
    await _auth.signOut();
  }
}
