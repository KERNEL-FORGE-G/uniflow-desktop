import 'dart:convert';
import 'package:http/http.dart' as http;

/// Modèle d'un livre Z-Library
class ZBook {
  final String id;
  final String title;
  final String author;
  final String year;
  final String publisher;
  final String extension;
  final String filesize;
  final String coverUrl;
  final String downloadUrl;

  ZBook({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    required this.publisher,
    required this.extension,
    required this.filesize,
    required this.coverUrl,
    required this.downloadUrl,
  });
}

/// Service de Bibliothèque Numérique Universitaire propulsé EXCLUSIVEMENT par Z-Library
class ZLibraryService {
  static const String _zlibBaseUrl = 'https://z-library.sk/api';

  /// Recherche exclusive dans le catalogue Z-Library
  static Future<List<ZBook>> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      return _getPopularAcademicBooks();
    }

    try {
      final uri = Uri.parse('$_zlibBaseUrl/search').replace(queryParameters: {
        'query': query,
        'limit': '20',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['books'] is List) {
          return (data['books'] as List).map((b) => ZBook(
            id: b['id']?.toString() ?? '',
            title: b['title']?.toString() ?? 'Titre inconnu',
            author: b['author']?.toString() ?? 'Auteur inconnu',
            year: b['year']?.toString() ?? '2025',
            publisher: b['publisher']?.toString() ?? 'Éditeur Universitaire',
            extension: b['extension']?.toString() ?? 'PDF',
            filesize: b['filesizeString']?.toString() ?? '4.2 MB',
            coverUrl: b['cover']?.toString() ?? '',
            downloadUrl: b['downloadUrl']?.toString() ?? '',
          )).toList();
        }
      }
    } catch (_) {}

    // Repli de sécurité avec les ouvrages de référence UY1
    return _getPopularAcademicBooks().where((b) {
      final q = query.toLowerCase();
      return b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q);
    }).toList();
  }

  /// Ouvrages académiques de référence Z-Library pour la Faculté des Sciences
  static List<ZBook> _getPopularAcademicBooks() {
    return [
      ZBook(
        id: 'zlib-101',
        title: 'Introduction to Algorithms (CLRS) - 4th Edition',
        author: 'Thomas H. Cormen, Charles E. Leiserson, Ronald L. Rivest',
        year: '2022',
        publisher: 'MIT Press',
        extension: 'PDF',
        filesize: '14.8 MB',
        coverUrl: 'https://images.unsplash.com/photo-1532012164546-f432f2e3edd4?w=400&q=80',
        downloadUrl: 'https://z-library.sk/book/intro-algorithms-4th',
      ),
      ZBook(
        id: 'zlib-102',
        title: 'Computer Networks: A Systems Approach',
        author: 'Larry L. Peterson, Bruce S. Davie',
        year: '2021',
        publisher: 'Morgan Kaufmann',
        extension: 'PDF',
        filesize: '8.4 MB',
        coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&q=80',
        downloadUrl: 'https://z-library.sk/book/computer-networks',
      ),
      ZBook(
        id: 'zlib-103',
        title: 'Database System Concepts (Silberschatz)',
        author: 'Abraham Silberschatz, Henry F. Korth, S. Sudarshan',
        year: '2020',
        publisher: 'McGraw-Hill Education',
        extension: 'PDF',
        filesize: '12.1 MB',
        coverUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400&q=80',
        downloadUrl: 'https://z-library.sk/book/database-concepts',
      ),
      ZBook(
        id: 'zlib-104',
        title: 'Software Engineering: A Practitioner\'s Approach',
        author: 'Roger S. Pressman, Bruce R. Maxim',
        year: '2020',
        publisher: 'McGraw-Hill',
        extension: 'PDF',
        filesize: '10.5 MB',
        coverUrl: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=400&q=80',
        downloadUrl: 'https://z-library.sk/book/software-eng-pressman',
      ),
      ZBook(
        id: 'zlib-105',
        title: 'Operating System Concepts (Dinosaur Book)',
        author: 'Abraham Silberschatz, Peter B. Galvin, Greg Gagne',
        year: '2021',
        publisher: 'Wiley',
        extension: 'PDF',
        filesize: '11.3 MB',
        coverUrl: 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=400&q=80',
        downloadUrl: 'https://z-library.sk/book/operating-systems-wiley',
      ),
      ZBook(
        id: 'zlib-106',
        title: 'Artificial Intelligence: A Modern Approach (4th Ed)',
        author: 'Stuart Russell, Peter Norvig',
        year: '2021',
        publisher: 'Pearson',
        extension: 'PDF',
        filesize: '18.2 MB',
        coverUrl: 'https://images.unsplash.com/photo-1507842229452-9533c3732c86?w=400&q=80',
        downloadUrl: 'https://z-library.sk/book/ai-modern-approach-norvig',
      ),
    ];
  }
}
