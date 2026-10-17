#!/bin/bash
echo "🧹 1. Dọn dẹp Flutter clean..."
flutter clean

echo "🗑️ 2. Dọn cache Gradle Android..."
cd android && ./gradlew clean && cd ..

echo "📦 3. Tải lại dependencies..."
flutter pub get

echo "⚙️ 4. Khởi tạo lại Flutter build runner (nếu có dùng code gen)..."
# dart run build_runner build --delete-conflicting-outputs

echo "✅ Dự án đã sạch sẽ! Sẵn sàng bấm F5 để test."
