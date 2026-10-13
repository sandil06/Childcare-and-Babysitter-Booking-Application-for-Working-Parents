

# 👶 LittleHands – Childcare & Babysitter Booking App

**Childcare & Babysitter Booking Management System** — Babysitter Search, Bookings, Scheduling, Payments & User Management.

![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?style=flat&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-Language-0175C2?style=flat&logo=dart&logoColor=white) ![Node.js](https://img.shields.io/badge/Node.js-Express-339933?style=flat&logo=node.js&logoColor=white) ![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?style=flat&logo=mongodb&logoColor=white) ![Stripe](https://img.shields.io/badge/Stripe-Payments-635BFF?style=flat&logo=stripe&logoColor=white)



---

## 🚀 Quick Start

### 1. Clone & Configure

```bash
git clone https://github.com/YOUR_USERNAME/careconnect.git
cd careconnect
```

Edit `server/.env`:

```env
PORT=4000
MONGO_URI=your_mongodb_uri
JWT_SECRET=your_secret
JWT_EXPIRE=7d
STRIPE_SECRET_KEY=sk_test_your_key
```

Configure the Stripe publishable key in the Flutter application.

### 2. Backend

```bash
cd childcare_mobile
cd backend
npm install
npm run dev       # http://localhost:3000
```

### 3. Flutter Frontend

```bash
cd childcare_mobile
flutter run (C:\src\flutter\bin\flutter.bat run -d chrome = Fill path)
```

---

## 🔐 Demo Credentials

| Role | Email | Password |
|---|---|---|
| Admin | agency@littlehands.lk | AdminSecure123! |
| Parent | sandiljayasuriya@gmail.com | sandil123 |
| Babysitter | guwanihathurusinghe@gmail.com | guwi@12345 |

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

