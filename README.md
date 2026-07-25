# HostelHub

A smart hostel management system for PSG College of Technology, built with Flutter and Firebase.

## Features

### Authentication
- Standard email + password login via Firebase Auth
- **eCampus login** — log in using your PSG roll number and eCampus password
  - Fetches CSRF token from `ecampus.psgtech.ac.in` and verifies credentials
  - Auto-creates a Firebase account linked to `{rollno}@psgtech.ac.in` on first login
  - Subsequent logins with roll number or email go to the same account
- Role-based routing — redirects to the correct dashboard after login

### Student
- Dashboard with quick access to all features
- **Complaints** — submit complaints by category, real-time chat with warden per complaint
- **Service Requests** — request hostel maintenance/services
- **Medical Help** — request medical assistance from the hostel doctor
- **Emergency** — trigger emergency alerts to wardens
- **Lost & Found** — post and browse lost or found items
- **Announcements** — view announcements posted by wardens
- **Parcels** — track parcel deliveries
- **Resource Sharing** — share and browse resources with other students
- **Profile** — view and update profile

### Warden
- Dashboard overview
- Manage and respond to student complaints with real-time chat
- Handle service requests
- Post announcements to all students
- View and respond to emergency alerts

### Doctor
- Dashboard to view and manage medical help requests

### Admin
- Dashboard
- Manage users
- View reports

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Push Notifications | Firebase Cloud Messaging + flutter_local_notifications |
| Routing | go_router |
| State Management | Provider |
| eCampus HTTP Login | http package (CSRF token scraping) |
| Backend | Firebase Cloud Functions (Node.js) |

## Project Structure

```
lib/
├── core/
│   ├── constants/       # Routes, colors, strings
│   ├── theme/           # App theme
│   ├── utils/           # Validators, helpers
│   └── widgets/         # Shared UI components
├── models/              # Data models (User, Complaint, Parcel, etc.)
├── providers/           # State management (Auth, Complaint, Parcel, etc.)
├── screens/
│   ├── auth/            # Login, Register, Forgot Password
│   ├── student/         # All student screens
│   ├── warden/          # All warden screens
│   ├── doctor/          # Doctor dashboard
│   └── admin/           # Admin screens
├── services/
│   ├── auth_service.dart         # Firebase Auth + eCampus login
│   ├── ecampus_auth_service.dart # CSRF token fetch + eCampus POST
│   ├── firestore_service.dart    # Firestore CRUD
│   └── notification_service.dart # FCM + local notifications
├── app.dart             # Router setup + role-based redirect
└── main.dart            # App entry point + provider setup
functions/
└── index.js             # Firebase Cloud Functions (ecampusLogin)
```

## Getting Started

### Prerequisites
- Flutter SDK 3.29+
- Android Studio / VS Code
- Firebase project (already configured)

### Run

```bash
flutter pub get
flutter run -d emulator-5554       # Android emulator
flutter run -d windows             # Windows desktop
```

### eCampus Login Flow

1. App GETs `https://ecampus.psgtech.ac.in/studzone/Login` to extract the `__RequestVerificationToken` from the HTML form and the `.AspNetCore.Antiforgery` cookie from response headers
2. POSTs `rollno`, `password`, `chkterms` along with the CSRF token and cookie to `https://ecampus.psgtech.ac.in/studzone`
3. On success (response does not contain the login form), credentials are confirmed valid
4. App then signs into Firebase Auth using `{rollno}@psgtech.ac.in` as email and the eCampus password
5. If no Firebase account exists for that email, one is created automatically
6. Full Firebase Auth session is established — all Firestore queries work normally

## Firebase Setup

- Project ID: `hostelhub-88559`
- Firestore rules: `firestore.rules` (deploy with `npx firebase-tools deploy --only firestore:rules --project hostelhub-88559`)
- Google services config: `android/app/google-services.json`
