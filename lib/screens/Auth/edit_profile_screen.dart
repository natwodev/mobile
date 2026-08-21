import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

import '../../widget/common/app_top_bar.dart';

import '../../widget/common/app_inputs.dart';
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: l10n.authPickDateOfBirth,
      cancelText: l10n.commonCancel,
      confirmText: l10n.authSelect,
    );

    if (picked != null) {
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
                style: TextStyle(
                  fontSize: 16,
                  color: _dateOfBirth != null ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    final l10n = AppLocalizations.of(context);

    return DropdownButtonFormField<bool?>(
      initialValue: _gender,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.authGenderLabel,
        prefixIcon: AppInputs.icon(HugeIcons.strokeRoundedUserAccount),
      ),
      items: [
        DropdownMenuItem<bool?>(
          value: null,
          child: Text(l10n.commonNotUpdated),
        ),
        DropdownMenuItem<bool?>(value: true, child: Text(l10n.authGenderMale)),
        DropdownMenuItem<bool?>(
          value: false,
          child: Text(l10n.authGenderFemale),
        ),
      ],
      onChanged: (value) => setState(() => _gender = value),
    );
  }
}
