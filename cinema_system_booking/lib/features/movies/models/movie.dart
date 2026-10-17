import 'package:cloud_firestore/cloud_firestore.dart';

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.durationMin,
    required this.ageRating,
    required this.releaseDate,
    required this.description,
    required this.director,
    required this.cast,
    required this.posterUrl,
    required this.backdropUrl,
    required this.trailerUrl,
    required this.isActive,
  });

  final String id;
  final String title;
  final List<String> genres;
  final int durationMin;
  final String ageRating;
  final DateTime releaseDate;
  final String description;
  final String director;
  final List<String> cast;
  final String posterUrl;
  final String backdropUrl;
  final String trailerUrl;
  final bool isActive;

  bool get isNowShowing {
    if (!isActive) return false;
    return releaseDate.isBefore(DateTime.now()) ||
        DateUtils.isSameDay(releaseDate, DateTime.now());
  }

  bool get isComingSoon {
    if (!isActive) return false;
    return releaseDate.isAfter(DateTime.now()) &&
        !DateUtils.isSameDay(releaseDate, DateTime.now());
  }

  String get genresText => genres.join(' · ');

  String get castText => cast.join(', ');

  factory Movie.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Movie.fromMap(doc.id, data);
  }

  factory Movie.fromMap(String id, Map<String, dynamic> data) {
    DateTime parsedReleaseDate;
    final rawDate = data['releaseDate'];
    if (rawDate is Timestamp) {
      parsedReleaseDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedReleaseDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedReleaseDate = DateTime.now();
    }

    return Movie(
      id: id,
      title: data['title'] as String? ?? 'Chưa có tiêu đề',
      genres: List<String>.from(data['genres'] ?? []),
      durationMin: (data['durationMin'] as num?)?.toInt() ?? 0,
      ageRating: data['ageRating'] as String? ?? 'P',
      releaseDate: parsedReleaseDate,
      description: data['description'] as String? ?? '',
      director: data['director'] as String? ?? '',
      cast: List<String>.from(data['cast'] ?? []),
      posterUrl: data['posterUrl'] as String? ?? '',
      backdropUrl: data['backdropUrl'] as String? ?? '',
      trailerUrl: data['trailerUrl'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'genres': genres,
      'durationMin': durationMin,
      'ageRating': ageRating,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'description': description,
      'director': director,
      'cast': cast,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'trailerUrl': trailerUrl,
      'isActive': isActive,
    };
  }
}

abstract final class DateUtils {
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
