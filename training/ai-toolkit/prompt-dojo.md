# Prompt Dojo — Luyện tập Prompt Engineering cho Flutter Developer

> "AI Dojo" — nơi luyện tập kỹ năng prompting như một skill chuyên môn. 10 bài thử thách từ cơ bản đến nâng cao.

---

## 1. Giới thiệu

### Prompt Engineering là gì?

Prompt engineering là kỹ năng viết yêu cầu cho AI tools (Copilot, ChatGPT, Claude) sao cho output chính xác, đúng context, và có thể sử dụng ngay. Giống như viết ticket/task description rõ ràng — prompt càng tốt, output càng chất lượng.

### Tại sao Flutter developer cần skill này?

- AI tools ngày càng phổ biến trong development workflow
- Prompt tốt = tiết kiệm 50%+ thời gian so với prompt tệ
- Kỹ năng này transferable — dùng được với mọi AI tool
- Phân biệt developer biết dùng AI vs developer phụ thuộc AI

### Cách sử dụng tài liệu này

1. Làm lần lượt 10 challenges (đã sắp xếp từ dễ → khó)
2. Mỗi challenge: đọc scenario → thử viết prompt TRƯỚC → so sánh với good prompt
3. Chạy prompt trong AI tool thực tế, đánh giá output
4. Tự chấm điểm theo rubric ở cuối tài liệu

---

## 2. Prompt Challenges

### Challenge 1: Widget cơ bản ⭐

**Scenario**: Cần tạo một `UserAvatar` widget hiển thị ảnh profile tròn, có fallback khi không có ảnh.

**❌ Bad Prompt**:
```
Tạo widget avatar Flutter
```
→ Output mơ hồ, thiếu specs, không đúng project convention.

**✅ Good Prompt**:
```
Tạo StatelessWidget `UserAvatar` trong Flutter:
- Props: String? imageUrl, double size (default 48), String fallbackText
- Hiển thị CircleAvatar với CachedNetworkImage nếu có imageUrl
- Fallback: hiển thị chữ cái đầu (fallbackText) trên nền màu primary
- Dùng Theme.of(context) cho colors
- Có const constructor
- Output chỉ code Dart, không cần giải thích
```

**Evaluation Criteria**:
- [ ] Prompt chỉ rõ widget type (Stateless vs Stateful)
- [ ] Nêu đủ props với types và defaults
- [ ] Chỉ rõ behavior: success case + fallback case
- [ ] Nêu styling approach (Theme)
- [ ] Chỉ định output format

---

### Challenge 2: State Management ⭐

**Scenario**: Cần tạo Riverpod provider quản lý danh sách todo items.

**❌ Bad Prompt**:
```
Viết provider cho todo list
```

**✅ Good Prompt**:
```
Tạo Riverpod AsyncNotifier cho Todo list:
- State: AsyncValue<List<Todo>> (Todo có: id, title, isCompleted)
- Methods: fetchTodos(), addTodo(title), toggleTodo(id), deleteTodo(id)
- fetchTodos gọi từ TodoRepository (đã có sẵn, inject qua ref)
- Handle loading, error, data states
- Dùng code generation syntax (@riverpod annotation)
- Todo model dùng freezed

Output:
1. Todo model (freezed)
2. TodoNotifier (AsyncNotifier)
3. Provider declaration
```

**Evaluation Criteria**:
- [ ] Nêu rõ state type (AsyncValue)
- [ ] Liệt kê methods cần thiết
- [ ] Chỉ rõ dependency (Repository) và cách inject
- [ ] Chỉ định code gen approach
- [ ] Output structure rõ ràng (3 phần)

---

### Challenge 3: API Integration ⭐

**Scenario**: Tạo data layer cho API endpoint lấy user profile.

**❌ Bad Prompt**:
```
Gọi API lấy user profile Flutter
```

**✅ Good Prompt**:
```
Tạo data layer cho Flutter project (Dio + retrofit pattern):

Endpoint: GET /api/v1/users/{userId}
Response JSON:
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "avatar_url": "https://...",
  "created_at": "2024-01-01T00:00:00Z"
}

Cần tạo:
1. UserProfile model (freezed + json_serializable, camelCase fields)
2. UserApiService (abstract class, retrofit annotation)
3. UserRepository (interface + implementation, return Either<AppException, UserProfile>)
4. Riverpod provider cho repository

Convention:
- json key `avatar_url` → field `avatarUrl`
- DateTime parse cho `created_at`
- Error handling: wrap Dio exceptions thành AppException
```

**Evaluation Criteria**:
- [ ] Cung cấp endpoint chi tiết (method, URL, response)
- [ ] Nêu rõ tech stack (Dio, retrofit, freezed)
- [ ] Chỉ ra conventions (naming, error handling)
- [ ] Output gồm đủ layers (model → service → repository → provider)
- [ ] Ví dụ JSON cụ thể

---

### Challenge 4: Debugging ⭐⭐

**Scenario**: App crash khi navigate tới profile page, error: "ProviderNotFoundException".

**❌ Bad Prompt**:
```
Flutter app crash ProviderNotFoundException sửa sao?
```

**✅ Good Prompt**:
```
Flutter app crash khi navigate tới ProfilePage.

Error: ProviderNotFoundException: No ProviderScope found.
Stack trace:
  - ProfilePage.build (profile_page.dart:25)
  - auto_route push '/profile'

Code ProfilePage:
```dart
class ProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    // ...
  }
}
```

App structure:
- main.dart có ProviderScope wrapping MaterialApp.router
- Dùng auto_route với AutoTabsRouter
- Router config nằm ngoài ProviderScope (nghi ngờ điểm này)

Hỏi:
1. Nguyên nhân chính xác?
2. Fix code cụ thể?
3. Cách tránh lỗi tương tự?
```

**Evaluation Criteria**:
- [ ] Cung cấp error message đầy đủ
- [ ] Paste relevant code
- [ ] Mô tả context (app structure, routing setup)
- [ ] Nêu giả thuyết của mình
- [ ] Câu hỏi cụ thể (cause, fix, prevention)

---

### Challenge 5: Testing ⭐⭐

**Scenario**: Viết unit test cho ViewModel quản lý form đăng ký.

**❌ Bad Prompt**:
```
Viết test cho registration form Flutter
```

**✅ Good Prompt**:
```
Viết unit tests cho RegistrationViewModel:

```dart
class RegistrationViewModel extends AsyncNotifier<RegistrationState> {
  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepoProvider).register(email, password);
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (user) => state = AsyncData(RegistrationState.success(user)),
    );
  }
  
  String? validateEmail(String email) { ... }
  String? validatePassword(String password) { ... }
}
```

Test requirements:
- Dùng mocktail cho AuthRepository mock
- Test cases:
  1. register thành công → state = success
  2. register thất bại (network error) → state = error
  3. register thất bại (invalid credentials) → state = error với message đúng
  4. validateEmail: valid, empty, invalid format
  5. validatePassword: valid, too short, no special char
- Pattern: arrange-act-assert
- Riverpod testing: dùng ProviderContainer
```

**Evaluation Criteria**:
- [ ] Paste implementation code để AI hiểu
- [ ] Liệt kê test cases cụ thể
- [ ] Chỉ rõ mocking library
- [ ] Nêu testing pattern (AAA)
- [ ] Chỉ cách test Riverpod (ProviderContainer)

---

### Challenge 6: UI Layout phức tạp ⭐⭐

**Scenario**: Tạo responsive product card grid cho e-commerce app.

**❌ Bad Prompt**:
```
Tạo product grid Flutter responsive
```

**✅ Good Prompt**:
```
Tạo responsive product card grid:

Layout:
- Mobile (<600px): 2 columns, card ratio 3:4
- Tablet (600-900px): 3 columns
- Desktop (>900px): 4 columns
- Gap giữa cards: 12px, padding: 16px

ProductCard spec:
- Image (top, aspect ratio 1:1, placeholder shimmer)
- Product name (max 2 lines, ellipsis)
- Price (bold, formatted VND: "đ 1.500.000")
- Rating stars (1-5, half stars)
- "Add to cart" button (bottom)

Constraints:
- Dùng SliverGrid (nằm trong CustomScrollView)
- Responsive breakpoint dùng MediaQuery hoặc LayoutBuilder
- Không dùng package bên ngoài cho responsive (chỉ Flutter SDK)
- Tối ưu: const constructor, RepaintBoundary cho mỗi card

Output: 2 files — ProductGrid widget và ProductCard widget
```

**Evaluation Criteria**:
- [ ] Breakpoints cụ thể (px values)
- [ ] Card specs chi tiết (image ratio, text lines, format)
- [ ] Chỉ rõ approach (SliverGrid, MediaQuery)
- [ ] Performance constraints
- [ ] Output structure (số files, tên files)

---

### Challenge 7: Architecture Decision ⭐⭐⭐

**Scenario**: Cần quyết định cách implement offline-first feature cho app.

**❌ Bad Prompt**:
```
Làm offline mode Flutter sao?
```

**✅ Good Prompt**:
```
Cần thiết kế offline-first architecture cho Flutter app:

Context:
- App hiện dùng clean architecture: data/domain/presentation layers
- State management: Riverpod
- API: REST, Dio client
- Local DB: chưa có (đang chọn giữa Isar, Drift, Hive)

Requirements:
- Danh sách items (1000-5000 records) cần có offline
- Sync strategy: optimistic UI, background sync khi có mạng
- Conflict resolution: server wins
- User biết trạng thái sync (synced, pending, failed)

Hỏi:
1. So sánh Isar vs Drift vs Hive cho use case này (table, pros/cons)
2. Repository pattern: làm sao abstract local vs remote data source?
3. Sync service design: khi nào sync, retry strategy
4. State management: model sync status trong Riverpod state
5. Diagram architecture (text-based)

Ưu tiên: giải pháp pragmatic, không over-engineer, phù hợp team 4 Flutter devs.
```

**Evaluation Criteria**:
- [ ] Context đầy đủ (current architecture, tech stack)
- [ ] Requirements cụ thể (scale, strategy, conflict handling)
- [ ] Câu hỏi structured (từ data layer đến UI)
- [ ] Constraints thực tế (team size, pragmatic)
- [ ] Yêu cầu output dạng diagram

---

### Challenge 8: Performance Optimization ⭐⭐⭐

**Scenario**: App bị jank khi scroll danh sách phức tạp.

**❌ Bad Prompt**:
```
Flutter list scroll chậm fix sao
```

**✅ Good Prompt**:
```
Flutter app bị jank (~40fps thay vì 60fps) khi scroll ListView:

Setup hiện tại:
- ListView.builder hiển thị 200+ items
- Mỗi item: ảnh (CachedNetworkImage), text, rating stars, animation shimmer
- Dùng Riverpod watch toàn bộ list state
- Rebuild toàn bộ list khi 1 item thay đổi (favorite toggle)

DevTools profiling (đã check):
- Build phase: ~12ms (quá cao, target <8ms)
- Paint phase: ~6ms  
- Nhiều unnecessary rebuilds khi scroll

Code (simplified):
```dart
class ItemList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemListProvider); // watch entire list
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) => ItemCard(item: items[i]), // no const, no key
    );
  }
}
```

Yêu cầu:
1. Phân tích nguyên nhân từ code trên
2. Suggest fixes theo thứ tự impact (cao → thấp)
3. Code example cho mỗi fix
4. Cách validate fix bằng DevTools

Tham khảo base_flutter project pattern.
```

**Evaluation Criteria**:
- [ ] Metrics cụ thể (fps, build time)
- [ ] Profiling data (đã dùng DevTools)
- [ ] Code có vấn đề được paste
- [ ] Yêu cầu prioritized fixes
- [ ] Yêu cầu validation method

---

### Challenge 9: CI/CD Pipeline ⭐⭐⭐

**Scenario**: Setup CI/CD cho Flutter project trên Codemagic.

**❌ Bad Prompt**:
```
Setup CI/CD Flutter Codemagic
```

**✅ Good Prompt**:
```
Setup CI/CD pipeline cho Flutter project trên Codemagic (codemagic.yaml):

Project specs:
- Flutter 3.24.x, Dart 3.5.x
- Flavors: develop, staging, production (dart_defines/ folder)
- Tests: unit + widget + golden tests
- Platforms: iOS + Android

Pipeline requirements:
1. PR check workflow:
   - Trigger: mỗi PR tới develop/main
   - Steps: analyze → format check → unit test → widget test
   - Fail fast: stop nếu step nào fail
   - Report: test results + coverage badge

2. Dev build workflow:
   - Trigger: merge vào develop
   - Build: APK (develop flavor) + IPA (develop flavor)
   - Distribute: Firebase App Distribution
   - Notify: Slack webhook

3. Release workflow:
   - Trigger: tag v*.*.*
   - Build: AAB (production) + IPA (production)
   - Sign: keystore (Android), provisioning profile (iOS)
   - Distribute: Google Play (internal track) + TestFlight
   - Notify: Slack + email

Environment variables cần:
- FIREBASE_TOKEN, SLACK_WEBHOOK_URL
- Android: KEYSTORE (base64), KEY_PASSWORD, KEY_ALIAS
- iOS: APP_STORE_CONNECT_KEY_ID, ISSUER_ID, P8_KEY

Output: codemagic.yaml hoàn chỉnh với comments giải thích mỗi section.
```

**Evaluation Criteria**:
- [ ] Nêu rõ 3 workflows riêng biệt
- [ ] Trigger conditions cụ thể
- [ ] Steps chi tiết cho mỗi workflow
- [ ] Environment variables liệt kê đủ
- [ ] Output format chỉ rõ (yaml + comments)

---

### Challenge 10: Full Feature Design ⭐⭐⭐

**Scenario**: Thiết kế toàn bộ architecture cho feature "Real-time Chat" trong Flutter app.

**❌ Bad Prompt**:
```
Thêm chat feature vào Flutter app
```

**✅ Good Prompt**:
```
Thiết kế architecture cho "Real-time Chat" feature trong Flutter app.

Existing app context:
- Clean architecture (data/domain/presentation), MVVM
- Riverpod, auto_route, Dio, freezed
- base_flutter project structure (lib/modules/[feature]/)
- Auth đã có: JWT token trong secure storage

Chat feature requirements:
- WebSocket connection cho real-time messages
- 1-on-1 chat (không group chat)
- Message types: text, image
- Offline queue: messages gửi khi offline, sync khi có mạng
- Read receipts (sent, delivered, read)
- Infinite scroll cho message history (API pagination)
- Push notification khi có tin nhắn mới

Cần output:
1. Folder structure (lib/modules/chat/...)
2. Domain layer: entities, use cases, repository interface
3. Data layer: WebSocket service, API service, local cache strategy
4. Presentation layer: screens, widgets, viewmodels
5. State management design: providers cần tạo, state classes
6. Navigation: routes cần thêm vào auto_route
7. Sequence diagram: send message flow (text-based)
8. Testing strategy: unit test nào, widget test nào

Constraints:
- Không dùng Firebase (backend custom REST + WebSocket)
- Tối ưu battery: reconnect strategy, heartbeat interval
- Message encryption: end-to-end không cần, TLS đủ

Style: pragmatic, phù hợp team 4 devs, ưu tiên ship nhanh iterative.
```

**Evaluation Criteria**:
- [ ] Context đầy đủ (existing architecture, auth, project structure)
- [ ] Requirements rõ ràng với scope cụ thể (1-on-1 only, text+image only)
- [ ] Output liệt kê đủ layers
- [ ] Technical constraints (no Firebase, battery optimization)
- [ ] Team/delivery constraints (pragmatic, 4 devs)

---

## 3. Prompt Templates cho Flutter Tasks

### Template: Widget

```
Tạo [Stateless/Stateful/Consumer]Widget [TenWidget]:
- Props: [danh sách props với types]
- Behavior: [mô tả tương tác]
- Styling: [Theme, specific colors/sizes]
- Constraints: [responsive, performance, accessibility]
Output: Dart code.
```

### Template: ViewModel / Notifier

```
Tạo [AsyncNotifier/StateNotifier] cho [feature]:
- State type: [AsyncValue<T> / custom state class]
- Methods: [danh sách methods với params]
- Dependencies: [repositories/services inject qua ref]
- Side effects: [navigation, show toast, etc.]
Output: Notifier class + provider declaration.
```

### Template: Bug Fix

```
Bug: [mô tả bug ngắn gọn]
Error: [paste error message]
Code: [paste relevant code]
Context: [Flutter version, packages, khi nào xảy ra]
Expected: [behavior mong muốn]
Actual: [behavior thực tế]
Hỏi: [nguyên nhân + fix + prevention]
```

### Template: Code Review

```
Review code sau theo tiêu chí:
- Flutter best practices
- Performance (rebuilds, const, keys)
- Error handling
- Naming conventions
- Architecture compliance ([pattern name])

[paste code]

Output: danh sách issues (severity: high/medium/low) + suggested fix.
```

---

## 4. Scoring Rubric cho Prompt Quality

| Tiêu chí | 0 điểm | 1 điểm | 2 điểm |
|----------|--------|--------|--------|
| **Context** | Không có context | Có context cơ bản | Context đầy đủ (tech stack, constraints) |
| **Specificity** | Quá chung chung | Có details nhưng thiếu | Đủ chi tiết để AI output usable |
| **Structure** | Dump text không format | Có format cơ bản | Structured rõ ràng (sections, lists) |
| **Constraints** | Không nêu constraints | Nêu 1-2 constraints | Đủ constraints (tech, performance, style) |
| **Output format** | Không chỉ định | Chỉ định chung | Chỉ rõ format, files, sections cần |
| **Actionability** | AI phải đoán nhiều | AI đoán ít | AI output dùng được ngay |

**Thang điểm** (tổng 12):
- **10-12**: ⭐⭐⭐ Master — prompts chuyên nghiệp, output quality cao
- **7-9**: ⭐⭐ Proficient — prompt tốt, cần tinh chỉnh output
- **4-6**: ⭐ Developing — cần cải thiện structure và context
- **0-3**: Beginner — cần luyện tập nhiều hơn

---

## 5. Tips nâng cao

1. **Chain prompts**: chia task lớn thành nhiều prompt nhỏ, mỗi prompt build on trước
2. **Few-shot learning**: paste 1 ví dụ code từ project → AI follow pattern
3. **Negative prompting**: nêu rõ "KHÔNG dùng X" để tránh suggestions không mong muốn
4. **Role setting**: "Bạn là senior Flutter developer review code của junior" → tone phù hợp
5. **Iterative refinement**: prompt lần 1 → check output → adjust prompt → re-run

---

## 6. Tài nguyên liên quan

- **AI tools guide**: [ai-driven-development.md](../ai-toolkit/ai-driven-development.md)
- **Study group operations**: [study-group-operations.md](../van-hanh-nhom/study-group-operations.md)
- **Capstone project**: [capstone-spec.md](../capstone/capstone-spec.md) — áp dụng prompting cho capstone

<!-- AI_VERIFY: generation-complete -->
