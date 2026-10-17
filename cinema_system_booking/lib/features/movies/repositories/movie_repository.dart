import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie.dart';

class MovieRepository {
  MovieRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  Future<List<Movie>> getMovies() async {
    try {
      final snapshot = await _db
          .collection('movies')
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();
      }
    } catch (_) {
      // In case Firestore is not yet configured or offline, fallback to built-in curated sample movies
    }
    return _sampleMovies;
  }

  Future<Movie?> getMovieById(String id) async {
    try {
      final doc = await _db.collection('movies').doc(id).get();
      if (doc.exists) {
        return Movie.fromFirestore(doc);
      }
    } catch (_) {}

    return _sampleMovies.where((m) => m.id == id).firstOrNull;
  }

  static final List<Movie> _sampleMovies = [
    Movie(
      id: 'mov_dune2',
      title: 'Dune: Part Two',
      genres: ['Khoa học viễn tưởng', 'Hành động'],
      durationMin: 166,
      ageRating: 'T16',
      releaseDate: DateTime.now().subtract(const Duration(days: 3)),
      description:
          'Paul Atreides hợp lực cùng Chani và tộc Fremen trên hành trình báo thù những kẻ đã hủy diệt gia tộc mình. Đứng trước sự lựa chọn giữa tình yêu của đời mình và số phận của vũ trụ, anh phải ngăn chặn một tương lai đen tối mà chỉ anh mới có thể nhìn thấy.',
      director: 'Denis Villeneuve',
      cast: [
        'Timothée Chalamet',
        'Zendaya',
        'Rebecca Ferguson',
        'Javier Bardem'
      ],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/xOMo8BRK7PfcJv9JCnx7s520042.jpg',
      trailerUrl: 'https://www.youtube.com/watch?v=Way9Dexny3w',
      isActive: true,
    ),
    Movie(
      id: 'mov_oppenheimer',
      title: 'Oppenheimer',
      genres: ['Lịch sử', 'Chính kịch'],
      durationMin: 180,
      ageRating: 'T18',
      releaseDate: DateTime.now().subtract(const Duration(days: 7)),
      description:
          'Bi kịch về nhà vật lý lý thuyết J. Robert Oppenheimer, người chỉ huy Dự án Manhattan chế tạo quả bom nguyên tử đầu tiên trong Thế chiến thứ hai, thay đổi toàn bộ vận mệnh nhân loại.',
      director: 'Christopher Nolan',
      cast: [
        'Cillian Murphy',
        'Emily Blunt',
        'Matt Damon',
        'Robert Downey Jr.'
      ],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/ptpr0kGAckfQkJeJIt8st5dglvd.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg',
      trailerUrl: 'https://www.youtube.com/watch?v=uYPbbksJxIg',
      isActive: true,
    ),
    Movie(
      id: 'mov_godzilla_kong',
      title: 'Godzilla x Kong: The New Empire',
      genres: ['Hành động', 'Khoa học viễn tưởng'],
      durationMin: 115,
      ageRating: 'T13',
      releaseDate: DateTime.now().subtract(const Duration(days: 4)),
      description:
          'Hai quái thú huyền thoại Godzilla và Kong buộc phải liên minh trước một mối đe dọa khổng lồ chưa từng thấy ẩn sâu trong Trái Đất Rỗng, thách thức sự tồn vong của nhân loại.',
      director: 'Adam Wingard',
      cast: ['Rebecca Hall', 'Brian Tyree Henry', 'Dan Stevens'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/bQ2ywkchIiaKLSEaMrcT6e29f91.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/qrGtVF3YZvJc1zfvP6v4yCfa2k7.jpg',
      trailerUrl: 'https://www.youtube.com/watch?v=lV1OOlGwExg',
      isActive: true,
    ),
    Movie(
      id: 'mov_kungfu_panda4',
      title: 'Kung Fu Panda 4',
      genres: ['Hoạt hình', 'Hài hước', 'Gia đình'],
      durationMin: 94,
      ageRating: 'P',
      releaseDate: DateTime.now().subtract(const Duration(days: 6)),
      description:
          'Gấu Po phải tìm kiếm và huấn luyện Thần Long Đại Hiệp mới trước khi chính thức tiếp quản vai trò Lãnh đạo tinh thần của Thung lũng Bình Yên, đồng thời đối đầu với mụ Tắc Kè Bông biến hình quỷ quyệt.',
      director: 'Mike Mitchell',
      cast: ['Jack Black', 'Awkwafina', 'Viola Davis', 'Dustin Hoffman'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/1XDDXPXGiI8id7MrUxK2Xq17O9W.jpg',
      trailerUrl: 'https://www.youtube.com/watch?v=_inKs4eeHiI',
      isActive: true,
    ),
    Movie(
      id: 'mov_exhuma',
      title: 'Exhuma: Quật Mộ Trùng Ma',
      genres: ['Kinh dị', 'Bí ẩn'],
      durationMin: 134,
      ageRating: 'T16',
      releaseDate: DateTime.now().subtract(const Duration(days: 2)),
      description:
          'Hai pháp sư trẻ tuổi, một thầy phong thủy hàng đầu và một nhân viên tang lễ bị cuốn vào chuỗi sự kiện kinh hoàng không thể lường trước sau khi nhận lời khai quật một ngôi mộ bí ẩn của gia tộc giàu có.',
      director: 'Jang Jae-hyun',
      cast: ['Choi Min-sik', 'Kim Go-eun', 'Yoo Hae-jin', 'Lee Do-hyun'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/pfcwVlq8JzW94F1cQ7dZgO6Y2n1.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/6aoyN6Zl1P8lP2oUqDk8dE0E8yO.jpg',
      trailerUrl: 'https://www.youtube.com/watch?v=F3q2z7xN8rI',
      isActive: true,
    ),
    Movie(
      id: 'mov_furiosa',
      title: 'Furiosa: A Mad Max Saga',
      genres: ['Hành động', 'Phiêu lưu'],
      durationMin: 148,
      ageRating: 'T18',
      releaseDate: DateTime.now().add(const Duration(days: 5)),
      description:
          'Hành trình nguồn gốc đầy máu và cát của chiến binh huyền thoại Furiosa trước khi cô gặp Mad Max tại vùng đất chết Wasteland khô cằn.',
      director: 'George Miller',
      cast: ['Anya Taylor-Joy', 'Chris Hemsworth', 'Tom Burke'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/iADOJ8Zymht2JPMoy3R7xUMZ51f.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/wNAhuOZ3Zf84jCI7Te2A74P1h4K.jpg',
      trailerUrl: 'https://www.youtube.com/watch?v=XJMuhwVwcaY',
      isActive: true,
    ),
    Movie(
      id: 'mov_deadpool_wolverine',
      title: 'Deadpool & Wolverine',
      genres: ['Hành động', 'Hài hước'],
      durationMin: 127,
      ageRating: 'T18',
      releaseDate: DateTime.now().add(const Duration(days: 10)),
      description:
          'Deadpool bất đắc dĩ phải lôi kéo Wolverine đang chìm trong u uất vào một phi vụ điên rồ nhằm cứu lấy vũ trụ và dòng thời gian của chính mình.',
      director: 'Shawn Levy',
      cast: ['Ryan Reynolds', 'Hugh Jackman', 'Emma Corrin'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/yDHYTfA3R0jFYba16jBB1jv8vEU.jpg',
      trailerUrl: 'https://www.youtube.com/watch?v=73_1biulkYk',
      isActive: true,
    ),
    Movie(
      id: 'mov_inside_out_2',
      title: 'Inside Out 2: Những Mảnh Ghép Cảm Xúc',
      genres: ['Hoạt hình', 'Gia đình', 'Hài hước'],
      durationMin: 96,
      ageRating: 'P',
      releaseDate: DateTime.now().add(const Duration(days: 14)),
      description:
          'Riley bước sang tuổi dậy thì, và đại bản doanh cảm xúc bất ngờ đón nhận những thành viên mới đầy rắc rối: Lo Âu, Ganh Tị, Xấu Hổ và Chán Nản.',
      director: 'Kelsey Mann',
      cast: ['Amy Poehler', 'Maya Hawke', 'Kensington Tallman'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/stKGOm8zToLPP9JwEjum26OiMi0.jpg',
      trailerUrl: 'https://www.youtube.com/watch?v=LEjhY15eCx0',
      isActive: true,
    ),
  ];
}
