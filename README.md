# 🎓 Studora - Campus Marketplace & Community Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-blue.svg)](https://flutter.dev/)
[![Next.js](https://img.shields.io/badge/Next.js-15.4.4-black.svg)](https://nextjs.org/)
[![Appwrite](https://img.shields.io/badge/Appwrite-Backend-f02e65.svg)](https://appwrite.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)

> 🚧 **Project Status**: Active Development - Perfect time to contribute!

A comprehensive cross-platform college community application that enables students to buy, sell, and negotiate items within campus using real-time messaging. Built with modern technologies and designed for scalability.

## 🌟 Key Features

### 📱 Mobile App (Flutter)

- **Real-time Messaging** - Instant communication between buyers and sellers
- **Item Marketplace** - Post, browse, and search campus items
- **User Authentication** - Secure login with email verification
- **Image Upload & Cropping** - Professional item photos
- **Cross-platform** - iOS and Android support

### 🌐 Web Platform (Next.js)

- **Landing Page** - Project showcase and contributor onboarding
- **Authentication Flow** - Email verification and password recovery
- **Responsive Design** - Seamless experience across devices
- **APK Distribution** - Direct app download capability

### ⚡ Backend (Appwrite Functions)

- **Cloud Functions** - Serverless architecture for scalability
- **Real-time Database** - Instant data synchronization
- **Message Management** - Efficient conversation handling
- **User Management** - Account lifecycle and verification

## 📱 Try Studora Now

### Download the Android App

Ready to experience Studora? Download the latest APK and start exploring the campus marketplace!

[![Download APK](https://img.shields.io/badge/Download-Android%20APK-green.svg?style=for-the-badge&logo=android)](https://studora.shop/APKs/app-release.apk)

_Latest Version - Android 5.0+ Required_

> **Note**: Since this is not published on Google Play Store, you'll need to enable "Install from Unknown Sources" in your Android settings.

### Installation Steps

1. **Download** the APK using the button above
2. **Enable Unknown Sources** in Android Settings → Security
3. **Install** the downloaded APK file
4. **Launch** Studora and create your account
5. **Start** buying and selling on your campus!

## 🏗️ Architecture & Tech Stack

### Mobile App

```
📱 Flutter 3.8.1
├── 🎯 Dart SDK
├── 🏪 GetX State Management
├── 💾 Hive Local Storage
├── 🔗 Appwrite SDK
├── 📸 Image Processing
└── 🌐 Connectivity Management
```

### Web Platform

```
🌐 Next.js 15.4.4
├── ⚛️ React 19
├── 📘 TypeScript
├── 🎨 Tailwind CSS 4
├── 🎭 Lucide Icons
└── 🔗 Node-Appwrite
```

### Backend Services

```
☁️ Appwrite Cloud
├── 🗄️ Database Management
├── 👤 User Authentication
├── 📁 File Storage
├── ⚡ Cloud Functions
└── 🔄 Real-time Subscriptions
```

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** 3.8.1+
- **Node.js** 18+
- **Appwrite** Account
- **Git**

### 1. Clone the Repository

```bash
git clone https://github.com/thesinghaman/studora.git
cd studora
```

### 2. Setup Mobile App

```bash
cd studora-app
flutter pub get
flutter run
```

### 3. Setup Web Platform

```bash
cd studora-web
npm install
npm run dev
```

### 4. Setup Backend Functions

```bash
cd appwrite-functions
# Deploy individual functions to your Appwrite project
```

## ⚙️ Configuration

### 🔒 Security Setup (IMPORTANT)

**Before running the project, you MUST configure sensitive files:**

1. **Firebase Configuration:**
   ```bash
   # Copy and configure Firebase settings
   cp studora-app/lib/firebase_options.dart.template studora-app/lib/firebase_options.dart
   cp studora-app/android/app/google-services.json.template studora-app/android/app/google-services.json
   ```

2. **Web Environment:**
   ```bash
   # Copy and configure environment variables
   cp studora-web/.env.example studora-web/.env.local
   ```

3. **Update with your actual credentials** - Never use placeholder values in production!

### Mobile App Configuration

Update the Appwrite settings in your Flutter app:

**Project Endpoint & ID Location:**

```
📁 studora-app/lib/app/services/appwrite_service.dart
```

**Collections & Functions ID Location:**

```
📁 studora-app/lib/app/shared_components/utils/app_constants.dart
```

### Web Platform Configuration

Create a `.env.local` file in the `studora-web` directory:

```bash
# studora-web/.env.local
APPWRITE_ENDPOINT=https://your-appwrite-endpoint/v1
APPWRITE_PROJECT_ID=your_appwrite_project_id
NEXT_PUBLIC_SITE_URL=http://localhost:3001
NODE_ENV=development
```

> ⚠️ **Security Warning**: Never commit real API keys, credentials, or `.env.local` files to version control!

## 📂 Project Structure

```
studora/
├── 📱 studora-app/           # Flutter mobile application
│   ├── lib/
│   │   ├── app/             # Core app modules
│   │   ├── main.dart        # Application entry point
│   │   └── firebase_options.dart
│   ├── android/             # Android platform files
│   ├── ios/                 # iOS platform files
│   └── pubspec.yaml         # Flutter dependencies
│
├── 🌐 studora-web/          # Next.js web platform
│   ├── src/
│   │   ├── app/             # App router pages
│   │   ├── components/      # Reusable components
│   │   └── middleware.ts    # Route protection
│   ├── public/              # Static assets
│   └── package.json         # Node dependencies
│
└── ⚡ appwrite-functions/    # Backend cloud functions
    ├── createMessage/       # Message creation logic
    ├── deleteConversations/ # Conversation management
    ├── getUserProfile/      # User data retrieval
    └── [8 more functions]/  # Additional backend logic
```

## 🤝 Contributing

We welcome contributions from developers of all skill levels! Whether you're a student learning mobile development or an experienced developer looking to make an impact, there's a place for you here.

### Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🛠️ Development Setup

### Environment Configuration

```bash
# Flutter
flutter doctor
flutter pub get

# Node.js
node --version  # Should be 18+
npm install

# Appwrite
# Configure your Appwrite endpoint and project ID
```

### Running Tests

```bash
# Flutter tests
cd studora-app
flutter test

# Web tests
cd studora-web
npm test
```

## 📈 Project Metrics

- **Languages**: Dart, TypeScript, JavaScript
- **Platforms**: iOS, Android, Web
- **Architecture**: Clean Architecture, MVC
- **Database**: Appwrite NoSQL
- **Real-time**: WebSocket connections
- **Security**: JWT tokens, Route protection

## 🎓 Learning Opportunities

This project offers excellent learning opportunities in:

- **Mobile Development** with Flutter
- **Web Development** with Next.js
- **Backend Development** with Appwrite
- **Real-time Applications**
- **Cross-platform Development**
- **Cloud Functions & Serverless**
- **State Management** (GetX, React State)
- **Database Design** and optimization

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Live Demo**: [https://studora.shop](https://studora.shop)
- **Documentation**: [Coming Soon]
- **API Reference**: [Coming Soon]

## 📞 Contact & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/thesinghaman/studora/issues)
- **Discussions**: [Join the community discussion](https://github.com/thesinghaman/studora/discussions)
- **Creator**: [@thesinghaman](https://github.com/thesinghaman)

---

**⭐ Star this repository if you find it helpful!**

_Built with ❤️ for the college community_
