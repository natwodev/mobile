import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

import '../../widget/common/app_top_bar.dart';

import '../../widget/common/app_inputs.dart';
import '../../widget/common/app_sheet.dart';
import '../../widget/common/app_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/student.dart';
import '../../services/auth/user_services.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_toast.dart';

/// Form chỉnh sửa thông tin cá nhân của sinh viên.
/// Trả về `true` qua Navigator.pop khi lưu thành công.
class EditProfileScreen extends StatefulWidget {
  final Student student;

  const EditProfileScreen({super.key, required this.student});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  DateTime? _dateOfBirth;
  bool? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.student.displayName,
    );
    _emailController = TextEditingController(text: widget.student.email ?? '');
    _phoneController = TextEditingController(
      text: widget.student.phoneNumber ?? '',
    );
    _dateOfBirth = widget.student.dateOfBirth;
    _gender = widget.student.gender;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    // KHÔNG dùng `showDatePicker`: nó dựng nguyên một hộp thoại của Material
    // kèm dải tiêu đề riêng, nút Huỷ/Chọn riêng và nút chuyển sang gõ tay. Tô
    // màu thì được (đã có `datePickerTheme`), nhưng cái khung thì không đổi
    // được — đứng cạnh các tấm trượt lên khác của app là lạc hẳn.
    //
    // `CalendarDatePicker` là RUỘT của hộp thoại đó, dùng riêng được. Nhờ vậy
    // lịch nằm trong đúng khung `AppSheet` như chọn Giới tính và Ngôn ngữ, mà
    // vẫn ăn trọn `datePickerTheme` đã cắm.
    final DateTime? picked = await showAppSheet<DateTime>(
      context: context,
      title: l10n.authPickDateOfBirth,
      icon: HugeIcons.strokeRoundedCalendar03,
      children: [
        SizedBox(
          // `CalendarDatePicker` đòi chiều cao có giới hạn; đặt trong vùng cuộn
          // của tấm sheet mà không ghim chiều cao là nó ném lỗi ràng buộc.
          height: 340,
          child: CalendarDatePicker(
            initialDate: _dateOfBirth ?? DateTime(now.year - 20),
            firstDate: DateTime(1950),
            lastDate: now,
            // Mở thẳng ở chế độ chọn NĂM. Ngày sinh thường cách hiện tại hai
            // mươi năm — mở ở chế độ tháng thì người dùng phải bấm mũi tên hai
            // trăm mấy lần, hoặc phải tự mò ra là bấm vào tiêu đề để đổi chế độ.
            initialCalendarMode: DatePickerMode.year,
            onDateChanged: (value) => Navigator.pop(context, value),
          ),
        ),
      ],
    );

    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Backend chỉ ghi đè trường khác null (email/SĐT còn phải khác rỗng), nên
    // trường bỏ trống được gửi null để giữ nguyên giá trị cũ.
    final result = await _userService.updateProfile(
      fullName: _fullNameController.text.trim(),
      email: email.isEmpty ? null : email,
      phoneNumber: phone.isEmpty ? null : phone,
      dateOfBirth: _dateOfBirth,
      gender: _gender,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      Navigator.pop(context, true);
      return;
    }

    AppToast.show(
      context,
      kind: AppToastKind.error,
      title:
          result.error ?? AppLocalizations.of(context).authProfileUpdateFailed,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(title: l10n.authEditProfileTitle, showBack: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildReadOnlyField(
                label: l10n.authStudentIdLabel,
                value: widget.student.userCode ?? l10n.authNotAvailable,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: l10n.authFullNameLabel,
                  hintText: l10n.authFullNameHint,
                  prefixIcon: AppInputs.icon(HugeIcons.strokeRoundedUser),
                ),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.authFullNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.authEmailLabel,
                  hintText: l10n.authEmailHint,
                  prefixIcon: AppInputs.icon(HugeIcons.strokeRoundedMail01),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return null; // Email không bắt buộc
                  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!regex.hasMatch(email)) {
                    return l10n.authEmailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: l10n.authPhoneLabel,
                  hintText: l10n.authPhoneHint,
                  prefixIcon: AppInputs.icon(HugeIcons.strokeRoundedCall),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                maxLength: 15,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (phone.isEmpty) return null; // SĐT không bắt buộc
                  if (phone.length < 9) {
                    return l10n.authPhoneMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              _buildDateOfBirthField(),
              const SizedBox(height: 16),

              _buildGenderField(),
              const SizedBox(height: 28),

              // Giữ `width` cho nút chiếm trọn bề ngang, phần còn lại theo theme.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  // Nút đang bị khoá trong lúc lưu -> nền xám nhạt, nên vòng
                  // quay phải lấy màu chữ lúc khoá chứ không phải màu trắng.
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.disabledInk,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(l10n.authSaveChanges),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      enabled: false,
      decoration: AppInputs.readOnly(
        label: label,
        prefixIcon: HugeIcons.strokeRoundedIdentityCard,
        helperText: AppLocalizations.of(context).authStudentIdHelper,
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    final l10n = AppLocalizations.of(context);
    final text = _dateOfBirth != null
        ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
        : l10n.authNotSelected;

    return InkWell(
      onTap: _pickDateOfBirth,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.authDateOfBirthLabel,
          prefixIcon: AppInputs.icon(HugeIcons.strokeRoundedCalendar03),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                // Cùng cỡ và cùng màu với ô chọn Giới tính ngay dưới: hai hàng
                // này trông y hệt nhau nên chữ lệch cỡ là nhận ra ngay.
                style: TextStyle(
                  fontSize: 15,
                  color: _dateOfBirth != null
                      ? AppColors.ink
                      : AppColors.disabledInk,
                ),
              ),
            ),
            AppInputs.dropdownIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    final l10n = AppLocalizations.of(context);

    // BỎ `DropdownButtonFormField`: tấm danh sách nó xổ ra không tô theo app
    // được. Widget đó chỉ mở ra `dropdownColor`, `borderRadius` và `elevation`
    // — không có chỗ nào đặt viền mảnh hay quầng sáng như mọi mặt nổi khác,
    // nên tấm menu luôn là bóng xám trung tính của Material.
    //
    // Thay bằng chính mẫu tấm trượt lên đang dùng cho chọn Ngôn ngữ. Được thêm
    // một thứ nữa: hàng này giờ hành xử y hệt hàng Ngày sinh ngay trên — chạm
    // vào là mở một tấm chọn. Trước đây một cái mở lịch, một cái xổ menu, hai
    // hàng trông giống hệt nhau mà bấm vào lại ra hai kiểu.
    return InkWell(
      onTap: _pickGender,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.authGenderLabel,
          prefixIcon: AppInputs.icon(HugeIcons.strokeRoundedUserAccount),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _genderLabel(l10n),
                style: TextStyle(
                  fontSize: 15,
                  color: _gender == null
                      ? AppColors.disabledInk
                      : AppColors.ink,
                ),
              ),
            ),
            AppInputs.dropdownIcon,
          ],
        ),
      ),
    );
  }

  String _genderLabel(AppLocalizations l10n) {
    return switch (_gender) {
      true => l10n.authGenderMale,
      false => l10n.authGenderFemale,
      null => l10n.commonNotUpdated,
    };
  }

  Future<void> _pickGender() async {
    final l10n = AppLocalizations.of(context);

    // Bọc trong `_GenderChoice` thay vì dùng thẳng `bool?`: giá trị `null` là
    // một lựa chọn HỢP LỆ ("Chưa cập nhật"), nên `showAppSheet<bool?>` trả về
    // null thì không phân biệt được là người dùng chọn "Chưa cập nhật" hay đã
    // đóng tấm mà không chọn gì.
    final _GenderChoice? picked = await showAppSheet<_GenderChoice>(
      context: context,
      title: l10n.authPickGender,
      icon: HugeIcons.strokeRoundedUserAccount,
      children: [
        _buildGenderOption(null, l10n.commonNotUpdated),
        const SizedBox(height: 8),
        _buildGenderOption(true, l10n.authGenderMale),
        const SizedBox(height: 8),
        _buildGenderOption(false, l10n.authGenderFemale),
      ],
    );

    if (picked == null || !mounted) return;
    setState(() => _gender = picked.value);
  }

  Widget _buildGenderOption(bool? value, String label) {
    final bool isSelected = _gender == value;

    return InkWell(
      onTap: () => Navigator.pop(context, _GenderChoice(value)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        // Mục đang chọn có nền và viền riêng, không chỉ mỗi dấu tích: trên tấm
        // chỉ có ba dòng thì dấu tích nhỏ ở mép phải rất dễ lướt qua.
        decoration: isSelected
            ? AppSurfaces.card(color: AppColors.accentBg, soft: true)
            : AppSurfaces.card(tint: AppColors.disabledInk, shadow: false),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.accent : AppColors.ink,
                ),
              ),
            ),
            if (isSelected)
              const HugeIcon(
                icon: HugeIcons.strokeRoundedTick01,
                color: AppColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Bọc giá trị giới tính để trả về từ tấm chọn.
///
/// Cần lớp bọc vì `null` là một lựa chọn HỢP LỆ ("Chưa cập nhật"): trả thẳng
/// `bool?` thì `showAppSheet` trả về null không phân biệt được người dùng chọn
/// "Chưa cập nhật" hay đã đóng tấm mà không chọn gì.
class _GenderChoice {
  const _GenderChoice(this.value);

  final bool? value;
}
