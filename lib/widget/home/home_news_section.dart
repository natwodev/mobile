import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/news_item.dart';
import '../../services/news_cache.dart';
import '../../services/news_service.dart';
import '../common/app_colors.dart';
import '../common/app_toast.dart';

/// Dải "Tin giáo dục" nằm dưới băng ảnh ở Trang chủ.
///
/// Tự tải lấy phần của mình và tự nuốt lỗi của mình: Trang chủ là màn đầu tiên
/// sinh viên thấy sau khi đăng nhập, hỏng mạng tin tức mà kéo sập cả màn thì
/// mất luôn hai nút vào thi — thứ duy nhất thực sự quan trọng ở đây.
class HomeNewsSection extends StatefulWidget {
  const HomeNewsSection({super.key});

  @override
  State<HomeNewsSection> createState() => HomeNewsSectionState();
}

/// State để CÔNG KHAI (không có gạch dưới) vì Trang chủ cần cầm `GlobalKey`
/// tới nó mà gọi [reload] khi người dùng kéo tải lại cả trang.
class HomeNewsSectionState extends State<HomeNewsSection> {
  static const NewsService _service = NewsService();

  List<NewsItem> _items = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Tải lại cho cú kéo-để-tải-lại của Trang chủ.
  ///
  /// Trả về true khi lấy được tin. Trang chủ dựa vào đó để quyết định có báo
  /// "tải lại thành công" hay không — hỏng mạng mà vẫn báo thành công thì tệ
  /// hơn hẳn im lặng.
  Future<bool> reload() async {
    await _load();
    return !_failed;
  }

  Future<void> _load() async {
    setState(() => _failed = false);

    // Hiện bản đã lưu TRƯỚC, y như màn Tài khoản làm với hồ sơ: mở Trang chủ là
    // có tin đọc ngay thay vì nhìn vòng quay chờ mạng mỗi lần.
    final cached = await NewsCache.load();
    if (!mounted) return;
    setState(() {
      if (cached.isNotEmpty) _items = cached;
      _loading = _items.isEmpty;
    });

    try {
      final items = await _service.fetchEducationNews();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      await NewsCache.save(items);
    } catch (_) {
      if (!mounted) return;
      // Mạng hỏng mà đã có bản lưu thì CỨ HIỆN BẢN LƯU — tin của một giờ trước
      // vẫn đáng đọc hơn một màn trắng kèm nút "Thử lại". Chỉ khi không còn gì
      // để hiện mới rơi vào trạng thái lỗi.
      //
      // `_failed` vẫn đặt true trong CẢ HAI trường hợp: nó trả lời câu hỏi "cú
      // gọi mạng có ăn không", khác với câu "màn hình có gì để hiện". Trang chủ
      // dựa vào nó để báo đỏ khi kéo tải lại hỏng.
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _open(NewsItem item) async {
    // Lấy l10n TRƯỚC khi await: sau await mà còn đụng vào context là dính
    // use_build_context_synchronously, và context có thể đã chết.
    final l10n = AppLocalizations.of(context);

    bool opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(item.link),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }

    if (!mounted) return;
    if (!opened) {
      AppToast.show(
        context,
        kind: AppToastKind.error,
        title: l10n.homeNewsOpenFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n),
          const SizedBox(height: 12),
          _buildBody(l10n),
        ],
      ),
    );
  }

  /// Tiêu đề mục. KHÔNG còn dòng "Nguồn: VnExpress" ở đây nữa: từ khi mỗi thẻ
  /// tin tự ghi nguồn, để thêm ở đây là lặp lại đúng một chữ ba lần trên cùng
  /// một khung hình.
  Widget _buildHeader(AppLocalizations l10n) {
    return Text(
      l10n.homeNewsTitle,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    // Xét CÓ TIN ĐỂ HIỆN trước, xét `_failed` sau — thứ tự này quan trọng.
    // Làm ngược lại thì mất mạng là nhảy thẳng vào màn "Thử lại" dù bản lưu còn
    // nguyên, và cả phần cache thành vô dụng.
    if (_items.isEmpty) {
      return _buildRetry(
        l10n,
        _failed ? l10n.homeNewsError : l10n.homeNewsEmpty,
      );
    }

    // shrinkWrap + NeverScrollable: dải này nằm trong SingleChildScrollView của
    // Trang chủ. Để ListView tự cuộn là có hai vùng cuộn lồng nhau — ngón tay
    // đặt trúng danh sách thì cả trang đứng im, đúng thứ người dùng chửi là
    // "app đơ".
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _items.length,
      itemBuilder: (context, index) =>
          _NewsTile(item: _items[index], onTap: () => _open(_items[index])),
    );
  }

  Widget _buildRetry(AppLocalizations l10n, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: Text(l10n.homeNewsRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một thẻ tin: ảnh, tiêu đề, tóm tắt ba dòng, rồi hàng nguồn và ngày đăng.
///
/// Bản trước chỉ có ảnh nhỏ bên trái kèm tiêu đề — đọc lướt qua thì không biết
/// tin nói gì cho tới khi bấm vào. Nay hiện luôn phần tóm tắt để người dùng
/// quyết định có mở hay không ngay trên Trang chủ.
class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Cùng công thức với khung hai nút nhanh ở Trang chủ: màu chủ đạo hạ
        // xuống 40% độ đục, dày nửa điểm ảnh logic.
        //
        // Thay cho `AppColors.line` dày 1.0 trước đây — màu xám trung tính đó
        // đọc ra gần như đen khi đặt cạnh ảnh tin nhiều màu, và dày 1.0 trên
        // màn 3x là ba điểm ảnh vật lý, đủ nặng để cái khung hút mắt hơn chính
        // tấm ảnh nó bao.
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
          width: 0.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      // clipBehavior để ảnh trong thẻ bo theo góc thẻ; thiếu nó thì ảnh vuông
      // góc thò ra ngoài đúng bốn góc bo.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumb(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  if (item.summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.disabledInk,
                      ),
                      const SizedBox(width: 4),
                      // Tên riêng, không dịch — nên để thẳng thay vì đẻ thêm
                      // một khoá l10n mà cả bốn ngôn ngữ đều ghi giống hệt.
                      const Text(
                        'VnExpress',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.disabledInk,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time_outlined,
                        size: 16,
                        color: AppColors.disabledInk,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _relativeTime(l10n, item.publishedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.disabledInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ảnh chạy hết bề ngang thẻ theo tỉ lệ 16:9.
  Widget _buildThumb() {
    if (item.imageUrl == null) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: SizedBox(
        width: double.infinity,
        child: Image.network(
          item.imageUrl!,
          fit: BoxFit.cover,
          // VnExpress chỉ phát ảnh ở w=1200 — tham số `w` nằm trong chữ
          // ký `s=` của URL nên sửa nhỏ lại là CDN trả 401. Không giảm
          // được lượng tải, nhưng giảm được chỗ ảnh chiếm trong RAM.
          //
          // 900 chứ không phải 300 như hồi ảnh còn là ô nhỏ 92px: giờ ảnh
          // chạy hết bề ngang thẻ, trên máy 1080px mà giải nén ở 300 là
          // nhìn rõ vỡ hạt.
          cacheWidth: 900,
          // Ảnh hỏng/mạng chậm chỉ được phép để lại một ô xám, tuyệt đối
          // không nhả exception làm đỏ cả thẻ tin.
          errorBuilder: (_, _, _) =>
              const ColoredBox(color: AppColors.surfaceMuted),
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const ColoredBox(color: AppColors.surfaceMuted),
        ),
      ),
    );
  }

  /// "Vừa xong / 5 phút trước / 3 giờ trước / 2 ngày trước".
  ///
  /// Tin cũ hơn một tuần thì đổi sang ngày tháng: "12 ngày trước" bắt người
  /// đọc tự trừ nhẩm, còn ngày cụ thể thì nhìn phát biết ngay.
  static String _relativeTime(AppLocalizations l10n, DateTime? moment) {
    if (moment == null) return '';

    final diff = DateTime.now().difference(moment);
    if (diff.inMinutes < 1) return l10n.homeNewsTimeJustNow;
    if (diff.inMinutes < 60) return l10n.homeNewsTimeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.homeNewsTimeHours(diff.inHours);
    if (diff.inDays <= 7) return l10n.homeNewsTimeDays(diff.inDays);

    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(moment.day)}/${two(moment.month)}/${moment.year}';
  }
}
