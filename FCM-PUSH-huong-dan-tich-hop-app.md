# Tích hợp thông báo cho app Flutter (`mobile/`)

Tài liệu để giao cho máy khác thực hiện. Backend đã xong và đã đẩy lên nhánh
`feat/fcm-push-notification` của repo `csharp_manage` — phần còn lại nằm hết ở app.

---

## 1. Bối cảnh: ba tầng thông báo

Hệ thống có ba tầng, **hai tầng đầu đã chạy**, tầng thứ ba là việc của tài liệu này.

| Tầng | Cơ chế | Khi nào tới được máy | Trạng thái |
|---|---|---|---|
| 1. Realtime | SignalR `NotificationHub` | App **đang mở** | ✅ Đã có |
| 2. Hộp thư | Bảng `Notifications` + `/api/notification` | User vào xem mới thấy | ✅ Đã có |
| 3. Push | FCM | App **đã tắt hẳn** | ⬜ Backend xong, app chưa làm |
| 4. Local | `flutter_local_notifications` | Hẹn giờ, offline | ⬜ Chưa làm |

Hai điểm dễ hiểu nhầm, đọc kỹ trước khi bắt tay:

- **FCM không thay thế được local notification.** Local do chính máy bắn, chạy offline,
  hẹn giờ được. FCM cần mạng và cần server. Muốn "còn 15 phút nữa tới ca thi" thì phải
  làm local, không có đường vòng.
- **Khi app đang mở, FCM KHÔNG tự hiện thông báo.** Android/iOS chỉ tự vẽ khi app ở
  background/quit. App đang foreground thì bạn phải tự gọi `flutter_local_notifications`
  để vẽ. Nghĩa là **kể cả chỉ làm push, vẫn phải cài gói local**.

---

## 2. ⚠️ Việc phải quyết TRƯỚC khi mở Firebase Console

Package name của app hiện đang **lệch nhau giữa hai nền tảng, và Android còn là tên mặc
định của Flutter**:

| Nền tảng | Giá trị hiện tại | Vấn đề |
|---|---|---|
| Android (`android/app/build.gradle.kts:24`) | `com.example.quizz_mobile` | `com.example.*` **Google Play từ chối**, không lên store được |
| iOS (`ios/Runner.xcodeproj`) | `com.natwodev1.quizzMobile` | Khác hẳn Android |

Firebase gắn cấu hình **chặt vào package name**. Đăng ký app với `com.example.quizz_mobile`
rồi sau này đổi tên thì phải tạo lại app trong Firebase Console và tải lại
`google-services.json` — làm lại từ đầu.

**Vì vậy: chốt package name cuối cùng trước, sửa cả hai nền tảng cho khớp, rồi mới sang
bước 3.** Đề xuất `com.natwodev1.quizzmobile` cho cả hai (Android không cho chữ hoa).

---

## 3. Firebase Console

1. Tạo project (hoặc dùng project sẵn có).
2. **Add app → Android**: nhập đúng `applicationId` đã chốt ở bước 2.
3. **Add app → iOS**: nhập đúng Bundle ID.
4. **iOS bắt buộc thêm**: vào Apple Developer → Keys → tạo **APNs Auth Key (`.p8`)**, rồi
   upload lên Firebase Console → Project Settings → Cloud Messaging.
   Thiếu bước này thì **Android chạy ngon còn iOS im hoàn toàn**, và không có thông báo lỗi
   nào — đây là lỗi tốn thời gian nhất khi mới làm.
5. Project Settings → Service accounts → **Generate new private key** → tải file JSON.
   File này dành cho **backend**, không đưa vào app. Xem mục 8.

---

## 4. Cài gói

```bash
cd mobile
flutter pub add firebase_core firebase_messaging flutter_local_notifications
flutter pub add timezone flutter_timezone      # chỉ cần nếu làm hẹn giờ
dart pub global activate flutterfire_cli
flutterfire configure                          # sinh lib/firebase_options.dart
```

`flutterfire configure` tự đặt `google-services.json` và `GoogleService-Info.plist` vào
đúng chỗ, đỡ được phần lớn thao tác tay.

Phiên bản tại thời điểm viết: `firebase_messaging` 16.5.0, `flutter_local_notifications`
22.3.0. App đang dùng Dart SDK `^3.9.0`.

### ⚠️ Bẫy API: `flutter_local_notifications` v20 đã đổi hết sang named parameters

Từ **v20.0.0**, `initialize()`, `show()`, `zonedSchedule()`, `cancel()` đã bỏ tham số vị trí,
và `details` đổi tên thành `notificationDetails`. **Gần như mọi tutorial google ra được đều
viết theo kiểu cũ và sẽ không compile.** Code dưới đây theo API v22.

---

## 5. Hợp đồng API với backend

Base URL lấy từ `dotenv.env['API_BASE_URL']`, mặc định `https://api.tracnghiem.online`
(xem `lib/services/base_service.dart`). Tất cả đều cần header
`Authorization: Bearer <token>`.

| Method | Endpoint | Body | Dùng khi |
|---|---|---|---|
| POST | `/api/push/register` | `{ token, platform, deviceInfo? }` | Sau khi lấy được FCM token, và mỗi lần token đổi |
| POST | `/api/push/unregister` | `{ token }` | **Trước khi** xoá JWT lúc đăng xuất |
| GET | `/api/push/status` | — | Kiểm tra backend đã gắn Firebase chưa |
| POST | `/api/push/send` | `{ title, body, userIds?, topic?, data? }` | Chỉ Teacher/Admin, để soạn tin thủ công |

`platform` nhận `android` \| `ios` \| `web`.

Backend trả về theo khuôn chung của dự án: `{ success, code }` hoặc `{ success, data }`.

**`register` là idempotent** — gọi lại bao nhiêu lần cũng chỉ giữ một dòng, đã kiểm chứng.
Cứ gọi thoải mái, không cần tự nhớ đã gửi hay chưa.

**Payload `data` backend gửi kèm** mỗi thông báo từ notification center:

```json
{ "notificationId": "...", "type": "...", "severity": "...", "linkUrl": "..." }
```

Dùng `type` / `linkUrl` để điều hướng khi user bấm vào thông báo.

---

## 6. Code phía app

### 6.1. Channel id phải khớp backend

Backend gửi kèm `ChannelId = "exam_notifications"`. **App phải tạo đúng channel id này**,
nếu không Android 8+ nhận được tin nhưng **không hiện gì cả** — im lặng, không lỗi.

```dart
const AndroidNotificationChannel kExamChannel = AndroidNotificationChannel(
  'exam_notifications',              // PHẢI trùng backend
  'Thông báo kỳ thi',
  description: 'Nhắc lịch thi, kết quả, thông báo từ giám thị',
  importance: Importance.high,
);
```

### 6.2. Handler nền phải là hàm top-level

```dart
@pragma('vm:entry-point')     // thiếu là bị tree-shaking xoá ở bản release
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Chạy trong isolate riêng — KHÔNG đụng được state/UI của app.
}
```

Phải là hàm top-level hoặc static, không được là closure hay method của class.

### 6.3. Khởi tạo

Đặt trong `main()` của `lib/main.dart`, **sau `dotenv.load()`**, trước `runApp()`:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
await PushService.instance.init();
```

```dart
class PushService {
  static final instance = PushService._();
  PushService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Tạo channel Android trước khi có tin nào tới
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(kExamChannel);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,   // xin riêng ở bước 2, đúng thời điểm
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (res) => _handleTap(res.payload),
    );

    // 2. Xin quyền hiện thông báo (Android 13+ và iOS đều cần)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 3. App ĐANG MỞ: FCM không tự vẽ, phải tự gọi local
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _local.show(
        id: msg.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'exam_notifications',
            'Thông báo kỳ thi',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(msg.data),
      );
    });

    // 4. User bấm vào thông báo lúc app ở background
    FirebaseMessaging.onMessageOpenedApp.listen((msg) => _handleTap(jsonEncode(msg.data)));

    // 5. App mở lên TỪ trạng thái tắt hẳn do bấm thông báo
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleTap(jsonEncode(initial.data));

    // 6. Đăng ký token với backend
    await _syncToken();
    _fcm.onTokenRefresh.listen((_) => _syncToken());
  }
}
```

Bước 5 hay bị bỏ sót: bấm thông báo khi app đã tắt thì `onMessageOpenedApp` **không**
bắn, phải đọc qua `getInitialMessage()`.

### 6.4. Đồng bộ token

```dart
Future<void> _syncToken() async {
  // Chưa đăng nhập thì đăng ký sẽ 401 — chờ đăng nhập xong rồi gọi lại
  if (!SessionController.instance.signedIn) return;

  final token = await _fcm.getToken();
  if (token == null) return;

  await BaseService().post('/api/push/register', {
    'token': token,
    'platform': Platform.isIOS ? 'ios' : 'android',
    'deviceInfo': await _deviceLabel(),
  });
}
```

Gọi `_syncToken()` ở **hai chỗ**: lúc `init()`, và **ngay sau khi đăng nhập thành công** —
lần đầu cài app thì `init()` chạy khi chưa có token JWT nên sẽ bị bỏ qua.

### 6.5. Đăng xuất — đừng bỏ qua

```dart
Future<void> logout() async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    // PHẢI gọi trước khi xoá JWT, sau đó thì request nào cũng 401
    await BaseService().post('/api/push/unregister', {'token': token});
  }
  await BaseService().removeToken();
}
```

Bỏ bước này thì **máy vẫn nhận thông báo của tài khoản vừa thoát** — lộ thông tin trên máy
dùng chung, đúng kiểu máy phòng thi.

---

## 7. Cấu hình nền tảng

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<application>
  <receiver android:exported="false"
      android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
  <receiver android:exported="false"
      android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
      <action android:name="android.intent.action.BOOT_COMPLETED"/>
      <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
      <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
  </receiver>
</application>
```

`RECEIVE_BOOT_COMPLETED` + boot receiver chỉ cần khi làm hẹn giờ, nhưng **thiếu nó thì user
khởi động lại máy là bay sạch lịch đã đặt**.

`android/app/build.gradle.kts` — bật desugaring, `compileSdk` tối thiểu 35:

```kotlin
compileOptions { isCoreLibraryDesugaringEnabled = true }
dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
```

### iOS — `ios/Runner/AppDelegate.swift`

```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```

Xcode → Signing & Capabilities → thêm **Push Notifications** và **Background Modes**
(tick *Remote notifications*).

---

## 8. Bật phía backend

Backend đã sẵn sàng, chỉ thiếu credential. Người giữ server làm:

```bash
base64 -i firebase-service-account.json | tr -d '\n'
```

Bỏ chuỗi đó vào `csharp_manage/.env`:

```
FIREBASE_SERVICE_ACCOUNT_BASE64=ewogICJ0eXBlIjo...
```

rồi `docker compose up -d --build backend`.

Base64 chứ không phải JSON thô: JSON gốc có dấu nháy, `=` và `\n` trong private key nên
parser `.env` sẽ cắt sai.

**File JSON gốc tuyệt đối không commit.** `.gitignore` của `csharp_manage` đã chặn sẵn
`firebase-service-account*.json` và `*-firebase-adminsdk-*.json`.

Kiểm tra bật thành công: `GET /api/push/status` trả `{"enabled": true}`. Chưa cấu hình thì
trả `false` và mọi lệnh gửi thành no-op — backend vẫn chạy bình thường, không sập.

---

## 9. Cách test

Theo thứ tự này, mỗi bước cô lập một mắt xích:

1. **Đường dây FCM có thông không** — Firebase Console → Messaging → Campaigns → soạn tin →
   "Send test message" → dán FCM token của máy. Không cần backend tham gia.
2. **Từng trạng thái app** — thử đủ ba: app đang mở (phải tự vẽ bằng local), app
   background, app đã kill hẳn.
3. **Backend → app** — gọi `POST /api/push/send` bằng tài khoản Teacher với `userIds`.
4. **Luồng thật** — tạo một thông báo qua notification center, xác nhận nhận được cả
   SignalR (app mở) lẫn push (app tắt).

Test trên **máy thật**. iOS **không nhận push trên simulator** — hạn chế của Apple, không
phải lỗi cấu hình.

---

## 10. Bảng bẫy

| Triệu chứng | Nguyên nhân |
|---|---|
| iOS im hoàn toàn, Android bình thường | Chưa upload APNs `.p8` lên Firebase Console |
| Nhận được tin nhưng không hiện gì (Android) | Channel id không khớp `exam_notifications` |
| App đang mở thì không thấy thông báo | Đúng như thiết kế — phải tự gọi `_local.show()` trong `onMessage` |
| Đổi âm thanh/importance không ăn | Android khoá cấu hình channel sau lần tạo đầu. Phải đổi channel id mới hoặc gỡ app cài lại |
| Handler nền không chạy ở bản release | Thiếu `@pragma('vm:entry-point')` |
| Bấm thông báo lúc app đã tắt thì không điều hướng | Chưa xử lý `getInitialMessage()` |
| `register` trả 401 | Gọi trước khi đăng nhập — chờ có JWT rồi gọi lại |
| Hẹn giờ mất sau khi khởi động máy | Thiếu `RECEIVE_BOOT_COMPLETED` + boot receiver |
| `ExactAlarmPermissionException` (Android 14+) | `SCHEDULE_EXACT_ALARM` không còn tự được cấp qua manifest, phải gọi `requestExactAlarmsPermission()` và có nhánh fallback |
| Máy Xiaomi/Oppo/Vivo hay mất thông báo | Battery optimization của hãng. Cần hướng dẫn user bật Autostart |

---

## 11. Ghi chú kỹ thuật: FID vs registration token

FirebaseAdmin 3.6 đánh dấu `MulticastMessage.Tokens` là `[Obsolete]`, khuyên chuyển sang
**Fids** (Firebase Installation ID). Backend **cố ý chưa chuyển**, lý do:

`firebase_messaging` của Flutter (16.5.0, bản mới nhất) vẫn chỉ trả registration token qua
`getToken()`, **chưa có API nào lấy FID**. Đổi backend sang Fids bây giờ là nhận một loại
định danh mà app không tạo ra được.

Google xác nhận hai đường được hỗ trợ song song và **chưa công bố ngày tắt**. Rà lại khi
FlutterFire ra API FID. Ghi chú này cũng nằm trong comment tại
`PushNotificationService.cs`.

---

## 12. Việc cần làm — tóm tắt

- [ ] Chốt và thống nhất package name Android/iOS (**làm trước tiên**)
- [ ] Tạo Firebase project, add app Android + iOS
- [ ] Upload APNs `.p8` cho iOS
- [ ] `flutterfire configure`
- [ ] Cài `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
- [ ] Viết `PushService` (mục 6)
- [ ] Nối `_syncToken()` vào luồng đăng nhập
- [ ] Nối `unregister` vào luồng đăng xuất
- [ ] Cấu hình AndroidManifest + AppDelegate + Xcode capabilities
- [ ] Nhờ người giữ server bỏ `FIREBASE_SERVICE_ACCOUNT_BASE64` vào `.env`
- [ ] Test theo mục 9 trên máy thật, cả Android lẫn iOS
- [ ] (Tuỳ chọn) Làm local notification hẹn giờ nhắc trước ca thi
