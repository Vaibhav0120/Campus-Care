## 🧠 a Flutter App – **Campus Care** (Student ↔ Cafeteria Platform)

Here is a **Flutter mobile app** called **Campus Care**, using **Supabase** as the backend. The project has **role-based access (Student / Cafeteria Staff)**, real-time database operations, cart & order features, and payment using **Razorpay UPI**. Supabase credentials are to be managed using a `.env` file.

[Watch Live](https://campus-care-seven.vercel.app/)

TO CHECK GOOGLE LOGIN IN DEV
flutter run -d chrome --web-port=3000

---

### 📁 Required Features and Roles

#### 🔐 Authentication (Supabase Auth)

* On app launch, the **Home Page** is shown with a **“Login”** button.
* From the **Login Page**, users can go to **Sign Up**.
* On **sign up**, the user is auto-marked as a `customer` (`role = "student"`) in Supabase.
* **Cafeteria staff accounts are created manually in Supabase** with role = `staff`.

---

### 👤 Role-Based Navigation After Login

#### 🧑‍🎓 If the user is a **Student**:

* Redirect to the **Home Page**
* Features:

  * Browse available food/items
  * Add to cart
  * View cart and total
  * Place order via **Razorpay UPI**
  * View previous orders
  * Real-time status of placed orders (e.g., Pending → Completed)

#### 👨‍🍳 If the user is a **Cafeteria Staff**:

* Redirect to a **Staff Dashboard**
* Features:

  * **View list of uncompleted orders**
  * Mark orders as **Completed**
  * Navigate to **Manage Items Page** to:

    * Edit item name/price
    * Toggle “Available Today” status (true/false)
    * Add new items (optional future scope)

---

### 🗃️ Supabase Tables Design

#### 1. `users`

| id   | email | role                 |
| ---- | ----- | -------------------- |
| UUID | text  | "student" or "staff" |

#### 2. `items`

| id   | name | description | price   | image\_url | available\_today |
| ---- | ---- | ----------- | ------- | ---------- | ---------------- |
| UUID | text | text        | numeric | text       | boolean          |

#### 3. `orders`

| id   | user\_id | items (jsonb)        | total\_price | status                  | created\_at |
| ---- | -------- | -------------------- | ------------ | ----------------------- | ----------- |
| UUID | UUID     | \[{ item\_id, qty }] | numeric      | "pending" / "completed" | timestamp   |

#### 4. `cart`

| user\_id | item\_id | quantity |
| -------- | -------- | -------- |

---

### 📱 UI Navigation Flow

```
App Start → Home Page
               ↓
         [ Login Button ]
               ↓
         Login Screen —→ [ Sign Up Button ]
               ↓
            On Login
               ↓
    ┌──────────────────────┬────────────────────┐
    │  if role == student  │  if role == staff  │
    └──────────────────────┴────────────────────┘
           ↓                          ↓
     HomeScreen                StaffDashboard
           ↓                          ↓
   View Items / Cart       View Orders / Manage Items
           ↓                          ↓
    Razorpay UPI Pay       Mark as Complete / Edit Item
```

---

### 🔧 Tech Stack

* **Flutter**
* **Supabase (Auth + Postgres + Realtime)**
* **Razorpay** for payment
* **flutter\_dotenv** for `.env` management
* **provider** or **flutter\_riverpod** for state management
* **cached\_network\_image**, **fluttertoast**, etc.

---

### 📦 Folder Structure

```
lib/
├── main.dart
├── config/
│   └── supabase_config.dart
├── models/
│   ├── user_model.dart
│   ├── item_model.dart
│   ├── cart_item.dart
│   └── order_model.dart
├── services/
│   ├── auth_service.dart
│   ├── item_service.dart
│   ├── cart_service.dart
│   └── order_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── cart_provider.dart
│   └── item_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── cart_screen.dart
│   ├── place_order_screen.dart
│   └── staff/
│       ├── staff_dashboard.dart
│       └── manage_items_screen.dart
├── widgets/
│   ├── item_card.dart
│   ├── cart_tile.dart
│   └── order_tile.dart
└── utils/
    └── validators.dart
```

---

### ✅ Logic Checklist

* [ ] User signup → auto-create as student in `users`
* [ ] Login → fetch user role → conditional navigation
* [ ] Role-based UI (Customer vs Staff)
* [ ] Cart management with provider
* [ ] Razorpay UPI integration for checkout
* [ ] Supabase real-time DB updates for orders
* [ ] Staff-only order management + item editing

