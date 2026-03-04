# 🗑️ Waste Disposal App (WDA)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/State%20Management-Riverpod-40C4FF" />
  <img src="https://img.shields.io/badge/Maps-OpenStreetMap%20%7C%20Google%20Maps-success" />
  <img src="https://img.shields.io/badge/Authentication-Google%20OAuth-red" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blueviolet" />
</p>

> A real-time waste management platform built with Flutter, integrating geolocation, driver matching, QR validation, and a reward-driven engagement system.

---

## 📌 Overview

The **Waste Disposal App (WDA)** is a cross-platform mobile application designed to connect waste producers with waste collection drivers efficiently and transparently.

The system leverages real-time cloud infrastructure, interactive mapping, and a gamified reward engine to modernize waste collection workflows.

### 👥 User Roles

- 👤 **User (Waste Producer)** – Creates and tracks disposal requests
- 🚛 **Driver (Waste Collector)** – Accepts and completes pickup jobs

---

## ✨ Core Features

### 👤 User Capabilities

- 📍 Create location-based waste pickup requests
- 🗺️ Select pickup point via interactive map
- 📊 Track task lifecycle in real time
- 🏆 Earn reward points for participation
- 📱 QR code generation for pickup validation
- 👤 Profile & statistics dashboard
- ⚙️ Customizable settings

---

### 🚛 Driver Capabilities

- 🗂️ View available and assigned jobs
- 🧭 Navigate to pickup locations
- ✅ Update job progress stages
- 📷 Scan QR codes for task confirmation
- 💰 Track completion metrics

---

## 🛠️ Tech Stack

### 📱 Frontend
- **Flutter (Dart)**
- Responsive UI scaling
- Modern animations and smooth transitions

### 🔥 Backend & Cloud Services
- **Firebase Core**
- **Firebase Authentication (Google Sign-In)**
- **Cloud Firestore (Real-Time NoSQL Database)**

### 🗺️ Maps & Geolocation
- OpenStreetMap (via flutter_map)
- Google Maps API (enhanced services)
- Geolocator (device GPS)
- Polyline routing & marker clustering

### 📦 Architecture & State Management
- Feature-based modular structure
- Flutter Riverpod (reactive state management)
- Clean separation of concerns

### 📷 QR Integration
- QR code generation
- QR code scanning & validation

---

## 🧠 System Highlights

### 🔄 Real-Time Driver Matching

- Tasks stored in Cloud Firestore
- Drivers receive instant updates
- Acceptance triggers synchronized state updates
- Status changes reflected live for both parties

This ensures low-latency coordination without manual refresh logic.

---

### 🏆 Reward Engine

Each task includes:

- Creation points
- Completion points
- Lifecycle validation flags
- QR confirmation state

Gamification mechanics encourage responsible waste disposal behavior.

---

### 📍 Geolocation System

- Latitude & longitude stored per request
- Interactive map-based location selection
- Route visualization using polylines
- Marker clustering for performance optimization

---

## 🔐 Authentication & Security

- Google OAuth authentication
- Firebase token-based sessions
- Role-based routing logic
- Protected navigation guards

---

## 📊 Core Data Model

### Task Entity Includes:

- Unique task identifier
- User & driver references
- Waste type & size metadata
- Pickup scheduling
- GPS coordinates
- Status lifecycle tracking
- QR validation state
- Points calculation
- Cancellation flags

---

## ⚙️ Installation & Setup

### 1️⃣ Clone Repository

```bash
git clone https://github.com/Adityaaaaaaaaaaaaaaa/WDA.git
cd WDA
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

### 3️⃣ Configure Environment

Create a `.env` file in the root directory:

```
GOOGLE_MAPS_API_KEY=your_key_here
FIREBASE_PROJECT_ID=your_project_id
```

### 4️⃣ Firebase Setup

- Create project in Firebase Console
- Enable Authentication (Google Sign-In)
- Enable Cloud Firestore
- Add Android/iOS configuration files

### 5️⃣ Run App

```bash
flutter run
```

---
