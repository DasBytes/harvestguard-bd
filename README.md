# 🌾 HarvestGuard – Smart Crop Protection & Weather-Aware Farming Assistant

**HarvestGuard** is a mobile app built using **Flutter**, **Firebase**, **OpenWeather API**, and **PlantNet API**, designed to help Bangladeshi farmers reduce food loss. The app provides hyper-local weather forecasts, crop batch monitoring, health scanning, and offline-safe data management to protect harvested crops and maximize profits.

---

## 🚀 Core Features

### 🔥 1. Storytelling Landing Page
- Engaging onboarding screens explaining Bangladesh’s food loss crisis
- Smooth animations and mobile-first responsive design
- Bangla and English language toggle
- Narrative flow: _Problem → Risk → Solution_

**Screenshot:**  
![Landing Page](screenshots/landing_page.png)

---

### 🌱 2. Farmer & Crop Management
- Firebase Authentication (Email & Password)
- Farmer profile with language preference
- Crop batch creation with:
  - Crop type  
  - Estimated weight  
  - Harvest date  
  - Storage district/division  
  - Storage type (silo/bag/open)
- Batch list and detailed batch view
- Gamification badges for engagement
- Offline support with local cache
- Export batch data as CSV/JSON

**Screenshot:**  
![Farmer Dashboard](screenshots/farmer_dashboard.png)

---

### ☁️ 3. Hyper-Local Weather Forecast
Powered by **OpenWeather API**:
- 5-day forecast with temperature, humidity, and rainfall probability
- Auto-selected weather based on Upazila
- Bangla advisories, e.g.:  
> “আগামী ৩ দিন বৃষ্টির সম্ভাবনা বেশি — ধান ঢেকে রাখুন”

**Screenshot:**  
![Weather Forecast](screenshots/weather_forecast.png)

---

### 🔮 4. Estimated Time to Critical Loss (ETCL)
- Custom prediction engine using temperature, humidity, and rainfall
- Outputs ETCL (hours until spoilage risk)
- Bangla warnings for mold, moisture, and drying issues

**Screenshot:**  
![ETCL Prediction](screenshots/etcl_prediction.png)

---

### 📷 5. Basic Crop Health Scanner
Using **PlantNet.org API**:
- Capture or upload plant photo
- Detect plant species
- Identify health condition (healthy/rotten-like)

**Screenshot:**  
![Crop Scanner](screenshots/crop_scanner.png)

---

## 🛠 Tech Stack

### Frontend
- Flutter 3.x  
- Dart  
- Flutter ScreenUtil  

### Backend
- Firebase Authentication  
- Firebase Firestore  
- Firebase Storage  

### APIs
- **OpenWeather API** — for hyper-local weather  
- **PlantNet API** — plant identification  

### Tools
- Git & GitHub  
- VS Code / Android Studio  

---

## ⚡ Installation & Setup

1. **Clone the repository**
```bash
git clone https://github.com/DasBytes/harvestguard-bd.git
cd harvestguard-bd

Install dependencies

flutter pub get
Firebase Setup

Create a Firebase project

Enable Firestore and Authentication

Download google-services.json (Android) or GoogleService-Info.plist (iOS)

Place the file in the respective platform folder

Run the app

flutter run


👥 Team Members
Name	                       
Sadrib Shaiyan Islam and Mohammad Saad Salmee : Flutter Developer / UI/UX
Pranta Das  :	Backend & Firebase Setup and API Integration & Testing
	

🌟 Notes

Supports Bangla and English languages

Offline-safe mode preserves data without internet

Designed to reduce food loss by up to 40% and maximize farmer profits
