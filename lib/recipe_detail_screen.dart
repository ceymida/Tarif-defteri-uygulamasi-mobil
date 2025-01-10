import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_update_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  RecipeDetailScreen({required this.recipeId});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isFavorite = false;
  String userName = '';
  String userId = '';
  String recipeAddedBy = '';
  bool canEdit = false;

  @override
  // sayfa başladığında favori takibi yapıyoruz - icon için
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.recipeId) // tarifin id sine göre alıyoruz.
          .get();

      setState(() {
        isFavorite = favSnapshot.exists; // tarif favorilerdeyse true
      });
    }
  }

  // parametre olarak recipeAddedBy geliyor. tarifin addedby kontrolüne göre geliyor
  Future<void> _getUserInfo(String userId) async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['displayName'] ?? 'Bilinmeyen Kullanıcı';
        this.userId = userId;
      });
    }
  }
// butona tıklanma durumundaki fonnksiyon 
  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.recipeId);

      if (isFavorite) {
        await favRef.delete(); // tarif favorilerdeyse silinir
      } else {
        await favRef.set({
          'recipeId': widget.recipeId
        }); // favorilerde değilse favorilere eklenir
      }

      setState(() {
        isFavorite = !isFavorite; // icon için
      });
    }
  }

  // Tarifi ekleyen kullanıcının ID'sini al- güncelle butonu için
  Future<void> _checkIfCanEdit(String recipeAddedBy) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && recipeAddedBy == user.uid) {
      setState(() {
        canEdit = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tarif Detayı')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.recipeId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // tarif verisini alıyoruz
          final recipeData = snapshot.data!.data() as Map<String, dynamic>?;

          // Eğer tarifin ekleyen kullanıcı added by ı varsa, kullanıcı bilgilerini al
          if (recipeData != null && recipeData.containsKey('addedBy')) {
            // recipeAddedBy burda
            recipeAddedBy = recipeData['addedBy'];
            _getUserInfo(recipeAddedBy);
            _checkIfCanEdit(recipeAddedBy);
          }

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // recipeData dan bilgileri çektiğim yer 
                recipeData != null && recipeData.containsKey('imageUrl')
                    ? Image.network(recipeData['imageUrl'],
                        width: 200, height: 200, fit: BoxFit.cover)
                    : SizedBox.shrink(), // görsel yoksa boş alan
                SizedBox(height: 10),
                Text(
                  recipeData != null && recipeData.containsKey('name')
                      ? recipeData['name']
                      : 'Tarif Adı Yok',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "Kategori: ${recipeData != null && recipeData.containsKey('category') ? recipeData['category'] : 'Kategori Yok'}",
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 10),
                Text(
                  "Malzemeler:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                recipeData != null && recipeData.containsKey('ingredients')
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          (recipeData['ingredients'] as List).length,
                          (index) =>
                              Text("- ${recipeData['ingredients'][index]}"),
                        ),
                      )
                    : Text("Malzeme bilgisi yok"),
                SizedBox(height: 10),
                Text(
                  "Hazırlık Adımları:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                recipeData != null && recipeData.containsKey('steps')
                    ? Text(recipeData['steps'])
                    : Text("Hazırlık adımları bilgisi yok"),
                Spacer(), // boşluk bırakma ağaşıya doğru
                Text(
                      "Tarifi Ekleyen: $userName",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,// toggleFavorites fonksiyonunda 
                        color: isFavorite ? Colors.red : null,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                   
                    
                    // Güncelleme butonu, yalnızca tarifi ekleyen kullanıcı için aktif olacak
                    if (canEdit)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecipeUpdateScreen(recipeId: widget.recipeId),
                            ),
                          );
                        },
                        child: Text('Tarifi Güncelle'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
