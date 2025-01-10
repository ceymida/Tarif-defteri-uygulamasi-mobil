import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_page.dart'; // Ana sayfaya yönlendirme
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  LoginPage({required this.onLoginSuccess}); //constructor metot giriş  başarılı olunca tetikleniyor. 

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login(BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        //trim() fonksiyonu, girilen metnin başındaki ve sonundaki boşlukları temizler.
      );

      if (userCredential.user != null) {
        // Başarılı giriş sonrası SnackBar ile mesaj göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Başarıyla giriş yapıldı!')),
        );

        // Login işlemi başarılı olduğunda callback fonksiyonunu çalıştırma
        onLoginSuccess();

        // Ana sayfaya yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        // FirebaseAuthException üzerinden hata kodlarını kontrol et
        String errorMessage = "Giriş sırasında bir hata oluştu.";
        if (e.code == 'user-not-found') {
          errorMessage =
              'Bu e-posta adresi ile kayıtlı bir kullanıcı bulunamadı.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Yanlış şifre girdiniz.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Geçersiz e-posta adresi.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giriş Yap')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'E-posta'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Şifre'),
              obscureText: true, // şifreyi gizlemek için
            ),
            ElevatedButton(
              onPressed: () => login(context),
              child: Text('Giriş Yap'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: const Text('Hesabınız yok mu? Kaydolun.'),
            ),
          ],
        ),
      ),
    );
  }
}
