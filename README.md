# HT Authentication Repository

## Overview

This repository provides a standardized way to handle user authentication. It abstracts the underlying authentication client (`ht_authentication_client`) and provides a simple, consistent interface for interacting with authentication-related features.

## Features

*   **Sign Up:** Register new users.
*   **Sign In:** Authenticate existing users.
*   **Sign Out:** Log out users.
*   **User Management:** Retrieve and update user information.
*   **Password Reset:** Handle password reset requests.
*   **Authentication State Management:** Stream authentication state changes.

## Dependencies

*   `flutter`: Flutter SDK.
*   `ht_authentication_client`: Headlines Toolkit authentication client.
*   `rxdart`: Reactive extensions for Dart.

## Getting Started

1.  **Add the dependency:**

    ```yaml
    dependencies:
      ht_authentication_repository:
        git:
          url: https://github.com/headlines-toolkit/ht-authentication-repository.git
          ref: main
    ```

2.  **Import the package:**

    ```dart
    import 'package:ht_authentication_repository/ht_authentication_repository.dart';
    ```

3.  **Instantiate the repository:**

    ```dart
    final authenticationRepository = HtAuthenticationRepository(
      authenticationClient: HtAuthenticationClient(), // Replace with your actual client
    );
    ```

## Example

```dart
import 'package:ht_authentication_client/ht_authentication_client.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart';

void main() async {
  // Initialize the authentication client (replace with your actual client).
  final authenticationClient = HtAuthenticationClient(); 

  // Initialize the authentication repository.
  final authenticationRepository = HtAuthenticationRepository(
    authenticationClient: authenticationClient,
  );

  // Access the user stream.
  authenticationRepository.user.listen((user) {
    print('User: ${user.id}');
  });

  // Sign in with email and password (replace with actual credentials).
  try {
    await authenticationRepository.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password',
    );
  } catch (e) {
    print('Sign in failed: $e');
  }

    // Sign in with google.
  try {
    await authenticationRepository.signInWithGoogle();
  } catch (e) {
    print('Sign in failed: $e');
  }

      // Sign in anonymously.
  try {
    await authenticationRepository.signInAnonymously();
  } catch (e) {
    print('Sign in failed: $e');
  }

  // Sign out.
  try {
    await authenticationRepository.signOut();
  } catch (e) {
    print('Sign out failed: $e');
  }

    // Delete Account.
  try {
    await authenticationRepository.deleteAccount();
  } catch (e) {
    print('Delete account failed: $e');
  }
}

```

## Testing

This package includes a comprehensive suite of unit tests. To run the tests:

```bash
flutter test
```

To generate coverage reports:

```bash
flutter test --coverage
```
