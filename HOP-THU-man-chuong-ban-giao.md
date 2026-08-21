# Màn chuông trong app — bàn giao

Backend đã xong và **đang chạy thật**. Toàn bộ việc còn lại nằm ở app Flutter.

Tài liệu này chỉ nói phần hộp thư. Phần tích hợp FCM nền tảng (Firebase Console,
`google-services.json`, quyền, channel id) nằm ở [`FCM-PUSH-huong-dan-tich-hop-app.md`](./FCM-PUSH-huong-dan-tich-hop-app.md)
và **đã làm xong cho Android** — đừng làm lại.

---

## 1. Nguyên tắc, đọc trước khi viết dòng nào

**Máy chủ giữ bản thật. FCM chỉ là tiếng gõ cửa.**

Push không mang nội dung để app lưu lại — nó mang cái khoá để app tra về máy chủ.
Danh sách trong chuông **luôn** lấy từ `GET /api/notification`.

### Vì sao không để app tự lưu tin FCM làm danh sách

Tin gửi kèm phần `notification` (không phải data-only). Khi app ở nền hoặc đã tắt thì
**hệ điều hành xử lý trọn, app không chạy dòng nào**. Sinh viên không bấm vào thông báo
là app không bao giờ biết tin đó tồn tại → danh sách chuông thiếu tin mà không ai phát
hiện. Chưa kể cài lại app là mất sạch, và đọc trên web rồi mở app vẫn thấy chưa đọc.

Handler nền `firebaseMessagingBackgroundHandler` trong `lib/services/notification/push_service.dart`
để trống **là cố ý**. Đừng thêm việc vẽ thông báo vào đó — OS đã vẽ rồi, thêm nữa là hiện hai cái.

---

## 2. API

Dùng `BaseService` sẵn có (đã tự gắn `Authorization: Bearer <JWT>`).

Trước đây cả `NotificationController` đòi quyền Teacher/Admin nên sinh viên gọi vào là
**403**. Đã sửa: các endpoint đọc chỉ cần đăng nhập, và tự lọc theo người đang đăng nhập
nên không đọc được thư của người khác.

### `GET /api/notification`

Query: `unread` (bool, mặc định false), `page` (mặc định 1), `pageSize` (mặc định 20, tối đa 100).

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "019f16a2-....",
        "type": "TeacherMessage",
        "severity": "Medium",
        "title": "7h30 mở phòng thi",
        "message": "Có mặt trước 15 phút.",
        "linkUrl": null,
        "isRead": false,
        "createdAt": "2026-08-21T09:02:11.123456Z",
        "examSessionSubjectId": null,
        "studentExamSessionId": null
      }
    ],
    "unreadCount": 1,
    "page": 1,
    "total": 1
  }
}
```

Sắp xếp sẵn theo `createdAt` giảm dần — tin mới nhất ở đầu mảng.

### `GET /api/notification/unread-count`

```json
{ "success": true, "data": { "unreadCount": 3 } }
```

### `PATCH /api/notification/{id}/read`

```json
{ "success": true, "code": "NOTIFICATION_MARK_READ_SUCCESS" }
```

Đọc thư của người khác → **403 với body rỗng** (không phải JSON). Đừng parse body ở nhánh này.

### `PATCH /api/notification/read-all`

```json
{ "success": true, "code": "NOTIFICATION_MARK_ALL_READ_SUCCESS" }
```

### `DELETE /api/notification/{id}`

Sinh viên tự gỡ một thư khỏi chuông của mình — dùng cho thao tác vuốt-để-xoá.

```json
{ "success": true, "code": "NOTIFICATION_DELETE_SUCCESS", "data": { "deletedCount": 1 } }
```

Xoá thư của người khác → **403 body rỗng**, y như `PATCH {id}/read`. Thư đã gỡ rồi mà
gọi lại → **404**.

### `DELETE /api/notification/all`

Dọn sạch chuông của chính mình.

```json
{ "success": true, "code": "NOTIFICATION_DELETE_ALL_SUCCESS", "data": { "deletedCount": 7 } }
```

### ⚠️ "Xoá" ở đây là gỡ khỏi chuông, không phải xoá khỏi hệ thống

Máy chủ đánh dấu `HiddenByRecipient` chứ không xoá dòng. Sinh viên không còn thấy nó ở
bất kỳ đâu — danh sách, số chưa đọc, đánh dấu đã đọc đều bỏ qua — nhưng giám thị vẫn
thấy trong trang quản lí kèm nhãn "Người nhận đã gỡ".

Cố ý như vậy: nếu xoá hẳn thì sinh viên sửa được lịch sử gửi của giám thị, con số
"đã gửi cho 603 người" sẽ tụt dần mỗi lần có người dọn hộp thư.

App **không cần biết** cờ này — API đã lọc sẵn, cứ gọi rồi tải lại danh sách.

---

## 3. Các trường trong một thông báo

| Trường | Dùng để làm gì |
|---|---|
| `type` | Chọn biểu tượng. Hiện có `TeacherMessage` (giám thị gửi), `Violation`, `VpnDetected`. **Phải có nhánh mặc định** cho kiểu lạ — backend thêm kiểu mới không báo trước. |
| `severity` | `Low` / `Medium` / `High`. Dùng để tô màu hoặc ghim lên đầu. |
| `linkUrl` | **Luôn null với thông báo cho sinh viên.** Cột này chứa route của WEB (`/teacher-monitor/...`), cố ý không dùng cho app. Đừng parse. |
| `examSessionSubjectId` | Dữ liệu điều hướng. Có giá trị thì mở được màn ca thi tương ứng. |
| `isRead` | Trạng thái đã đọc, đồng bộ với web. |

---

## 4. Payload FCM

```
notification: { title, body }        ← OS tự vẽ khi app ở nền/đã tắt
data: {
  "type":     "TeacherMessage",
  "severity": "Medium"
}
```

### ⚠️ Gửi hàng loạt KHÔNG có `notificationId`

Multicast là **một** message dùng chung cho nhiều token, mà mỗi người lại có id thông báo
riêng — không nhét id riêng vào message chung được.

- Gửi **lẻ** (thông báo vi phạm cho giáo viên): data **có** `notificationId`, `linkUrl`.
- Gửi **hàng loạt** (giám thị bắn cho sinh viên): data **chỉ có** `type`, `severity`.

Nên app phải xử lý được cả hai: có `notificationId` thì mở thẳng tin đó; không có thì mở
màn chuông rồi tải lại danh sách — tin mới nhất nằm trên cùng.

---

## 5. Việc phải làm

### 5.1. Thay ruột `lib/screens/notification/notification_screen.dart`

File hiện là cái vỏ rỗng. Comment trong đó ghi *"Backend chưa có endpoint thông báo nào"*
— **câu đó đã sai**, xoá đi khi sửa.

Cần: danh sách phân trang, kéo để tải lại, phân biệt đã đọc/chưa đọc, bấm vào thì gọi
`PATCH {id}/read` rồi cập nhật tại chỗ. Giữ nguyên khung `Scaffold` + `AppBar` sẵn có,
và giữ trạng thái rỗng hiện tại cho trường hợp thật sự không có thư.

Thêm vuốt-để-xoá (`Dismissible`) gọi `DELETE {id}`, và một nút "dọn tất cả" trên AppBar
gọi `DELETE /all`. Gỡ xong nhớ cập nhật badge — số chưa đọc đổi theo.

### 5.2. Badge trên nút chuông

Gọi `unread-count` khi mở app và sau mỗi lần nhận push. Không cần polling.

### 5.3. Ba handler FCM

| Handler | Khi nào chạy | Việc |
|---|---|---|
| `onMessage` | App đang mở | Vẽ local notification hoặc snackbar, tăng badge, tải lại nếu đang ở màn chuông |
| `onMessageOpenedApp` | Bấm push, app ở nền | Mở màn chuông (có `notificationId` thì mở đúng tin) |
| `getInitialMessage` | Bấm push, app **đã tắt hẳn** | Y hệt trên |

**`getInitialMessage` là chỗ hay quên nhất.** Thiếu nó thì bấm thông báo lúc app đã tắt
sẽ vào thẳng màn chính, mất ngữ cảnh, và lỗi này chỉ lộ khi thử trên máy thật với app đã
bị kill — chạy debug bình thường không thấy.

### 5.4. Cache offline

Lưu trang đầu của `GET /api/notification` xuống máy để mất mạng vẫn mở chuông xem được tin cũ.
Đây là **cache**, không phải nguồn sự thật: có mạng là ghi đè bằng dữ liệu máy chủ, không merge.

---

## 6. Đã có sẵn, đừng làm lại

| Thứ | Ở đâu |
|---|---|
| `firebase_core`, `firebase_messaging`, `flutter_local_notifications` | `pubspec.yaml` |
| `google-services.json` (Android) | `android/app/` |
| Xin quyền, lấy token, `onTokenRefresh` | `lib/services/notification/push_service.dart` |
| Đăng ký / gỡ token (`api/push/register`, `api/push/unregister`) | cùng file trên |
| Handler nền top-level đúng chuẩn `@pragma('vm:entry-point')` | cùng file trên |
| Vẽ local notification | `lib/services/notification/local_notification_service.dart` |

**Còn thiếu:** iOS chưa có `GoogleService-Info.plist` và APNs key. Android chạy được trước,
iOS bù sau — không chặn phần màn chuông.

---

## 7. Cách thử

1. **Gửi từ web:** Danh sách sinh viên → nút chuông tím "Gửi thông báo" → chọn sinh viên
   hoặc "toàn bộ" → nhập tiêu đề, nội dung → Gửi.
2. **Hoặc gửi bằng curl** với token giáo viên (tài khoản seed nằm trong
   `csharp_manage/backend_manage/backend_manage.core/Data/DbSeeder.cs`):

```bash
curl -X POST http://localhost:5000/api/notification/send \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"title":"Thử","message":"Nội dung thử","studentIds":["<StudentId>"]}'
```

Kết quả trả về nói rõ chuyện gì đã xảy ra:

```json
{ "storedCount": 2, "skippedUnknownCount": 1,
  "push": { "successCount": 1, "targetedUserCount": 1, "noDeviceUserCount": 1 } }
```

- `storedCount` — số thư đã lưu, tức số người sẽ thấy trong chuông
- `push.successCount` — số **thiết bị** nhận được tiếng gõ cửa
- `noDeviceUserCount` — số người chưa cài app; họ **vẫn có thư**
- `skippedUnknownCount` — id không khớp sinh viên nào

3. **Kiểm chuông:** đăng nhập app bằng đúng sinh viên đó, mở chuông, phải thấy tin.

### Ba trạng thái phải thử trên máy thật

App đang mở → app ở nền → app đã kill hẳn. Ba đường đi khác nhau trong code, và chỉ có
trạng thái thứ ba lộ ra lỗi thiếu `getInitialMessage`.

---

## 8. Định danh — đã khớp sẵn, đừng ánh xạ lại

JWT của sinh viên có `NameIdentifier` = **StudentId**. Cùng một id đó được dùng cho
`DeviceToken.UserId` và `Notification.RecipientUserId`. App không phải đổi id sang dạng nào khác.

---

## 9. Trạng thái backend

Đã merge vào `main` và đang chạy. Toàn bộ đã kiểm bằng lệnh thật trên bản đang chạy:

- Gửi: 2 thư lưu đúng, 1 id rác bị loại, 1 thiết bị Android nhận push, 1 sinh viên không
  có máy vẫn có thư.
- Đọc: gọi bằng token, ra 200 kèm danh sách (trước đây sinh viên bị 403).
- Tự gỡ: xoá 1 thư → hộp thư 2 còn 1, số chưa đọc giảm theo; `DELETE /all` → về 0;
  gỡ thư người khác → 403 và thư đó không hề bị đụng.

Dữ liệu test đã xoá.

Phía web còn có trang quản lí (gom theo lượt gửi, đếm đã đọc, thu hồi cả lượt) nằm trong
Danh sách sinh viên → nút chuông. App không cần quan tâm, chỉ cần biết một lượt gửi bị
thu hồi thì thư biến khỏi `GET /api/notification` — nên đừng cache vĩnh viễn.
