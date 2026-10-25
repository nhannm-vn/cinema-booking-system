/**
 * Công cụ xem trực tiếp Database Cloud Firestore ngay trong IDE Terminal
 * 
 * Cách dùng:
 *   1. Xem danh sách toàn bộ vé:
 *      node tool/view_db.js bookings
 * 
 *   2. Xem các vé thuộc rạp của Staff 1 (Quận 1 - cn_q1):
 *      node tool/view_db.js bookings cn_q1
 * 
 *   3. Xem các vé thuộc rạp Tân Bình (cn_tb):
 *      node tool/view_db.js bookings cn_tb
 * 
 *   4. Xem chi tiết 1 mã vé cụ thể:
 *      node tool/view_db.js bookings BK92M7XP
 */

const https = require('https');

const PROJECT_ID = 'cinemabookingsystem-fcdb3';
const collection = process.argv[2] || 'bookings';
const filterArg = process.argv[3];

function unwrapValue(val) {
  if (!val) return null;
  if ('stringValue' in val) return val.stringValue;
  if ('integerValue' in val) return parseInt(val.integerValue, 10);
  if ('doubleValue' in val) return parseFloat(val.doubleValue);
  if ('booleanValue' in val) return val.booleanValue;
  if ('timestampValue' in val) return val.timestampValue;
  if ('arrayValue' in val) return (val.arrayValue.values || []).map(unwrapValue);
  if ('mapValue' in val) {
    const res = {};
    for (const [k, v] of Object.entries(val.mapValue.fields || {})) {
      res[k] = unwrapValue(v);
    }
    return res;
  }
  return null;
}

const isCinemaFilter = filterArg && (filterArg.startsWith('cn_') || filterArg === 'q1' || filterArg === 'tb');
const targetCinemaId = filterArg === 'q1' ? 'cn_q1' : (filterArg === 'tb' ? 'cn_tb' : filterArg);

const isSingleDoc = filterArg && !isCinemaFilter;

const url = isSingleDoc
  ? `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${filterArg}`
  : `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}`;

https.get(url, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const json = JSON.parse(data);
      if (json.error) {
        console.error(`\n❌ Lỗi từ Firebase: ${json.error.message}\n`);
        return;
      }

      // Trường hợp 1: Xem chi tiết 1 document
      if (isSingleDoc) {
        console.log(`\n================================================================================`);
        console.log(` 📄 DOCUMENT: [${collection}/${filterArg}]`);
        console.log(`================================================================================\n`);
        const result = {};
        for (const [k, v] of Object.entries(json.fields || {})) {
          result[k] = unwrapValue(v);
        }
        console.dir(result, { depth: null, colors: true });
        return;
      }

      // Trường hợp 2: Xem danh sách trong collection
      if (!json.documents || json.documents.length === 0) {
        console.log(`\nℹ️ Collection '${collection}' hiện chưa có dữ liệu nào.`);
        return;
      }

      let docs = json.documents;
      if (isCinemaFilter) {
        docs = docs.filter(doc => {
          const cid = doc.fields?.cinemaId?.stringValue;
          return cid === targetCinemaId;
        });
      }

      console.log(`\n================================================================================`);
      if (isCinemaFilter) {
        console.log(` 📦 FIRESTORE: [${collection.toUpperCase()}] - Lọc theo rạp: [${targetCinemaId}] (Tìm thấy ${docs.length} vé)`);
      } else {
        console.log(` 📦 FIRESTORE: [${collection.toUpperCase()}] - Tìm thấy ${docs.length} bản ghi`);
      }
      console.log(`================================================================================\n`);

      const rows = docs.map(doc => {
        const id = doc.name.split('/').pop();
        const obj = { ID: id };
        for (const [key, val] of Object.entries(doc.fields || {})) {
          const unwrapped = unwrapValue(val);
          obj[key] = typeof unwrapped === 'object' ? JSON.stringify(unwrapped) : unwrapped;
        }
        return obj;
      });

      if (collection === 'bookings') {
        console.table(rows, ['ID', 'movieTitle', 'cinemaId', 'roomName', 'status', 'foodStatus', 'showtimeStart']);
      } else {
        console.table(rows);
      }
      console.log('\n💡 Mẹo:');
      console.log(`   - Xem chi tiết 1 mã vé: node tool/view_db.js bookings <MÃ_VÉ>`);
      console.log(`   - Lọc theo rạp khác:    node tool/view_db.js bookings cn_tb\n`);
    } catch (e) {
      console.error('Lỗi xử lý dữ liệu:', e);
    }
  });
}).on('error', err => {
  console.error('Lỗi kết nối Firestore:', err.message);
});
