# HostelHub - Database & Firebase Setup

## Firebase Setup Instructions

Step 1: Create a Firebase project at console.firebase.google.com
Step 2: Enable Authentication → Email/Password
Step 3: Create Firestore Database in production mode
Step 4: Add Android app with package name: `com.hostelhub.app`
Step 5: Download `google-services.json` → place in `android/app/`
Step 6: Add Firebase dependencies to `android/build.gradle` and `android/app/build.gradle`
Step 7: Run: `flutterfire configure` (install FlutterFire CLI first via `dart pub global activate flutterfire_cli`)
Step 8: Set Firestore security rules (see below)
Step 9: Enable Cloud Messaging for push notifications (upload APNs certs / get Server Key if needed)
Step 10: Run: `flutter pub get` → `flutter run`

---

## Firestore Security Rules

Copy and paste these exact rules into your Firestore rules dashboard.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Function to easily check user roles
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    // Function to check if user is admin
    function isAdmin() {
      return getUserRole() == 'admin';
    }

    // Function to check if user is warden
    function isWarden() {
      return getUserRole() == 'warden';
    }
    
    // Default: Deny all unauthenticated access
    match /{document=**} {
      allow read, write: if request.auth != null && isAdmin();
    }

    // Users Collection
    match /users/{userId} {
      // User can read/write their own data
      // Anyone logged in can read names/basic profiles for resources/complaints if needed
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Complaints Collection
    match /complaints/{complaintId} {
      // Student can read their own complaints, Warden & Admin can read all
      allow read: if request.auth != null && (request.auth.uid == resource.data.studentId || isWarden() || isAdmin());
      // Student can create their own complaint
      allow create: if request.auth != null && request.auth.uid == request.resource.data.studentId;
      // Warden can update complaint status
      allow update: if request.auth != null && isWarden();
      allow delete: if isAdmin();
    }

    // Resources Collection
    match /resources/{resourceId} {
      // Any authenticated user can view resources
      allow read: if request.auth != null;
      // Anyone can create a resource
      allow create: if request.auth != null && request.auth.uid == request.resource.data.ownerId;
      // Users can update to 'requested', owners can update status
      allow update: if request.auth != null;
      allow delete: if request.auth != null && (request.auth.uid == resource.data.ownerId || isAdmin());
    }

    // Service Requests Collection
    match /service_requests/{requestId} {
      allow read: if request.auth != null && (request.auth.uid == resource.data.studentId || isWarden() || isAdmin());
      allow create: if request.auth != null && request.auth.uid == request.resource.data.studentId;
      allow update: if request.auth != null && isWarden();
    }

    // Lost & Found Collection
    match /lost_found/{itemId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.reportedBy;
      allow update: if request.auth != null && (request.auth.uid == resource.data.reportedBy || isWarden());
    }

    // Announcements Collection
    match /announcements/{announcementId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && (isWarden() || isAdmin());
    }

    // Parcels Collection
    match /parcels/{parcelId} {
      allow read: if request.auth != null && (request.auth.uid == resource.data.studentId || isAdmin());
      allow write: if request.auth != null && isAdmin();
    }

    // Emergency Alerts Collection
    match /emergency_alerts/{alertId} {
      allow read: if request.auth != null && (isWarden() || isAdmin() || request.auth.uid == resource.data.sentBy);
      // Students can create emergency alerts
      allow create: if request.auth != null && request.auth.uid == request.resource.data.sentBy;
      // Wardens/Admins can update status
      allow update: if request.auth != null && (isWarden() || isAdmin());
    }
  }
}
```
