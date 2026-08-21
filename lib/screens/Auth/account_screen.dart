import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_modal.dart';
import '../../widget/common/app_toast.dart';
import '../../widget/common/app_top_bar.dart';
import '../../widget/common/app_refresh_indicator.dart';
import '../../widget/common/success_banner.dart';
import '../../l10n/locale_controller.dart';
import '../../models/student.dart';
import '../../services/auth/user_services.dart';
import '../../controller/session_controller.dart';
import '../../services/cache_service.dart';
import '../../widget/language_selector.dart';
import 'change_password_screen.dart';
import 'device_info_screen.dart';
import 'edit_profile_screen.dart';
import 'feedback_screen.dart';
import 'support_contact_sheet.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.scrollController});

  /// Do [HomeNavigation] giữ, để bấm nút tab là cuộn màn này về đầu.
  final ScrollController? scrollController;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final UserService _userService = UserService();

  Student? _student;
  bool _loading = true;
  String? _error;

  /// Đang tải ảnh đại diện lên. Khoá luôn thao tác chọn ảnh trong lúc này để
  /// hai lần tải không chồng nhau — request sau về trước là avatar hiển thị
  /// một đằng, máy chủ giữ một nẻo.
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Hiện bản đã lưu TRƯỚC: mở màn Tài khoản là thấy tên mình ngay, không
    // phải nhìn vòng quay chờ mạng mỗi lần.
    final cached = await _userService.getCachedProfile();
    if (!mounted) return;

    setState(() {
      if (cached != null) _student = cached;
      _loading = _student == null;
      _error = null;
    });

    final profile = await _userService.getProfile();
    if (!mounted) return;

    setState(() {
      if (profile != null) _student = profile;
      _loading = false;
      // Tải hỏng mà đã có bản lưu thì cứ hiện bản lưu, đừng đá người dùng sang
      // màn báo lỗi chỉ vì mạng chập chờn.
      _error = (profile == null && _student == null)
          ? AppLocalizations.of(context).authProfileLoadFailedRetry
          : null;
    });
  }

  Future<void> _openEditProfile() async {
    final current = _student;
    if (current == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(student: current)),
    );

    if (updated == true) {
      await _loadProfile();
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context).authProfileUpdateSuccess);
    }
  }

  Future<void> _openChangePassword() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );

    if (changed == true && mounted) {
      _showMessage(AppLocalizations.of(context).authChangePasswordSuccess);
    }
  }

  /// Hỏi nguồn ảnh rồi tải lên.
  ///
  /// Tách "chọn nguồn" thành một bảng riêng thay vì mở thẳng thư viện: máy
  /// thật của sinh viên phần lớn chưa có sẵn ảnh chân dung, mở thẳng thư viện
  /// là bắt họ thoát ra chụp rồi quay lại.
  Future<void> _changeAvatar() async {
    final l10n = AppLocalizations.of(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    l10n.authAvatarChangeTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01,
                color: AppColors.accent,
                size: 22,
              ),
              title: Text(l10n.authAvatarFromCamera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                color: AppColors.accent,
                size: 22,
              ),
              title: Text(l10n.authAvatarFromGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        // Thu ảnh ngay lúc chọn: máy 50MP xuất ra tệp 8-12MB, vượt trần 10MB
        // của máy chủ mà chẳng để làm gì — ảnh đại diện lớn nhất chỉ hiển thị
        // ở 70px. Thu ở đây cũng đỡ được cả thời gian tải lên qua 4G.
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      // Người dùng từ chối quyền máy ảnh/thư viện thì plugin ném lỗi chứ không
      // trả null — nuốt lỗi ở đây là màn hình đứng im, không ai biết vì sao.
      debugPrint('Lỗi chọn ảnh đại diện: $e');
      if (!mounted) return;
      _showError(AppLocalizations.of(context).msgAvatarUploadFailed);
      return;
    }

    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    final result = await _userService.uploadAvatar(picked.path);
    if (!mounted) return;
    setState(() => _uploadingAvatar = false);

    if (result.success) {
      await _loadProfile();
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context).authAvatarUpdateSuccess);
    } else {
      _showError(
        result.error ?? AppLocalizations.of(context).msgAvatarUploadFailed,
      );
    }
  }

  void _showError(String message) {
    AppToast.show(context, kind: AppToastKind.error, title: message);
  }

  /// Xác nhận một việc người dùng vừa làm xong: lưu hồ sơ, đổi mật khẩu, đổi
  /// ảnh đại diện.
  ///
  /// Dùng thanh báo chung chứ không dùng [AppToast]: cả ba đều là phản hồi cho
  /// thao tác của chính người dùng, cùng loại với "tải lại xong" — nên phải
  /// hiện cùng một kiểu. Toast để dành cho tin từ hệ thống.
  void _showMessage(String message) {
    showSuccessBanner(context, message);
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppModal(
        title: l10n.authLogout,
        icon: HugeIcons.strokeRoundedLogout03,
        accentColor: AppColors.danger,
        onClose: () => Navigator.pop(dialogContext, false),
        children: [Text(l10n.authLogoutConfirmMessage)],
        actions: [
          // `quietDanger`: màu đỏ thuộc về NÚT chứ không phải chữ bên trong —
          // tô ở `child` thì vệt ripple khi nhấn vẫn là màu mặc định, bấm vào
          // là thấy hai màu đá nhau.
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: AppButtons.quietDanger,
            child: Text(l10n.authLogout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  void _openDeviceInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeviceInfoScreen()),
    );
  }

  void _openFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  /// Hỏi trước khi dọn: nói rõ xoá cái gì và đang chiếm bao nhiêu, vì nghe
  /// "xoá bộ nhớ" nhiều người tưởng mất luôn tài khoản với bài đã làm.
  Future<void> _confirmClearCache() async {
    final l10n = AppLocalizations.of(context);
    final int currentSize = await CacheService.size();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppModal(
        title: l10n.clearCacheTitle,
        icon: HugeIcons.strokeRoundedDelete02,
        accentColor: AppColors.accent,
        onClose: () => Navigator.pop(dialogContext, false),
        children: [
          Text(l10n.clearCacheMessage),
          const SizedBox(height: 8),
          Text(
            l10n.clearCacheSize(CacheService.formatBytes(currentSize)),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clearCacheConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final int freed = await CacheService.clear();
      if (!mounted) return;
      _showMessage(
        freed <= 0
            ? l10n.clearCacheAlreadyEmpty
            : l10n.clearCacheDone(CacheService.formatBytes(freed)),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(l10n.clearCacheFailed(e.toString()));
    }
  }

  Future<void> _logout() async {
    try {
      // Gọi API logout trước để backend đóng phiên, sau đó mới xoá dữ liệu máy.
      await _userService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      SessionController.instance.markSignedOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        kind: AppToastKind.error,
        title: AppLocalizations.of(context).authLogoutFailed(e.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // AppRefreshIndicator bọc NGOÀI Scaffold chứ không nằm trong body: vòng
    // xoay là con của widget nào thì vẽ theo thứ tự của widget đó, đặt trong
    // body là AppBar luôn vẽ đè lên và vòng xoay bị che mất. Bọc ngoài thì nó
    // nổi trên cả AppBar, rơi ngay dưới thanh trạng thái — giống hệt Trang chủ
    // vốn không có AppBar.
    return AppRefreshIndicator(
      edgeOffset: MediaQuery.paddingOf(context).top,
      onRefresh: _handleRefresh,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppTopBar(title: AppLocalizations.of(context).authAccountTitle),
        // `bottom: false` để danh sách chạy tiếp xuống dưới dải tab kính mờ —
        // khoảng chừa cho dải đã nằm trong padding cuối của `ListView`.
        body: SafeArea(bottom: false, child: _buildBody()),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _loadProfile();
    // _loadProfile giữ bản đã lưu khi mạng hỏng, và chỉ đặt _error lúc không
    // còn gì để hiện. Bám vào đó nên không phải đổi chữ ký hàm.
    if (!mounted || _error != null) return;
    showRefreshDone(context);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null || _student == null) {
      return _buildErrorState();
    }

    final student = _student!;

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _buildHeaderCard(student),
        const SizedBox(height: 16),
        _buildPersonalInfoCard(student),
        const SizedBox(height: 16),
        _buildSettingsCard(),
        const SizedBox(height: 16),
        _buildSupportCard(),
        const SizedBox(height: 24),
        _buildChangePasswordButton(),
        const SizedBox(height: 12),
        _buildLogoutButton(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedNoInternet,
              color: Colors.grey[400]!,
              size: 56.0,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? l10n.authProfileLoadFailed,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
            const SizedBox(height: 12),
            // Vẫn là "Đăng xuất" nên vẫn `quietDanger` như trong hộp thoại xác
            // nhận: cùng một hành động thì không được đổi màu theo màn hình.
            TextButton(
              onPressed: _confirmLogout,
              style: AppButtons.quietDanger,
              child: Text(l10n.authLogout),
            ),
          ],
        ),
      ),
    );
  }

  /// Ảnh đại diện, kiêm nút đổi ảnh.
  ///
  /// Huy hiệu máy ảnh ở góc là thứ DUY NHẤT nói rằng bấm được: một vòng tròn
  /// ảnh trần trông y hệt phần trang trí, không ai nghĩ tới việc chạm vào.
  /// [Semantics] mang nhãn nút vì huy hiệu chỉ là hình.
  Widget _buildAvatar(AppLocalizations l10n, String? avatarUrl) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Semantics(
      button: true,
      label: l10n.authAvatarChangeTitle,
      child: GestureDetector(
        onTap: _uploadingAvatar ? null : _changeAvatar,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey[300],
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
              child: hasAvatar
                  ? null
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      color: Colors.white,
                      size: 30.0,
                    ),
            ),
            if (_uploadingAvatar)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Khối đầu trang: ảnh đại diện + họ tên + MSSV
  Widget _buildHeaderCard(Student student) {
    final l10n = AppLocalizations.of(context);
    final name = student.displayName;
    final avatarUrl = student.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(79, 161, 234, 253),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildAvatar(l10n, avatarUrl),
          const SizedBox(width: 16),
          // Expanded để tên dài không đẩy tràn Row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? l10n.authNoName : name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedIdentityCard,
                      color: Colors.black87,
                      size: 22.0,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        student.userCode ?? l10n.authNoStudentId,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(Student student) {
    final l10n = AppLocalizations.of(context);

    return _buildSection(
      title: l10n.authPersonalInfoTitle,
      action: TextButton.icon(
        onPressed: _openEditProfile,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(l10n.authEdit),
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      children: [
        _buildInfoRow(
          icon: HugeIcons.strokeRoundedUser,
          label: l10n.authFullNameLabel,
          value: student.displayName,
        ),
        _buildInfoRow(
          icon: HugeIcons.strokeRoundedMail01,
          label: l10n.authEmailLabel,
          value: student.email,
        ),
        _buildInfoRow(
          icon: HugeIcons.strokeRoundedCall,
          label: l10n.authPhoneLabel,
          value: student.phoneNumber,
        ),
        _buildInfoRow(
          icon: HugeIcons.strokeRoundedCalendar02,
          label: l10n.authDateOfBirthLabel,
          value: student.dateOfBirth != null
              ? DateFormat('dd/MM/yyyy').format(student.dateOfBirth!)
              : null,
        ),
        _buildInfoRow(
          icon: HugeIcons.strokeRoundedUserSquare,
          label: l10n.authGenderLabel,
          value: student.gender == null
              ? null
              : (student.gender! ? l10n.authGenderMale : l10n.authGenderFemale),
          isLast: true,
        ),
      ],
    );
  }

  // Mục Cài đặt: hiện chỉ có đổi ngôn ngữ (Tiếng Việt / English).
  Widget _buildSettingsCard() {
    final l10n = AppLocalizations.of(context);

    return _buildSection(
      title: l10n.settingsTitle,
      children: [
        InkWell(
          onTap: () => showLanguagePicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    icon: HugeIcons.strokeRoundedLanguageCircle,
                    label: l10n.settingsLanguage,
                    value: languageLabel(LocaleController.instance.locale),
                    isLast: true,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Mục Hỗ trợ: thông tin máy, dọn bộ nhớ đệm, báo lỗi và đầu mối liên hệ.
  Widget _buildSupportCard() {
    final l10n = AppLocalizations.of(context);

    return _buildSection(
      title: l10n.supportSectionTitle,
      children: [
        _buildActionRow(
          icon: HugeIcons.strokeRoundedSmartPhone01,
          title: l10n.supportDeviceInfo,
          subtitle: l10n.supportDeviceInfoSubtitle,
          onTap: _openDeviceInfo,
        ),
        _buildActionRow(
          icon: HugeIcons.strokeRoundedDelete02,
          title: l10n.supportClearCache,
          subtitle: l10n.supportClearCacheSubtitle,
          onTap: _confirmClearCache,
        ),
        _buildActionRow(
          icon: HugeIcons.strokeRoundedBug01,
          title: l10n.supportFeedback,
          subtitle: l10n.supportFeedbackSubtitle,
          onTap: _openFeedback,
        ),
        _buildActionRow(
          icon: HugeIcons.strokeRoundedCustomerSupport,
          title: l10n.supportContact,
          subtitle: l10n.supportContactSubtitle,
          onTap: () => showSupportContactSheet(context),
          isLast: true,
        ),
      ],
    );
  }

  /// Hàng bấm được: khác _buildInfoRow ở chỗ dòng trên mới là dòng chính, dòng
  /// dưới chỉ giải thích — hàng thông tin thì ngược lại.
  Widget _buildActionRow({
    required List<List<dynamic>> icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(top: 12, bottom: isLast ? 12 : 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HugeIcon(icon: icon, color: AppColors.accent, size: 20.0),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const Divider(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required List<List<dynamic>> icon,
    required String label,
    String? value,
    bool isLast = false,
  }) {
    final hasValue = value != null && value.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: isLast ? 12 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(icon: icon, color: AppColors.accent, size: 20.0),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValue
                      ? value
                      : AppLocalizations.of(context).commonNotUpdated,
                  style: TextStyle(
                    fontSize: 15,
                    color: hasValue ? Colors.black87 : Colors.grey,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Nút viền — đổi mật khẩu là hành động phụ đứng một mình, không được nặng
  /// bằng nút chính. Mọi [OutlinedButton] đã ăn sẵn `AppButtons.outlined` từ
  /// theme nên ở đây không khai style; icon và chữ tự lấy màu nhấn của nút.
  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openChangePassword,
        icon: const Icon(Icons.lock_outline),
        label: Text(AppLocalizations.of(context).authChangePasswordTitle),
      ),
    );
  }

  /// `danger`: đăng xuất là hành động phá huỷ phiên đăng nhập. Để nó cùng màu
  /// xanh với "Lưu"/"Đăng nhập" thì nút cuối trang trông y hệt một nút xác
  /// nhận thường, không có gì báo cho người dùng biết là sẽ mất phiên.
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _confirmLogout,
        style: AppButtons.danger,
        // Cùng icon với hộp thoại xác nhận mở ra ngay sau đó, để người dùng
        // thấy hộp thoại là biết mình vừa bấm đúng nút.
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedLogout03,
          color: Colors.white,
          size: 20,
        ),
        label: Text(AppLocalizations.of(context).authLogout),
      ),
    );
  }
}
