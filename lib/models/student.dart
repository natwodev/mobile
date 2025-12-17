class student {
  int? studentId;
  String? studentCode;
  String? firstName;
  String? lastName;
  String? gender;
  String? dateOfBirth;
  bool? isLogin;
  DateTime? lastLoggedIn;
  DateTime? lastLoggedOut;
  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  bool? isDeleted;
  int? version;

  student({
    this.studentId,
    this.studentCode,
    this.firstName,
    this.lastName,
    this.gender,
    this.dateOfBirth,
    this.isLogin,
    this.lastLoggedIn,
    this.lastLoggedOut,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.isDeleted,
    this.version,
  });
  // Tạo factory để parse từ JSON
  factory student.fromJson(Map<String, dynamic> json) => student(
    studentId: json['studentId'],
    studentCode: json['studentCode'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    gender: json['gender'],
    dateOfBirth: json['dateOfBirth'],
    isLogin: json['isLogin'],
    lastLoggedIn: json['lastLoggedIn'] != null
        ? DateTime.parse(json['lastLoggedIn'])
        : null,
    lastLoggedOut: json['lastLoggedOut'] != null
        ? DateTime.parse(json['lastLoggedOut'])
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
    createdBy: json['createdBy'],
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : null,
    updatedBy: json['updatedBy'],
    isDeleted: json['isDeleted'],
    version: json['version'],
  );
}
