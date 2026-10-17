import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SeedService {
  static Future<void> runSeed() async {
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    debugPrint('>>> BẮT ĐẦU SEED DỮ LIỆU CINEMA BOOKING APP <<<');

    // 1. Cấu hình bảng giá chuẩn (settings/pricing)
    await db.collection('settings').doc('pricing').set({
      'baseByFormat': {
        '2D': 80000,
        '3D': 100000,
        'IMAX': 120000,
      },
      'vipSurcharge': 20000,
      'coupleSurcharge': 20000,
      'weekendSurcharge': 10000,
      'primeTimeSurcharge': 10000,
      'primeStartHour': 18,
      'primeEndHour': 22,
      'weekendWeekdays': [5, 6, 7],
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': 'system_seed',
    });
    debugPrint('-> [1/6] Đã tạo bảng giá');

    // 2. Rạp & Phòng chiếu (2 rạp x 2 phòng)
    const standardLayout = [
      'NNNNNNNNNN',
      'NNNNNNNNNN',
      'NNVVVVVVNN',
      'NNVVVVVVNN',
      'NNVVVVVVNN',
      'NNVVVVVVNN',
      'NNNNNNNNNN',
      'DDDDDDDDDD',
    ];

    final cinemas = [
      {
        'id': 'cn_q1',
        'name': 'Cinema Quận 1 Flagship',
        'address': 'Số 1 Hai Bà Trưng, Bến Nghé, Quận 1, TP.HCM',
        'phone': '19001001',
        'openingHours': '08:00–23:30',
        'location': const GeoPoint(10.776889, 106.700806),
        'imageUrl':
            'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
        'isActive': true,
      },
      {
        'id': 'cn_tb',
        'name': 'Cinema Tân Bình Hub',
        'address': 'Số 20 Cộng Hòa, Phường 4, Tân Bình, TP.HCM',
        'phone': '19001002',
        'openingHours': '08:30–23:00',
        'location': const GeoPoint(10.801556, 106.655861),
        'imageUrl':
            'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c',
        'isActive': true,
      },
    ];

    for (final c in cinemas) {
      final cid = c['id'] as String;
      await db.collection('cinemas').doc(cid).set(c);

      await db
          .collection('cinemas')
          .doc(cid)
          .collection('rooms')
          .doc('room_01')
          .set({
        'name': 'Phòng 01 - Standard Prime',
        'formats': ['2D', '3D'],
        'rows': 8,
        'cols': 10,
        'seatLayout': standardLayout,
        'seatCount': 75,
      });

      await db
          .collection('cinemas')
          .doc(cid)
          .collection('rooms')
          .doc('room_02')
          .set({
        'name': 'Phòng 02 - IMAX Laser',
        'formats': ['IMAX'],
        'rows': 8,
        'cols': 10,
        'seatLayout': standardLayout,
        'seatCount': 75,
      });
    }
    debugPrint('-> [2/6] Đã tạo rạp và phòng chiếu');

    // 3. Menu đồ ăn (10 món / rạp)
    final foodMenu = [
      {
        'name': 'Combo Bắp Nước Solo',
        'category': 'combo',
        'price': 79000,
        'desc': '1 bắp ngọt 60oz + 1 nước ngọt 32oz',
        'img':
            'https://images.unsplash.com/photo-1585647347384-2593bc35786b?w=400&auto=format&fit=crop&q=80',
        'avail': true
      },
      {
        'name': 'Combo Couple Thân Mật',
        'category': 'combo',
        'price': 119000,
        'desc': '1 bắp lớn + 2 nước ngọt 32oz',
        'img':
            'https://images.unsplash.com/photo-1505686994434-e3cc5abf1330?w=400&auto=format&fit=crop&q=80',
        'avail': true
      },
      {
        'name': 'Combo Party Gia Đình',
        'category': 'combo',
        'price': 169000,
        'desc': '2 bắp ngọt + 4 nước ngọt + 1 snack khoai tây',
        'img':
            'https://images.unsplash.com/photo-1572177812156-58036aae439c?w=400&auto=format&fit=crop&q=80',
        'avail': true
      },
      {
        'name': 'Bắp Rang Phô Mai',
        'category': 'popcorn',
        'price': 49000,
        'desc': 'Bắp rang bơ lắc bột phô mai béo ngậy',
        'img':
            'https://images.unsplash.com/photo-1578849278619-e73505e9610f?w=400&auto=format&fit=crop&q=80',
        'avail': true
      },
      {
        'name': 'Bắp Rang Caramel',
        'category': 'popcorn',
        'price': 49000,
        'desc': 'Bắp thơm giòn phủ sốt caramel đậm vị',
        'img':
            'https://images.unsplash.com/photo-1512149177596-f817c7ef5d4c?w=400&auto=format&fit=crop&q=80',
        'avail': true
      },
      {
        'name': 'Coca-Cola Zero 32oz',
        'category': 'drink',
        'price': 32000,
        'desc': 'Nước ngọt có gas không calo mát lạnh',
        'img':
            'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80',
        'avail': true
      },
      {
        'name': 'Trà Đào Cam Sả',
        'category': 'drink',
        'price': 39000,
        'desc': 'Trà trái cây tươi thanh mát giải nhiệt',
        'img':
            'https://images.unsplash.com/photo-1556881286-fc6915169721?w=400&auto=format&fit=crop&q=80',
        'avail': true
      },
      {
        'name': 'Nước Khoáng Dasani 500ml',
        'category': 'drink',
        'price': 20000,
        'desc': 'Nước khoáng tinh khiết đóng chai',
        'img':
            'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400&auto=format&fit=crop&q=80',
        'avail': true
      },
      {
        'name': 'Snack Khoai Tây Lay\'s Vị Tảo',
        'category': 'snack',
        'price': 25000,
        'desc': 'Khoai tây sấy giòn tan vị tảo biển',
        'img':
            'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&auto=format&fit=crop&q=80',
        'avail': true
      },
      {
        'name': 'Xúc Xích Nướng Phô Mai',
        'category': 'snack',
        'price': 35000,
        'desc': 'Xúc xích Đức nướng nóng giòn kẹp phô mai',
        'img':
            'https://images.unsplash.com/photo-1627054234584-386b03943343?w=400&auto=format&fit=crop&q=80',
        'avail': false
      },
    ];

    for (final c in cinemas) {
      final cid = c['id'] as String;
      for (int i = 0; i < foodMenu.length; i++) {
        final f = foodMenu[i];
        final fid = 'food_${cid}_0${i + 1}';
        await db
            .collection('cinemas')
            .doc(cid)
            .collection('foods')
            .doc(fid)
            .set({
          'name': f['name'],
          'category': f['category'],
          'price': f['price'],
          'description': f['desc'],
          'imageUrl': f['img'],
          'isAvailable': f['avail'],
        });
      }
    }
    debugPrint('-> [3/6] Đã tạo menu đồ ăn');

    // 4. Danh mục 8 phim
    final now = DateTime.now();
    final movies = [
      {
        'id': 'mov_dune2',
        'title': 'Dune: Part Two',
        'genres': ['Khoa học viễn tưởng', 'Hành động'],
        'durationMin': 166,
        'ageRating': 'T16',
        'releaseDate':
            Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'description':
            'Paul Atreides hợp lực cùng Chani và tộc Fremen trên hành trình báo thù những kẻ đã hủy diệt gia tộc.',
        'director': 'Denis Villeneuve',
        'cast': [
          'Timothée Chalamet',
          'Zendaya',
          'Rebecca Ferguson',
          'Javier Bardem'
        ],
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
        'backdropUrl':
            'https://image.tmdb.org/t/p/original/xOMo8BRK7PfcJv9JCnx7s520042.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=Way9Dexny3w',
        'isActive': true,
      },
      {
        'id': 'mov_oppenheimer',
        'title': 'Oppenheimer',
        'genres': ['Lịch sử', 'Chính kịch'],
        'durationMin': 180,
        'ageRating': 'T18',
        'releaseDate':
            Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'description':
            'Bi kịch về nhà vật lý lý thuyết J. Robert Oppenheimer, người chỉ huy Dự án Manhattan chế tạo bom nguyên tử.',
        'director': 'Christopher Nolan',
        'cast': [
          'Cillian Murphy',
          'Emily Blunt',
          'Matt Damon',
          'Robert Downey Jr.'
        ],
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/ptpr0kGAckfQkJeJIt8st5dglvd.jpg',
        'backdropUrl':
            'https://image.tmdb.org/t/p/original/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=uYPbbksJxIg',
        'isActive': true,
      },
      {
        'id': 'mov_godzilla_kong',
        'title': 'Godzilla x Kong: The New Empire',
        'genres': ['Hành động', 'Khoa học viễn tưởng'],
        'durationMin': 115,
        'ageRating': 'T13',
        'releaseDate':
            Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'description':
            'Hai quái thú huyền thoại Godzilla và Kong buộc phải liên minh trước một mối đe dọa khổng lồ chưa từng thấy.',
        'director': 'Adam Wingard',
        'cast': ['Rebecca Hall', 'Brian Tyree Henry', 'Dan Stevens'],
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/bQ2ywkchIiaKLSEaMrcT6e29f91.jpg',
        'backdropUrl':
            'https://image.tmdb.org/t/p/original/qrGtVF3YZvJc1zfvP6v4yCfa2k7.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=lV1OOlGwExg',
        'isActive': true,
      },
      {
        'id': 'mov_kungfu_panda4',
        'title': 'Kung Fu Panda 4',
        'genres': ['Hoạt hình', 'Hài hước', 'Gia đình'],
        'durationMin': 94,
        'ageRating': 'P',
        'releaseDate':
            Timestamp.fromDate(now.subtract(const Duration(days: 6))),
        'description':
            'Po phải tìm kiếm và huấn luyện Thần Long Đại Hiệp mới trước khi nhận vai trò Lãnh đạo tinh thần của Thung lũng.',
        'director': 'Mike Mitchell',
        'cast': ['Jack Black', 'Awkwafina', 'Viola Davis', 'Dustin Hoffman'],
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg',
        'backdropUrl':
            'https://image.tmdb.org/t/p/original/1XDDXPXGiI8id7MrUxK2Xq17O9W.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=_inKs4eeHiI',
        'isActive': true,
      },
      {
        'id': 'mov_exhuma',
        'title': 'Exhuma: Quật Mộ Trùng Ma',
        'genres': ['Kinh dị', 'Bí ẩn'],
        'durationMin': 134,
        'ageRating': 'T16',
        'releaseDate':
            Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'description':
            'Hai pháp sư, một thầy phong thủy và một nhân viên tang lễ bị cuốn vào chuỗi sự kiện kinh hoàng sau khi khai quật ngôi mộ cổ.',
        'director': 'Jang Jae-hyun',
        'cast': ['Choi Min-sik', 'Kim Go-eun', 'Yoo Hae-jin', 'Lee Do-hyun'],
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/pfcwVlq8JzW94F1cQ7dZgO6Y2n1.jpg',
        'backdropUrl':
            'https://image.tmdb.org/t/p/original/6aoyN6Zl1P8lP2oUqDk8dE0E8yO.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=F3q2z7xN8rI',
        'isActive': true,
      },
      {
        'id': 'mov_furiosa',
        'title': 'Furiosa: A Mad Max Saga',
        'genres': ['Hành động', 'Phiêu lưu'],
        'durationMin': 148,
        'ageRating': 'T18',
        'releaseDate': Timestamp.fromDate(now.add(const Duration(days: 5))),
        'description':
            'Nguồn gốc của chiến binh Furiosa trước khi cô gặp Mad Max tại Wasteland.',
        'director': 'George Miller',
        'cast': ['Anya Taylor-Joy', 'Chris Hemsworth', 'Tom Burke'],
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/iADOJ8Zymht2JPMoy3R7xUMZ51f.jpg',
        'backdropUrl':
            'https://image.tmdb.org/t/p/original/wNAhuOZ3Zf84jCI7Te2A74P1h4K.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=XJMuhwVwcaY',
        'isActive': true,
      },
      {
        'id': 'mov_deadpool_wolverine',
        'title': 'Deadpool & Wolverine',
        'genres': ['Hành động', 'Hài hước'],
        'durationMin': 127,
        'ageRating': 'T18',
        'releaseDate': Timestamp.fromDate(now.add(const Duration(days: 10))),
        'description':
            'Deadpool phải hợp tác với Wolverine đang chán đời trong một nhiệm vụ bảo vệ dòng thời gian.',
        'director': 'Shawn Levy',
        'cast': ['Ryan Reynolds', 'Hugh Jackman', 'Emma Corrin'],
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
        'backdropUrl':
            'https://image.tmdb.org/t/p/original/yDHYTfA3R0jFYba16jBB1jv8vEU.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=73_1biulkYk',
        'isActive': true,
      },
      {
        'id': 'mov_inside_out_2',
        'title': 'Inside Out 2: Những Mảnh Ghép Cảm Xúc',
        'genres': ['Hoạt hình', 'Gia đình', 'Hài hước'],
        'durationMin': 96,
        'ageRating': 'P',
        'releaseDate': Timestamp.fromDate(now.add(const Duration(days: 14))),
        'description':
            'Riley bước vào tuổi dậy thì với sự xuất hiện bất ngờ của những cảm xúc mới.',
        'director': 'Kelsey Mann',
        'cast': ['Amy Poehler', 'Maya Hawke', 'Kensington Tallman'],
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
        'backdropUrl':
            'https://image.tmdb.org/t/p/original/stKGOm8zToLPP9JwEjum26OiMi0.jpg',
        'trailerUrl': 'https://www.youtube.com/watch?v=LEjhY15eCx0',
        'isActive': true,
      },
    ];

    for (final m in movies) {
      final mid = m['id'] as String;
      await db.collection('movies').doc(mid).set(m);
    }
    debugPrint('-> [4/6] Đã tạo 8 bộ phim');

    // 5. Suất chiếu 7 ngày tới
    final movieIds = [
      'mov_dune2',
      'mov_oppenheimer',
      'mov_godzilla_kong',
      'mov_kungfu_panda4',
      'mov_exhuma'
    ];
    final cinemaIds = ['cn_q1', 'cn_tb'];

    for (int day = 0; day < 7; day++) {
      final targetDate = DateTime(now.year, now.month, now.day + day);

      for (final cid in cinemaIds) {
        final room1Shows = [
          {'hour': 10, 'minute': 0, 'format': '2D', 'mIdx': 3},
          {'hour': 14, 'minute': 30, 'format': '2D', 'mIdx': 2},
          {'hour': 19, 'minute': 0, 'format': '3D', 'mIdx': 4},
        ];

        for (int i = 0; i < room1Shows.length; i++) {
          final s = room1Shows[i];
          final start = DateTime(targetDate.year, targetDate.month,
              targetDate.day, s['hour'] as int, s['minute'] as int);
          final mId = movieIds[s['mIdx'] as int];
          final dur = movies.firstWhere(
              (element) => element['id'] == mId)['durationMin'] as int;
          final end = start.add(Duration(minutes: dur));

          await db
              .collection('showtimes')
              .doc('shw_${cid}_r1_d${day}_s$i')
              .set({
            'movieId': mId,
            'cinemaId': cid,
            'roomId': 'room_01',
            'format': s['format'],
            'startTime': Timestamp.fromDate(start),
            'endTime': Timestamp.fromDate(end),
            'status': 'scheduled',
            'totalSeats': 75,
            'soldSeats': 0,
          });
        }

        final room2Shows = [
          {'hour': 13, 'minute': 0, 'format': 'IMAX', 'mIdx': 0},
          {'hour': 18, 'minute': 30, 'format': 'IMAX', 'mIdx': 1},
        ];

        for (int i = 0; i < room2Shows.length; i++) {
          final s = room2Shows[i];
          final start = DateTime(targetDate.year, targetDate.month,
              targetDate.day, s['hour'] as int, s['minute'] as int);
          final mId = movieIds[s['mIdx'] as int];
          final dur = movies.firstWhere(
              (element) => element['id'] == mId)['durationMin'] as int;
          final end = start.add(Duration(minutes: dur));

          await db
              .collection('showtimes')
              .doc('shw_${cid}_r2_d${day}_s$i')
              .set({
            'movieId': mId,
            'cinemaId': cid,
            'roomId': 'room_02',
            'format': s['format'],
            'startTime': Timestamp.fromDate(start),
            'endTime': Timestamp.fromDate(end),
            'status': 'scheduled',
            'totalSeats': 75,
            'soldSeats': 0,
          });
        }
      }
    }
    debugPrint('-> [5/6] Đã tạo suất chiếu');

    // 6. Tài khoản mẫu
    final sampleAccounts = [
      {
        'email': 'admin@cinema.vn',
        'pass': '123456',
        'role': 'admin',
        'name': 'Quản Trị Viên',
        'cinemaId': null
      },
      {
        'email': 'manager1@cinema.vn',
        'pass': '123456',
        'role': 'manager',
        'name': 'Trần Quản Lý (Q1)',
        'cinemaId': 'cn_q1'
      },
      {
        'email': 'manager2@cinema.vn',
        'pass': '123456',
        'role': 'manager',
        'name': 'Lê Quản Lý (TB)',
        'cinemaId': 'cn_tb'
      },
      {
        'email': 'staff1@cinema.vn',
        'pass': '123456',
        'role': 'staff',
        'name': 'Nguyễn Nhân Viên (Q1)',
        'cinemaId': 'cn_q1'
      },
      {
        'email': 'staff2@cinema.vn',
        'pass': '123456',
        'role': 'staff',
        'name': 'Phạm Nhân Viên (TB)',
        'cinemaId': 'cn_tb'
      },
      {
        'email': 'khach1@cinema.vn',
        'pass': '123456',
        'role': 'customer',
        'name': 'Võ Khách Hàng',
        'cinemaId': null
      },
    ];

    for (final acc in sampleAccounts) {
      final email = acc['email'] as String;
      final pass = acc['pass'] as String;
      try {
        UserCredential cred;
        try {
          cred = await auth.createUserWithEmailAndPassword(
              email: email, password: pass);
        } catch (_) {
          cred = await auth.signInWithEmailAndPassword(
              email: email, password: pass);
        }

        await db.collection('users').doc(cred.user!.uid).set({
          'fullName': acc['name'],
          'email': email,
          'phone': '0908123456',
          'role': acc['role'],
          'cinemaId': acc['cinemaId'],
          'isLocked': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('   + Đã tạo/đồng bộ: $email [${acc['role']}]');
      } catch (e) {
        debugPrint('   x Lỗi tài khoản $email: $e');
      }
    }
    debugPrint('-> [6/6] Hoàn tất 6 tài khoản mẫu');
    debugPrint('>>> SEED DỮ LIỆU THÀNH CÔNG 100% <<<');
  }
}
