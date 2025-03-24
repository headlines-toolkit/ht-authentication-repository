import 'package:ht_authentication_client/ht_authentication_client.dart';
import 'package:rxdart/rxdart.dart';

/// {@template ht_authentication_repository}
/// Repository which manages authentication.
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

  /// Signs in with email and password.
  ///
  /// Throws an [EmailSignInException] if sign-in fails.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _authenticationClient.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on EmailSignInException catch (e, st) {
      throw EmailSignInException(e, st);
    } catch (e, st) {
      throw EmailSignInException(e, st);
    }
  }

  /// Signs in with Google.
  ///
  /// Throws a [GoogleSignInException] if sign-in fails.
  Future<void> signInWithGoogle() async {
    try {
      await _authenticationClient.signInWithGoogle();
    } on GoogleSignInException catch (e, st) {
      throw GoogleSignInException(e, st);
    } catch (e, st) {
      throw GoogleSignInException(e, st);
    }
  }

  /// Signs in anonymously.
  ///
  /// Throws an [AnonymousLoginException] if sign-in fails.
  Future<void> signInAnonymously() async {
    try {
      await _authenticationClient.signInAnonymously();
    } on AnonymousLoginException catch (e, st) {
      throw AnonymousLoginException(e, st);
    } catch (e, st) {
      throw AnonymousLoginException(e, st);
    }
  }

  /// Signs out the current user.
  ///
  /// Throws a [LogoutException] if sign-out fails.
  Future<void> signOut() async {
    try {
      await _authenticationClient.signOut();
    } on LogoutException catch (e, st) {
      throw LogoutException(e, st);
    } catch (e, st) {
      throw LogoutException(e, st);
    }
  }

  /// Deletes the current user's account.
  ///
  /// Throws a [DeleteAccountException] if account deletion fails.
  Future<void> deleteAccount() async {
    try {
      await _authenticationClient.deleteAccount();
    } on DeleteAccountException catch (e, st) {
      throw DeleteAccountException(e, st);
    } catch (e, st) {
      throw DeleteAccountException(e, st);
    }
  }
}
