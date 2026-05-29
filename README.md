# Lanka Go - Smart QR-Based Bus Card Management System

**Lanka Go** is a dedicated, low-cost, offline-capable bus card management system tailored for public transport in Sri Lanka (specifically government buses in Colombo and suburbs). 

This repository contains:
1. **Frontend Mobile Application**: Built using Flutter 3.22 + Dart 3.4.
2. **Backend Services API**: Built using Python 3.12 + Flask 3.0.
3. **Database Integration**: Powered by Firebase Firestore + local SQLite 3 sync caching layer.

---

## 🚀 Quick Start Guide

### 1. Prerequisites
Make sure you have the following installed on your machine:
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22.0 or higher)
*   [Dart SDK](https://dart.dev/get-started) (v3.4.0 or higher)
*   [Python 3](https://www.python.org/downloads/) (v3.9 or higher, preferably 3.10+)
*   An Android Emulator, iOS Simulator, or physical device connected.

---

### 2. Backend Setup & Run (Flask API)

The backend handles central processing, PayHere sandbox payments, and synchronizes transactions with Firebase Firestore.

1.  **Navigate to the backend directory**:
    ```bash
    cd backend
    ```

2.  **Add Firebase Credentials (Firestore Integration)**:
    *   Generate a new Private Key from your **Firebase Console** -> **Project Settings** -> **Service Accounts**.
    *   Save the downloaded JSON file as `firebase-key.json` inside the `backend/` directory.
    *(Note: If no file is added, the server will automatically run using an in-memory database simulator for testing).*

3.  **Install dependencies**:
    ```bash
    pip3 install -r requirements.txt
    ```

4.  **Run the backend**:
    ```bash
    python3 app.py
    ```
    The server will start up on **`http://localhost:5001`**. Keep this terminal window open!

---

### 3. Frontend Setup & Run (Flutter Mobile)

The frontend mobile app performs offline scans, manages user balances, displays routes, and syncs queue records.

1.  **Navigate back to the project root**:
    ```bash
    cd ..
    ```

2.  **Fetch dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the application**:
    > [!IMPORTANT]
    > Because `sqflite` (the native SQLite caching plugin) was recently integrated, do **not** use hot reload for the first run. You must perform a clean compile to link native libraries.
    
    ```bash
    flutter run
    ```
    *(If multiple devices are available, you can select your simulator or run `flutter run -d chrome` / `flutter run -d macos` if desktop is configured).*

---

## 🛠️ Main Features & Business Logic Rules

The following core rules are fully implemented and verified:

| Feature | Description |
| :--- | :--- |
| **50% Student Discount** | Automatically slashes travel fares by 50% if the passenger `accountType` is `'student'`. |
| **LKR 100 Daily Cap** | Limits total expenditures to LKR 100.00 per calendar day. Subsequent rides cost LKR 0.00 and are saved as `travel_capped`. |
| **Duplicate Scan Protection** | Blocks consecutive card scans on the same bus within 1 minute of each other to prevent accidental double-billing. |
| **Offline SQLite Cache** | Allows up to 500 transactions to be queued offline on the validator, checking local card values. They are pushed/synced to Firestore when online connectivity returns. |
| **Low Balance Alerts** | Activates if the card balance drops below LKR 50.00, simulating a Firebase Push Notification in the UI and logging a fallback telco SMS to the console. |
| **PayHere Sandbox Gateway** | Simulates reloading balances (min LKR 10.00) using PayHere sandbox signatures (MD5 check). |

---

## 🧪 Running Automated Tests

We use `sqflite_common_ffi` to test SQLite queues and provider state management rules directly from the command line.

Run all tests using:
```bash
flutter test
```

This validates:
1.  Student fare discount deductions.
2.  LKR 100.00 capping limits.
3.  1-minute scan lockout intervals.
4.  Insufficent balance and card freezing checks.
5.  500 maximum offline transaction blocks.
