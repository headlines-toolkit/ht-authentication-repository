import 'package:ht_authentication_client/ht_authentication_client.dart';
import 'package:ht_kv_storage_service/ht_kv_storage_service.dart';
import 'package:rxdart/rxdart.dart';

/// {@template ht_authentication_repository}
/// Repository which manages authentication using various providers.
/// It abstracts the underlying [HtAuthenticationClient] and manages
/// temporary storage for flows like passwordless sign-in.
/// {@endtemplate}
class HtAuthenticationRepository {
  /// {@macro ht_authentication_repository}
  HtAuthenticationRepository({
    required HtAuthenticationClient authenticationClient,
    required HtKVStorageService storageService,
  }) : _authenticationClient = authenticationClient,
       _storageService = storageService {
    _authenticationClient.user.listen(_userSubject.add);
  }

  final HtAuthenticationClient _authenticationClient;
  final HtKVStorageService _storageService;
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

  /// Sends a sign-in link to the provided email address and stores the email
  /// temporarily for verification during sign-in.
  ///
  /// Throws a [SendSignInLinkException] if sending the link or storing the
  /// email fails.
  Future<void> sendSignInLinkToEmail({required String email}) async {
    final st = StackTrace.current; // Capture stack trace early
    try {
      await _authenticationClient.sendSignInLinkToEmail(email: email);
      // Store the email after the link is sent successfully
      await _storageService.writeString(
        key: StorageKey.pendingSignInEmail.stringValue,
        value: email,
      );
    } on SendSignInLinkException {
      rethrow; // Re-throw specific client exceptions directly
    } on StorageWriteException catch (e) {
      // Wrap storage write exceptions
      throw SendSignInLinkException(e, st);
    } catch (e) {
      // Wrap other generic exceptions
      throw SendSignInLinkException(e, st);
    }
  }

  /// Checks if the incoming link is a valid sign-in link.
  /// Delegates directly to the [HtAuthenticationClient].
  Future<bool> isSignInWithEmailLink({required String emailLink}) {
    // Directly delegate to the client
    return _authenticationClient.isSignInWithEmailLink(emailLink: emailLink);
  }

  /// Signs in the user using the validated sign-in link.
  /// It retrieves the email stored during the `sendSignInLinkToEmail` step.
  ///
  /// Throws an [InvalidSignInLinkException] if the link is invalid, expired,
  /// the stored email cannot be retrieved/validated, or cleanup fails.
  /// Throws a [UserNotFoundException] if the email is not found by the client.
  Future<void> signInWithEmailLink({required String emailLink}) async {
    final st = StackTrace.current; // Capture stack trace early
    String? storedEmail;
    try {
      // 1. Retrieve the stored email
      storedEmail = await _storageService.readString(
        key: StorageKey.pendingSignInEmail.stringValue,
      );

      if (storedEmail == null) {
        throw const StorageKeyNotFoundException(
          'pending_signin_email',
          message: 'Pending sign-in email not found in storage.',
        );
      }

      // 2. Sign in using the retrieved email and the link
      await _authenticationClient.signInWithEmailLink(
        email: storedEmail,
        emailLink: emailLink,
      );

      // 3. Clear the stored email after successful sign-in
      await _storageService.delete(
        key: StorageKey.pendingSignInEmail.stringValue,
      );
    } on InvalidSignInLinkException {
      rethrow; // Re-throw specific client exceptions directly
    } on UserNotFoundException {
      rethrow; // Re-throw specific client exceptions directly
    } on StorageException catch (e) {
      // Wrap any storage exception (read, delete, type mismatch, not found)
      throw InvalidSignInLinkException(e, st);
    } catch (e) {
      // Wrap other generic exceptions
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
