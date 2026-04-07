# Hướng dẫn vận hành nhóm học Flutter

> Tài liệu dành cho facilitator và thành viên nhóm học Flutter — chương trình đào tạo chuyển đổi từ Frontend sang Flutter.

---

## 1. Tổng quan nhóm học

### Đối tượng
- 6–8 Frontend developer (React/Vue/Angular) chuyển đổi sang Flutter
- Kinh nghiệm FE tối thiểu 1 năm
- Đã quen làm việc với component-based architecture, state management, REST API

### Mục tiêu
- Hoàn thành chương trình đào tạo 20 modules (M0–M19) trong 8 buổi sync-up
- Đạt chuẩn middle-level Flutter developer theo [rubric đánh giá](../tieu-chuan/middle-level-rubric.md)
- Hoàn thành capstone project theo [spec](../capstone/capstone-spec.md)

### Nguyên tắc hoạt động
- **Self-study first**: mỗi thành viên tự học trước buổi sync-up
- **Peer review**: review code lẫn nhau, không chỉ dựa vào facilitator
- **Hands-on driven**: mỗi buổi phải có bài thực hành cụ thể
- **AI-assisted**: khuyến khích sử dụng AI tools theo [hướng dẫn](../ai-toolkit/ai-driven-development.md)

---

## 2. Lịch 8 buổi sync-up

|| Buổi | Module                              | Chủ đề chính                          | Thời lượng |
|------|-------------------------------------|---------------------------------------|------------|
| 1    | M0–M3 — Dart, Entrypoint, Architecture, Common | Dart syntax, project structure, DI, shared utilities | 2.5h |
| 2    | M4–M6 — Exception, Navigation, Theme | Error handling, routing, theming | 2.5h |
| 3    | M7–M8 — Base Page & Riverpod State | MVVM, page lifecycle, state management | 2.5h |
| 4    | M9–M11 — Page Structure, Hooks, i18n | Widget composition, React Hooks mapping, slang | 2.5h |
| 5    | M12–M13 — Data Layer & Interceptors | Dio, Repository, auth refresh, error handling | 2.5h |
| 6    | M14–M15 — Storage & Login Capstone | SharedPreferences, secure storage, end-to-end login | 3h |
| 7    | M16–M18 — Dialog, Performance, Testing | Dialogs, DevTools, unit/widget/golden tests | 2.5h |
| 8    | M19 + Capstone Review + Full Capstone Intro | CI/CD pipeline, capstone demo, full capstone kick-off | 3h |

> **Lưu ý**: Buổi 1, 6, 8 cần thêm thời gian vì nội dung phức tạp hơn. M15 (Login Capstone) được ghép ở buổi 6 vì là hands-on capstone cần thời gian code thực tế.

> 💡 **Double-module sessions**: Hầu hết các buổi đều cover 2–3 modules nhỏ gộp chung để tập trung thực hành. Nếu nhóm chưa hoàn thành, dời sang buổi tiếp hoặc self-study.

---

## 3. Chi tiết mỗi buổi sync-up

### 3.1 Preparation Checklist (trước buổi học)

**Thành viên:**
- [ ] Đọc xong tài liệu module tương ứng
- [ ] Hoàn thành bài tập self-study (nếu có)
- [ ] Chạy thành công code example trong `base_flutter/`
- [ ] Ghi lại tối thiểu 2 câu hỏi / điểm chưa rõ
- [ ] Push code bài tập lên branch cá nhân

**Facilitator:**
- [ ] Review nhanh code submission của thành viên
- [ ] Chuẩn bị slide tóm tắt (max 10 slides)
- [ ] Chuẩn bị bài thực hành hands-on
- [ ] Setup project/branch cho bài tập nhóm (nếu cần)

### 3.2 Cấu trúc buổi sync-up (2.5h mẫu)

|| Thời gian  | Hoạt động                          | Mô tả                                         |
||------------|-------------------------------------|------------------------------------------------|
|| 0:00–0:15  | **Check-in & Q&A nhanh**           | Giải đáp thắc mắc từ self-study               |
|| 0:15–0:45  | **Concept recap**                   | Facilitator trình bày key concepts (không lặp lại tài liệu) |
|| 0:45–1:00  | **Live coding demo**               | Facilitator demo 1 use-case thực tế            |
|| 1:00–1:05  | **Break**                           | —                                              |
|| 1:05–1:40  | **Hands-on practice**              | Thành viên code theo đề bài, pair programming  |
|| 1:40–1:55  | **Code review & discussion**       | Review 2–3 submissions, thảo luận approach     |
|| 1:55–2:05  | **Wrap-up & assignment**           | Tóm tắt, giao bài self-study cho buổi tiếp    |

### 3.3 Discussion Points (gợi ý cho mỗi buổi)

Mỗi buổi nên thảo luận ít nhất 3 trong 5 chủ đề sau:
1. **So sánh FE↔Flutter**: pattern nào giống, khác gì? (VD: React state vs Riverpod)
2. **Pitfalls**: những lỗi phổ biến của người mới chuyển từ FE sang
3. **Best practices**: cách áp dụng đúng trong `base_flutter` project
4. **Real-world scenarios**: case study từ project thực tế
5. **AI-assisted approach**: dùng AI tool nào hiệu quả cho chủ đề này (tham khảo [Prompt Dojo](../ai-toolkit/prompt-dojo.md))

### 3.4 Review Criteria cho bài tập

|| Tiêu chí              | Trọng số | Mô tả                                                  |
||------------------------|----------|---------------------------------------------------------|
|| **Correctness**        | 30%      | Code chạy đúng, không crash, handle edge cases          |
|| **Architecture**       | 25%      | Đúng layer, đúng pattern theo `base_flutter`            |
|| **Code quality**       | 20%      | Naming, formatting, lint pass, không code smell          |
|| **Testing**            | 15%      | Có unit test, coverage hợp lý                           |
|| **Documentation**      | 10%      | Comment hợp lý, commit message rõ ràng                  |

---

## 4. Vai trò Facilitator

### Trách nhiệm chính
- **Chuẩn bị nội dung**: tóm tắt module, chuẩn bị bài tập hands-on
- **Điều phối thảo luận**: đảm bảo mọi thành viên tham gia, không ai bị bỏ lại
- **Review code**: review bài tập, cho feedback cụ thể (không chỉ "looks good")
- **Tracking progress**: cập nhật bảng tiến độ hàng tuần
- **Escalation**: báo cáo cho training lead nếu thành viên bị trễ > 2 buổi

### Kỹ năng cần có
- Kinh nghiệm Flutter ≥ 2 năm
- Quen thuộc với `base_flutter` project structure
- Kỹ năng facilitation: đặt câu hỏi mở, khuyến khích thảo luận
- Kiên nhẫn với người mới chuyển đổi tech stack

### Những việc Facilitator KHÔNG nên làm
- Giảng bài dài (thành viên đã tự đọc tài liệu)
- Viết code thay thành viên
- Skip review vì "không có thời gian"
- Cho pass bài tập khi chưa đạt criteria

---

## 5. Progress Tracking

### 5.1 Badge Completion

Mỗi module hoàn thành = 1 badge. Có 3 loại badge:

|| Badge               | Điều kiện                                                  |
||----------------------|------------------------------------------------------------|
|| 🟢 **Completed**    | Hoàn thành bài tập, pass review                           |
|| 🟡 **In Progress**  | Đang làm hoặc cần sửa theo feedback                       |
|| 🔴 **Not Started**  | Chưa bắt đầu                                              |

### 5.2 Bảng tracking mẫu

|| Thành viên | M0–M3 | M4–M6 | M7–M8 | M9–M11 | M12–M13 | M14–M15 | M16–M18 | M19 | Capstone |
||------------|--------|--------|--------|----------|----------|----------|----------|------|----------|
|| Dev A      | 🟢 | 🟢 | 🟡 |    |    |    |    |    |          |
|| Dev B      | 🟢 | 🟡 |    |    |    |    |    |    |          |

### 5.3 Exercise Sign-off

Mỗi bài tập cần được sign-off bởi facilitator hoặc peer reviewer:
- **PR submitted** → reviewer assigned → **feedback** → **fix** → **merged** = sign-off ✅
- Tối đa 2 vòng review. Nếu vẫn chưa đạt → pair session với facilitator.

### 5.4 Capstone Milestones

Theo [capstone spec](../capstone/capstone-spec.md):
- **Milestone 1** (Day 1–2): Architecture setup, navigation, UI skeleton
- **Milestone 2** (Day 3): API integration, state management
- **Milestone 3** (Day 4): Testing, error handling
- **Milestone 4** (Day 5): CI/CD, code review, demo presentation

---

## 6. Các vấn đề thường gặp khi FE → Flutter

### 6.1 Mindset Shift

|| FE Mindset                          | Flutter Mindset                          | Module tham khảo                             |
||-------------------------------------|------------------------------------------|----------------------------------------------|
|| DOM manipulation                    | Widget tree rebuild                      | [M6](../module-06-resource-theme/)            |
|| CSS styling                         | Widget composition + Theme              | [M3](../module-03-common-layer/)           |
|| npm packages                        | pub.dev packages                        | [M1](../module-01-app-entrypoint/)           |
|| Browser DevTools                    | Flutter DevTools                        | [M17](../module-17-performance-animation/)   |
|| `useState` / Redux                  | Riverpod providers                      | [M8](../module-08-riverpod-state/)         |
|| `fetch` / Axios                     | Dio + interceptors                      | [M12](../module-12-data-layer/)         |
|| Jest / Cypress                      | flutter_test + integration_test         | [M18](../module-18-testing/)                 |

### 6.2 Lỗi phổ biến

1. **Quên `const` constructor** → rebuild không cần thiết → tham khảo [M17](../module-17-performance-animation/)
2. **Nested widget quá sâu** → khó maintain → extract widget, tham khảo [M7](../module-07-base-viewmodel/)
3. **Dùng `setState` thay vì Riverpod** → không scalable → tham khảo [M8](../module-08-riverpod-state/)
4. **Không handle loading/error state** → UX kém → tham khảo [M4](../module-04-exception-handling/)
5. **Bỏ qua null safety** → runtime crash → tham khảo [M0](../module-00-dart-primer/)
6. **Copy-paste AI code không review** → lỗi logic ẩn → tham khảo [AI guidelines](../ai-toolkit/ai-driven-development.md)

### 6.3 Giải pháp

- **Pair programming**: ghép 1 người đã quen Flutter với 1 người mới
- **Code review checklist**: dùng review criteria ở mục 3.4
- **Flashcard**: tạo flashcard so sánh FE↔Flutter concepts
- **Daily standup** (async): báo cáo tiến độ hàng ngày qua Slack/Teams

---

## 7. Weekly Standup Format

### Async Standup (hàng ngày, qua Slack/Teams)

Template:
```
📅 [Ngày]
✅ Hôm qua: [module/bài tập đã hoàn thành]
🔄 Hôm nay: [module/bài tập đang làm]
🚧 Blockers: [vấn đề cần hỗ trợ — hoặc "không có"]
```

### Weekly Sync (15 phút, đầu buổi sync-up)

- Mỗi thành viên báo cáo 1 phút:
  - Module đã hoàn thành trong tuần
  - Điểm khó nhất gặp phải
  - Cần hỗ trợ gì
- Facilitator tổng hợp:
  - Ai đang on-track, ai cần hỗ trợ
  - Điều chỉnh lịch nếu cần (VD: thêm buổi cho module khó)

### Escalation Rules

|| Tình huống                         | Hành động                                        |
||------------------------------------|--------------------------------------------------|
|| Trễ 1 buổi                        | Facilitator nhắc nhở, gợi ý catch-up plan        |
|| Trễ 2 buổi                        | 1-on-1 với facilitator, xác định nguyên nhân     |
|| Trễ 3 buổi trở lên               | Báo cáo training lead, xem xét điều chỉnh lộ trình |
|| Không submit bài tập 2 tuần liên tiếp | Meeting với manager + training lead            |

---

## 8. Tài nguyên hỗ trợ

- **Rubric đánh giá**: [middle-level-rubric.md](../tieu-chuan/middle-level-rubric.md)
- **AI tools guide**: [ai-driven-development.md](../ai-toolkit/ai-driven-development.md)
- **Prompt practice**: [prompt-dojo.md](../ai-toolkit/prompt-dojo.md)
- **Capstone project**: [capstone-spec.md](../capstone/capstone-spec.md)
- **Base Flutter project**: `../../base_flutter/`
- **Flutter official docs**: https://docs.flutter.dev
- **Dart language tour**: https://dart.dev/language

---

## 9. Checklist khởi động nhóm học

- [ ] Xác nhận danh sách 6–8 thành viên
- [ ] Chọn và brief facilitator
- [ ] Setup Slack/Teams channel riêng cho nhóm
- [ ] Tạo Git repository cho bài tập (branch per member)
- [ ] Clone và chạy thành công `base_flutter` project
- [ ] Cài đặt Flutter SDK, IDE (VS Code + extensions hoặc Android Studio)
- [ ] Chia sẻ lịch 8 buổi sync-up
- [ ] Giới thiệu [AI tools guide](../ai-toolkit/ai-driven-development.md) và [Prompt Dojo](../ai-toolkit/prompt-dojo.md)
- [ ] Buổi kick-off: giới thiệu chương trình, expectation setting

<!-- AI_VERIFY: generation-complete -->
