package com.natwodev1.quizzmobile

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 1. Chặn Screenshot và Quay màn hình
        // TẠM TẮT để chụp màn hình khi phát triển — BẬT LẠI TRƯỚC KHI PHÁT HÀNH.
        // Mở lại: bỏ dấu // ở dòng dưới, rồi dựng lại app (hot reload không ăn).
        // window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    // 2. Override hàm này để đảm bảo khi vào chế độ đa cửa sổ (nếu bị ép), 
    // chúng ta có thể thực hiện hành động nào đó (ví dụ: đóng app hoặc cảnh báo)
    override fun onMultiWindowModeChanged(isInMultiWindowMode: Boolean) {
        super.onMultiWindowModeChanged(isInMultiWindowMode)
        if (isInMultiWindowMode) {
            // Nếu phát hiện bị chia màn hình, bạn có thể tắt app ngay lập tức để chống gian lận
            finish()
        }
    }
}