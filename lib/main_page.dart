import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'add_recipe_screen.dart';
import 'recipe_detail_screen.dart';
import 'favorites_screen.dart';
import 'register_page.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<String> categories = [
    "Tatlı",
    "Ana Yemek",
    "Aperatif",
    "Çorba",
    "Diyet"
  ];
  final TextEditingController searchController = TextEditingController();
  String selectedCategory = ""; // Seçilen kategori
  String searchQuery = ""; // Arama sorgusu

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("TARİF DEFTERİ"),
        actions: [
          if (user == null) ...[
            // Giriş yapmamış kullanıcılar için butonlar
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(onLoginSuccess: () {
                      setState(() {}); // Giriş sonrası sayfa yenileme
                    }),
                  ),
                );
              },
              child: Text("Giriş Yap",
                  style: TextStyle(
                      color: const Color.fromARGB(255, 117, 57, 107))),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text("Kayıt Ol",
                  style: TextStyle(
                      color: const Color.fromARGB(255, 117, 57, 107))),
            ),
          ],
          if (user != null) ...[
            // Giriş yapmış kullanıcılar için butonlar
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut(); // Çıkış yap
                setState(() {}); // Sayfa yenileme
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Çıkış yapıldı!")),
                );
              },
              child: Text("Çıkış Yap",
                  style: TextStyle(
                      color: const Color.fromARGB(255, 117, 57, 107))),
            ),
            IconButton(
              icon: Icon(Icons.favorite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FavoritesScreen()),
                );
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (user != null) ...[
            // Giriş yapan kullanıcıya hoş geldin mesajı
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Tarif Defterine Hoşgeldiniz..',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          // Kategori Seçim Butonları
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                //Her eleman için bir ElevatedButton (buton) oluşturulur.
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory == category
                          ? const Color.fromARGB(255, 162, 95, 154)
                          : const Color.fromARGB(255, 216, 158, 212),
                    ),
                    onPressed: () {
                      //Kullanıcı butona tıkladığında setState çağrılır ve selectedCategory güncellenir
                      setState(() {
                        selectedCategory = selectedCategory == category
                            ? "" //kategori zaten seçilmişse, seçim kaldırılır
                            : category; // başka bir kategori seçilmişse, o kategori atanır.
                      });
                    },
                    child: Text(category),
                  ),
                );
              }).toList(),
            ),
          ),
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Tarif ara...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), //çerçeve border
                ),
              ),
              onChanged: (query) { //her tuşa basıldığında
                setState(() {
                  searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
          // Tarif Kartları
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              //streambuilder anlık yenilemek için
              stream:
                  // recipes taki verileri izler.
                  FirebaseFirestore.instance.collection('recipes').snapshots(),
              builder: (context, snapshot) {
                // Hata durumunu kontrol et
                if (snapshot.hasError) {
                  return Center(
                    child:
                        Text("Tarifleri görüntüleyebilmek için giriş yapınız."),
                  );
                }

                // Bağlantı durumunu kontrol et
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Veriler boşsa
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Henüz tarif eklenmemiş."));
                }

                // Tarif verilerini filtrele ve listele
                final recipes = snapshot.data!.docs.where((doc) {
                  // doc=tarif
                  final data = doc.data() as Map<String,
                      dynamic>; //tarifteki veriyi al map olarak işle.
                  final name = data['name']?.toString().toLowerCase() ?? "";
                  final category = data['category']?.toString().toLowerCase() ?? "";

                  // Arama ve kategori filtresi
                  // Eğer arama sorgusu boşsa tüm tarifler geçerli. doluysa kategoriyle eşleşiyor mu
                  final matchesCategory = selectedCategory.isEmpty ||//Eğer selectedCategory boşsa , kategori filtreleme yapılmaz, yani tüm tarifler gösterilir.
                      category == selectedCategory.toLowerCase();
                  final matchesSearch = searchQuery.isEmpty 
                  || name.contains(searchQuery); 

                  return matchesCategory && matchesSearch; // recipes a eklendiği kısım 
                }).toList();

                if (recipes.isEmpty) {
                  return Center(child: Text("Eşleşen tarif bulunamadı."));
                }

                return ListView.builder(
                  //scrollDirection:,
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    // her öge için oluşturulacak widget**
                    final doc = recipes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    // tarif bilgilerini saklamak için bir map
                    final recipe = {
                      "id": doc.id,
                      "name": data['name'] ?? 'Tarif Adı Yok',
                      "category": data['category'] ?? 'Kategori Yok',
                      "imageUrl": data['imageUrl'] ?? '', // Görsel URL'si
                    };
                    // her tarife card widget ı
                    return Card(
                      margin: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 16.0), // kartın etrafındaki boşluk
                      child: ListTile(
                        leading: recipe["imageUrl"] !=
                                '' //boş değilse görseli göster--- başında leading
                            ? Image.network(recipe["imageUrl"],
                                width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.image, size: 50), // boşsa icon göster
                        title: Text(recipe["name"]),
                        subtitle: Text("Kategori: ${recipe["category"]}"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecipeDetailScreen(recipeId: recipe['id']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (user == null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(
                  onLoginSuccess: () {
                    setState(() {});
                  },
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecipeAddScreen()),
            );
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
