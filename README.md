# VR Real Estate Demo Backend

A backend system for a virtual reality real estate platform built with Dart Frog and Firebase.

## Table of Contents

- [VR Real Estate Demo Backend](#vr-real-estate-demo-backend)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Prerequisites](#prerequisites)
  - [Project Installation](#project-installation)
  - [Running the Project](#running-the-project)
  - [API Endpoints](#api-endpoints)
    - [Authentication](#authentication)
    - [Devices](#devices)
    - [Estates (Projects)](#estates-projects)
    - [Admin](#admin)
    - [WebSocket](#websocket)
  - [File Structure](#file-structure)
  - [Testing](#testing)
  - [Troubleshooting Common Errors](#troubleshooting-common-errors)
  - [Contributing](#contributing)

## Features

- User authentication (register/login)
- Estate management (CRUD operations)
- Device management (CRUD operations)
- Real-time updates via WebSocket
- Firebase integration

## Prerequisites

- Dart SDK (>=3.0.0 <4.0.0)
- Flutter SDK (latest stable version)
- Firebase project set up

## Project Installation

1. Clone the repository:

   ```sh
   git clone https://github.com/wewerlive/vrrealstatedemo.git
   cd vrrealstatedemo
   ```

2. Install dependencies:

   ```sh
   dart pub get
   ```

3. Set up environment variables:
   Create a `.env` file in the root directory and add your Firebase credentials:
   ```sh
   FIREBASE_API_KEY=your_api_key
   FIREBASE_PROJECT_ID=your_project_id
   ```

## Running the Project

1. Start the Dart Frog server:

   ```sh
   dart_frog dev
   ```

2. The server will start, typically on `http://localhost:8080`.

## API Endpoints

### Authentication
- `POST /auth/register`: Register a new user
- `POST /auth/login`: Login user

### Devices
- `GET /data/devices`: Get all devices
- `POST /data/devices`: Add a new device
- `PUT /data/devices`: Update a device

### Estates (Projects)
- `GET /data/projects`: Get all estates
- `POST /data/projects`: Add a new estate
- `PUT /data/projects`: Update an estate
- `DELETE /data/projects`: Delete a scene from an estate

### Admin
- `GET /admin/users`: Get all users
- `POST /admin/ownerships/project`: Manage project ownerships
- `POST /admin/ownerships/device`: Manage device ownerships

### WebSocket
- Connect to `/server/socket` for real-time updates

## File Structure

```
vrrealstatedemo/
├── .dart_frog/
├── lib/
│   └── Firebase.dart
├── routes/
│   ├── _middleware.dart
│   ├── index.dart
│   ├── admin/
│   │   ├── _middleware.dart
│   │   ├── users/
│   │   │   └── index.dart
│   │   └── ownerships/
│   │       ├── device.dart
│   │       └── project.dart
│   ├── auth/
│   │   ├── login/
│   │   │   ├── _middleware.dart
│   │   │   └── index.dart
│   │   └── register/
│   │       ├── _middleware.dart
│   │       └── index.dart
│   ├── data/
│   │   ├── _middleware.dart
│   │   ├── index.dart
│   │   ├── devices.dart
│   │   └── projects.dart
│   └── server/
│       ├── _middleware.dart
│       └── socket.dart
├── test/
│   └── routes/
│       └── index_test.dart
├── analysis_options.yaml
├── dart_frog.yaml
├── pubspec.yaml
└── README.md
```

## Testing

Run tests using the following command:

```sh
dart test
```

## Troubleshooting Common Errors

1. **Firebase Initialization Error**:
   - Error: "Firebase credentials not found in environment variables"
   - Solution: Ensure that your `.env` file is properly set up with the correct Firebase credentials.

2. **Dart Frog Server Won't Start**:
   - Error: "Address already in use"
   - Solution: Check if another process is using port 8080. You can change the port in the `.dart_frog/server.dart` file.

3. **Firestore Connection Issues**:
   - Error: "Failed to get document because the client is offline"
   - Solution: Check your internet connection and ensure your Firebase project is properly set up and the rules allow read/write operations.

4. **CORS Errors**:
   - Error: "Access to XMLHttpRequest has been blocked by CORS policy"
   - Solution: Ensure the CORS middleware is properly set up in your `_middleware.dart` file.

5. **Flutter SDK Not Found**:
   - Error: "Flutter SDK not found. Define location with flutter.sdk in the local.properties file."
   - Solution: Ensure Flutter is properly installed and added to your PATH.

6. **Dart SDK Version Mismatch**:
   - Error: "Dart SDK version x.x.x is required to use package:y"
   - Solution: Update your Dart SDK to the required version or adjust the SDK constraints in `pubspec.yaml`.

If you encounter any other errors, please check the Dart Frog and Firebase documentation or open an issue in the project repository.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
