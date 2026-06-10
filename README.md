# 💸 Xpense - Monthly Expense Monitoring App

![Platform](https://img.shields.io/badge/Platform-Android-green?style=for-the-badge&logo=android)
![Language](https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart)
![Framework](https://img.shields.io/badge/Framework-Flutter-02569B?style=for-the-badge&logo=flutter)
![AI Integration](https://img.shields.io/badge/AI_Integration-Gemini_3.5_Flash-FF6F00?style=for-the-badge&logo=google-gemini)

An advanced, intelligent personal finance companion built with Flutter that completely simplifies monthly expense tracking. By combining automated SMS transaction parsing with Google's Gemini AI, Xpense eliminates the tedious chore of manual budgeting, turning daily text notifications and physical receipts into clear financial insights.

### 🚀 Download Link
📥 **[Click Here to Download Xpense APK (v1.0.0)](https://github.com/JAKOB-010/xpense-monthly-expense-monitoring-app/releases/download/v1.0.0/xpense.app.apk)


---

## 📝 Project Description

**Xpense** is designed for anyone who wants effortless command over their personal cash flow. Traditional tracking applications fail because they demand meticulous manual input for every minor purchase. Xpense bridges this gap through seamless automation and cloud security.

The app relies strictly on **Cloud Firestore** as its absolute single source of truth, guaranteeing your dashboard syncs flawlessly across active sessions. Security is prioritized down to the infrastructure layer: runtime secrets are fed directly from protected environment configurations, while underlying ProGuard configuration files safeguard your native builds against code optimization issues. Whether you are budgeting manually, scanning bills with AI, or tracking notifications natively, Xpense serves as a secure, local financial operations center.

### 🌟 Core Pillars

* **AI Bill Parsing:** Direct REST integration with the high-speed **Gemini 3.5 Flash** model securely extracts amounts, vendors, and line items from complex invoices, bypassing heavy SDK wrapper version locks.
* **Automated Inbox Insights:** A custom regex-driven `BankMessageParser` safely ingests financial alerts locally via your inbox, using a dedicated session cache to avoid redundant platform reads.
* **Modern Android Foundations:** Updated entirely to modern Flutter standards, featuring an architecture built on native Kotlin tooling alongside strict security overrides.

---

## 📑 Table of Contents

* [Project Description](#-project-description)
* [Features & Screenshots](#-features)
* [Technical Architecture](#-technical-architecture)
* [Installation & Setup](#-installation--setup)
* [How to Use](#-how-to-use)
* [Credits & Acknowledgments](#-credits--acknowledgments)

## ✨ Features & Screenshots

Xpense provides a seamless financial monitoring experience by blending an intuitive, modern user interface with advanced backend integrations like Google’s Gemini AI and native device data extraction.

### 🔐 1. Secure Authentication

Access to Xpense is protected by a secure authentication layer. This ensures that personal expense data synced from the local device to the cloud remains private to the authenticated user.

* **Firebase Auth Integration:** The application utilizes a secure login system tied directly to Firebase Authentication, protecting all Cloud Firestore data.
* **Intuitive UI:** Features clear, focused inputs for Email and Password, along with essential "Remember Me" and "Forgot Password" functions.

<p align="center">
  <img src="https://github.com/user-attachments/assets/02cd36da-0bc2-43f3-9b71-435416d117c6" width="300" alt="Xpense Login Authentication Screen" />
</p>


### 🏠 2. The Home Dashboard

Once authenticated, users are greeted with a high-level command center providing an immediate overview of their monthly financial health, pulling real-time data from Cloud Firestore.

* **Expense Overview:** A bold indicator of the total combined expenses logged for the active period.
* **Category Breakdown:** Expenses are automatically segmented into distinct, aesthetic cards for primary categories like "Food" and "Grocery," displaying category illustrations and the exact currency spent.

<p align="center">
  <img src="https://github.com/user-attachments/assets/f6ef5548-5ac6-4b3e-918f-01b7a46c9ca8" width="300" alt="Xpense Home Screen Dashboard" />
</p>



### 🚀 3. Intelligent Expense Tracker & AI Bill Scanner

This core feature page offers multiple avenues for expense logging, using state management to provide instantaneous budget feedback.

* **Data Visualization:** A dynamic donut chart provides a visual distribution of spending between active categories.
* **Real-time Budgeting:** Setting a new income via **Set Salary** instantly triggers budget recalculations via standard `setState` logic, updating the **Total Salary** and remaining **Balance** metrics.
* **Gemini AI Bill Scanner (Key Feature):** Tapping "Scan Bill" captures a receipt image which is converted to Base64 format. The app then makes a high-speed HTTP REST call to the **Gemini 3.5 Flash** model (bypassing SDK wrappers for maximum stability). The AI securely extracts vendor names and total amounts, automagically pre-filling the entry form.
* **Analytics:** A "Compare Years" button enables historical data analysis.

<p align="center">
  <img src="https://github.com/user-attachments/assets/675f21f6-235b-4bb9-918b-7614f83fb4b7" width="300" alt="Xpense Expense Tracker and AI Scan Screen" />
</p>



### 📲 4. Native SMS Bank Statement Parser

Xpense turns daily financial notifications into useful financial records by parsing native device messages.

* **Regex Parser:** Utilizes the `flutter_sms_inbox` package to retrieve device messages. Incoming SMS alerts from confirmed banking headers are processed locally by a custom **Regular Expression (RegEx)** `BankMessageParser` class to extract transaction amounts and resulting balances, displayed cleanly in Indian Rupees (₹).
* **Performance Optimization:** `sms_screen.dart` utilizes dedicated static variable caching to keep the extracted SMS messages in memory, preventing redundant, slow inbox reads during a single app session.

<p align="center">
  <img src="https://github.com/user-attachments/assets/5346f908-75ed-403d-be46-39b55c06477d" width="300" alt="Xpense SMS Banking Tracker" />
</p>


### ⚙️ 5. Personalized Settings & Theme Control

The configuration screen allows for basic profile review and global app state customization.

* **Provider Theme Toggling:** Toggling the **Light Mode** switch instantly shifts the app’s default dark mode aesthetic to light mode. This implementation utilizes the **Provider** pattern specifically for global state management via the `ThemeNotifier` class.
* **Account Controls:** Provides quick access to standard sign-out procedures and critical secure **Delete Account** functions.

<p align="center">
  <img src="https://github.com/user-attachments/assets/f5d9d0da-6690-41c4-8825-d8b37e30a408" width="300" alt="Xpense Profile and Theme Settings Screen" />
</p>

## 🏗️ Technical Architecture

Xpense is built on a modular architecture designed to separate the user interface, native device sensors, local processing, and cloud/AI integrations. This ensures the app remains highly responsive while securely handling sensitive financial data.

<p align="center">
  <img src="https://github.com/user-attachments/assets/fa3cbcd7-3d22-49c1-a298-3b69f787800e" alt="Xpense Technical Architecture Diagram" />
</p>

### 1. Application Framework & State Layer
The core of the application is built using the **Flutter View Engine**, delivering a natively compiled, cross-platform UI.
* **Global State (Provider):** The `ThemeNotifier` utilizes the Provider package to broadcast theme changes (Dark/Light mode) globally across the widget tree without rebuilding unaffected components.
* **Component State:** Standard `setState` logic is used for highly localized, instantaneous UI mutations, such as real-time budget recalculations when adding an expense.

### 2. Local Data Processing Engine & Native Hardware
To ensure user privacy and optimal performance, SMS parsing is handled entirely locally on the device.
* **Native OS Sensor:** The app hooks into the Android OS via `flutter_sms_inbox` to read notification logs.
* **RegEx Pipeline:** The custom `BankMessageParser` class applies strict Regular Expressions to identify valid banking headers and extract financial variables (amounts, balances).
* **In-Memory Cache:** `sms_screen.dart` utilizes a session cache to hold parsed SMS data in memory, preventing redundant and resource-heavy inbox reads during a single active session.

### 3. Intelligence Pipeline (AI)
The application avoids heavy, version-locked AI SDKs in favor of direct network communication.
* **Base64 Encoding:** Captured receipt images are compressed and converted into Base64 binary strings directly on the device.
* **Direct REST API Endpoint:** The Base64 payload is securely transmitted via a high-speed HTTPS POST request directly to the **Gemini 3.5 Flash** model, which tokenizes the vendor and total amount, returning a clean JSON response to the Flutter UI.

### 4. Google Cloud Infrastructure (Backend)
All persistent user data is strictly managed through Google's Firebase infrastructure to guarantee secure cross-session synchronization.
* **Firebase Authentication:** Handles user context partitioning, ensuring that every database read/write is strictly bound to an authenticated session token.
* **Cloud Firestore:** Acts as the absolute single source of truth for the application. The dashboard streams real-time updates directly from Firestore documents.

### 5. Build & Native Security Layer
The underlying Android build infrastructure has been modernized and locked down to prevent compilation errors and memory leaks.
* **Built-in Kotlin Daemon:** Migrated to modern `org.jetbrains.kotlin.android` tooling for faster, safer native compilation.
* **ProGuard Obfuscation:** A custom `proguard-rules.pro` configuration safeguards the release APK, explicitly preventing the R8 compiler from aggressively minifying or stripping out critical optional dependencies (like ML Kit components).

## 🛠️ Installation & Setup

To get a local copy of the Xpense project up and running on your development machine, follow these steps. 

### Prerequisites

Before you begin, ensure you have the following installed and configured:
* **Flutter SDK:** [Install Flutter](https://docs.flutter.dev/get-started/install) (Ensure you are on the stable channel, modern version).
* **IDE:** Android Studio, VS Code, or IntelliJ IDEA with the Flutter & Dart plugins installed.
* **Firebase Account:** A Google account to create a Firebase Project.
* **Gemini API Key:** An active API key from [Google AI Studio](https://aistudio.google.com/) for the receipt scanning feature.

---

### Step 1: Clone the Repository

Open your terminal and clone the project to your local machine:

```bash
git clone [https://github.com/JAKOB-010/xpense-monthly-expense-monitoring-app.git](https://github.com/JAKOB-010/xpense-monthly-expense-monitoring-app)
cd xpense-monthly-expense-monitoring-app.git
```


