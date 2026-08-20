/// Hồ sơ sinh viên, khớp với entity Student trả về từ `GET api/student/profile`.
class Student {
  final String? studentId;
  final String? userCode;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;

  /// Backend dùng bool?: true = Nam, false = Nữ, null = chưa xác định.
  final bool? gender;

  final String? address;
  final String? avatarUrl;
  final bool emailConfirmed;
  final DateTime? lastLoginTime;
  final DateTime? lastLogoutTime;
  final String? lastLoginLocation;

  Student({
    this.studentId,
    this.userCode,
    this.fullName,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.avatarUrl,
    this.emailConfirmed = false,
    this.lastLoginTime,
    this.lastLogoutTime,
    this.lastLoginLocation,
  });

  /// Họ tên hiển thị: ưu tiên FullName, không có thì ghép First + Last.
  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final parts = [
      firstName,
      lastName,
    ].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim());
    return parts.isEmpty ? '' : parts.join(' ');
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// Gender có thể về dạng bool, hoặc chuỗi "Nam"/"Nữ"/"true" tuỳ endpoint.
  static bool? _parseGender(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (['true', '1', 'nam', 'male'].contains(text)) return true;
    if (['false', '0', 'nữ', 'nu', 'female'].contains(text)) return false;
    return null;
  }

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    studentId: json['studentId']?.toString() ?? json['id']?.toString(),
    userCode: json['userCode'] ?? json['studentCode'],
    fullName: json['fullName'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
    dateOfBirth: _parseDate(json['dateOfBirth']),
    gender: _parseGender(json['gender']),
    address: json['address'],
    avatarUrl: json['avatarUrl'],
    emailConfirmed: json['emailConfirmed'] == true,
    lastLoginTime: _parseDate(json['lastLoginTime'] ?? json['lastLoggedIn']),
    lastLogoutTime: _parseDate(json['lastLogoutTime'] ?? json['lastLoggedOut']),
    lastLoginLocation: json['lastLoginLocation'],
  );

  /// Ghi lại đúng những khoá mà [Student.fromJson] đọc được, để vòng
  /// `toJson -> fromJson` không rụng trường nào khi lưu vào máy.
  ///
  /// Ngày giờ ghi dạng ISO-8601, giới tính ghi bool — đây là hai dạng
  /// [fromJson] hiểu chắc chắn, khỏi phụ thuộc endpoint nào trả kiểu gì.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'studentId': studentId,
    'userCode': userCode,
    'fullName': fullName,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phoneNumber,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'gender': gender,
    'address': address,
    'avatarUrl': avatarUrl,
    'emailConfirmed': emailConfirmed,
    'lastLoginTime': lastLoginTime?.toIso8601String(),
    'lastLogoutTime': lastLogoutTime?.toIso8601String(),
    'lastLoginLocation': lastLoginLocation,
  };
}
