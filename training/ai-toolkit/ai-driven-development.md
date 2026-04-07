# AI-Driven Development cho Flutter

> Hướng dẫn sử dụng AI tools hiệu quả trong quá trình học và phát triển Flutter. Dành cho developer trong chương trình đào tạo.

---

## 1. Tổng quan AI Tools

### Công cụ chính

| Tool | Loại | Điểm mạnh cho Flutter | Hạn chế |
|------|------|----------------------|---------|
| **GitHub Copilot** | Code completion, chat | Inline suggestions, codebase-aware, VS Code integration | Cần subscription, context window hạn chế |
| **ChatGPT** (GPT-4o) | Conversational AI | Giải thích concepts, debug, tạo boilerplate | Không biết codebase hiện tại |
| **Claude** | Conversational AI | Phân tích code dài, reasoning tốt, careful answers | Không realtime access |
| **Gemini** | Multi-modal AI | Tích hợp Google ecosystem, hiểu images/UI | Flutter-specific knowledge đôi khi không chính xác |

### Khi nào dùng tool nào?

| Tình huống | Tool khuyên dùng | Lý do |
|------------|------------------|-------|
| Đang code, cần suggestion nhanh | GitHub Copilot | Inline, không cần switch context |
| Debug error message phức tạp | ChatGPT / Claude | Paste error + code, nhận giải thích |
| Tạo boilerplate (model, API client) | GitHub Copilot Chat | Biết project structure |
| Hiểu concept mới (Riverpod, auto_route) | Claude / ChatGPT | Giải thích chi tiết, có ví dụ |
| Review code cho best practices | Claude | Phân tích kỹ, ít hallucination |
| Tạo test cases | GitHub Copilot / ChatGPT | Generate từ implementation |
| Thiết kế UI từ mockup | Gemini / ChatGPT | Multi-modal, input hình ảnh |

---

## 2. AI-Assisted Flutter Development Patterns

### Pattern 1: Scaffold → Refine → Test

```
Bước 1: Dùng AI tạo scaffold (widget, model, viewmodel)
Bước 2: Review và sửa theo convention của base_flutter
Bước 3: Dùng AI generate test cases
Bước 4: Review tests, bổ sung edge cases
```

**Ví dụ thực tế:**

```
Prompt: "Tạo một StatelessWidget hiển thị user profile card với avatar, 
tên, email. Dùng Theme.of(context) cho styling. Follow MVVM pattern."

→ AI tạo code
→ Bạn: kiểm tra đúng pattern base_flutter chưa, sửa nếu cần
→ Prompt: "Generate unit test cho widget trên, mock user data"
→ Bạn: review test, thêm edge cases (null avatar, long name)
```

### Pattern 2: Error → Explain → Fix

```
Bước 1: Copy error message + relevant code
Bước 2: Hỏi AI giải thích nguyên nhân
Bước 3: Hỏi AI suggest fix
Bước 4: HIỂU fix trước khi apply
```

### Pattern 3: Learn → Compare → Apply

```
Bước 1: "Giải thích concept X trong Flutter" (VD: Riverpod AsyncNotifier)
Bước 2: "So sánh X với Y mà tôi đã biết từ React" (VD: vs React Query)
Bước 3: "Cho ví dụ áp dụng X trong project dạng base_flutter"
```

### Pattern 4: Review → Improve → Document

```
Bước 1: Paste code đã viết
Bước 2: "Review code này theo Flutter best practices"
Bước 3: Apply improvements hợp lý
Bước 4: "Generate dartdoc cho các public APIs"
```

---

## 3. Prompt Engineering cho Flutter Code Generation

### Nguyên tắc cơ bản

1. **Cung cấp context**: nêu rõ project structure, pattern đang dùng
2. **Chỉ định output format**: "viết dạng StatelessWidget", "return `Either<Failure, T>`"
3. **Nêu constraints**: "không dùng `setState`", "phải dùng Riverpod"
4. **Cho ví dụ**: paste 1 file mẫu từ project cho AI follow pattern
5. **Chia nhỏ**: đừng yêu cầu cả feature, hãy chia thành widget → viewmodel → model → test

### Prompt template: Widget Generation

```
Role: Senior Flutter developer
Context: Project dùng clean architecture (MVVM), Riverpod, auto_route.
  Theme được define trong AppTheme, dùng Theme.of(context) cho colors/text styles.

Task: Tạo [widget name] widget:
- Input: [props list]
- Behavior: [mô tả interaction]
- Styling: dùng AppTheme, responsive cho mobile
- Pattern: StatelessWidget, extract sub-widgets nếu >50 lines

Output: Dart code, không cần giải thích.
```

### Prompt template: API Integration

```
Context: 
- Dùng Dio + retrofit cho API calls
- Model class dùng freezed + json_serializable
- Error handling: AppException, trả về Either<AppException, T>

Task: Tạo data layer cho [feature]:
1. Model class (freezed)
2. API service (retrofit)  
3. Repository implementation
4. Riverpod provider

Endpoint: [method] [url]
Request body: [JSON example]
Response: [JSON example]
```

### Prompt template: Debugging

```
Error message: [paste error]

Code gây lỗi:
```dart
[paste code]
```

Context:
- Flutter [version], Dart [version]
- Packages: [relevant packages]
- Lỗi xảy ra khi: [action that triggers error]

Hỏi:
1. Nguyên nhân lỗi?
2. Cách fix?
3. Cách prevent lỗi tương tự?
```

Thực hành prompt engineering thêm tại [Prompt Dojo](../ai-toolkit/prompt-dojo.md).

---

## 4. Code Review với AI

### Cách sử dụng

```
Prompt: "Review đoạn code sau theo các tiêu chí:
1. Flutter/Dart best practices
2. Performance (unnecessary rebuilds, const constructors)
3. Null safety (proper handling, no force unwrap)
4. Error handling (no unhandled exceptions)
5. Architecture compliance (MVVM, layer separation)
6. Potential bugs

Code:
[paste code]
"
```

### Checklist AI Code Review

Khi nhận review từ AI, kiểm tra:
- [ ] AI có hiểu đúng context project không? (đôi khi suggest pattern khác)
- [ ] Suggestion có compatible với `base_flutter` conventions không?
- [ ] AI có hallucinate API không tồn tại không? (phải verify documentation)
- [ ] Performance suggestion có hợp lý trong context cụ thể không?

### Red flags trong AI review

- AI suggest deprecated APIs → luôn check Flutter/package version
- AI suggest thêm dependency mới → cân nhắc kỹ, check pub.dev
- AI bỏ qua null safety → code có thể crash runtime
- AI suggest pattern quá phức tạp cho use case đơn giản → KISS principle

---

## 5. AI cho Testing

### Generate Test Cases

```
Prompt: "Cho implementation sau, generate:
1. Unit tests cho tất cả public methods
2. Edge cases: null input, empty list, network error
3. Dùng mocktail cho mocking
4. Follow arrange-act-assert pattern

Implementation:
[paste code]
"
```

### Golden Test Baselines

```
Prompt: "Tạo golden test cho widget [WidgetName]:
- Test states: loading, data, error, empty
- Dùng ProviderScope override cho mock data
- Screen size: 375x812 (iPhone 13 mini)
- Theme: cả light và dark mode
"
```

### Test Coverage Gaps

```
Prompt: "Phân tích code sau và liệt kê các scenarios chưa được test:
[paste implementation]

Tests hiện tại:
[paste existing tests]

Còn thiếu test gì?"
```

> **Tham khảo**: [M18 — Testing](../module-18-testing/) cho chi tiết về testing patterns trong `base_flutter`.

---

## 6. AI cho Documentation

### Dartdoc Generation

```
Prompt: "Generate dartdoc comments cho các public APIs trong class sau.
Bao gồm: description, @param, @return, @throws (nếu có).
Style: ngắn gọn, tập trung vào what & why, không mô tả implementation detail.

[paste code]
"
```

### README Generation

```
Prompt: "Tạo README.md cho feature module [name]:
- Purpose
- Architecture diagram (mermaid)
- Usage example
- Dependencies
- Testing instructions
"
```

---

## 7. AI_VERIFY Tags

### AI_VERIFY là gì?

`AI_VERIFY` là convention tag dùng trong chương trình training để đánh dấu nội dung được tạo hoặc hỗ trợ bởi AI.

### Các tags

| Tag | Ý nghĩa | Dùng khi |
|-----|---------|----------|
| `<!-- AI_VERIFY: generation-complete -->` | Tài liệu được generate hoàn chỉnh bởi AI | Cuối mỗi file tài liệu training |
| `// AI_VERIFY: reviewed` | Code đã được AI review | Sau khi qua AI code review |
| `// AI_VERIFY: generated` | Code được AI generate | Code scaffold từ AI, chưa review |
| `// AI_VERIFY: human-verified` | Code AI generate đã được dev verify | Sau khi dev review và confirm AI code |

### Cách sử dụng

```dart
// AI_VERIFY: generated
// TODO: Review null handling and error cases
class UserProfileViewModel extends BaseViewModel {
  // ... AI generated code
}
```

Sau khi review:
```dart
// AI_VERIFY: human-verified
class UserProfileViewModel extends BaseViewModel {
  // ... reviewed and approved code
}
```

### Tại sao cần AI_VERIFY?

- **Transparency**: biết nội dung nào AI tạo
- **Accountability**: dev phải verify trước khi merge
- **Quality tracking**: facilitator biết code nào cần review kỹ hơn
- **Learning signal**: nếu AI code luôn đúng → dev đang verify tốt; nếu hay sai → cần improve prompting

---

## 8. Responsible AI Usage Guidelines

### ✅ NÊN làm

1. **Hiểu trước khi copy**: đọc và hiểu code AI generate, giải thích được cho người khác
2. **Verify output**: chạy code, viết test, check edge cases
3. **Cung cấp context**: AI output tốt hơn khi có context rõ ràng
4. **Iterate**: prompt lần 1 chưa tốt → refine prompt, không accept code kém
5. **Learn from AI**: AI suggest pattern mới → tìm hiểu tại sao, không chỉ copy
6. **Acknowledge AI usage**: dùng AI_VERIFY tags
7. **Cross-reference**: check Flutter docs, pub.dev, Stack Overflow để verify AI answer

### ❌ KHÔNG nên làm

1. **Blindly copy-paste**: không đọc, không test, paste thẳng vào project
2. **Skip understanding**: "AI viết cho rồi, chạy được là xong"
3. **Depend 100%**: không thể code nếu không có AI → nguy hiểm
4. **Trust API suggestions**: AI có thể hallucinate API/method không tồn tại
5. **Share sensitive data**: không paste API keys, credentials, internal URLs vào AI tools
6. **Plagiarize**: submit bài tập 100% AI, claim tự viết
7. **Ignore warnings**: AI suggestions "có thể" sai → PHẢI verify

### Quy tắc đặc biệt cho training

| Tình huống | Được phép? | Ghi chú |
|------------|-----------|---------|
| Dùng AI để hiểu concept | ✅ | Khuyến khích |
| Dùng AI generate scaffold | ✅ | Phải review, sửa, hiểu |
| Dùng AI debug lỗi | ✅ | Phải hiểu root cause |
| AI viết 100% bài tập | ❌ | Phải tự code phần core logic |
| AI viết test cho code mình | ✅ | Phải review test quality |
| Copy AI code không hiểu | ❌ | Facilitator sẽ hỏi explain |

---

## 9. Integration với Training Workflow

### Mỗi module training

```
1. Đọc tài liệu module (self-study)
   ↓
2. Dùng AI để clarify concepts chưa rõ
   ↓
3. Làm bài tập: tự code trước, dùng AI hỗ trợ khi stuck
   ↓
4. AI review code trước khi submit PR
   ↓
5. Submit PR (có AI_VERIFY tags nếu dùng AI)
   ↓
6. Peer review + facilitator review
   ↓
7. Fix feedback, merge
```

### Recommended AI Workflow per Module Type

| Module Type | AI Usage | Chi tiết |
|-------------|----------|----------|
| Concept modules (M0, M2) | Learn & compare | Hỏi AI so sánh với FE concepts |
| UI modules (M6, M7, M9) | Scaffold & review | AI generate skeleton, bạn refine |
| Logic modules (M4, M8, M12) | Debug & test | Tự code, dùng AI debug + generate tests |
| Practice modules (M15, Capstone) | Review only | Tự code 100%, dùng AI review cuối |

### Progress Tracking với AI

- Ghi lại prompts hiệu quả → contribute vào [Prompt Dojo](../ai-toolkit/prompt-dojo.md)
- Ghi lại AI mistakes → giúp team tránh tương tự
- Self-assess: "Liệu tôi có code được cái này KHÔNG CẦN AI?" → nếu không, cần học thêm

### AI Tools Setup

| Tool | Setup | Module tham khảo |
|------|-------|-------------------|
| GitHub Copilot | VS Code extension + subscription | [M1](../module-01-app-entrypoint/) |
| Copilot Chat | VS Code sidebar | — |
| Claude / ChatGPT | Browser hoặc API | — |
| Flutter DevTools | Built-in `dart devtools` | [M17](../module-17-performance-animation/) |

---

## 10. Tài nguyên bổ sung

- **Prompt Dojo**: [prompt-dojo.md](../ai-toolkit/prompt-dojo.md) — luyện tập prompt engineering
- **Study group guide**: [study-group-operations.md](../van-hanh-nhom/study-group-operations.md)
- **Assessment rubric**: [middle-level-rubric.md](../tieu-chuan/middle-level-rubric.md)
- **Capstone spec**: [capstone-spec.md](../capstone/capstone-spec.md)

<!-- AI_VERIFY: generation-complete -->
