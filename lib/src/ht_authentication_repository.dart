import 'package:ht_authentication_client/ht_authentication_client.dart';
import 'package:rxdart/rxdart.dart';

/// {@template ht_authentication_repository}
/// Repository which manages authentication using various providers.
/// It abstracts the underlying [HtAuthenticationClient].
/// {@endtemplate}
class HtAuthenticationRepository {
  /// {@macro ht_authentication_repository}
  HtAuthenticationRepository({
    required HtAuthenticationClient authenticationClient,
  }) : _authenticationClient = authenticationClient {
    _authenticationClient.user.listen(_userSubject.add);
  }

  final HtAuthenticationClient _authenticationClient;
  final _userSubject = BehaviorSubject<User>.seeded(User());

  /// Stream of [User] which will emit the current user when
  /// the authentication state changes.
  ///
  /// Emits a default [User] if the user is not authenticated.
  Stream<User> get user => _userSubject.stream;

  /// Returns the current cached user.
  ///
  /// Defaults to a default [User] if there is no cached user.
  User get currentUser => _userSubject.value;

  /// Sends a sign-in link to the provided email address.
  ///
  /// Throws a [SendSignInLinkException] if sending the link fails.
  Future<void> sendSignInLinkToEmail({required String email}) async {
    try {
      await _authenticationClient.sendSignInLinkToEmail(email: email);
    } on SendSignInLinkException {
      rethrow; // Re-throw specific client exceptions directly
    } catch (e, st) {
      // Wrap generic exceptions
      throw SendSignInLinkException(e, st);
    }
  }

  /// Signs in the user using the email and the validated sign-in link.
  ///
  /// Throws an [InvalidSignInLinkException] if the link is invalid or expired.
  /// Throws a [UserNotFoundException] if the email is not found.
  Future<void> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      await _authenticationClient.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
    } on InvalidSignInLinkException {
      rethrow; // Re-throw specific client exceptions directly
    } on UserNotFoundException {
      rethrow; // Re-throw specific client exceptions directly
    } catch (e, st) {
      // Wrap generic exceptions, defaulting to InvalidSignInLinkException
      // as the most likely failure mode if not UserNotFound.
      throw InvalidSignInLinkException(e, st);
    }
  }

  /// Signs in with Google.
  ///
  /// Throws a [GoogleSignInException] if sign-in fails.
  Future<void> signInWithGoogle() async {
    try {
      await _authenticationClient.signInWithGoogle();
    } on GoogleSignInException {
      rethrow; // Re-throw specific client exceptions directly
    } catch (e, st) {
      // Wrap generic exceptions
      throw GoogleSignInException(e, st);
    }
  }

  /// Signs in anonymously.
  ///
  /// Throws an [AnonymousLoginException] if sign-in fails.
  Future<void> signInAnonymously() async {
    try {
      await _authenticationClient.signInAnonymously();
    } on AnonymousLoginException {
      rethrow; // Re-throw specific client exceptions directly
    } catch (e, st) {
      // Wrap generic exceptions
      throw AnonymousLoginException(e, st);
    }
  }

  /// Signs out the current user.
  ///
  /// Throws a [LogoutException] if sign-out fails.
  Future<void> signOut() async {
    try {
      await _authenticationClient.signOut();
    } on LogoutException {
      rethrow; // Re-throw specific client exceptions directly
    } catch (e, st) {
      // Wrap generic exceptions
      throw LogoutException(e, st);
    }
  }

  /// Deletes the current user's account.
  ///
  /// Throws a [DeleteAccountException] if account deletion fails.
  Future<void> deleteAccount() async {
    try {
      await _authenticationClient.deleteAccount();
    } on DeleteAccountException {
      rethrow; // Re-throw specific client exceptions directly
    } catch (e, st) {
      // Wrap generic exceptions
      throw DeleteAccountException(e, st);
    }
  }
}
