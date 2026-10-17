#!/bin/bash
echo "🎨 Đang tự động format lại toàn bộ code Dart..."
dart format .

echo "🧹 Đang dọn dẹp các import thừa và áp dụng fix..."
dart fix --apply

echo "✨ Xong! Code đã được format gọn gàng."
