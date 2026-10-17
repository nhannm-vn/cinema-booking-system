import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../repositories/movie_repository.dart';

class MovieProvider extends ChangeNotifier {
  MovieProvider({required MovieRepository repo}) : _repo = repo {
    loadMovies();
  }

  final MovieRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;
  List<Movie> _movies = [];
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Movie> get movies => _movies;
  String get searchQuery => _searchQuery;

  List<Movie> get nowShowingMovies =>
      _movies.where((m) => m.isNowShowing).toList();

  List<Movie> get comingSoonMovies =>
      _movies.where((m) => m.isComingSoon).toList();

  List<Movie> get filteredMovies {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _movies;

    return _movies.where((m) {
      final titleMatch = m.title.toLowerCase().contains(query);
      final genreMatch =
          m.genres.any((g) => g.toLowerCase().contains(query));
      final directorMatch = m.director.toLowerCase().contains(query);
      final castMatch = m.cast.any((c) => c.toLowerCase().contains(query));
      return titleMatch || genreMatch || directorMatch || castMatch;
    }).toList();
  }

  Future<void> loadMovies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _movies = await _repo.getMovies();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách phim: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
}
