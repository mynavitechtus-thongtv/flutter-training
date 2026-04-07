# Module 18 – Testing (Unit + Widget + Golden)

## Tổng quan

Module này survey toàn bộ test infrastructure của dự án Flutter — từ global configuration, mock patterns, unit testing ViewModels, golden visual regression, đến integration testing. Đây là **Advanced Survey**: nắm structural overview + key patterns, không deep-dive triển khai từ đầu.

**Depth**: Advanced Survey — đọc hiểu codebase test sẵn có, viết tests theo pattern có sẵn.

**Cycle:** CODE (đọc test infra + case study) → EXPLAIN (hiểu patterns & pyramid) → PRACTICE (viết test theo pattern).

---

## ⏭️ Skip Path

Bạn có thể bỏ qua module này nếu trả lời **Yes** cho tất cả câu sau:

1. Giải thích được `flutter_test_config.dart` — global config cho golden, fonts, threshold?
2. Viết được unit test cho ViewModel dùng `mocktail` — AAA pattern, happy/unhappy groups?
3. Hiểu golden test workflow — `autoUpdateGoldenFiles`, pixel comparison, threshold tuning?
4. Trace được mock setup: `registerFallbackValue`, `when/thenReturn`, `verify/verifyNever`?
5. Giải thích được testing pyramid — unit vs widget vs golden vs integration trade-offs?

→ Nếu **5/5 Yes** — chuyển thẳng [Module 19 — CI/CD](../module-19-cicd/).
→ Nếu có bất kỳ **No** — hoàn thành module này.

---

## Bạn sẽ học

1. **Testing Pyramid** — 4 tầng: Unit → Widget → Golden → Integration, trade-offs và tỷ lệ
2. **Test Configuration** — `flutter_test_config.dart`, golden toolkit setup, font loading, threshold
3. **Test Doubles Taxonomy** — Mock vs Stub vs Fake vs Spy — phân biệt mục đích từng loại
4. **Mocktail Patterns** — `registerFallbackValue`, `when/thenReturn`, `verify/verifyNever`
5. **Unit Test Convention** — AAA pattern, happy/unhappy groups, ViewModel testing
6. **Golden Testing** — Visual regression, pixel comparison, update workflow
7. **Integration Testing** — Real app E2E, screenshots, driver pattern

**Phân bố:** 🔴 ~29% · 🟡 ~57% · 🟢 ~14%

---

## Kiến thức cần có

| Module | Nội dung | Vai trò trong M18 |
|--------|----------|-------------------|
| **M7** | BaseViewModel | Target chính để unit test |
| **M8** | Riverpod providers | Mock pattern: override providers |
| **M15** | LoginViewModel flow | Case study: test files thực tế |

---

## Cấu trúc files

| File | Nội dung | Thời gian |
|------|----------|-----------|
| [01-code-walk.md](./01-code-walk.md) | Walk-through test infra + LoginViewModel case study | 30 min |
| [02-concept.md](./02-concept.md) | 7 concepts: pyramid, config, **test doubles taxonomy**, mocktail, unit, golden, integration | 30 min |
| [03-exercise.md](./03-exercise.md) | 4 exercises: ⭐ run → ⭐⭐ unit → ⭐⭐ golden → ⭐⭐⭐ AI dojo | 90 min |
| [04-verify.md](./04-verify.md) | Verification checklist | 10 min |

---

## 💡 FE Perspective

| Flutter | FE Equivalent |
|---------|---------------|
| `flutter_test` (unit) | Jest / Vitest |
| Widget test (`pumpWidget`) | React Testing Library (`render`) |
| Golden test (pixel diff) | Storybook + Percy / Chromatic |
| Integration test | Cypress / Playwright E2E |
| `flutter_test_config.dart` | `jest.config.ts` / `vitest.config.ts` |
| `mocktail` | `jest.fn()` / `jest.mock()` |
| `make cov` → lcov | `jest --coverage` → Istanbul |

---

## Key Files trong Codebase

```
test/
├── flutter_test_config.dart     ← Global config (golden, fonts, threshold)
├── common/
│   ├── base_test.dart           ← Mock registration (setUpAll/setUp)
│   ├── test_config.dart         ← Device sizes, locale, theme
│   └── test_util.dart           ← createContainer, buildRouterMaterialApp
└── unit_test/ui/page/login/
    └── login_view_model_test.dart  ← Case study
```

---

## Forward Reference

→ **M19 (CI/CD)**: Tests từ module này sẽ chạy tự động trong CI pipeline (`make te` + `make cov`).

<!-- AI_VERIFY: generation-complete -->
