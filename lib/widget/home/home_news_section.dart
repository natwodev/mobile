import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/news_item.dart';
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
  State<HomeNewsSection> createState() => _HomeNewsSectionState();
}

class _HomeNewsSectionState extends State<HomeNewsSection> {
  static const NewsService _service = NewsService();

  List<NewsItem> _items = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final items = await _service.fetchEducationNews();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Nuốt lỗi thật và chỉ hiện nút thử lại: người dùng không làm được gì với
      // "SocketException", còn nút bấm lại thì có.
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

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            l10n.homeNewsTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(
          l10n.homeNewsSource,
          style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
        ),
      ],
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (_failed) return _buildRetry(l10n, l10n.homeNewsError);
    if (_items.isEmpty) return _buildRetry(l10n, l10n.homeNewsEmpty);

    // shrinkWrap + NeverScrollable: dải này nằm trong SingleChildScrollView của
    // Trang chủ. Để ListView tự cuộn là có hai vùng cuộn lồng nhau — ngón tay
    // đặt trúng danh sách thì cả trang đứng im, đúng thứ người dùng chửi là
    // "app đơ".
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(
        height: 20,
        thickness: 1,
        color: AppColors.line,
      ),
      itemBuilder: (context, index) => _NewsTile(
        item: _items[index],
        onTap: () => _open(_items[index]),
      ),
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

/// Một thẻ tin: ảnh vuông bên trái, tiêu đề và mốc thời gian bên phải.
class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumb(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _relativeTime(l10n, item.publishedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb() {
    const double size = 92;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size * 0.78,
        child: item.imageUrl == null
            ? const ColoredBox(color: AppColors.surfaceMuted)
            : Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                // VnExpress chỉ phát ảnh ở w=1200 — tham số `w` nằm trong chữ
                // ký `s=` của URL nên sửa nhỏ lại là CDN trả 401. Không giảm
                // được lượng tải, nhưng giảm được chỗ ảnh chiếm trong RAM:
                // không có cacheWidth thì mỗi tấm giải nén full 1200px ≈ 3,8 MB
                // bitmap cho một ô rộng 92px, mười mấy tin là hàng chục MB.
                cacheWidth: 300,
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
