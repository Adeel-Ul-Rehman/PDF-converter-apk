# 📱 FluxConvert — Advanced PDF Converter & Document Scanner

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2F%20Feature--First-blueviolet)](#project-architecture)
[![State Management](https://img.shields.io/badge/State-Riverpod%202.x-brightgreen)](https://riverpod.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-orange)](#supported-platforms)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**FluxConvert** is a modern, high-performance, **100% offline-first** document converter, smart camera scanner, and PDF utility suite built with **Flutter**. Designed with clean architecture and Material 3 design principles, FluxConvert handles all document processing, conversions, compressions, and encryptions completely on-device without requiring an internet connection or compromising user privacy.

---

## 🌟 Key Features

### 📸 Smart Document Scanner
- **Live Edge Detection**: Automatically identifies document boundaries and quadrilateral corners via camera stream.
- **Perspective Correction**: Transforms skewed, angled captures into flat, rectilinear documents.
- **Multi-Page Batch Sessions**: Scan multiple pages continuously with quick re-ordering, deletion, and retakes.
- **Enhancement Filters**: One-tap image post-processing including **Magic Color**, **Black & White**, **Grayscale**, and **Original**.

### 🖼️ Image to PDF Converter
- Import multiple images from camera or photo library.
- **Drag-and-Drop Sorting**: Rearrange page sequence intuitively before conversion.
- **Image Editor**: In-app crop, rotate, flip, and contrast adjustments.
- **Custom Page Layouts**: Configure margins, page orientations (*Portrait* / *Landscape*), and paper dimensions (*A4*, *Letter*, *Fit-to-Image*).

### 📄 Document & Spreadsheet Conversion
- Convert **Text files (`.txt`)** to styled PDF documents.
- Convert **Excel Spreadsheets (`.xlsx`, `.xls`)** directly into paginated PDFs.
- Clean document layout rendering with custom fonts and tables.

### 🗜️ Advanced PDF Compression
- Multi-tier compression engine (**Low**, **Medium**, **Extreme**).
- Drastically reduces file size for email and messaging attachments while maintaining crisp text readability.
- Real-time file size estimation and side-by-side comparison before saving.

### 🔒 PDF Security & Encryption
- **AES Password Protection**: Set user and owner passwords for confidential documents.
- **Permission Controls**: Restrict printing, copying, and modification.
- **PDF Decryption**: Unlock password-protected PDFs with valid credentials.

### ✍️ Signatures & Annotations
- **Electronic Signature Pad**: Create, save, and overlay digital signatures directly onto PDF pages.
- **Freehand Doodling**: Draw, highlight, and sketch on top of documents.
- **Text Overlays**: Add custom text notes, headers, and stamps.
- **Watermarking**: Apply semi-transparent text or logo watermarks across all pages.

### 📑 PDF Manipulation Tools
- **Merge PDFs**: Combine multiple PDF documents into a single consolidated file.
- **Split PDFs**: Extract specific pages or divide files by page ranges.
- **Page Management**: Reorder, rotate, or delete specific pages within any existing PDF.

### 👁️ Built-in High-Performance PDF Viewer
- Powered by Syncfusion PDF engine with hardware-accelerated rendering.
- Smooth pinch-to-zoom, page carousel, vertical/horizontal scrolling, thumbnail previews, outline bookmarks, and search.

### 🗄️ Offline Storage & History
- Comprehensive history log of all converted documents with date, size, and page count.
- Instant search and filtering.
- Quick actions: Open, Share via Android System Sheet, Rename, and Delete.
- Storage manager with cache cleanup and orphan file scanner to keep device storage clean.

### 🎨 Material 3 UI / UX
- Full support for **Light** and **Dark** themes (system adaptive).
- Zero network font dependencies — utilizes bundled and system typography to guarantee flawless 100% offline startup.
- Memory-pressure-aware image caching preventing Out-Of-Memory (OOM) crashes on large batches.

---

## 🏗️ Project Architecture

The application adheres to **Clean Architecture** organized with a **Feature-First** directory structure for maximum testability, modularity, and maintainability:

```text
lib/
├── bootstrap/               # App initialization, async setup, service locators
├── core/                    # Cross-cutting utilities, theme, routing, shared UI
│   ├── animations/          # Reusable motion transitions
│   ├── constants/           # Global dimensions, keys, and tokens
│   ├── error/               # Global error handling and zoned guard callbacks
│   ├── logging/             # Structured logger service (silenced in release)
│   ├── permissions/         # Android 13+ runtime permission handlers
│   ├── routing/             # GoRouter configuration & deep link observers
│   ├── services/            # Storage, notifications, and error logging services
│   ├── theme/               # Material 3 light/dark color schemes & typography
│   └── widgets/             # Common UI components (buttons, dialogs, loaders)
├── features/                # Domain-specific modules
│   ├── annotations/         # PDF drawing, signatures, and markups
│   ├── conversion/          # Core conversion engine and validation pipeline
│   ├── converter/           # Conversion selection UI and settings
│   ├── document_converter/  # Text & Excel to PDF processors
│   ├── files/               # File manager & picker abstractions
│   ├── history/             # Conversion history and records repository
│   ├── home/                # Main dashboard, quick tools, and navigation shell
│   ├── image_editor/        # Image cropping, rotating, and filters
│   ├── image_engine/        # High-speed image decoding, EXIF orientation
│   ├── notifications/       # Local notifications for conversion status
│   ├── pdf_compression/     # Compression algorithms and quality presets
│   ├── pdf_engine/          # Syncfusion PDF generation, merge, split, security
│   ├── pdf_viewer/          # Custom PDF viewer with thumbnail navigation
│   ├── performance/         # Memory monitoring and image cache limits
│   ├── security/            # Encryption, password protection, and hash utilities
│   ├── settings/            # Theme, default export paths, developer logs
│   ├── smart_scan/          # Camera live edge detection & perspective transform
│   ├── splash/              # Animated brand launch sequence
│   └── storage/             # Path management, cache cleanup, disk stats
└── main.dart                # Application entrypoint with zoned guard
```

---

## 🛠️ Tech Stack & Dependencies

| Layer | Package / Tool | Purpose |
| :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (SDK ^3.11.0) | Cross-platform UI toolkit |
| **Language** | [Dart](https://dart.dev) | Object-oriented client-optimized language |
| **State Management** | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) `^2.6.1` | Reactive, compile-safe dependency injection & state |
| **Navigation** | [go_router](https://pub.dev/packages/go_router) `^15.1.2` | Declarative URL-based routing with shell navigation |
| **PDF Processing** | [syncfusion_flutter_pdf](https://pub.dev/packages/syncfusion_flutter_pdf) `^33.2.13`<br>[pdf](https://pub.dev/packages/pdf) `^3.11.1` | Low-level PDF creation, compression, security, merging |
| **PDF Viewer** | [syncfusion_flutter_pdfviewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer) `^33.2.13`<br>[pdfx](https://pub.dev/packages/pdfx) `^2.6.0` | High-fidelity PDF rendering with pinch-zoom |
| **Camera & Capture** | [camera](https://pub.dev/packages/camera) `^0.11.0+2` | Hardware camera stream for smart scanning |
| **Image Processing** | [image](https://pub.dev/packages/image) `^4.3.0` | Pure Dart image decoding, matrix transforms, filters |
| **Spreadsheets** | [excel](https://pub.dev/packages/excel) `^4.0.2` | Reading and parsing `.xlsx` worksheets |
| **File Access** | [file_picker](https://pub.dev/packages/file_picker) `^8.1.7`<br>[path_provider](https://pub.dev/packages/path_provider) `^2.1.5` | Storage directory access and file selection |
| **Permissions** | [permission_handler](https://pub.dev/packages/permission_handler) `^11.3.1` | Android 13+ granular permission handling |
| **Sharing** | [share_plus](https://pub.dev/packages/share_plus) `^10.1.0` | Native system sharing dialog |

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your development machine:
1. **Flutter SDK** (`>= 3.11.0`): [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Dart SDK** (included with Flutter)
3. **Android Studio** with Android SDK and command-line tools
4. **Java JDK 17** (recommended for Android Gradle Plugin 8+)
5. An Android device or emulator running **Android 5.0 (API 21)** or higher

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Adeel-Ul-Rehman/PDF-converter-apk.git
   cd PDF-converter-apk
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code generation** (if modifying freezed or json_serializable models):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📦 Building Production Binaries

### Generate Android APK
To compile a release APK for manual distribution or testing:
```bash
flutter build apk --release
```
The output APK will be generated at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### Generate Android App Bundle (AAB)
To produce an optimized AAB for the Google Play Store:
```bash
flutter build appbundle --release
```
The output bundle will be generated at:
```text
build/app/outputs/bundle/release/app-release.aab
```

---

## 🧪 Testing

The repository contains automated unit and widget tests:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

Key test suites:
- `test/features/smart_scan/` — Perspective transform algorithms and document quadrilateral calculation.
- `test/features/pdf_compression/` — PDF compression service and state notifiers.

---

## 🔒 Permissions & Privacy

FluxConvert is strictly an **offline-first** application.
- **No data is uploaded to external servers.**
- All conversions, OCR/scan operations, and compression processes occur directly on the device CPU/GPU.
- Required Android permissions:
  - `CAMERA`: For live document scanning.
  - `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`: For picking photos from gallery.
  - `POST_NOTIFICATIONS`: For background conversion progress updates.

---

## 👤 Author

**Adeel Ul Rehman**
- GitHub: [@Adeel-Ul-Rehman](https://github.com/Adeel-Ul-Rehman)
- Repository: [PDF-converter-apk](https://github.com/Adeel-Ul-Rehman/PDF-converter-apk)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
