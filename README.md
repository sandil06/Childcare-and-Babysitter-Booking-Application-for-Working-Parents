👶 LittleHands – Childcare & Babysitter Booking App

A smart mobile application connecting parents with trusted babysitters through easy booking, secure payments, and childcare management.

Tech Stack: Flutter | Dart | Node.js | Express.js | MongoDB | Stripe 

📖 About the Project

CareConnect is a mobile application designed to help working parents find reliable babysitters, manage childcare bookings, and make secure payments. It also allows babysitters to manage their availability and administrators to monitor platform activities.

👥 User Roles

Parents: Search babysitters, book services, and make payments.

Babysitters: Manage profiles, availability, and booking requests.

Admin: Manage users, verify babysitters, and monitor bookings.

✅ Key Features

•	User registration and login

•	Babysitter search and profile management

•	Booking and scheduling management
•	Availability tracking
•	Secure Stripe payments
•	Ratings and reviews
•	Role-based dashboards

🏗️ Technology Stack
•	Component

•	Technology
•	Frontend
•	Flutter, Dart
•	Backend
•	Node.js, Express.js
•	Database
•	MongoDB
•	Payment
•	Stripe
•	UI/UX Design
•	Figma

🚀 Quick Start
git clone https://github.com/YOUR_USERNAME/careconnect.git
cd childcare_mobile

Backend
cd childcare_mobile
cd backend
npm install
npm run dev

Frontend
cd frontend
flutter run (C:\src\flutter\bin\flutter.bat run -d chrome - location)

🎓 Academic Information
Module: IT3060 – Human Computer Interaction

University: Sri Lanka Institute of Information Technology (SLIIT)
Year: 2026
Developed by the SLIIT HCI Project Team ❤️

3rd Year 2nd Semester HCI Project

# 👶 CareConnect – Childcare & Babysitter Booking App

**Childcare & Babysitter Booking Management System** — Babysitter Search, Bookings, Scheduling, Payments & User Management.

![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?style=flat&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-Language-0175C2?style=flat&logo=dart&logoColor=white) ![Node.js](https://img.shields.io/badge/Node.js-Express-339933?style=flat&logo=node.js&logoColor=white) ![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?style=flat&logo=mongodb&logoColor=white) ![Stripe](https://img.shields.io/badge/Stripe-Payments-635BFF?style=flat&logo=stripe&logoColor=white)

---

## 👥 Group Members

| Name | Student ID |
|---|---|
| JAYASOORIYA S R | IT23849006 |
| Member 2 | ITXXXXXXXX |
| Member 3 | ITXXXXXXXX |
| Member 4 | ITXXXXXXXX |

---

## 🚀 Quick Start

### 1. Clone & Configure

```bash
git clone https://github.com/YOUR_USERNAME/careconnect.git
cd careconnect
```

Edit `server/.env`:

```env
PORT=5000
MONGO_URI=your_mongodb_uri
JWT_SECRET=your_secret
JWT_EXPIRE=7d
STRIPE_SECRET_KEY=sk_test_your_key
```

Configure the Stripe publishable key in the Flutter application.

### 2. Backend

```bash
cd server
npm install
npm run dev       # http://localhost:5000
```

### 3. Flutter Frontend

```bash
cd client
flutter pub get
flutter run
```

---

## 🔐 Demo Credentials

| Role | Email | Password |
|---|---|---|
| Admin | admin@example.com | Configure demo account |
| Parent | parent@example.com | Configure demo account |
| Babysitter | babysitter@example.com | Configure demo account |

**Stripe test card:** `4242 4242 4242 4242` · any future date · any CVC

---

## ✅ Features

- **Authentication** — User registration, login & role-based access
- **Parents** — Search babysitters, view profiles & manage bookings
- **Babysitters** — Profile management, availability & booking requests
- **Bookings** — Schedule childcare services with availability checking
- **Payments** — Secure Stripe payment integration
- **Reviews** — Babysitter ratings & feedback
- **Admin** — User management, babysitter verification & booking monitoring
- **Dashboard** — Role-based dashboards for parents, babysitters & administrators

---

## 🏗 Tech Stack

**Frontend:** Flutter, Dart

**Backend:** Node.js, Express.js, JWT

**Database:** MongoDB Atlas, Mongoose

**Payments:** Stripe

**UI/UX:** Figma

---

## 📁 Structure

```text
careconnect/
├── client/                # Flutter mobile application
│   ├── lib/
│   │   ├── screens/       # Login, Parent, Babysitter, Admin, Booking, Payment
│   │   ├── widgets/       # Reusable UI components
│   │   ├── models/        # Data models
│   │   ├── services/      # API integration
│   │   └── main.dart
│   ├── assets/
│   └── pubspec.yaml
│
└── server/                # Node.js & Express backend
    ├── config/            # MongoDB connection
    ├── controllers/       # Business logic
    ├── models/            # User, Babysitter, Booking, Payment, Review
    ├── routes/            # Auth, Babysitters, Bookings, Payments, Admin
    ├── middleware/        # Authentication & authorization
    └── server.js
```

---

## 🌐 Key API Routes

| Module | Base Route |
|---|---|
| Auth | `POST /api/auth/register` · `POST /api/auth/login` |
| Babysitters | `GET /api/babysitters` · `GET /api/babysitters/:id` |
| Bookings | `GET/POST /api/bookings` |
| Payments | `POST /api/payments/create-payment-intent` |
| Reviews | `GET/POST /api/reviews` |
| Admin | `GET /api/admin/users` |

---

## 🗂 .gitignore

```gitignore
node_modules/
.env
.dart_tool/
build/
.flutter-plugins-dependencies
.DS_Store
```

---

## 🎓 Academic Information

**Module:** IT3060 – Human Computer Interaction

**University:** Sri Lanka Institute of Information Technology (SLIIT)

**Academic Year:** 2026

---

**Developed by the SLIIT HCI Project Team ❤️**

