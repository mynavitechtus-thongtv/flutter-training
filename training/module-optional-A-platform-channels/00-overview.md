# Optional Module A — Platform Channels

> **Depth:** Advanced Survey — optional module, lighter scaffolding

---

## Mục tiêu

Sau module này, bạn sẽ:
- Hiểu kiến trúc platform channel: MethodChannel, EventChannel, BasicMessageChannel
- Trace flow Flutter ↔ Native, phân biệt plugin package vs raw channel
- Nắm Pigeon code generation cho type-safe channel interface

---

## Prerequisites

| Module | Cần nắm |
|--------|---------|
| **M0** | Dart basics, type system — codec serialization dựa trên Dart types |
| **M1** | `WidgetsFlutterBinding` — platform channel messages dispatch |
| **M3** | Config/Constants — environment values, app initialization |

---

## Nội dung

| File | Nội dung | Thời lượng |
|------|----------|-----------|
| [01-code-walk.md](./01-code-walk.md) | FlutterMethodChannel iOS, FlutterEngine, plugin registration | ~30 min |
| [02-concept.md](./02-concept.md) | 6 concepts: channel types, codecs, flow, callbacks, plugin vs raw, Pigeon | ~25 min |
| [03-exercise.md](./03-exercise.md) | 3 exercises: trace channels → MethodChannel battery → Pigeon type-safe API | ~2-4 hrs |
| [04-verify.md](./04-verify.md) | Checklist xác nhận hoàn thành | ~10 min |

**Phân bố:** 🔴 ~33% · 🟡 ~50% · 🟢 ~17%

---

## Anchor Files

```
ios/Runner/AppDelegate.swift           — FlutterMethodChannel explicit ("jp.flutter.app")
ios/Runner/SceneDelegate.swift         — FlutterEngine lifecycle
android/.../MainActivity.kt           — FlutterActivity (extensible for channels)
android/.../GeneratedPluginRegistrant  — 15+ auto-registered plugin channels
lib/data_source/preference/app_preferences.dart — FlutterSecureStorage (implicit channel)
```

---

## 💡 FE Perspective Summary

| Flutter | Frontend Equivalent |
|---------|-------------------|
| `MethodChannel` | WebView `postMessage` / RN `NativeModules` |
| `EventChannel` | `EventSource` (SSE) / WebSocket |
| `FlutterEngine` | WebView JS runtime / RN Bridge (JSI) |
| Plugin package | Cordova/Capacitor plugin / RN module |
| Pigeon codegen | RN Codegen (TurboModules) |

---

## Forward Reference

→ **Module Optional B: Push & Deep Link** deep-dives vào Firebase Messaging plugin — real-world complex plugin dùng MethodChannel + EventChannel.

<!-- AI_VERIFY: generation-complete -->
