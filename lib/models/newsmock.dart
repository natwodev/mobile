class NewsMock {
  final String title;
  final String imageUrl;
  final String content;
  final String author;
  final DateTime publishedAt;

  NewsMock({
    required this.title,
    this.imageUrl = 'https://via.placeholder.com/150',
    required this.content,
    required this.author,
    required this.publishedAt,
  });
}

final List<NewsMock> newsMockData = [
  NewsMock(
    title: "Thông báo lịch thi học kỳ 2 năm 2024",
    content:
        "Kính gửi sinh viên, lịch thi học kỳ 2 sẽ diễn ra từ ngày 15/06 đến 30/06. Vui lòng kiểm tra lịch thi chi tiết trên hệ thống và chuẩn bị đầy đủ giấy tờ tùy thân.",
    author: "Phòng Đào tạo",
    publishedAt: DateTime(2024, 6, 1, 8, 30),
  ),
  NewsMock(
    title: "Khai giảng học kỳ 1 năm học 2024-2025",
    content:
        "Trường Đại học Công nghệ TP.HCM thông báo lịch khai giảng chính thức năm học mới vào ngày 02/09/2024. Sinh viên cần có mặt đúng giờ tại hội trường A.",
    author: "Ban Giám hiệu",
    publishedAt: DateTime(2024, 8, 25, 14, 15),
  ),
  NewsMock(
    title: "Hội thảo Khoa học Công nghệ 2024",
    content:
        "Khoa Công nghệ Thông tin tổ chức hội thảo về AI và Machine Learning. Thời gian: 9h00 ngày 15/10/2024. Địa điểm: Phòng hội thảo B203. Đăng ký tham gia qua email.",
    author: "Khoa CNTT",
    publishedAt: DateTime(2024, 10, 5, 9, 0),
  ),
  NewsMock(
    title: "Thông báo nghỉ lễ Quốc khánh 2/9",
    content:
        "Nhà trường thông báo lịch nghỉ lễ Quốc khánh từ ngày 31/08 đến 03/09/2024. Sinh viên lưu ý điều chỉnh lịch học và ôn tập.",
    author: "Văn phòng Khoa",
    publishedAt: DateTime(2024, 8, 20, 16, 45),
  ),
  NewsMock(
    title: "Tuyển sinh Cao học khóa 2024",
    content:
        "Trường mở đợt tuyển sinh Cao học năm 2024 với các ngành: Khoa học máy tính, Kỹ thuật phần mềm, An toàn thông tin. Hạn nộp hồ sơ: 30/11/2024.",
    author: "Phòng Sau đại học",
    publishedAt: DateTime(2024, 10, 15, 10, 20),
  ),
  NewsMock(
    title: "Hướng dẫn đăng ký học phần học kỳ 2",
    content:
        "Sinh viên lưu ý thời gian đăng ký học phần học kỳ 2 từ ngày 05/12 đến 15/12/2024. Vui lòng đăng nhập hệ thống để đăng ký môn học và kiểm tra lịch học.",
    author: "Phòng Đào tạo",
    publishedAt: DateTime(2024, 11, 25, 13, 30),
  ),
  NewsMock(
    title: "Chương trình học bổng Merit 2024",
    content:
        "Nhà trường công bố danh sách sinh viên đạt học bổng Merit năm 2024. Sinh viên được nhận học bổng vui lòng liên hệ phòng CTSV để hoàn tất thủ tục.",
    author: "Phòng CTSV",
    publishedAt: DateTime(2024, 9, 10, 11, 0),
  ),
  NewsMock(
    title: "Triển khai hệ thống quản lý mới",
    content:
        "Từ ngày 01/01/2025, trường sẽ triển khai hệ thống quản lý học tập mới với giao diện thân thiện hơn. Sinh viên vui lòng cập nhật thông tin cá nhân.",
    author: "Trung tâm CNTT",
    publishedAt: DateTime(2024, 12, 20, 15, 10),
  ),
  NewsMock(
    title: "Cuộc thi lập trình HUTECH Code Challenge 2024",
    content:
        "Khoa CNTT tổ chức cuộc thi lập trình dành cho sinh viên toàn trường. Giải thưởng hấp dẫn lên đến 50 triệu đồng. Đăng ký trước ngày 20/11/2024.",
    author: "CLB Lập trình",
    publishedAt: DateTime(2024, 11, 1, 9, 45),
  ),
  NewsMock(
    title: "Workshop: Kỹ năng phỏng vấn cho sinh viên IT",
    content:
        "Phòng Quan hệ Doanh nghiệp tổ chức workshop về kỹ năng phỏng vấn và viết CV cho sinh viên ngành CNTT. Thời gian: 14h00 thứ 7, ngày 07/12/2024.",
    author: "Phòng QHDN",
    publishedAt: DateTime(2024, 12, 1, 14, 0),
  ),
  NewsMock(
    title: "Thông báo về việc đóng học phí học kỳ 2",
    content:
        "Sinh viên cần hoàn tất đóng học phí học kỳ 2 trước ngày 10/01/2025. Sinh viên có hoàn cảnh khó khăn vui lòng liên hệ phòng Tài chính để được hỗ trợ.",
    author: "Phòng Tài chính",
    publishedAt: DateTime(2024, 12, 15, 8, 0),
  ),
  NewsMock(
    title: "Lễ tốt nghiệp sinh viên khóa 2020-2024",
    content:
        "Lễ tốt nghiệp cho sinh viên khóa 2020-2024 sẽ được tổ chức vào ngày 20/07/2024 tại Hội trường Lớn. Sinh viên đủ điều kiện tốt nghiệp vui lòng đăng ký tham dự.",
    author: "Ban Giám hiệu",
    publishedAt: DateTime(2024, 6, 20, 7, 30),
  ),
];
