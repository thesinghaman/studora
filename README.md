# 🎓 Studora

> A modern, cross-platform college marketplace application empowering students to buy, sell, rent, and report lost & found items within their campus community.

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)](https://flutter.dev)
[![Appwrite](https://img.shields.io/badge/Appwrite-Backend-F02E65?logo=appwrite)](https://appwrite.io)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Custom-blue.svg)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
  - [Appwrite Setup](#1-appwrite-setup)
  - [Firebase Setup](#2-firebase-setup)
  - [Appwrite Functions](#3-appwrite-functions-deployment)
- [Project Structure](#-project-structure)
- [Running the App](#-running-the-app)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**Studora** is a comprehensive campus marketplace solution designed specifically for college communities. Students can seamlessly buy and sell items, rent equipment, list lost & found items, and communicate through real-time messaging—all within a secure, college-verified environment.

### 🎯 Key Highlights

- **Real-Time Messaging**: Built-in chat system for negotiation and communication
- **Multi-Category Support**: Marketplace, Rentals, Lost & Found
- **Image Management**: Upload, crop, and manage item photos
- **Push Notifications**: Firebase Cloud Messaging integration
- **Offline Support**: Local caching with GetStorage and Hive
- **Cross-Platform**: iOS and Android Support

---

## ✨ Features

### 🛍️ Marketplace

- Browse and search items by category
- Post items for sale with multiple images
- Price negotiation through integrated chat
- Wishlist functionality
- Filter by condition, price range, and category

### 🏠 Rentals

- List items for rent with daily/monthly rates
- Set rental periods and availability
- Manage rental requests

### 🔍 Lost & Found

- Report lost items with descriptions and photos
- Browse found items by category
- Contact finders directly through messaging

### 💬 Real-Time Messaging

- One-on-one chat with automatic conversation creation
- Image sharing in messages
- Read receipts and typing indicators
- Message notifications

### 👤 User Profile

- Manage personal listings
- Update profile information and avatar
- Block users and report content

---

## 🛠️ Tech Stack

### Frontend (Flutter App)

- **Framework**: Flutter 3.8.1+
- **State Management**: GetX
- **Local Storage**: Hive, GetStorage
- **Networking**: Appwrite SDK
- **UI Components**: Custom Material Design
- **Image Handling**: image_picker, image_cropper, cached_network_image

### Backend (Appwrite)

- **Authentication**: Email/Password
- **Database**: NoSQL Collections
- **Storage**: Cloud Storage for images
- **Realtime**: WebSocket subscriptions
- **Functions**: Node.js serverless functions

### Push Notifications

- **Service**: Firebase Cloud Messaging (FCM)
- **Local Notifications**: flutter_local_notifications

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────────────┐     │
│  │   UI Layer │  │ Controllers│  │  Services/Repos    │     │
│  │   (Views)  │◄─┤   (GetX)   │◄─┤ (Business Logic)   │     │
│  └────────────┘  └────────────┘  └────────────────────┘     │
│                                            ▲                │
└────────────────────────────────────────────┼────────────────┘
                                             │
                        ┌────────────────────┴──────────────────┐
                        │         Appwrite Backend              │
                        │  ┌──────────┐  ┌─────────────────┐    │
                        │  │ Database │  │    Storage      │    │
                        │  ├──────────┤  ├─────────────────┤    │
                        │  │ Auth     │  │  Cloud Functions│    │
                        │  ├──────────┤  ├─────────────────┤    │
                        │  │ Realtime │  │   Permissions   │    │
                        │  └──────────┘  └─────────────────┘    │
                        └───────────────────────────────────────┘
                                             ▲
                        ┌────────────────────┴──────────────────┐
                        │         Firebase                      │
                        │  ┌──────────────────────────────┐     │
                        │  │ Cloud Messaging (Push)       │     │
                        │  └──────────────────────────────┘     │
                        └───────────────────────────────────────┘
```

---

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: `>= 3.8.1` ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: `>= 3.8.1`
- **Android Studio** or **VS Code** with Flutter extensions
- **Xcode** (for iOS development on macOS)
- **Node.js**: `>= 18.x` (for local Appwrite Functions development)
- **GitHub Account**: For hosting Appwrite Functions repositories
- **Firebase CLI** (optional): For Firebase configuration

---

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/thesinghaman/studora.git
cd studora
```

### 2. Install Flutter Dependencies

```bash
cd studora-app
flutter pub get
```

### 3. Install Appwrite Functions Dependencies

```bash
cd ../appwrite-functions

# Install dependencies for all functions
for dir in */; do
  cd "$dir"
  npm install
  cd ..
done
```

---

## ⚙️ Configuration

### 1. Appwrite Setup

#### Step 1: Create Appwrite Project

1. Go to [Appwrite Console](https://cloud.appwrite.io)
2. Create a new project
3. Note down your **Project ID** and **Endpoint URL**

#### Step 2: Create Database & Collections

Create a database with the following collections:

| Collection Name  | Purpose                           |
| ---------------- | --------------------------------- |
| `users`          | User profiles and metadata        |
| `items`          | Marketplace & rental listings     |
| `lostFoundItems` | Lost & found reports              |
| `categories`     | Item categories                   |
| `conversations`  | Chat conversations                |
| `messages`       | Chat messages                     |
| `countries`      | Supported countries               |
| `colleges`       | College list with domains         |
| `reports`        | User reports & content moderation |
| `supportTickets` | User support requests             |
| `legalDocuments` | Terms, Privacy Policy             |

#### Step 3: Configure Collections Schema

**Users Collection** (`users`):

```javascript
{
  userId: string (required),
  userName: string (required),
  email: string (required),
  collegeId: string (required),
  rollNumber: string,
  hostel: string,
  dateJoined: datetime,
  fcmToken: string,
  userAvatarUrl: string,
  userAvatarFileId: string,
  wishlist: string[] (array),
  blockedUsers: string[] (array),
  reportedContent: string[] (array),
  isOnline: boolean,
  lastSeen: datetime,
  showReadReceipts: boolean
}
```

**Items Collection** (`items`):

```javascript
{
  itemId: string (required),
  title: string (required),
  description: string,
  price: number,
  rentalPrice: number,
  categoryId: string,
  categoryType: string, // 'sale' or 'rental'
  condition: string,
  imageUrls: string[] (array),
  imageFileIds: string[] (array),
  sellerId: string,
  sellerName: string,
  sellerAvatarUrl: string,
  collegeId: string,
  status: string, // 'available', 'sold', 'rented'
  createdAt: datetime,
  updatedAt: datetime,
  viewCount: number
}
```

**Conversations Collection** (`conversations`):

```javascript
{
  conversationId: string (required),
  participants: string[] (array), // user IDs
  participantNames: object,
  participantAvatars: object,
  lastMessage: string,
  lastMessageType: string,
  lastMessageTime: datetime,
  unreadCounts: object,
  relatedItem: object,
  createdAt: datetime,
  updatedAt: datetime
}
```

**Messages Collection** (`messages`):

```javascript
{
  messageId: string (required),
  conversationId: string,
  senderId: string,
  text: string,
  messageType: string, // 'text', 'image', 'system'
  imageUrls: string[] (array),
  imageFileIds: string[] (array),
  readBy: string[] (array),
  createdAt: datetime
}
```

> **Note**: Create indexes on frequently queried fields for better performance.

#### Step 4: Create Storage Bucket

1. Navigate to **Storage** in Appwrite Console
2. Create a bucket named `items-images`
3. Configure permissions:
   - Read: `any()`
   - Create: `users()`
   - Update: `users()`
   - Delete: `users()`

#### Step 5: Update App Configuration

Edit `studora-app/lib/app/services/appwrite_service.dart`:

```dart
class AppwriteService extends GetxService {
  static const String projectEndpoint = 'https://cloud.appwrite.io/v1'; // Your Appwrite endpoint
  static const String projectId = 'YOUR_PROJECT_ID'; // Your project ID
  // ...
}
```

Edit `studora-app/lib/app/shared_components/utils/app_constants.dart`:

```dart
class AppConstants {
  static const String appwriteDatabaseId = 'YOUR_DATABASE_ID';

  // Collection IDs
  static const String usersCollectionId = 'YOUR_USERS_COLLECTION_ID';
  static const String itemsCollectionId = 'YOUR_ITEMS_COLLECTION_ID';
  static const String categoriesCollectionId = 'YOUR_CATEGORIES_COLLECTION_ID';
  static const String conversationsCollectionId = 'YOUR_CONVERSATIONS_COLLECTION_ID';
  static const String messagesCollectionId = 'YOUR_MESSAGES_COLLECTION_ID';
  // ... add all other collection IDs

  // Storage Bucket ID
  static const String itemsImagesBucketId = 'YOUR_BUCKET_ID';

  // Function IDs (will be filled after deploying functions)
  static const String createMessageFunctionId = '';
  static const String updateConversationsFunctionId = '';
  // ... other function IDs
}
```

---

### 2. Firebase Setup

#### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Add Android and iOS apps

#### Step 2: Configure Android

1. Download `google-services.json`
2. Place it in `studora-app/android/app/`
3. Ensure `build.gradle` includes Firebase plugin

#### Step 3: Configure iOS

1. Download `GoogleService-Info.plist`
2. Place it in `studora-app/ios/Runner/`
3. Update Xcode project settings

#### Step 4: Generate Firebase Options

```bash
cd studora-app

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will create `lib/firebase_options.dart` with your Firebase configuration.

#### Step 5: Enable Cloud Messaging & Download Service Account

1. In Firebase Console, navigate to **Cloud Messaging**
2. Enable Firebase Cloud Messaging API
3. Go to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Download the JSON file (e.g., `serviceAccountKey.json`)
6. **Save this file securely** - you'll need to upload it to Appwrite for push notifications

---

### 3. Appwrite Functions Deployment

Appwrite Functions can be deployed directly from GitHub repositories, eliminating the need for CLI deployment.

#### Step 1: Prepare Function Repositories

You have two options:

**Option A: Individual Repositories**

- Create separate GitHub repositories for each function
- Example: `studora-function-createMessage`, `studora-function-notifyOnNewMessage`, etc.

**Option B: Monorepo with Subdirectories**

- Use the existing `appwrite-functions/` directory structure
- Each function folder will be linked separately

#### Step 2: Push Functions to GitHub

If using the monorepo approach:

```bash
# Ensure your functions are committed
git add appwrite-functions/
git commit -m "Add Appwrite Functions"
git push origin main
```

#### Step 3: Connect Functions in Appwrite Console

For **each function**, follow these steps:

1. Go to **Appwrite Console** → **Functions** → **Create Function**
2. Click **Connect Git Repository**
3. Authorize GitHub if not already connected
4. Select your repository (e.g., `studora`)
5. **Production Branch**: `main` (or your preferred branch)
6. **Root Directory**: Enter the function path
   - For `createMessage`: `appwrite-functions/createMessage`
   - For `notifyOnNewMessage`: `appwrite-functions/notifyOnNewMessage`
   - For `updateConversations`: `appwrite-functions/updateConversations`
   - Repeat for all 9 functions
7. **Runtime**: Select `Node.js 18.0` or higher
8. **Entrypoint**: `src/main.js`
9. **Build Settings**:
   - Build Command: `npm install`
   - Leave other settings as default
10. Click **Connect**

Appwrite will automatically deploy the function from GitHub. Any future commits to the connected branch will trigger automatic redeployment.

#### Step 4: Configure Push Notifications

To enable Firebase Cloud Messaging in Appwrite:

1. Go to **Appwrite Console** → **Messaging** → **Providers**
2. Click **Add Provider** → **FCM**
3. **Upload Service Account JSON**:
   - Click **Upload** and select your Firebase `serviceAccountKey.json` file
   - This file is required for Appwrite to send push notifications
4. Click **Create**

#### Step 5: Update Function IDs in App

After deployment, copy each function ID from Appwrite Console and update `app_constants.dart`:

```dart
static const String createMessageFunctionId = 'FUNCTION_ID_HERE';
static const String updateConversationsFunctionId = 'FUNCTION_ID_HERE';
static const String notifyOnNewMessageFunctionId = 'FUNCTION_ID_HERE';
static const String markMessagesAsReadFunctionId = 'FUNCTION_ID_HERE';
static const String getUserProfileFunctionId = 'FUNCTION_ID_HERE';
static const String deleteUserAccountFunctionId = 'FUNCTION_ID_HERE';
static const String deleteUnverifiedUserFunctionId = 'FUNCTION_ID_HERE';
static const String deleteConversationsFunctionId = 'FUNCTION_ID_HERE';
static const String getPublicsListingsFunctionId = 'FUNCTION_ID_HERE';
```

---

## 📁 Project Structure

```
studora/
├── studora-app/                    # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart              # App entry point
│   │   ├── firebase_options.dart  # Firebase configuration
│   │   └── app/
│   │       ├── bindings/          # GetX dependency injection
│   │       ├── config/            # App configuration
│   │       │   ├── navigation/    # Routes and pages
│   │       │   └── theme/         # App theming
│   │       ├── data/
│   │       │   ├── models/        # Data models
│   │       │   ├── providers/     # API providers
│   │       │   └── repositories/  # Business logic layer
│   │       ├── modules/           # Feature modules
│   │       │   ├── auth/          # Authentication
│   │       │   ├── home/          # Home dashboard
│   │       │   ├── marketplace/   # Item listings
│   │       │   ├── messages/      # Chat functionality
│   │       │   ├── profile/       # User profile
│   │       │   └── ...
│   │       ├── services/          # Core services
│   │       │   ├── appwrite_service.dart
│   │       │   ├── notification_service.dart
│   │       │   ├── logger_service.dart
│   │       │   └── storage_service.dart
│   │       └── shared_components/ # Reusable widgets & utils
│   ├── android/                   # Android native code
│   ├── ios/                       # iOS native code
│   └── pubspec.yaml              # Flutter dependencies
│
├── appwrite-functions/            # Serverless backend functions
│   ├── createMessage/            # Message creation logic
│   ├── updateConversations/      # Conversation updates
│   ├── notifyOnNewMessage/       # FCM notifications
│   ├── markMessagesAsRead/       # Read receipts
│   ├── getUserProfile/           # User data retrieval
│   ├── deleteUserAccount/        # Account deletion
│   ├── deleteUnverifiedUser/     # Cleanup unverified users
│   ├── deleteConversations/      # Conversation management
│   └── getPublicListings/        # Public item listings
│
└── README.md                      # This file
```

---

## 🏃 Running the App

### Development Mode

```bash
cd studora-app

# Run on Android emulator/device
flutter run

# Run on iOS simulator/device (macOS only)
flutter run

# Run on Chrome (Web)
flutter run -d chrome
```

### Production Build

#### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### iOS IPA

```bash
flutter build ios --release
```

Then use Xcode to archive and export IPA.

### Debug Tips

- Use `flutter doctor` to check for any setup issues
- Enable verbose logging: `flutter run -v`
- Check Appwrite logs in Console for backend issues
- View Firebase logs in Firebase Console for FCM issues

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

---

## 📄 License

This project is licensed under a **Custom Non-Commercial License**.

**You are allowed to:**

- ✅ View, study, and learn from the source code
- ✅ Use the software for personal and educational purposes
- ✅ Fork the repository for learning and experimentation

**You are NOT allowed to:**

- ❌ Sell, sublicense, or commercialize the software
- ❌ Redistribute the software or substantial portions of it
- ❌ Use it in any commercial product or service

See the [LICENSE](LICENSE) file for complete terms and conditions.

For commercial licensing inquiries, please contact the author.

---

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing framework
- **Appwrite Team** - For the powerful backend solution
- **Firebase Team** - For reliable push notifications
- **GetX Community** - For state management insights

---

## 📧 Contact & Support

- **Author**: Aman Singh
- **GitHub**: [@thesinghaman](https://github.com/thesinghaman)
- **Repository**: [studora](https://github.com/thesinghaman/studora)

For issues and feature requests, please use the [GitHub Issues](https://github.com/thesinghaman/studora/issues) page.

---

<div align="center">

**Made with ❤️ for college communities**

⭐ Star this repo if you find it helpful!

</div>
