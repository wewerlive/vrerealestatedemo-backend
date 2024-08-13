# VR Real Estate Demo - Backend

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Dart Frog](https://img.shields.io/endpoint?url=https://tinyurl.com/dartfrog-badge)](https://dartfrog.vgv.dev)

A backend system for a virtual reality real estate platform built with Dart Frog and Firebase.

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

## Flutter Installation

### macOS

1. Download the Flutter SDK from the [official Flutter website](https://flutter.dev/docs/get-started/install/macos).
2. Extract the downloaded file in the desired location, e.g., `~/development`.
3. Add Flutter to your path:
   ```sh
   export PATH="$PATH:[PATH_TO_FLUTTER_GIT_DIRECTORY]/flutter/bin"
   ```
4. Run `flutter doctor` to verify the installation and install any missing dependencies.

### Windows

1. Download the Flutter SDK from the [official Flutter website](https://flutter.dev/docs/get-started/install/windows).
2. Extract the zip file in the desired location, e.g., `C:\src\flutter`.
3. Update your path:
   - From the Start search bar, type 'env' and select "Edit environment variables for your account".
   - Under "User variables", find the "Path" variable, select it and click "Edit".
   - Click "New" and add the full path to `flutter\bin`.
4. Run `flutter doctor` in Command Prompt to verify the installation and install any missing dependencies.

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

- `POST /auth/register`: Register a new user
- `POST /auth/login`: Login user
- `GET /data/devices`: Get all devices
- `POST /data/devices`: Add a new device
- `PUT /data/devices`: Update a device
- `GET /data/projects`: Get all estates
- `POST /data/projects`: Add a new estate
- `PUT /data/projects`: Update an estate

<div style="background-color: #ce2d2d; padding: 1rem; color:black;">

## WebSocket Connection

#### Work In Progress

Connect to `/socket/connection` for real-time updates.

</div>

## Testing

Run tests using the following command:

```
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
