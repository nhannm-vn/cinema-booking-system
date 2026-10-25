/**
 * Script tạo dữ liệu VÉ THẬT 100% vào Google Cloud Firestore
 * Chạy lệnh: node tool/seed_real_bookings.js
 */

const https = require('https');

const PROJECT_ID = 'cinemabookingsystem-fcdb3';

// Giờ chiếu hôm nay
const now = new Date();
const in30Mins = new Date(now.getTime() + 30 * 60 * 1000).toISOString();
const past2Hours = new Date(now.getTime() - 2 * 60 * 60 * 1000).toISOString();
const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString();

const REAL_BOOKINGS = [
  // 1. VÉ HỢP LỆ 100% (Phim Dune 2 - T16 - Suất chiếu còn 30' - Rạp Q1 - Có Combo bắp nước)
  {
    id: 'BK92M7XP',
    data: {
      userId: { stringValue: 'user_cust_1' },
      customerName: { stringValue: 'Hoàng Minh Quân' },
      movieId: { stringValue: 'mov_dune2' },
      movieTitle: { stringValue: 'Dune: Hành Tinh Cát 2' },
      posterUrl: { stringValue: 'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg' },
      ageRating: { stringValue: 'T16' },
      cinemaId: { stringValue: 'cn_q1' },
      cinemaName: { stringValue: 'Cinema Flagship Q1' },
      roomName: { stringValue: 'Phòng 01 - IMAX Laser' },
      format: { stringValue: 'IMAX 2D' },
      showtimeStart: { timestampValue: in30Mins },
      seats: {
        arrayValue: {
          values: [
            { mapValue: { fields: { id: { stringValue: 'D05' }, type: { stringValue: 'vip' } } } },
            { mapValue: { fields: { id: { stringValue: 'D06' }, type: { stringValue: 'vip' } } } }
          ]
        }
      },
      foods: {
        arrayValue: {
          values: [
            {
              mapValue: {
                fields: {
                  name: { stringValue: 'Combo Bắp Nước Solo' },
                  qty: { integerValue: '2' },
                  unitPrice: { integerValue: '79000' }
                }
              }
            }
          ]
        }
      },
      foodStatus: { stringValue: 'pending' },
      foodSummary: { stringValue: '2x Combo Bắp Nước Solo' },
      totalAmount: { integerValue: '398000' },
      status: { stringValue: 'paid' },
      channel: { stringValue: 'online' },
      paymentMethod: { stringValue: 'vnpay' },
      createdAt: { timestampValue: new Date(now.getTime() - 60 * 60 * 1000).toISOString() },
      paidAt: { timestampValue: new Date(now.getTime() - 55 * 60 * 1000).toISOString() }
    }
  },

  // 2. VÉ ĐÃ SỬ DỤNG (Used) - Rạp Q1
  {
    id: 'BK7721AA',
    data: {
      userId: { stringValue: 'user_cust_2' },
      customerName: { stringValue: 'Lê Thảo Vy' },
      movieId: { stringValue: 'mov_exhuma' },
      movieTitle: { stringValue: 'Exhuma: Quật Mộ Trùng Ma' },
      posterUrl: { stringValue: 'https://image.tmdb.org/t/p/w500/muU9LpE1Ym821sL8iZfP9w7Zp7t.jpg' },
      ageRating: { stringValue: 'T18' },
      cinemaId: { stringValue: 'cn_q1' },
      cinemaName: { stringValue: 'Cinema Flagship Q1' },
      roomName: { stringValue: 'Phòng 01 - IMAX Laser' },
      format: { stringValue: '2D' },
      showtimeStart: { timestampValue: in30Mins },
      seats: {
        arrayValue: {
          values: [
            { mapValue: { fields: { id: { stringValue: 'E01' }, type: { stringValue: 'standard' } } } },
            { mapValue: { fields: { id: { stringValue: 'E02' }, type: { stringValue: 'standard' } } } }
          ]
        }
      },
      foods: { arrayValue: { values: [] } },
      foodStatus: { stringValue: 'none' },
      totalAmount: { integerValue: '200000' },
      status: { stringValue: 'used' },
      checkedInAt: { timestampValue: new Date(now.getTime() - 15 * 60 * 1000).toISOString() },
      checkedInBy: { stringValue: 'Nguyễn Nhân Viên (Q1)' },
      channel: { stringValue: 'online' },
      paymentMethod: { stringValue: 'vnpay' },
      createdAt: { timestampValue: new Date(now.getTime() - 120 * 60 * 1000).toISOString() }
    }
  },

  // 3. VÉ THUỘC RẠP KHÁC (Rạp Tân Bình cn_tb)
  {
    id: 'BK333TB',
    data: {
      userId: { stringValue: 'user_cust_3' },
      customerName: { stringValue: 'Nguyễn Văn Nam' },
      movieId: { stringValue: 'mov_godzilla_kong' },
      movieTitle: { stringValue: 'Godzilla x Kong: Đế Chế Mới' },
      posterUrl: { stringValue: 'https://image.tmdb.org/t/p/w500/bQ2ywAsx97yKq4O06OAEZ6e9p0.jpg' },
      ageRating: { stringValue: 'T13' },
      cinemaId: { stringValue: 'cn_tb' },
      cinemaName: { stringValue: 'Cinema Tân Bình Hub' },
      roomName: { stringValue: 'Phòng 01 - Standard' },
      format: { stringValue: '2D' },
      showtimeStart: { timestampValue: in30Mins },
      seats: {
        arrayValue: {
          values: [
            { mapValue: { fields: { id: { stringValue: 'C04' }, type: { stringValue: 'standard' } } } }
          ]
        }
      },
      foods: { arrayValue: { values: [] } },
      foodStatus: { stringValue: 'none' },
      totalAmount: { integerValue: '110000' },
      status: { stringValue: 'paid' },
      channel: { stringValue: 'online' },
      paymentMethod: { stringValue: 'vnpay' },
      createdAt: { timestampValue: new Date(now.getTime() - 30 * 60 * 1000).toISOString() }
    }
  },

  // 4. VÉ VÀO QUÁ SỚM (> 60 phút) - Suất chiếu ngày mai
  {
    id: 'BK555EARLY',
    data: {
      userId: { stringValue: 'user_cust_4' },
      customerName: { stringValue: 'Trần Văn Sớm' },
      movieId: { stringValue: 'mov_dune2' },
      movieTitle: { stringValue: 'Dune: Hành Tinh Cát 2' },
      posterUrl: { stringValue: 'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg' },
      ageRating: { stringValue: 'T16' },
      cinemaId: { stringValue: 'cn_q1' },
      cinemaName: { stringValue: 'Cinema Flagship Q1' },
      roomName: { stringValue: 'Phòng 02 - IMAX Laser' },
      format: { stringValue: 'IMAX' },
      showtimeStart: { timestampValue: tomorrow },
      seats: {
        arrayValue: {
          values: [
            { mapValue: { fields: { id: { stringValue: 'F08' }, type: { stringValue: 'vip' } } } }
          ]
        }
      },
      foods: { arrayValue: { values: [] } },
      foodStatus: { stringValue: 'none' },
      totalAmount: { integerValue: '140000' },
      status: { stringValue: 'paid' },
      channel: { stringValue: 'online' },
      paymentMethod: { stringValue: 'vnpay' },
      createdAt: { timestampValue: new Date(now.getTime() - 10 * 60 * 1000).toISOString() }
    }
  },

  // 5. VÉ QUÁ GIỜ CHIẾU (> 15 phút sau giờ chiếu)
  {
    id: 'BK999EXP',
    data: {
      userId: { stringValue: 'user_cust_5' },
      customerName: { stringValue: 'Bùi Thị Muộn' },
      movieId: { stringValue: 'mov_exhuma' },
      movieTitle: { stringValue: 'Exhuma: Quật Mộ Trùng Ma' },
      posterUrl: { stringValue: 'https://image.tmdb.org/t/p/w500/muU9LpE1Ym821sL8iZfP9w7Zp7t.jpg' },
      ageRating: { stringValue: 'T18' },
      cinemaId: { stringValue: 'cn_q1' },
      cinemaName: { stringValue: 'Cinema Flagship Q1' },
      roomName: { stringValue: 'Phòng 01 - IMAX Laser' },
      format: { stringValue: '2D' },
      showtimeStart: { timestampValue: past2Hours },
      seats: {
        arrayValue: {
          values: [
            { mapValue: { fields: { id: { stringValue: 'A01' }, type: { stringValue: 'standard' } } } }
          ]
        }
      },
      foods: { arrayValue: { values: [] } },
      foodStatus: { stringValue: 'none' },
      totalAmount: { integerValue: '100000' },
      status: { stringValue: 'paid' },
      channel: { stringValue: 'online' },
      paymentMethod: { stringValue: 'vnpay' },
      createdAt: { timestampValue: new Date(now.getTime() - 180 * 60 * 1000).toISOString() }
    }
  }
];

function writeBooking(b) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({ fields: b.data });
    const url = new URL(`https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/bookings/${b.id}`);
    
    const req = https.request(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log(` ✅ Đã tạo vé thật [${b.id}] (${b.data.movieTitle.stringValue} - ${b.data.status.stringValue})`);
          resolve();
        } else {
          console.error(` ❌ Lỗi tạo vé [${b.id}]:`, body);
          reject(new Error(body));
        }
      });
    });

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function run() {
  console.log(`\n================================================================================`);
  console.log(` 🚀 ĐANG GHI DỮ LIỆU VÉ THẬT LÊN CLOUD FIRESTORE (${PROJECT_ID})...`);
  console.log(`================================================================================\n`);

  for (const b of REAL_BOOKINGS) {
    await writeBooking(b);
  }

  console.log(`\n🎉 HOÀN TẤT SEED VÉ THẬT VÀO FIRESTORE DB 100%!`);
  console.log(`👉 Chạy lệnh: node tool/view_db.js bookings để xem bảng dữ liệu trên DB.\n`);
}

run();
