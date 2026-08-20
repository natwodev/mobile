import 'dart:ui' show ImageFilter;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Một tấm trong băng ảnh.
class HomeBannerSlide {
  const HomeBannerSlide({
    required this.asset,
    this.alignment = Alignment.center,
  });

  /// Đường dẫn ảnh trong `assets/banners/`.
  final String asset;

  /// Phần ảnh được giữ lại khi khung hẹp hơn ảnh.
  ///
  /// Các tấm vẽ cho khung 393x280 thì để giữa là vừa khít; tấm nào vẽ cho
  /// khung thấp hơn sẽ bị cắt hai bên, lúc đó neo về phía có nội dung chính.
  final Alignment alignment;
}

/// Băng ảnh động trên màn Trang chủ.
///
/// Ảnh là pixel art (lưới ô vuông) nên vẽ bằng [FilterQuality.none]: để Flutter
/// làm mượt theo mặc định là từng ô bị nhoè thành vệt xám, đúng thứ pixel art
/// tránh.
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, required this.slides});

  final List<HomeBannerSlide> slides;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _current = 0;

  /// Đúng tỉ lệ ảnh (393x165) nên không tấm nào bị xén cạnh nào.
  ///
  /// Ảnh được vẽ thẳng cho khung này (xem `tool/make_banners.py`); đổi số ở
  /// đây mà không vẽ lại ảnh là quay về cảnh mỗi tấm mất một dải nội dung.
  static const double _aspectRatio = 393 / 165;

  /// Dựng dãy chấm.
  ///
  /// [onTap] chỉ truyền cho lớp trên cùng: chấm nhỏ hơn ngón tay nên
  /// `onDotClicked` là thứ duy nhất khiến chúng bấm được, còn lớp hào quang
  /// nằm dưới thì không được ăn chạm.
  Widget _buildDots({void Function(int index)? onTap}) {
    return AnimatedSmoothIndicator(
      activeIndex: _current,
      count: widget.slides.length,
      onDotClicked: onTap,
      effect: ExpandingDotsEffect(
        dotHeight: 6,
        dotWidth: 6,
        expansionFactor: 3.2,
        spacing: 4,
        activeDotColor: Colors.white,
        dotColor: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: widget.slides.length,
          options: CarouselOptions(
            aspectRatio: _aspectRatio,
            // Bề ngang tấm giữa so với màn hình, ngắm theo thẻ 2 nút nhanh
            // ngay phía trên: thẻ đó chừa 16 mỗi
            // bên (~92% bề ngang màn), tấm ảnh lấy 90% của thẻ. Trừ tiếp 4 đệm
            // mỗi bên của từng tấm thì ra con số này.
            viewportFraction: 0.88,
            enlargeCenterPage: true,
            // Kiểu `height`: tấm giữa cao hết khung, hai tấm bên bị hạ thấp
            // xuống nên nhìn như hai mẩu thấp hơn nhô ra ở mép — khác kiểu
            // `scale` mặc định, vốn thu nhỏ cả tấm nên hai bên vẫn cao gần
            // bằng tấm giữa. `enlargeFactor` là mức chênh giữa hai bên và giữa.
            enlargeStrategy: CenterPageEnlargeStrategy.height,
            enlargeFactor: 0.22,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (index, _) => setState(() => _current = index),
          ),
          itemBuilder: (context, index, _) {
            final slide = widget.slides[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  slide.asset,
                  // Ép lấp hết ô của mình. Thiếu hai dòng này thì với
                  // `enlargeStrategy: height` (chỉ ghim chiều cao, thả bề
                  // ngang) ảnh co lại đúng tỉ lệ gốc, hẹp hơn ô — nên tấm ảnh
                  // không chạm được tới mép và hai tấm bên chẳng ló ra nổi.
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  alignment: slide.alignment,
                  filterQuality: FilterQuality.none,
                  isAntiAlias: false,
                ),
              ),
            );
          },
        ),
        // Chấm nằm ĐÈ LÊN ảnh chứ không xếp dưới: xếp dưới thì chúng chiếm
        // thêm một dải trắng, đẩy phần nội dung kế tiếp xuống.
        //
        // Đè lên ảnh thì nền phía sau lúc sáng lúc tối tuỳ tấm, nên chấm ngồi
        // trong một viên nền tối mờ — thiếu nó là chấm trắng biến mất trên tấm
        // trang vở nền sáng.
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hào quang: đúng bộ chấm đó vẽ nhoè rồi đặt phía sau bản sắc
                // nét. Không dùng `boxShadow` được vì bóng chỉ bám theo viên
                // nền, còn thứ cần toả sáng là từng cái chấm bên trong.
                IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                    child: _buildDots(),
                  ),
                ),
                _buildDots(onTap: (index) => _controller.animateToPage(index)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
