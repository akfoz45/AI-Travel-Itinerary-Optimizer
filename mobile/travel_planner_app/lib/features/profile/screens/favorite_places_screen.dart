import 'package:flutter/material.dart';

class FavoritePlacesScreen extends StatelessWidget {
  const FavoritePlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Şimdilik tasarım amaçlı örnek veriler (Mock Data)
    // İleride bu verileri backend'den çekeceğiz
    final List<Map<String, dynamic>> favoritePlaces = [
      {
        'name': 'Eiffel Tower',
        'category': 'History',
        'rating': 4.8,
        'image': 'https://picsum.photos/seed/eiffel/400/300',
      },
      {
        'name': 'Louvre Museum',
        'category': 'Museum',
        'rating': 4.9,
        'image': 'https://picsum.photos/seed/louvre/400/300',
      },
      {
        'name': 'Central Park',
        'category': 'Nature',
        'rating': 4.7,
        'image': 'https://picsum.photos/seed/park/400/300',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Places'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: favoritePlaces.isEmpty
          ? const Center(child: Text('No favorite places yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favoritePlaces.length,
              itemBuilder: (context, index) {
                final place = favoritePlaces[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withValues(alpha: 0.2) 
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        child: Image.network(
                          place['image'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    place['category'],
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    place['rating'].toString(),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Favorilerden çıkarma işlemi
                        },
                        icon: const Icon(Icons.favorite, color: Colors.red),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                );
              },
            ),
    );
  }
}