# Flutter Training Ecosystem

### Full-cycle Developer Initiative — FE team mở rộng sang Mobile Flutter trong ~1 tháng, tích hợp AI vào mọi bước.

> Trong thời đại AI, gò bó ở một tech stack là không đủ.
> Công ty hướng tới mục tiêu: mỗi thành viên là **full-cycle developer + AI master**.
> Vì thế FE team lên kế hoạch chủ động — Và Mobile Flutter là 1 options .
>
> **Hệ sinh thái này được xây dựng cho hành trình đó.**

`140 files` · `28 modules` · `118 exercises` · `8 buổi sync-up` · `~1 tháng` · `308 FE↔Flutter bridges` · `AI-Integrated` · `Peer-to-Peer` · `Chi phí training ≈ 0`

---

## 📌 Mục lục

- [Bài toán](#-bài-toán)
- [Ý tưởng gốc — Tại sao CODE-FIRST?](#-ý-tưởng-gốc--tại-sao-code-first)
- [Cách tiếp cận](#-cách-tiếp-cận)
- [Badge System — Skill Triage cho thời đại AI](#%EF%B8%8F-badge-system--skill-triage-cho-thời-đại-ai)
- [So sánh với cách học Flutter thông thường](#-so-sánh-với-cách-học-flutter-thông-thường)
- [Hệ sinh thái](#%EF%B8%8F-hệ-sinh-thái)
- [Module Map](#-module-map)
- [AI Toolkit](#-ai-toolkit--prompt-dojo--ai-driven-development)
- [Assessment & Capstone](#-assessment--capstone)
- [Bắt đầu nhanh](#-bắt-đầu-nhanh)
- [Kết quả sau ~1 tháng](#-kết-quả-sau-1-tháng)
- [Dành cho ai](#-dành-cho-ai)
- [Đóng góp](#-đóng-góp)
- [License](#-license)

---

## 🔍 Bài toán

Trong thời đại AI phát triển mạnh mẽ, bối cảnh công nghệ thay đổi nhanh chóng:

- **FE team đã có nền tảng vững:** Các Frontend Developer (React, Vue, Angular) trong team có nền tảng — hiểu rõ component architecture, state management, async patterns, clean code. Họ không phải beginner.
- **Gò bó tech stack là rủi ro:** Trong kỷ nguyên AI, việc chỉ giỏi một công nghệ duy nhất là hạn chế. Developer cần mở rộng biên giới kỹ năng để thích ứng và tạo ra nhiều giá trị hơn.
- **Tầm nhìn full-cycle:** Công ty hướng tới mục tiêu mỗi thành viên đều là **full-cycle developer** về tech stack lẫn **AI master** — không phải chuyên gia một ngách, mà là engineer đa năng.
- **Training hiện có không phù hợp:** Các khoá Flutter trên thị trường dạy từ zero — giải thích lại component là gì, state management hoạt động thế nào, async/await là gì. FE developer không cần những thứ đó. Họ cần **lớp ánh xạ** (translation layer), không phải khoá beginner.

Hưởng ứng tầm nhìn full-cycle, team FE chủ động lên kế hoạch mở rộng sang mobile — bắt đầu với Flutter — để thêm một thế mạnh mới cho toàn thể thành viên.

**Đây là sáng kiến từ bên trong tổ chức. Khi FE developer đã mạnh, bước tiếp theo tự nhiên là mở rộng — và Flutter là điểm khởi đầu hoàn hảo.**

---

## 💡 Ý tưởng gốc — Tại sao CODE-FIRST?

### Vấn đề của cách học truyền thống

Hầu hết các chương trình training đều đi theo lộ trình **THEORY-FIRST**: lý thuyết → ví dụ minh hoạ → bài tập → kiểm tra. Mô hình này có thể phù hợp với beginner, nhưng với **experienced developer** — những người đã qua giai đoạn nhập môn — nó cực kỳ kém hiệu quả:

- **Lý thuyết trước, context sau:** Developer ngồi nghe giải thích concept mà chưa thấy nó xuất hiện ở đâu trong thực tế. Kiến thức trôi tuột vì không có điểm neo.
- **Ví dụ toy project:** Counter app, todo list — quá xa production. Developer không thấy được cách concept đó hoạt động trong kiến trúc thực.
- **Bài tập tách rời:** Homework không liên quan đến codebase thật, làm xong rồi quên.
- **Kết quả:** Dài dòng ngoài lề lan man lý thuyết — mà vào dự án vẫn bỡ ngỡ.

### Insight từ thực tế: developer vào dự án học thế nào?

Nghĩ lại xem — khi một developer join vào dự án thực tế, **điều đầu tiên phải làm là gì?**

Không phải đọc documentation dài 50 trang. Không phải xem tutorial. **Điều đầu tiên là mở source code ra đọc:**

- File nào nằm ở đâu?
- Entry point chạy như thế nào?
- Kiến trúc tổ chức ra sao?
- Pattern nào đang được dùng?
- Tại sao nó được viết theo cách này?

**Thông thạo source code → bắt tay vào làm được ngay.** Không cần training thêm. Không cần detour lý thuyết. Đây là cách developer thực sự học trong môi trường production — và đây chính là ý tưởng gốc của toàn bộ chương trình.

### CODE → CONCEPT → EXERCISE → VERIFY

Từ insight đó, chương trình đảo ngược hoàn toàn mô hình truyền thống:

```
  Truyền thống (THEORY-FIRST)         Chương trình này (CODE-FIRST)
  ─────────────────────────────        ─────────────────────────────────
  📖 Lý thuyết (trừu tượng)           📂 CODE — Đọc source code thực
       ↓                                    ↓
  👀 Ví dụ minh hoạ (toy)             💡 CONCEPT — Rút ra concept từ code
       ↓                                    ↓
  📝 Bài tập (tách rời)               🛠️ EXERCISE — Thực hành trên codebase thật
       ↓                                    ↓
  ✅ Kiểm tra (lý thuyết)             ✅ VERIFY — Đối chiếu với production standard
```

Mỗi phase có lý do tồn tại rõ ràng:

| Phase | Làm gì | Tại sao |
|---|---|---|
| **📂 CODE** | Đọc file thực trong `base_flutter/`, guided bởi `01-code-walk.md` | Developer vào dự án thực tế, điều đầu tiên phải biết source code. Đọc code trước → mọi concept sau đó đều có context. |
| **💡 CONCEPT** | Rút ra concept từ code vừa đọc, ánh xạ FE↔Flutter qua `02-concept.md` | Concept không còn trừu tượng — bạn **đã thấy** nó hoạt động. Lý thuyết trở thành giải thích cho thứ bạn đã chạm vào. |
| **🛠️ EXERCISE** | Thực hành trên chính codebase thật qua `03-exercise.md` | Bài tập có ý nghĩa vì bạn đang build trên kiến trúc mà bạn đã hiểu — không phải toy project xa rời thực tế. |
| **✅ VERIFY** | Tự đánh giá theo checklist, quality gates qua `04-verify.md` | Tiêu chuẩn verify là production standard — cùng thước đo mà code review thực sự dùng. |

### Kết quả của cách tiếp cận này

> **Không cần dài dòng ngoài lề lan man lý thuyết.**
> Mỗi phút học đều gắn với production codebase.
> Kết thúc chương trình, developer không chỉ "biết Flutter" — họ **đã quen thuộc với source code** mà team sẽ dùng thật.

Đây là điều khiến chương trình này khác biệt hoàn toàn: bạn không học Flutter rồi mới vào dự án — bạn **học Flutter bằng cách vào dự án**.

---

## 🧭 Cách tiếp cận

Chương trình được xây dựng trên **3 trụ cột** khác biệt cơ bản so với training Flutter thông thường:

### 1. FE→Flutter Translation Layer — 308 điểm ánh xạ

FE developer đã nắm vững: component lifecycle, state management patterns, async/await, clean architecture, routing, responsive layouts.

Chương trình này **không dạy lại những khái niệm đó**. Thay vào đó, 308 callout box **"💡 FE Perspective"** xuyên suốt 23 module ánh xạ trực tiếp từ cái đã biết sang Flutter:

| Đã biết (React/Vue) | Sẽ học (Flutter) | Module |
|---|---|---|
| `useState` / `ref()` | `useState` (Flutter Hooks) — cùng tên, cùng API! | M10 |
| Redux / Pinia / Zustand | Riverpod (Provider, StateNotifier, AsyncValue) | M8 |
| React Router / Vue Router | auto_route (declarative route tree, guards, nesting) | M5 |
| Axios interceptors | Dio interceptors (gần như 1:1) | M12–M13 |
| `useEffect([])` | `useEffect([])` — API giống hệt trong Flutter Hooks | M10 |
| Error boundaries | `runCatching` pattern + Exception layer | M4, M13 |
| CSS Theme / CSS Variables | `ThemeData`, `AppColors`, `AppTextStyles` | M6 |
| `localStorage` / cookies | `SharedPreferences`, `flutter_secure_storage` | M14 |

> **Kết quả:** Tiết kiệm 60–70% thời gian học so với chương trình dạy từ đầu. Developer không bắt đầu từ zero — họ **mở rộng** từ nền đã có.

### 2. Codebase-Driven Learning — Không toy project

Mọi bài học đều neo trực tiếp vào [`base_flutter/`](base_flutter/) — một dự án Flutter production-ready thực sự:

- **158 file Dart viết tay** + 33 file generated (freezed, injectable, auto_route)
- **Clean Architecture + MVVM** với dependency injection đầy đủ
- **50+ production packages**: Riverpod, Dio, auto_route, freezed, injectable, Firebase, flutter_secure_storage, và nhiều hơn nữa
- **482 tag `AI_VERIFY`** trong tài liệu — mỗi code snippet đều trỏ về file thực trong `base_flutter/`, đảm bảo docs luôn đồng bộ với source code

Thay vì học qua counter app hay todo list, học viên đọc, phân tích, và build trên **kiến trúc thực tế** mà team sẽ dùng trong production.

### 3. AI-First Workflow — Có cấu trúc, không tuỳ hứng

Năm 2026, developer không cần thuộc hết syntax mới — nhưng phải biết **giao việc cho AI đúng cách**.

Mỗi module đều tích hợp AI workflow có cấu trúc:
- **🔴🟡🟢 Badge System** — phân loại rõ phần nào phải biết, phần nào AI hỗ trợ, phần nào giao hẳn cho AI ([chi tiết bên dưới](#%EF%B8%8F-badge-system--skill-triage-cho-thời-đại-ai))
- **AI Prompt Dojo** — 10 bài tập prompt engineering graduated từ ⭐ đến ⭐⭐⭐ ([chi tiết](#-ai-toolkit--prompt-dojo--ai-driven-development))
- **Review Checklist** — lỗi AI hay mắc và cách phát hiện
- **Manual Override** — phần nào bắt buộc tự viết tay (🔴 badge)

Không phải "dùng AI nếu muốn." Đây là workflow có cấu trúc, nơi AI tăng tốc cả việc học lẫn chất lượng output.

---

## 🏷️ Badge System — Skill Triage cho thời đại AI

Một trong những đặc trưng quan trọng nhất của chương trình: mỗi concept trong 23 module đều được phân loại theo **Triple Badge System**:

| Badge | Ý nghĩa | Hành động | Ví dụ |
|---|---|---|---|
| 🔴 **MUST-KNOW** | Kiến thức nền tảng, phải hiểu sâu | Tự viết tay, không dùng AI | Widget lifecycle, `BuildContext`, state flow |
| 🟡 **SHOULD-KNOW** | Quan trọng nhưng pattern có thể AI hỗ trợ | Hiểu concept → AI assist → review kỹ | Riverpod providers, Dio interceptors, route guards |
| 🟢 **AI-GENERATE** | Boilerplate, codegen, repetitive patterns | AI generate → verify output | Freezed models, injectable config, i18n keys |

**Tại sao điều này quan trọng?**

Trong thời đại AI, kỹ năng quan trọng nhất không phải là "viết mọi thứ bằng tay" hay "giao hết cho AI" — mà là **biết phân loại**: cái nào phải hiểu sâu, cái nào delegate được, cái nào chỉ cần verify. Badge system dạy chính xác kỹ năng triage đó.

> Mỗi module có bảng phân bổ badge cụ thể. Ví dụ Module 8 (Riverpod): 🔴 30% · 🟡 50% · 🟢 20%.

---

## 📊 So sánh với cách học Flutter thông thường

| Tiêu chí | Cách học Flutter thông thường | Chương trình này |
|---|---|---|
| **Đối tượng** | Beginner | FE developer (React/Vue/Angular) |
| **Kiến thức yêu cầu** | Không giả định | Tận dụng kinh nghiệm FE — 308 điểm ánh xạ |
| **Thời lượng** | 3–6 tháng | ~1 tháng (8 buổi sync-up × 2–3h) |
| **Tích hợp AI** | Tuỳ chọn / không có | Tích hợp mọi module: Badge System + Prompt Dojo |
| **Phụ thuộc trainer** | Cần giảng viên | Peer-to-peer, tự tổ chức, chi phí ≈ 0 |
| **Mô hình học** | Thụ động (xem → code) | Chủ động (present → dạy → xây dựng) |
| **Codebase** | Toy project (counter, todo) | Production codebase — 158 file Dart, Clean Arch |
| **Bài tập** | Bài tập đơn lẻ | 99 exercises (⭐–⭐⭐⭐) + 3-tier Capstone |
| **Chất lượng output** | Không đồng đều | Chuẩn hoá: 121 file, 5-file module architecture |
| **Đánh giá** | Không có hoặc chung chung | Rubric 5 chiều × 4 cấp + Capstone scoring |
| **Production readiness** | Chỉ khái niệm | CI/CD, testing, error handling, performance |

---

## 🏗️ Hệ sinh thái

Repo này không chỉ là tài liệu training. Đây là **hệ sinh thái tự duy trì** với 3 thành phần chính:

```
fultter-training/
│
├── 📚 training/                        Tài liệu đào tạo (121 files)
│   ├── module-00 → module-19/          20 core modules × 5 file mỗi module
│   ├── module-optional-A, B, C/        3 optional modules × 5 file
│   ├── ai-toolkit/                     AI Prompt Dojo + AI-Driven Development
│   ├── capstone/                       Capstone specification & rubric
│   ├── tieu-chuan/                     Middle-level developer rubric
│   └── van-hanh-nhom/                  Hướng dẫn vận hành nhóm học
│
├── 🏗️ base_flutter/                    Production codebase tham chiếu
│   ├── lib/                            158 Dart files (hand-written)
│   ├── test/                           Unit & widget tests
│   ├── integration_test/               Integration tests
│   └── 50+ packages                    Riverpod, Dio, auto_route, freezed...
│
└── 🌐 web/                             Web Platform tương tác
    └── Duyệt & tìm kiếm tài liệu online
```

### Five-File Module Architecture

Mỗi module tuân theo cấu trúc 5 file nhất quán — tạo nhịp học dự đoán được, chất lượng đồng đều bất kể ai present:

| File | Vai trò | Nội dung |
|---|---|---|
| `00-overview.md` | Bản đồ module | Mục tiêu, prerequisites, badge distribution, skip path |
| `01-code-walk.md` | Guided tour | Dẫn đọc code thực trong `base_flutter/` với `AI_VERIFY` tags |
| `02-concept.md` | Lý thuyết + ánh xạ | Concept chính với 💡 FE Perspective callouts |
| `03-exercise.md` | Thực hành | Bài tập graduated ⭐–⭐⭐⭐, pair programming |
| `04-verify.md` | Tự đánh giá | Checklist, self-assessment, quality gates |

> **Skip Path:** Developer đã biết concept nào có thể bỏ qua phần tương ứng — mỗi `00-overview.md` chỉ rõ đường tắt.

---

## 📚 Module Map

### 🟦 Foundation — Tuần 1, Sessions 1–2

| Module | Chủ đề | Highlights |
|---|---|---|
| [M0](training/module-00-dart-primer/) | Dart Reading Primer + Toolchain | TypeScript → Dart syntax mapping, null safety |
| [M1](training/module-01-app-entrypoint/) | App Entrypoint & Bootstrap | `main.dart`, app initialization, DI setup |
| [M2](training/module-02-architecture-barrel/) | Architecture & Barrel Files | Clean Architecture layers, barrel exports |
| [M3](training/module-03-common-layer/) | Common Layer | Shared utilities, base classes, extensions |
| [M4](training/module-04-exception-handling/) | Exception Handling | `runCatching`, `AppException`, multi-field error, error boundaries |
| [M5](training/module-05-navigation/) | Navigation & Routing | auto_route basics, route guards, deep linking — React Router mapping |
| [M5a](training/module-05a-advanced-navigation/) | Advanced Navigation | PopScope, nested tabs (`AutoTabsRouter`), custom transitions, `go_router` comparison |
| [M6](training/module-06-resource-theme/) | Resource & Theme Layer | `ThemeData`, assets, fonts — CSS variables mapping |

### 🟧 Intermediate — Tuần 2–3, Sessions 3–6

| Module | Chủ đề | Highlights |
|---|---|---|
| [M7](training/module-07-base-viewmodel/) | Base ViewModel & Page | MVVM pattern, base classes, page lifecycle |
| [M8](training/module-08-riverpod-state/) | Riverpod & State Management | Provider types, `ref`, family, selectors — Redux/Pinia mapping |
| [M9](training/module-09-page-structure/) | Page Structure & Components | Widget composition, screen architecture |
| [M9a](training/module-09a-advanced-widgets/) | Advanced Widgets | `BuildContext`, `InheritedWidget`, `CustomScrollView`, `GridView`, `ValueKey` vs `GlobalKey` |
| [M10](training/module-10-hooks/) | Flutter Hooks | `useState`, `useEffect` — **API gần như giống hệt React Hooks!** |
| [M11](training/module-11-i18n/) | Internationalization (i18n) | slang, locale switching, pluralization |
| [M11a](training/module-11a-advanced-i18n/) | Advanced i18n | Pluralization rules, locale fallback chain, gender parameter, ARB management, `intl` formatting |
| [M12](training/module-12-data-layer/) | Data Layer & API | Dio, Repository pattern, API models — Axios mapping |
| [M13](training/module-13-middleware-interceptor-chain/) | Middleware & Interceptors | Dio interceptors, auth refresh — Axios interceptors mapping |
| [M14](training/module-14-local-storage/) | Local Storage | SharedPreferences, secure storage, Isar database — localStorage mapping |

### 🟥 Advanced — Tuần 4, Sessions 7–8

| Module | Chủ đề | Highlights |
|---|---|---|
| [M15](training/module-15-capstone-login/) | **🎓 Mini Capstone: Login Flow** | End-to-end feature: UI → ViewModel → API → Storage |
| [M16](training/module-16-popup-dialog-paging/) | Popup, Dialog & Paging | Bottom sheets, dialogs, infinite scroll |
| [M17](training/module-17-performance-animation/) | Performance & Animation | DevTools profiling, implicit/explicit animation, Lottie, physics-based |
| [M17a](training/module-17a-linting-code-quality/) | Linting & Code Quality | `analysis_options.yaml`, `super_lint`, custom lint rules, `lefthook` |
| [M18](training/module-18-testing/) | Testing | Unit test, widget test, integration test, mocking |
| [M18a](training/module-18a-network-debugging/) | Network Debugging | Charles Proxy, `CustomLogInterceptor`, network throttling, SSL issues |
| [M19](training/module-19-cicd/) | **🎓 CI/CD & Production** | Codemagic, Bitbucket Pipelines, Fastlane, store deployment |

> **Sau tuần 4:** Hoàn thành 1 tuần Capstone project (User Profile Feature) để đạt chuẩn Middle Mobile Developer.

### 🟪 Optional — Tự học

| Module | Chủ đề | Highlights |
|---|---|---|
| [MA](training/module-optional-A-platform-channels/) | Platform Channels | Method channels, native iOS/Android integration |
| [MB](training/module-optional-B-push-deeplink/) | Push & Deep Linking | Firebase messaging, deep link handling |
| [MC](training/module-optional-C-isolates/) | Isolates & Background | Compute isolates, background processing |

### Cấu trúc session 2h

```
Check-in & Q&A (15 min)
  → Concept recap bởi rotating presenter (25 min)
    → Live coding demo (15 min)
      → Break (5 min)
        → Hands-on practice + pair programming (35 min)
          → Code review (15 min)
            → Wrap-up & next steps (10 min)
```

> 8 buổi sync-up × 2–3h mỗi buổi. Presenter rotate theo [hiệu ứng Feynman](https://en.wikipedia.org/wiki/Learning_by_teaching) — người dạy học sâu nhất.

---

## 🤖 AI Toolkit — Prompt Dojo & AI-Driven Development

Chương trình không chỉ *dùng* AI — mà **dạy cách dùng AI hiệu quả** cho Flutter development:

### AI Prompt Dojo — [10 bài tập graduated](training/ai-toolkit/prompt-dojo.md)

Từ ⭐ (cơ bản) đến ⭐⭐⭐ (nâng cao), mỗi challenge bao gồm:

| Thành phần | Nội dung |
|---|---|
| ❌ Bad Prompt | Prompt thiếu context, kết quả không dùng được |
| ✅ Good Prompt | Prompt có constraints, architecture context, expected output |
| 📋 Evaluation Criteria | Checklist đánh giá output quality |
| 🔍 Comparison | So sánh kết quả — tại sao prompt tốt hơn |

**Ví dụ:**

```
❌ "Tạo login page Flutter"
✅ "Tạo LoginPage dùng ConsumerStatefulWidget, auto_route @RoutePage(),
   LoginViewModel extends BaseViewModel, Riverpod ref.watch(),
   theo cấu trúc base_flutter/lib/ui/. Validate email regex + password ≥8 chars.
   Handle loading state, error state, success navigation."
```

### AI-Driven Development — [Workflow hoàn chỉnh](training/ai-toolkit/ai-driven-development.md)

Hướng dẫn tích hợp AI tools (Copilot, Cursor, Claude) vào quy trình phát triển Flutter hàng ngày — không phải tips rời rạc, mà là workflow end-to-end.

---

## 🎯 Assessment & Capstone

### Middle-Level Flutter Developer Rubric

[Rubric đánh giá](training/tieu-chuan/middle-level-rubric.md) 5 chiều × 4 cấp độ với hành vi quan sát được cụ thể:

| Chiều đánh giá | ⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
|---|---|---|---|---|
| **Dart & Flutter Core** | Syntax cơ bản | Widget tree, lifecycle | Custom widgets, performance | Advanced patterns |
| **Architecture** | Đọc hiểu code | Follow patterns | Design patterns | Architect features |
| **State Management** | setState | Riverpod basics | Complex state flows | State architecture |
| **Testing** | Viết unit test | Widget test + mock | Integration test | Test strategy |
| **Production** | Debug locally | CI/CD basics | Performance tuning | Full pipeline |

**Tiêu chí hoàn thành:**
- ≥16/20 core modules completed
- Tất cả 5 chiều ≥ ⭐⭐
- Ít nhất 2 chiều đạt ⭐⭐⭐
- Capstone Pass (≥75/100 điểm)

### Three-Tier Capstone

| Tier | Tên | Thời điểm | Yêu cầu |
|---|---|---|---|
| 🥉 Mini Capstone | Login Flow | M15 (tuần 4) | UI → ViewModel → API → Storage, end-to-end |
| 🥈 CI/CD Pipeline | Build & Deploy | M19 (tuần 4) | Codemagic/Bitbucket Pipeline hoạt động |
| 🥇 Full Capstone | [User Profile Feature](training/capstone/capstone-spec.md) | Sau tuần 4 (1 tuần) | Feature hoàn chỉnh, ≥70% test coverage, code review pass |

---

## 🚀 Bắt đầu nhanh

### Cho team muốn dùng ngay chương trình:

```bash
# 1. Clone repository
git clone <repo-url>
cd fultter-training

# 2. Đọc README training
open training/README.md

# 3. Thiết lập nhóm học (rotating presenter, session checklist)
open training/van-hanh-nhom/study-group-operations.md

# 4. Cài đặt môi trường base_flutter
cd base_flutter
flutter pub get

# 5. Bắt đầu Module 0
open training/module-00-dart-primer/00-overview.md
```

### Cho cá nhân tự học:

1. Đọc [M0 Overview](training/module-00-dart-primer/00-overview.md) → follow skip path nếu đã biết Dart
2. Mỗi module: `00-overview` → `01-code-walk` → `02-concept` → `03-exercise` → `04-verify`
3. Dùng [AI Prompt Dojo](training/ai-toolkit/prompt-dojo.md) song song để nâng kỹ năng prompt
4. Tự đánh giá theo [rubric](training/tieu-chuan/middle-level-rubric.md) sau mỗi tier

---

## 🎯 Kết quả sau ~1 tháng

Sau ~1 tháng (8 buổi sync-up), FE developer sẽ có thêm mobile như một thế mạnh mới:

### Flutter Development
- Xây dựng ứng dụng Flutter hoàn chỉnh trên nền **Clean Architecture + MVVM**
- Thành thạo **Riverpod** cho state management — mapping trực tiếp từ kinh nghiệm Redux/Pinia
- Implement networking layer với **Dio** (interceptors, auth refresh, error handling)
- Viết **unit test, widget test, integration test** — target ≥70% coverage
- Profile và tối ưu performance với **Flutter DevTools**
- Cấu hình **CI/CD pipeline** (Codemagic / Bitbucket Pipelines) và ship lên Store
- Tích hợp native platform qua **Platform Channels** (optional track)

### AI-Augmented Development
- Phân loại concept theo **🔴🟡🟢 Badge** — biết khi nào tự viết, khi nào delegate cho AI
- Viết prompt có context và constraints để AI gen code **production-ready**
- Review AI-generated code theo production checklist — phát hiện lỗi AI hay mắc
- Dùng AI tools (Copilot, Cursor, Claude) như **force multiplier**, không phải crutch

### Chứng nhận
Đạt tiêu chuẩn [Middle-Level Flutter Developer](training/tieu-chuan/middle-level-rubric.md) — tự triển khai feature end-to-end, từ UI đến CI/CD.

---

## 👤 Dành cho ai

| Vai trò | Giá trị nhận được |
|---|---|
| **Engineering Manager / CTO** | Nâng cấp FE team thành full-cycle developer với khả năng mobile trong ~1 tháng — peer-to-peer, chi phí ≈ 0, có rubric đánh giá rõ ràng |
| **Tech Lead** | 23 module có cấu trúc, 5-file architecture nhất quán, team adopt ngay — không cần prep từ đầu |
| **FE Developer** | Học Flutter bằng cách build trên kiến thức React/Vue — 308 điểm ánh xạ, không bắt đầu từ zero |
| **Training / L&D** | Chương trình sẵn sàng: rubric 5 chiều, 3-tier capstone, 99 exercises, theo dõi tiến độ |

### Điều kiện tiên quyết

- **1+ năm** kinh nghiệm với React, Vue, hoặc Angular
- Thành thạo **JavaScript/TypeScript** (types, async/await, classes)
- Quy trình **Git** cơ bản (branch, merge, PR)
- **Không yêu cầu** biết Dart hay Flutter trước

---

## 🤝 Đóng góp

Chào mừng mọi đóng góp:

- **Cải thiện nội dung:** Sửa lỗi, cải thiện giải thích, thêm FE↔Flutter bridge examples
- **Nội dung mới:** Thêm optional module, mở rộng Prompt Dojo challenges
- **Cập nhật codebase:** Sync tài liệu khi `base_flutter/` thay đổi (kiểm tra `AI_VERIFY` tags)
- **Bản dịch:** Adapt curriculum cho ngôn ngữ hoặc FE framework khác
- **Web platform:** Cải thiện trải nghiệm web tương tác

Vui lòng tạo issue để thảo luận trước khi submit PR cho thay đổi lớn.

---

## 📄 License

Dự án này là open source. Xem [LICENSE](LICENSE) để biết chi tiết.

---

<p align="center">
  <strong>121 files · 23 modules · 99 exercises · 8 buổi · ~1 tháng</strong><br/>
  <strong>308 FE↔Flutter bridges · 482 AI_VERIFY tags · 10 Prompt Dojo challenges</strong><br/>
  <em>AI-Integrated · Peer-to-Peer · Zero Trainer Cost</em><br/><br/>
  <em>Dành cho team chủ động phát triển — không giới hạn ở một tech stack.</em>
</p>
