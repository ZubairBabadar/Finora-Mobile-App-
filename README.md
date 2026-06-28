# Finora 🚀

Finora is a secure, high-performance, cross-platform mobile trading dashboard and portfolio management simulator built using **Flutter** and **Dart**. Designed with a robust cloud-native architecture, Finora integrates live financial market data with secure, state-aware cloud synchronization to deliver an intuitive and responsive user experience.

This project was developed as a comprehensive practical security and software engineering implementation for the **IT Security** curriculum at the **University of Europe for Applied Sciences**.

---

# 🎓 Academic Credentials

* **Developer:** Zubair Hassan Badar Babadar
* **Enrolled Program:** IT Security (B.Sc.)
* **Current Semester:** 4th Semester (Group A+B)
* **University Matriculation Number:** 26710250
* **Institution:** University of Europe for Applied Sciences

---

# ✨ Core Features

* **📈 Live Market Tracking:** Consumes data from the Finnhub API to display live quote pricing, historical chart coordinate trends, and active financial indices dynamically.
* **💼 Advanced Portfolio Simulation:** Supports immediate **BUY IN** and **LIQUIDATE** transaction pipelines that calculate real-time capital allocation metrics, average cost bases, and dynamic profits/losses.
* **📊 Visual Asset Allocation:** Features interactive multi-timeframe line charts (`1D`, `1W`, `1M`) alongside a custom-rendered asset distribution doughnut chart driven directly by live holdings data.
* **💳 Interactive Wallet Funding:** Includes an embedded modal bottom sheet allowing simulated fiat currency deposits via multiple funding channels (Bank, PayPal, Credit Card).
* **📰 Real-Time Market Intelligence:** Integrates a localized news engine that processes and presents trending macroeconomic news relevant to each selected equity index.
* **🛡️ Security-Hardened Cloud Pipeline:** State persistence is synchronized securely through Google Cloud Firestore with authenticated access control.

---

# 🛠️ Architecture & Tech Stack

## Technology Stack

| Layer                | Technology                         |
|:---------------------|:-----------------------------------|
| **Frontend**         | Flutter (Dart)                     |
| **State Management** | ListenableBuilder + ChangeNotifier |
| **Backend**          | Google Firebase                    |
| **Database**         | Cloud Firestore                    |
| **Charts**           | fl_chart                           |
| **Market Data**      | Finnhub REST API                   |

---

## System Architecture

The application follows a cloud-native architecture where the Flutter client communicates securely with Firebase Authentication and Cloud Firestore while retrieving live financial market data from the Finnhub REST API.

The business logic is separated from the presentation layer through dedicated service classes and portfolio management components. UI updates are driven through Flutter's `ListenableBuilder` and Change Notification architecture, enabling efficient state synchronization and immediate interface refreshes after data mutations.

---

# 📂 Project Structure

```text
Finora/
├── assets/
│   └── images/
│       └── logo.png
└── lib/
    ├── screens/
    │   ├── account_screen.dart
    │   ├── auth_screen.dart
    │   ├── detail_screen.dart
    │   ├── home_screen.dart
    │   ├── portfolio_screen.dart
    │   ├── premium_screen.dart
    │   └── watchlist_screen.dart
    │
    ├── services/
    │   ├── finnhub_service.dart
    │   ├── location_service.dart
    │   ├── otp_service.dart
    │   └── watchlist_manager.dart
    │
    ├── widgets/
    │   ├── app_logo.dart
    │   ├── forgot_password_sheet.dart
    │   ├── otp_verification_sheet.dart
    │   └── trade_sheet.dart
    │
    ├── firebase_options.dart
    ├── main.dart
    ├── navigation_controller.dart
    └── portfolio_manager.dart
```
---

# 🚀 Getting Started

## Prerequisites

Before running the application, ensure you have the following installed:

* Flutter SDK (Latest Stable Channel)
* Android Studio or Xcode
* Git
* A valid Finnhub API Key
* A Firebase Project

---

## 1. Clone the Repository

```bash
git clone https://github.com/ZubairBabadar/finora.git
cd finora
```

---

## 2. Install Dependencies

```bash
flutter pub get
```

---

## 3. Configure the Finnhub API

Insert your API key into the application's configuration.

```dart
const String FINNHUB_API_KEY = "YOUR_SECRET_API_KEY_HERE";
```

---

## 4. Configure Firebase

Authenticate the project using FlutterFire.

```bash
flutterfire configure
```

---

## 5. Run the Application

```bash
flutter run
```

---

# 🔒 Security Practices & Compliance

Developed following academic IT Security best practices:

* Secure authentication using Firebase Authentication.
* Cloud Firestore security rules enforcing authenticated access.
* Separation between presentation, business logic, and network layers.
* Stateful portfolio synchronization through secure cloud persistence.
* Transaction validation prior to portfolio mutation.
* API keys isolated from application logic.
* Defensive input validation across authentication and trading workflows.
* Modular architecture reducing attack surface and improving maintainability.

---

# 📚 Technologies Used

* Flutter
* Dart
* Firebase Authentication
* Cloud Firestore
* Finnhub REST API
* fl_chart
* Google Cloud

---

# 📄 License

This project was developed solely for academic purposes as part of the **IT Security (B.Sc.)** curriculum at the **University of Europe for Applied Sciences**.

Unauthorized commercial redistribution is not permitted without the author's permission.
