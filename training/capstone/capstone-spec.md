# Capstone Project Specification — User Profile Feature

> Bài tập tổng hợp cuối chương trình đào tạo Flutter. Áp dụng kiến thức từ M0–M19 để xây dựng feature hoàn chỉnh trên `base_flutter` project.

---

## 🗺️ Capstone Path — Lộ trình Capstone

Training curriculum có **3 điểm capstone** theo mức độ tăng dần:

| # | Tên | Module | Mục đích | Prerequisite |
|---|-----|--------|----------|--------------|
| 1 | **Mini Capstone: Login Flow** | [Module 15](../module-15-capstone-login/) | Tổng hợp M1-M14: navigation, state, API, error handling, storage | Hoàn thành M0-M14 |
| 2 | **CI/CD Pipeline** | [Module 19](../module-19-cicd/) | Build + deploy pipeline cho app đã xây dựng | Hoàn thành M0-M18 |
| 3 | **Full Capstone Project** | Tài liệu này ↓ | Xây dựng feature hoàn chỉnh end-to-end từ spec | Hoàn thành M0-M19 |

> 💡 **Gợi ý:** Hoàn thành Mini Capstone (M15) trước để kiểm tra kiến thức nền tảng. Full Capstone Project dưới đây yêu cầu tất cả concepts từ toàn bộ curriculum.

---

## 1. Tổng quan

### Mục tiêu
Mở rộng `base_flutter` app với feature **User Profile Page** — một feature hoàn chỉnh bao gồm CRUD operations, photo upload, form validation, state management, testing, và CI/CD.

### Tại sao User Profile?
- Cover hầu hết modules trong chương trình (architecture → UI → API → testing)
- Đủ phức tạp để đánh giá năng lực middle-level
- Đủ đơn giản để hoàn thành trong 1 tuần
- Real-world feature — mọi app đều cần

### Scope
- **In scope**: User profile CRUD, avatar upload, form validation, settings
- **Out of scope**: Social features, chat, notification, real-time updates

---

## 2. Feature Specification

### 2.1 Màn hình chính: Profile Page

**Route**: `/profile`

**UI Components**:
- Header: avatar (tròn, 120px), tên, email
- Section "Thông tin cá nhân": tên, email, số điện thoại, ngày sinh
- Section "Cài đặt": ngôn ngữ, dark mode toggle, notification on/off
- Button "Chỉnh sửa" → navigate tới Edit Profile
- Button "Đăng xuất" → confirm dialog → logout

**State**:
- Loading: shimmer placeholder
- Data: hiển thị profile info
- Error: retry button + error message

### 2.2 Màn hình Edit Profile

**Route**: `/profile/edit`

**Form Fields**:

| Field | Type | Validation | Required |
|-------|------|-----------|----------|
| Avatar | Image picker (camera/gallery) | Max 5MB, JPG/PNG | Không |
| Họ tên | TextField | 2-50 ký tự, không special chars | Có |
| Email | TextField | Email format, hiển thị nhưng không cho sửa | — |
| Số điện thoại | TextField | 10-11 số, bắt đầu bằng 0 | Không |
| Ngày sinh | DatePicker | Không lớn hơn today, tuổi ≥ 16 | Không |
| Bio | TextField (multiline) | Max 200 ký tự, character counter | Không |

**Behaviors**:
- Unsaved changes warning: nếu user nhấn back khi có thay đổi → confirm dialog
- Save: validate → API call → show loading → success toast / error message
- Avatar upload: chọn ảnh → crop (1:1) → compress → upload → hiển thị preview

### 2.3 API Endpoints

**GET** `/api/v1/users/me`
```json
{
  "id": 1,
  "name": "Nguyễn Văn A",
  "email": "a@example.com",
  "phone": "0901234567",
  "date_of_birth": "1995-06-15",
  "bio": "Flutter developer",
  "avatar_url": "https://cdn.example.com/avatars/1.jpg",
  "settings": {
    "language": "vi",
    "dark_mode": false,
    "notification_enabled": true
  }
}
```

**PUT** `/api/v1/users/me`
```json
{
  "name": "Nguyễn Văn A (updated)",
  "phone": "0901234568",
  "date_of_birth": "1995-06-15",
  "bio": "Senior Flutter developer"
}
```
Response: updated user object (same format as GET).

**POST** `/api/v1/users/me/avatar` (multipart/form-data)
```
file: <image binary>
```
Response:
```json
{
  "avatar_url": "https://cdn.example.com/avatars/1_new.jpg"
}
```

> **Lưu ý**: API là mock — dùng mock server hoặc interceptor trong Dio. Không cần backend thật.

### 2.4 Settings

| Setting | Type | Behavior |
|---------|------|----------|
| Language | Dropdown (vi/en/ja) | Thay đổi ngôn ngữ app ngay lập tức, persist local |
| Dark mode | Switch | Toggle theme, persist local |
| Notification | Switch | Toggle push notification permission |

---

## 3. Technical Requirements — Module Mapping

### M0 — Dart Primer
- [ ] Sử dụng null safety đúng cách (nullable fields: phone, bio, avatar_url)
- [ ] Extension methods cho String validation
- [ ] Generic type cho API response wrapper

### M1 — App Entrypoint
- [ ] Feature chạy đúng trên cả develop và staging flavor
- [ ] Environment-specific API URL

### M2 — Architecture
- [ ] Đúng clean architecture layers (theo convention base_flutter):
  - `lib/data_source/` — API service, repository implementation
  - `lib/model/` — data models, entities
  - `lib/ui/page/profile/` — pages, widgets, viewmodels
- [ ] Dependency flow: ui → data_source → model

### M3 — Common Layer
- [ ] Dùng AppTheme cho tất cả styling (không hardcode colors/sizes)
- [ ] Assets: default avatar image trong `assets/images/`
- [ ] Shared widgets: nếu dùng lại widget có sẵn trong `base_flutter`

### M4 — Exception Handling
- [ ] AppException cho API errors
- [ ] Result type (`Result.fromAsyncAction` + `runCatching`) cho repository/ViewModel methods
- [ ] User-friendly error messages (không show raw error)

### M5 — Navigation
- [ ] Routes trong auto_route: `/profile`, `/profile/edit`
- [ ] Navigation guard: redirect về login nếu chưa auth
- [ ] Back navigation: xử lý unsaved changes warning

### M6 — Resource & Theme Layer
- [ ] Responsive layout (handle safe area, keyboard, orientation)
- [ ] Proper widget composition (extract widgets khi > 50 lines)
- [ ] `const` constructors cho stateless widgets

### M7 — Base ViewModel & Page
- [ ] ProfileViewModel extends BaseViewModel
- [ ] EditProfileViewModel cho form logic
- [ ] Base classes cho loading/error/success states (CommonState)

### M8 — State Management (Riverpod)
- [ ] Profile state provider (StateNotifierProvider.autoDispose — theo convention base_flutter)
- [ ] Form state management cho edit profile
- [ ] Provider scoping đúng (auto-dispose khi rời page)
- [ ] Optimistic update cho settings toggle

### M9 — Page Structure & UI Components
- [ ] ProfilePage follows base_flutter page pattern
- [ ] Reusable form field components
- [ ] Shimmer loading skeleton

### M10 — Hooks
- [ ] `useTextEditingController` cho form fields
- [ ] `useMemoized` cho computed values
- [ ] Custom hook nếu cần (VD: `useFormValidation`)

### M11 — Internationalization (i18n)
- [ ] Strings hiển thị trên Profile/Settings UI sử dụng localized strings (slang)
- [ ] Hỗ trợ switch ngôn ngữ (locale) từ Settings page
- [ ] Localization keys được tổ chức theo slang YAML namespace structure (VD: `profile.name`, `profile.settings.language`, `settings.theme`) — theo convention của slang tool, KHÔNG phải per source module

### M12 — Data Layer & API
- [ ] Dio service cho profile endpoints
- [ ] Retrofit annotations (hoặc manual Dio nếu phù hợp)
- [ ] Multipart upload cho avatar
- [ ] Error interceptor handle 401, 500, network errors

### M13 — Middleware & Interceptors
- [ ] Global error handler catch unhandled exceptions
- [ ] Per-feature error handling (profile-specific error messages)
- [ ] Logging errors (dev mode: console, prod mode: Crashlytics-ready)

### M14 — Local Storage
- [ ] Settings persist bằng SharedPreferences hoặc secure storage
- [ ] Cache profile data locally (offline-capable read)
- [ ] Clear cache khi logout

### M15 — Login Integration
- [ ] Profile feature chỉ accessible khi đã login
- [ ] Logout flow: clear token, navigate về login, clear cache

### M16 — UI Patterns
- [ ] Confirm dialog cho: logout, discard changes
- [ ] Toast/snackbar cho: save success, upload success, errors
- [ ] Bottom sheet cho: avatar source selection (camera/gallery)

### M17 — Performance
- [ ] Image caching cho avatar (CachedNetworkImage)
- [ ] Lazy loading cho sections (nếu profile page dài)
- [ ] No unnecessary rebuilds (const, select providers)

### M18 — Testing
- [ ] **Unit tests**: ViewModel logic, validation functions, repository
- [ ] **Widget tests**: ProfilePage states (loading, data, error), form validation UI
- [ ] **Golden tests**: ProfilePage light mode, dark mode
- [ ] **Coverage**: tối thiểu 70% cho profile module

### M19 — CI/CD
- [ ] Tests chạy pass trong CI pipeline
- [ ]  lint pass (analyze + format)
- [ ] Build thành công trên CI

---

## 4. Deliverables

| # | Deliverable | Mô tả | Deadline |
|---|-------------|-------|----------|
| 1 | **Source code** | Feature branch: `feature/user-profile` | End of Week |
| 2 | **Unit tests** | ≥ 70% coverage cho profile module | End of Week |
| 3 | **Golden tests** | Light + dark mode cho ProfilePage, EditProfilePage | End of Week |
| 4 | **CI pipeline** | PR check workflow pass (lint + test + build) | End of Week |
| 5 | **PR description** | Mô tả changes, screenshots, testing notes | End of Week |
| 6 | **Demo** | Live demo + trả lời câu hỏi technical | Demo day |

---

## 5. Evaluation Criteria

Đánh giá theo [rubric middle-level](../tieu-chuan/middle-level-rubric.md) với trọng số:

| Tiêu chí | Trọng số | Chi tiết |
|----------|----------|----------|
| **Architecture** | 25% | Đúng layer, đúng pattern, clean dependencies |
| **Functionality** | 20% | Feature hoạt động đúng spec, edge cases handled |
| **Code Quality** | 20% | Readable, maintainable, follows conventions |
| **Testing** | 20% | Coverage, test quality, meaningful assertions |
| **Production Readiness** | 15% | CI pass, error handling, performance, UX polish |

### Scoring

| Score | Level | Mô tả |
|-------|-------|-------|
| 90-100% | **Excellent** | Vượt expectations, production-ready code |
| 75-89% | **Pass** ✅ | Đạt chuẩn middle-level |
| 60-74% | **Conditional Pass** 🟡 | Cần fix issues trong 3 ngày |
| < 60% | **Fail** 🔴 | Cần thêm thời gian training |

---

## 6. Timeline — 1 Tuần

### Day 1–2

| Ngày | Milestone | Tasks |
|------|-----------|-------|
| Day 1 | **M1: Setup** | Tạo folder structure, models, mock API, navigation routes |
| Day 2 | **M2: Core Logic** | Repository, ViewModel, state management, API integration |

### Day 3–4

| Ngày | Milestone | Tasks |
|------|-----------|-------|
| Day 3 | **M3: UI & Polish** | Complete UI, form validation, image upload, settings, error handling |
| Day 4 | **M4: Testing** | Unit tests, widget tests, golden tests, coverage check |

### Day 5

| Ngày | Milestone | Tasks |
|------|-----------|-------|
| Day 5 | **M5: CI & Demo** | CI pipeline pass, PR submitted, demo prep. **Demo day** |

### Milestone Checkpoints

| Milestone | Ngày | Criteria | Reviewer |
|-----------|------|----------|----------|
| **M1** | Day 1 | Folder structure + models + routes created | Self-check |
| **M2** | Day 2 | API call works, state management correct, architecture review | Facilitator |
| **M3** | Day 3 | Full UI functional, form validation working | Peer review |
| **M4** | Day 4 | Tests pass, CI green | Facilitator |
| **M5** | Day 5 | Demo ready, PR submitted | Facilitator + team |

---

## 7. Review Process

### 7.1 PR Review

**PR cần có:**
- Title: `feat: User Profile Page — [Your Name]`
- Description template:

```markdown
## Changes
- [ ] Profile page (view mode)
- [ ] Edit profile page (form + validation)
- [ ] Avatar upload (camera/gallery + crop)
- [ ] Settings (language, dark mode, notification)
- [ ] Logout flow

## Screenshots
| Light Mode | Dark Mode |
|------------|-----------|
| [screenshot] | [screenshot] |

## Testing
- Unit test coverage: XX%
- Golden tests: [list test names]
- CI status: ✅ / ❌

## Checklist
- [ ] Lint pass (analyze + format)
- [ ] All tests pass
- [ ] No hardcoded strings (i18n)
- [ ] No hardcoded colors/sizes (AppTheme)
- [ ] Error handling cho all API calls
- [ ] Responsive layout tested
```

### 7.2 Code Walkthrough

- Thời gian: 20-30 phút
- Developer trình bày:
  1. Architecture decisions (tại sao chọn approach này?)
  2. State management design (providers, state flow)
  3. Phần khó nhất và cách giải quyết
  4. Những gì AI hỗ trợ (AI_VERIFY tags)
- Reviewer hỏi:
  - Technical questions về implementation
  - "Nếu thêm feature X, cần sửa gì?"
  - "Tại sao không dùng approach Y?"

### 7.3 Demo Session

- Thời gian: 10-15 phút
- Demo trước nhóm học:
  1. Happy path: view profile → edit → save → verify
  2. Error path: network error → retry → success
  3. Edge cases: empty fields, large image, long text
  4. Settings: toggle dark mode, change language
  5. Logout flow
- Q&A từ nhóm: 5-10 phút

---

## 8. Grading

### Pass ✅ (75-100%)
- Tất cả deliverables submitted
- Feature hoạt động đúng spec (happy path + error handling)
- Architecture đúng pattern
- Test coverage ≥ 70%
- CI pipeline pass
- Demo thuyết phục

### Conditional Pass 🟡 (60-74%)
- Feature hoạt động cơ bản (happy path OK, thiếu edge cases)
- Architecture nhìn chung đúng, có 1-2 violations nhỏ
- Test coverage 50-69%
- CI pipeline có minor issues
- **Yêu cầu**: fix issues trong 3 ngày, re-review

### Fail 🔴 (< 60%)
- Feature không hoạt động hoặc thiếu major parts
- Architecture sai pattern
- Test coverage < 50% hoặc không có tests
- CI pipeline fail
- **Yêu cầu**: lập kế hoạch bổ sung với facilitator, timeline mới

---

## 9. Mock Data & Resources

### Mock API Setup

Có 2 options:

**Option A: Dio Interceptor (khuyên dùng)**
```dart
class MockProfileInterceptor extends Interceptor {
  static const _mockUserProfile = {
    'id': 'user-001',
    'email': 'test@example.com',
    'name': 'Test User',
    'avatar_url': null,
    'phone': '+84 123 456 789',
    'date_of_birth': '1995-06-15',
    'gender': 'male',
    'created_at': '2025-01-01T00:00:00Z',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // GET /users/me → profile data
    if (options.path.contains('/users/me') && options.method == 'GET') {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: _mockUserProfile,
      ));
      return;
    }
    // PUT /users/me → update profile
    if (options.path.contains('/users/me') && options.method == 'PUT') {
      final updated = {..._mockUserProfile, ...options.data as Map};
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: updated,
      ));
      return;
    }
    handler.next(options);
  }
}
```

**Option B: JSON files trong assets/**
- `assets/raw/mock_user_profile.json`
- Load bằng `rootBundle.loadString()` trong mock repository

### Default Avatar

Sử dụng image có sẵn trong `assets/images/` hoặc tạo mới:
- `assets/images/default_avatar.png` (200x200px)
- Dùng khi `avatar_url` là null

---

## 10. FAQ

**Q: Có phải dùng chính xác API response format trên không?**
A: Có. Format là chuẩn để đánh giá model mapping và serialization.

**Q: Có được dùng thêm packages ngoài base_flutter không?**
A: Có, nhưng phải justify tại sao cần. Ưu tiên dùng packages đã có trong `pubspec.yaml`.

**Q: AI viết bao nhiêu % code là chấp nhận được?**
A: AI có thể hỗ trợ scaffold, generate tests, review code. Nhưng core logic (viewmodel, validation, state management) phải tự viết và hiểu. Xem [AI guidelines](../ai-toolkit/ai-driven-development.md).

**Q: Nếu không kịp deadline thì sao?**
A: Báo facilitator sớm nhất có thể. Tối đa extend thêm 3 ngày cho Conditional Pass.

**Q: Mock API hay real API?**
A: Mock API. Focus vào Flutter architecture, không phải backend.

---

## 11. Tài nguyên

- **Rubric đánh giá**: [middle-level-rubric.md](../tieu-chuan/middle-level-rubric.md)
- **Study group guide**: [study-group-operations.md](../van-hanh-nhom/study-group-operations.md)
- **AI tools**: [ai-driven-development.md](../ai-toolkit/ai-driven-development.md)
- **Prompt practice**: [prompt-dojo.md](../ai-toolkit/prompt-dojo.md)
- **Base Flutter project**: `../../base_flutter/`
- **Training modules**: `../module-00-dart-primer/` → `../module-19-cicd/`

<!-- AI_VERIFY: generation-complete -->
