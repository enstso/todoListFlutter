# 📝 Flutter Todo List App

A modern and scalable **Todo List application built with Flutter**, powered by:

* **Firebase Authentication**
* **Cloud Firestore**
* **Firebase Storage**
* **Provider + MVVM architecture**
* **Task assignment system**
* **Dynamic Light/Dark theme**
* **Unit, Widget and Service tests**
* **Full CI pipeline with GitHub Actions**

---

# 🚀 Features

## 🔐 Authentication

* Email/password login
* Secure signup
* Live auth state tracking (auto redirect)

## 🗂 Task Management

* Add / edit / delete tasks
* Mark as completed or pending
* Category selection (Work, Personal, Shopping, etc.)
* Add tags
* Attach/remove/replace photos
* Automatic creation + completion timestamps
* Image preview inside task tiles

## 🧑‍🤝‍🧑 Task Assignment System (NEW)

✔ Assign a task to another registered user
✔ Email validation in real time
✔ Prevents assigning a task **to yourself**
✔ Displays **assignee email** in the task card
✔ Assignee also sees tasks assigned to them (Firestore rules-ready)

## 🌓 Light & Dark Mode (NEW)

✔ System theme support
✔ Manual toggle in the app (AppBar icon)
✔ Saved using a `ThemeProvider`
✔ Clean Material 3 design

## 🎨 UI / UX

* Modern Material 3 UI
* Smart category color coding
* Smooth bottom sheet editor
* Search by title, description or tags
* Filter by category / status
* Sort by date or alphabetical
* Active filters displayed as chips
* Empty state screens

## 🧱 Architecture

* MVVM (Model - View - ViewModel)
* Provider for dependency injection + state
* Clean Services: `AuthService`, `TaskService`, `UserService`
* Reusable UI components (`TaskTile`, `CategoryFilter`, `AddTaskSheet`, etc.)
* Fully typed models and enums

## 🧪 Testing

* **ViewModel unit tests**
* **Service tests with Mockito** (Firestore, Auth, Storage mocked)
* **Widget tests** using `network_image_mock`
* **Test coverage for assignment system**
* **Fail fast on GitHub Actions**

# 📦 Project Structure

```
lib/
│── firebase_options.dart
│── main.dart
│
├── services/
│   ├── auth/auth_service.dart
│   ├── task/task_service.dart
│   └── user/user_service.dart       
│
├── models/
│   └── task_model.dart
│
├── enum/
│   └── task_enum.dart
│
├── ui/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_provider.dart      
│   │
│   ├── pages/
│   │   ├── sign_in_page.dart
│   │   ├── sign_up_page.dart
│   │   ├── tasks_page.dart
│   │   └── viewmodels/
│   │       ├── add_task_view_model.dart
│   │       ├── edit_task_view_model.dart
│   │       └── task_view_model.dart
│   │
│   └── widgets/
│       ├── add_task_sheet.dart
│       ├── edit_task_sheet.dart
│       └── task_tile.dart
│
test/
│── viewmodels/
│── services/
└── widgets/
```

---

# 🛠 Setup Instructions

## 1. Install dependencies

```sh
flutter pub get
```

## 2. Configure Firebase

```sh
dart pub global activate flutterfire_cli
flutterfire configure
```

Services required:

| Service             | Purpose          |
| ------------------- | ---------------- |
| 🔐 Auth             | Login & signup   |
| 🔥 Firestore        | Tasks storage    |
| 📦 Storage          | Task images      |
| 👥 Users collection | Task assignation |

### Important Firestore Collections

```
users/
   uid/email
tasks/
   taskId/{userId, assignedToUid, ...}
```

---

# ▶️ Run the App

```sh
flutter run
```

---

# 🧪 Run Tests

## Generate mocks

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Run all tests

```sh
flutter test
```

---

# 🔄 GitHub Actions CI

Runs automatically on every push + PR:

```yaml
name: Flutter CI
on:
  push:
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: flutter pub get
      - run: flutter test --no-pub
```

✔ Ensures no broken merge
✔ Executes all unit/widget/service tests

---

# 🧰 Troubleshooting

### “Cannot assign task to yourself”

This is intentional: `AddTaskViewModel` & `EditTaskViewModel` block it.

### `MissingStubError: collection('users')`

You must stub **both** Firestore collections in tests:

```dart
when(mockFirestore.collection('users')).thenReturn(fakeUsers);
```

### Image crashes in widget tests

Use:

```dart
mockNetworkImagesFor(() async { ... });
```

### build_runner skipping files

Delete generated mocks:

```sh
rm -rf lib/**/*.mocks.dart
dart run build_runner build --delete-conflicting-outputs
```

---

# 📄 License

MIT License — open-source, free to modify & distribute.