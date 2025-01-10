
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Favoriler")),
      body: user == null
          ? Center(child: Text("Favorilerinizi görmek için giriş yapmalısınız."))
          : 
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final favoriteRecipes = snapshot.data!.docs; 
                if (favoriteRecipes.isEmpty) {
                  return Center(child: Text("Henüz favorilere eklenen tarif yok."));
                }

                return ListView.builder(
                  itemCount: favoriteRecipes.length,
                  itemBuilder: (context, index) {
                    // her favori tarif için recipe idleri alıyoruz.
                    final recipeId = favoriteRecipes[index]['recipeId'];

                    // recipe id ye göre tarif verilerini alacağız. 
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('recipes').doc(recipeId).get(),
                      builder: (context, recipeSnapshot) {
                        //tairf verileri gelmediyse boş container döndür
                        if (!recipeSnapshot.hasData) return Container();

                        // tairf verilerinin alındığı yer
                        final recipeData = recipeSnapshot.data!;
                        // tairf kartlarını oluştuğu yer
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: ListTile(
                            title: Text(recipeData['name']),
                            subtitle: Text("Kategori: ${recipeData['category']}"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailScreen(recipeId: recipeId),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
