import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class RecipeAddScreen extends StatefulWidget {
  @override
  _RecipeAddScreenState createState() => _RecipeAddScreenState();
}

class _RecipeAddScreenState extends State<RecipeAddScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController ingredientsController = TextEditingController();
  final TextEditingController stepsController = TextEditingController();

  XFile? _image; // Seçilen görselin dosya bilgilerin tutacak değişken

  bool isLoading = false;

  // Görsel Seçme İşlemi
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // seçilen dosyanın 
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    // pick image ile aleriden seçilen dosyanın bilgisini döner picked file
    setState(() {
      _image = pickedFile; // seçilen görselin dosya bilgisini değişkene atıyoruz. 
    });
  }

  // Görseli Firebase Storage'a Yükleyip URL'sini Döndürme
  Future<String> _uploadImage(XFile image) async {
    try {
      // Firebase Storage'da, 'recipes' klasörüne yeni bir dosya adı (şu anki zaman) ile referans oluşturuluyor.
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('recipes/${DateTime.now().toString()}');
      // Görsel, storageRef referansına yüklenir. 'putFile' ile görsel yüklenir.
      final uploadTask = storageRef.putFile(File(image.path));
      // Yükleme tamamlandıktan sonra snapshot alınır.
      final snapshot = await uploadTask.whenComplete(() {});
      // Yüklenen görselin URL'si alınır.
      final downloadUrl = await snapshot.ref.getDownloadURL();

      
     // print('Görselin URL\'si: $downloadUrl'); 

      return downloadUrl;
    } catch (e) {
      print("Hata oluştu: $e");
      return '';
    }
  }

  // Tarif Ekleme
  Future<void> saveRecipe() async {
    if (_image == null) { // görsel seçilmesi zorunlu 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen bir görsel seçin.")),
      );
      return;
    }
    setState(() {
      // Yükleme işlemi başladığında isLoading true yapılır, UI güncellenir.
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Görseli Firebase Storage'a yükle
        String imageUrl = await _uploadImage(_image!);

        //
        // print(
        //     'Tarif kaydedilecekken imageUrl: $imageUrl'); // Bu satır ile URL'yi yazdırıyoruz

        // Tarifi Firestore'a kaydetme
        await FirebaseFirestore.instance.collection('recipes').add({
          // tarifin adı titlecontrollerdan alınıyor.
          'name': titleController.text,
          'category': categoryController.text,
          'ingredients': ingredientsController.text
              .split(','), // Malzemeleri virgülle ayırarak listeye çevir
          'steps': stepsController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'addedBy': user.uid,
          'imageUrl': imageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tarif başarıyla eklendi!")),
        );
        Navigator.pop(
            context); // ekleme işlemi başarılı olursa önceki sayfaya dön
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Giriş yapılmadan tarif eklenemez.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tarif eklenirken bir hata oluştu: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tarif Ekle')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Tarif Adı
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Tarif Adı'),
            ),
            // Kategori
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: 'Kategori'),
            ),
            // Malzemeler
            TextField(
              controller: ingredientsController,
              decoration:
                  InputDecoration(labelText: 'Malzemeler (Virgülle ayırın)'),
            ),
            // Hazırlık Adımları
            TextField(
              controller: stepsController,
              decoration: InputDecoration(labelText: 'Hazırlık Adımları'),
            ),
            SizedBox(height: 20),

            // Görsel Seçme Butonu
            ElevatedButton(
              onPressed: _pickImage,
              child: Text(_image == null ? 'Resim Seç' : 'Resim Seçildi'),
            ),

            // Görsel Önizleme
            if (_image != null)
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                height: 200,
                width: double.infinity,
                child: Image.file(File(_image!.path), fit: BoxFit.cover),
              ),

            // Yükleniyor ise yükleniyor sembolü gözüksün. 
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: saveRecipe,
                    child: Text('Kaydet'),
                  ),
          ],
        ),
      ),
    );
  }
}
