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

4.  **Use the repository in your BLoCs:**

    Inject the `HtAuthenticationRepository` instance into your BLoCs and use its methods to handle authentication-related events.

## Example

```dart
// Example of using the repository in a BLoC
class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required HtAuthenticationRepository authenticationRepository,
  }) : _authenticationRepository = authenticationRepository,
        super(const AuthenticationState.unknown()) {
    on<AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
    on<AuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);

    _authenticationStatusSubscription = _authenticationRepository.status
        .listen((status) => add(AuthenticationStatusChanged(status)));
  }

  final HtAuthenticationRepository _authenticationRepository;
  late StreamSubscription<AuthenticationStatus> _authenticationStatusSubscription;

  Future<void> _onAuthenticationStatusChanged(
      AuthenticationStatusChanged event,
      Emitter<AuthenticationState> emit,
      ) async {
    switch (event.status) {
      case AuthenticationStatus.unauthenticated:
        return emit(const AuthenticationState.unauthenticated());
      case AuthenticationStatus.authenticated:
        final user = await _authenticationRepository.user;
        return emit(
          user != null
              ? AuthenticationState.authenticated(user)
              : const AuthenticationState.unauthenticated(),
        );
      case AuthenticationStatus.unknown:
        return emit(const AuthenticationState.unknown());
    }
  }

    Future<void> _onAuthenticationLogoutRequested(
      AuthenticationLogoutRequested event,
      Emitter<AuthenticationState> emit,
    ) async {
    _authenticationRepository.logOut();
  }

  @override
  Future<void> close() {
    _authenticationStatusSubscription.cancel();
    return super.close();
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
