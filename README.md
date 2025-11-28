# 🌾 HarvestGuard – Smart Crop Protection & Weather-Aware Farming Assistant  

A mobile app built using **Flutter**, **Firebase**, **OpenWeather API**, and **PlantNet API** to help Bangladeshi farmers reduce food loss through weather forecasting, crop scanning, batch monitoring, and offline-safe data management.

---

## 🚀 Core Features

### 🔥 1. Storytelling Landing Page 
- Visually engaging onboarding describing Bangladesh’s food loss crisis  
- Smooth animations & mobile-first design  
- Bangla and English language toggle  
- Clear narrative flow: _Problem → Risk → Solution_

---

### 🌱 2. Farmer & Crop Management 
- Firebase Authentication (Email + Password)  
- Farmer profile with language preference  
- Crop batch creation with:
  - Crop type  
  - Estimated weight  
  - Harvest date  
  - Storage district/division  
  - Storage type (silo/bag/open)  
- Batch list + Batch details  
- Gamification badges  
- Offline support (local cache)  
- Export batch data as CSV/JSON  

---

### ☁️ 3. Hyper-Local Weather Forecast 
Using **OpenWeather API**:
- 5-day forecast with:
  - Temperature  
  - Humidity  
  - Rain probability  
- Auto-selected weather based on Upazila  
- Bangla advisories like:
  > “আগামী ৩ দিন বৃষ্টির সম্ভাবনা বেশি — ধান ঢেকে রাখুন”

---

### 🔮 4. Estimated Time to Critical Loss 
Custom prediction engine:
- Uses temperature + humidity + rainfall  
- Outputs ETCL (hours until spoilage risk)  
- Bangla warnings (mold, moisture, drying issues)  

---

### 📷 5. Basic Crop Health Scanner 
Using **PlantNet.org API**:
- Capture or upload plant photo  
- Detect plant species  
- Identify health condition (healthy/rotten-like)  

---

## 🛠 Tech Stack

### **Frontend**
- Flutter 3.x  
- Dart  
- Flutter ScreenUtil  

### **Backend**
- Firebase Authentication  
- Firebase Firestore  
- Firebase Storage  

### **APIs**
- **OpenWeather API** — hyper-local weather  
- **PlantNet API** — plant identification  

### **Tools**
- Git & GitHub  
- VS Code / Android Studio  

---

## ⚙️ Installation & Setup

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/yourusername/harvestguard.git
cd harvestguard
