# Lanka Go - Smart QR-Based Bus Card Management System

**Lanka Go** is a dedicated, low-cost, offline-capable bus card management system tailored for public transport in Sri Lanka (specifically government buses in Colombo and suburbs).

This repository contains:
1. **Frontend Mobile Application**: Built using Flutter 3.22 + Dart 3.4.
2. **Backend Services API**: Built using Python 3.12 + Flask 3.0.
3. **Database Integration**: Powered by Firebase Auth, Firebase Firestore + local SQLite 3 sync caching layer.

---

## 🚀 Quick Start Guide

### 1. Prerequisites
Make sure you have the following installed on your machine:
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22.0 or higher)
*   [Dart SDK](https://dart.dev/get-started) (v3.4.0 or higher)
*   [Python 3](https://www.python.org/downloads/) (v3.9 or higher, preferably 3.10+)
*   Android Studio (for Android Emulator setup)

---

### 2. Backend Setup & Run (Flask API)

The backend handles central processing, email registration/login validations, PayHere sandbox payments, and synchronizes transactions with Firebase Firestore.

1.  **Navigate to the backend directory**:
    ```bash
    cd backend
    ```

2.  **Add Firebase Credentials (Firestore Integration)**:
    *   Generate a new Private Key from your **Firebase Console** -> **Project Settings** -> **Service Accounts**.
    *   Save the downloaded JSON file as `firebase-key.json` inside the `backend/` directory.
    *(Note: If no file is added, the server will automatically run using an in-memory database simulator for testing).*

3.  **Configure Firebase Authentication (Optional)**:
    *   To enable real email/password login and register verification via Firebase Auth, retrieve your **Web API Key** from your **Firebase Console** -> **Project Settings** -> **General**.
    *   Set it as an environment variable:
        ```bash
        export FIREBASE_WEB_API_KEY="your-firebase-web-api-key"
        ```
    *(Note: If no environment variable is provided, the server will fall back to verifying credentials using the in-memory database simulator).*

4.  **Install dependencies**:
    ```bash
    pip3 install -r requirements.txt
    ```

5.  **Run the backend**:
    ```bash
    python3 app.py
    ```
    The server will start up on **`http://localhost:5002`**. *(Port 5002 is used to avoid port conflicts with the macOS AirPlay Receiver system service).* Keep this terminal window open!

---

### 3. Frontend Setup & Run (Flutter App)

#### Running the Output on the Android Studio Emulator while coding in your IDE:

1.  **Launch the Emulator in Android Studio**:
    *   Open **Android Studio**.
    *   Open the **Device Manager** (phone icon in the top right, or go to **Tools > Device Manager**).
    *   Launch your configured Android Virtual Device (AVD) by clicking the green **Play** button.
    *   Once the emulator has booted up on your screen, you can minimize Android Studio.
2.  **Open this project in your code IDE** (e.g. VS Code, Cursor).
3.  **Verify the emulator is connected**:
    *   Open a terminal in your IDE and run:
        ```bash
        flutter devices
        ```
        You should see your emulator listed (e.g. `emulator-5554`).
4.  **Fetch dependencies**:
    ```bash
    flutter pub get
    ```
5.  **Run the application**:
    *   Run the app from your IDE terminal targeting the running emulator:
        ```bash
        flutter run -d emulator-5554
        ```
        *(Replace `emulator-5554` with your emulator's ID if different).*
    *   **Hot Reload**: Press **`r`** inside your IDE terminal to hot reload changes instantly onto the emulator screen as you edit code.

> [!IMPORTANT]
> **Dynamic Network Routing**: 
> The Flutter application dynamically checks its runtime environment. When running on an Android Emulator, it automatically routes network calls to **`http://10.0.2.2:5002`** (which maps to your host Mac loopback interface where the Flask server is running), while falling back to **`http://localhost:5002`** on Web/iOS.

---

#### Running the Project on Web:
1.  Verify Chrome is connected as a device:
    ```bash
    flutter devices
    ```
2.  Run the app:
    ```bash
    flutter run -d chrome
    ```

---

## 🛠️ Main Features & Business Logic Rules

The following core rules are fully implemented and verified:

| Feature | Description |
| :--- | :--- |
| **Email/Password Auth** | Secure user registration and login powered by Firebase Authentication (or high-fidelity in-memory mock fallback). Includes 100 LKR sign-up promotional credit. |
| **QR Code Scanner Login** | Support logging in instantly using card QR payloads (`LANKAGO:USER:id:name...`). |
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
1.  Widget loading and login interface rendering.
2.  Student fare discount deductions.
3.  LKR 100.00 capping limits.
4.  1-minute scan lockout intervals.
5.  Insufficient balance and card freezing checks.
6.  500 maximum offline transaction blocks.
