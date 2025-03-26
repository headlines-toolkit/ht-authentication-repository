# HT Authentication Repository

## Overview

This repository provides a standardized way to handle user authentication. It abstracts the underlying authentication client (`ht_authentication_client`) and provides a simple, consistent interface for interacting with authentication-related features.

## Features

*   **Passwordless Sign-in (Magic Link):** Send a sign-in link to an email address and complete the sign-in process using the link.
*   **Google Sign-In:** Authenticate users via their Google account.
*   **Anonymous Sign-In:** Allow users to sign in anonymously.
*   **Sign Out:** Log out the current user.
*   **Delete Account:** Delete the current user's account.
*   **Authentication State:** Stream the current user's authentication state.
*   **Current User Access:** Synchronously get the latest cached user.

## Dependencies

*   `flutter`: Flutter SDK.
*   `ht_authentication_client`: Abstract authentication client.
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
    print('User ID: ${user.id}, Status: ${user.status}');
  });

  // Get the current user synchronously (might be the default empty user initially)
  print('Current User ID: ${authenticationRepository.currentUser.id}');

  // --- Email Link Sign-In Flow ---
  const email = 'test@example.com';
  try {
    // 1. Send the link
    await authenticationRepository.sendSignInLinkToEmail(email: email);
    print('Sign-in link sent to $email');

    // 2. In a separate part of your app (e.g., after user clicks the link),
    //    get the emailLink and complete sign-in:
    const emailLink = 'https://your-app.link/signIn?oobCode=...'; // Replace with actual link
    await authenticationRepository.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );
    print('Signed in with email link successfully!');
  } on SendSignInLinkException catch (e) {
    print('Failed to send sign-in link: $e');
  } on InvalidSignInLinkException catch (e) {
    print('Failed to sign in with email link (invalid link): $e');
  } on UserNotFoundException catch (e) {
    print('Failed to sign in with email link (user not found): $e');
  } catch (e) {
    print('Email link sign-in failed: $e');
  }

  // --- Google Sign-In ---
  try {
    await authenticationRepository.signInWithGoogle();
    print('Signed in with Google successfully!');
  } on GoogleSignInException catch (e) {
    print('Google sign-in failed: $e');
  } catch (e) {
    print('Google sign-in failed with unexpected error: $e');
  }

  // --- Anonymous Sign-In ---
  try {
    await authenticationRepository.signInAnonymously();
    print('Signed in anonymously successfully!');
  } on AnonymousLoginException catch (e) {
    print('Anonymous sign-in failed: $e');
  } catch (e) {
    print('Anonymous sign-in failed with unexpected error: $e');
  }

  // --- Sign Out ---
  try {
    await authenticationRepository.signOut();
    print('Signed out successfully!');
  } on LogoutException catch (e) {
    print('Sign out failed: $e');
  } catch (e) {
    print('Sign out failed with unexpected error: $e');
  }

  // --- Delete Account ---
  try {
    await authenticationRepository.deleteAccount();
    print('Account deleted successfully!');
  } on DeleteAccountException catch (e) {
    print('Delete account failed: $e');
  } catch (e) {
    print('Delete account failed with unexpected error: $e');
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
