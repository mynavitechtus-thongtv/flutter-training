# Module 15 — Capstone: Login Feature Deep Dive

**⏱️ Thời lượng ước tính:** 90–120 phút (hands-on capstone cần thời gian thực hành nhiều hơn module thông thường).

## 🎯 Mục tiêu

Trace **toàn bộ login flow** end-to-end qua tất cả layers của codebase. Module này là capstone tổng hợp kiến thức M0–M14, chứng minh khả năng đọc hiểu và build feature cross-layer.

> 🗺️ **Capstone Path:** Đây là **Mini Capstone #1** trong [lộ trình 3 capstone](../capstone/capstone-spec.md#-capstone-path--lộ-trình-capstone). Sau khi hoàn thành M15, bạn sẽ tiếp tục curriculum đến M19, rồi thực hiện [Full Capstone Project](../capstone/capstone-spec.md).

---

## 📌 Prerequisites — Modules Required

| Module | Concept cần nắm | Relevance cho M15 |
|--------|-----------------|-------------------|
| **M5** | `AppNavigator`, `replaceAll()`, route guards | Post-login navigation, stack clearing |
| **M7** | `BasePage`, `BaseViewModel`, `runCatching`, `@freezed` code generation | Login page structure, error boundary, `LoginState` immutable data |
| **M8** | Riverpod `StateNotifierProvider`, `ref.read/watch`, `select()` | State management, reactive UI |
| **M9** | Page UI structure, `Consumer` widget, `buildPage()` | LoginPage layout, selective rebuilds |
| **M10** | Flutter Hooks — `useScrollController()` | Hook usage trong `HookConsumerWidget` |
| **M11** | i18n — `slang` localization | Localized strings (`l10n.login`, `l10n.email`, etc.) |
| **M12** | `AppApiService`, Dio, interceptor chain | API call, request/response pipeline |
| **M13** | Exception mapping, `RemoteException`, interceptors | Error flow: API error → UI display |
| **M14** | `AppPreferences`, encrypted token storage | Token persistence post-login |

---

## 📂 Anchor Files

| File | Path | Lines | Role |
|------|------|-------|------|
| LoginPage | `lib/ui/page/login/login_page.dart` | ~157 | UI layer — form, buttons, error display |
| LoginViewModel | `lib/ui/page/login/view_model/login_view_model.dart` | ~60 | Business logic — orchestrate login flow |
| LoginState | `lib/ui/page/login/view_model/login_state.dart` | ~20 | Data contract — form state + computed |
| BaseViewModel | `lib/ui/base/base_view_model.dart` | ~170 | Framework — `runCatching`, loading, error |
| BasePage | `lib/ui/base/base_page.dart` | ~100 | Framework — auto loading/exception handling |
| AppPreferences | `lib/data_source/preference/app_preferences.dart` | ~80 | Storage — token persistence |
| AppNavigator | `lib/navigation/app_navigator.dart` | ~60+ | Navigation — route management |

---

## 🔄 End-to-End Flow Summary

```
User taps Login button
  ├─ 1. UI (M9):  LoginPage → ElevatedButton.onPressed
  ├─ 2. VM (M7):  LoginViewModel.login() → runCatching {}
  ├─ 3. State (M8): CommonState<LoginState> with loading
  ├─ 4. API (M12): AppApiService.login(email, password)
  ├─ 5. Chain (M13): Interceptor chain executes
  ├─ 6. Storage (M14): AppPreferences → save tokens
  ├─ 7. Nav (M5): replaceAll([MainRoute()])
  │
  └─ ERROR: API throws → runCatching catches → onPageError → red text
```

---

## 💡 FE Perspective

| Flutter (Base Project) | React Equivalent |
|------------------------|-----------------|
| `LoginViewModel` + Riverpod | Redux Thunk / Context + useReducer |
| `runCatching` | Custom `useAsyncAction` hook |
| `AppApiService.login()` | `fetch('/api/login')` / Axios |
| `AppPreferences.saveAccessToken()` | `localStorage.setItem('token')` |
| `appNavigator.replaceAll()` | `navigate('/home', { replace: true })` |
| `Consumer` + `select()` | `useSelector()` (Redux) / `useMemo` |

**Phân bố:** 🔴 ~57% · 🟡 ~29% · 🟢 ~14%

---

## 📖 Files trong module này

| # | File | Nội dung | Lines |
|---|------|----------|-------|
| 1 | [01-code-walk.md](./01-code-walk.md) | Full end-to-end trace qua source code | 400–600 |
| 2 | [02-concept.md](./02-concept.md) | 7 capstone-level concepts | 250–350 |
| 3 | [03-exercise.md](./03-exercise.md) | 7 exercises: trace → remember-me → error variants → real API → logout trace → forgot-password → cross-layer | 200–374 |
| 4 | [04-verify.md](./04-verify.md) | 16 câu verify (Flow + Architecture + Cross-module) | 120–170 |

---

## ✅ Completion Criteria

- [ ] Trace được login flow qua ≥ 7 files không cần nhìn code
- [ ] Giải thích `runCatching` hoạt động với 3 configurations khác nhau
- [ ] Build feature mới (forgot password) theo exact same pattern
- [ ] Pass verify quiz ≥ 70/100

Bắt đầu → [01-code-walk.md](./01-code-walk.md)

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Trace được login flow từ `LoginPage` → `LoginViewModel` → `AppApiService` → API → token storage → navigation?
2. Giải thích `runCatching` hoạt động thế nào khi API trả 401 vs network timeout vs success?
3. Mô tả form validation flow: `PrimaryTextField.onChanged` → ViewModel state → button enable/disable?
4. Phân biệt `AppPreferences.saveAccessToken()` vs `AppPreferences.saveRefreshToken()` — khi nào dùng gì?
5. Build được feature "Forgot Password" theo exact same pattern mà không cần nhìn login code?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 16 — Popup, Dialog & Paging](../module-16-popup-dialog-paging/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

## Unlocks (Module 16+)

Sau khi hoàn thành Module 15, bạn sẽ:

- **Module 16 — Popup, Dialog & Paging:** Popup/dialog patterns build on error handling concepts from login flow. PagingExecutor reuses `runCatching` + `LoadMoreOutput` state management.
- **Module 17 — Performance & Animation:** Performance optimization context (selective rebuilds, animation) áp dụng trực tiếp lên login và form pages.
- **Capstone Project:** Login feature là foundation — mọi capstone feature đều follow same architecture pattern.

<!-- AI_VERIFY: generation-complete -->
