import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeUpdateScreen extends StatefulWidget {
  final String recipeId; // güncellenecek tarifin idsi

  RecipeUpdateScreen({required this.recipeId});

  @override
  _RecipeUpdateScreenState createState() => _RecipeUpdateScreenState();
}

class _RecipeUpdateScreenState extends State<RecipeUpdateScreen> {
  final _formKey = GlobalKey<FormState>(); // form doğrulaması için bir anahtar tanımladım.

  TextEditingController _nameController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _ingredientsController = TextEditingController();
  TextEditingController _stepsController = TextEditingController();

  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _getRecipeDetails();
  }

  // Tarif detaylarını al ve ekranda düzenlenebilir hale getir
  Future<void> _getRecipeDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // recipeId ye göre tarif dökümanını alıyrouz.
      DocumentSnapshot recipeSnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();

      if (recipeSnapshot.exists) { //döküman varsa verileri map olarak alıyoruzç
        var recipeData = recipeSnapshot.data() as Map<String, dynamic>;

        // alınan değerleri controller lara atıyoruz .
        _nameController.text = recipeData['name'];
        _categoryController.text = recipeData['category'];
        _ingredientsController.text = recipeData['ingredients'].join(', ');
        _stepsController.text = recipeData['steps'];
      }
    } catch (e) {
      //print("Error getting recipe details: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Tarifi güncelle
  Future<void> _updateRecipe() async {
    
    if (_formKey.currentState!.validate()) {// form geçerliyse 
      setState(() {
        _isLoading = true;
      });

      try {
        // tarif dökümanının güncellendiği yer
        await FirebaseFirestore.instance.collection('recipes').doc(widget.recipeId).update({
          'name': _nameController.text,
          'category': _categoryController.text,
          'ingredients': _ingredientsController.text.split(','),
          'steps': _stepsController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tarif başarıyla güncellendi")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bir hata oluştu: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tarif Güncelle')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey, // doğrulamak için 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Tarif Adı'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tarif adı boş olamaz';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(labelText: 'Kategori'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kategori boş olamaz';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _ingredientsController,
                      decoration: InputDecoration(labelText: 'Malzemeler (Virgülle ayırın)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Malzemeler boş olamaz';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _stepsController,
                      decoration: InputDecoration(labelText: 'Hazırlık Adımları'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Hazırlık adımları boş olamaz';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateRecipe,
                      child: Text('Güncelle'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
