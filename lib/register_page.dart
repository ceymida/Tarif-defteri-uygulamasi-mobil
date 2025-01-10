import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore'u import et
import 'login_page.dart'; // Giriş sayfasına yönlendirme

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // kullanıcıdan alınacak veriler için kontroller 
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  void register(BuildContext context) async {
    String email = emailController.text;
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (password == confirmPassword) { 
      try {
        // Firebase Authentication ile kullanıcı kaydını oluştur
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Kullanıcı verilerini Firestore'a kaydet
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email, 
            'displayName': nameController.text +
                " " +
                surnameController.text, 
            'favorites':
                [], 
            'createdAt': FieldValue
                .serverTimestamp(), 
          });
        }

        // Başarı mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Başarıyla oluşturuldu!")),
        );

        // Giriş sayfasına yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LoginPage(onLoginSuccess: () {})),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = "Kayıt sırasında hata oluştu.";

        // Firebase hata kodlarına göre özel mesajlar
        if (e.code == 'email-already-in-use') {
          errorMessage = 'Bu e-posta adresi zaten kayıtlı.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Geçersiz e-posta adresi.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } else {
      // Şifreler uyuşmazsa hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Şifreler uyuşmuyor!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kayıt Ol")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Kayıt Ol",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.0),
            // Ad alanı
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Ad",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            // Soyad alanı
            TextField(
              controller: surnameController,
              decoration: InputDecoration(
                labelText: "Soyad",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            // E-posta alanı
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "E-posta",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            // Şifre alanı
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            // Şifre onayı alanı
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifreyi Onayla",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24.0),
            // Kayıt butonu
            ElevatedButton(
              onPressed: () => register(context),
              child: Text("Kayıt Ol"),
            ),
          ],
        ),
      ),
    );
  }
}
