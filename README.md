# 📝 Flutter Todo List App

A modern, fully-featured **Todo List application built with Flutter**, using:

* **Firebase Authentication**
* **Cloud Firestore** for tasks
* **Firebase Storage** for task photos
* **Provider + MVVM architecture**
* **Unit tests**
* **Widget tests with mocked images**
* **Service tests with Mockito**
* **GitHub Actions CI** running tests on every push

---

## 🚀 Features

### 🔐 Authentication

* Email/password login (Firebase Auth)
* Sign-up page
* Automatic redirection depending on login state

### 🗂 Task Management

* Add / edit / delete tasks
* Mark tasks as completed
* Add categories (Work, Personal, Health, etc.)
* Add tags
* Attach or remove images (from gallery)
* Filter by category, status, sorting
* Search by title, description, or tags

### 📸 Images

* Upload task images to Firebase Storage
* Display image previews in `TaskTile`
* Remove or replace existing images

### 🧱 Architecture

* MVVM pattern with `ChangeNotifier`
* UI separated into pages, widgets, viewmodels, services
* Each service tested independently with mocks
* Widget tests isolate the UI

### 🧪 Testing

* Unit tests for ViewModels
* Widget tests for components (with fake network images)
* Service tests using Mockito

### 🔄 Continuous Integration

* GitHub Actions workflow that runs **flutter test** on every push and PR.

---

# 📦 Project Structure

```
lib/
│── firebase_options.dart          # Firebase config (auto-generated)
│── main.dart                      # App bootstrap + providers
│
├── services/
│   ├── auth/auth_service.dart     # FirebaseAuth wrapper
│   └── task/task_service.dart     # Firestore + Storage wrapper
│
├── models/
│   └── task_model.dart            # Task entity + mapping
│
├── enum/
│   └── task_enum.dart             # Filters and sort enums
│
├── ui/
│   ├── theme/                     # Themes
│   ├── pages/
│   │   ├── sign_in_page.dart
│   │   ├── sign_up_page.dart
│   │   ├── tasks_page.dart
│   │   └── viewmodels/…           # MVVM logic
│   |
│   ├── widgets/
│       ├── task_tile.dart
│       ├── add_task_sheet.dart
│       └── edit_task_sheet.dart
│
test/
│── viewmodels/
│── widgets/
└── services/
```

---

# 🛠 Setup Instructions

## 1. Install dependencies

```sh
flutter pub get
```

## 2. Configure Firebase

Install FlutterFire CLI:

```sh
dart pub global activate flutterfire_cli
```

Run:

```sh
flutterfire configure
```

This generates:

* `firebase_options.dart`
* GoogleService-Info.plist (iOS)
* google-services.json (Android)

## 3. Enable Firebase Services

In Firebase Console:

### Required:

| Service          | Used For         |
| ---------------- | ---------------- |
| Authentication   | Login / Sign-up  |
| Cloud Firestore  | Storing tasks    |
| Firebase Storage | Uploading photos |

✔ Enable Email/Password authentication
✔ Create Firestore DB (Production mode recommended)
✔ Enable Firebase Storage

---

# ▶️ Running the App

```sh
flutter run
```

---

# 🧪 Running Tests

## 1. Generate mocks

(If you modify any `@GenerateMocks`)

```sh
dart run build_runner build --delete-conflicting-outputs
```

## 2. Run all tests

```sh
flutter test
```

Widget tests use a custom fake HTTP client so that network images do not crash during tests.

---

# ⚙️ GitHub Actions CI

Create the file:

**.github/workflows/flutter-ci.yml**

```yaml
name: Flutter CI

on:
  push:
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --no-pub
```

✔ Runs on every push
✔ Runs on PR
✔ Executes all unit, widget, and service tests

---

# 🧪 Testing Strategy

### Unit tests

Located in `test/viewmodels/`

Examples:

* `tasks_view_model_test.dart`
* `edit_task_view_model_test.dart`

Test:

* Filtering logic
* Sorting
* Search
* ViewModel state changes

---

### Widget tests

Located in `test/widgets/`

Examples:

* `task_tile_test.dart`
* `add_task_sheet_test.dart`

Widgets tested:

* UI appearance
* Buttons, chips, image display
* Actions (open edit, delete, mark completed)

---

### Service tests

Located in `test/services/`

Examples:

* `task_service_test.dart`
* `auth_service_test.dart`

Mocked with Mockito:

* FirebaseAuth
* FirebaseFirestore
* FirebaseStorage

Uses dependency injection:

```dart
TaskService(
  auth: mockAuth,
  firestore: mockFirestore,
  storage: mockStorage,
);
```

---

# 🧰 Troubleshooting

### ❌ "MissingStubError: collection('tasks')"

You must stub Firestore:

```dart
when(mockFirestore.collection('tasks'))
  .thenReturn(fakeCollection);
```

### ❌ Widget test fails loading image

Add:

```dart
setUpAll(() => HttpOverrides.global = FakeHttpOverrides());
```

### ❌ `thenReturn` used with a Future

Use:

```dart
thenAnswer((_) async => value);
```

### ❌ build_runner says “skipped”

Remove generated files:

```sh
rm -rf lib/**/**.mocks.dart
dart run build_runner build --delete-conflicting-outputs
```

---

# 📄 License

MIT License — free to use, modify, distribute.
