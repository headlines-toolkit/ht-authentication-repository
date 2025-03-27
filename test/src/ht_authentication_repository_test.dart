import 'package:flutter_test/flutter_test.dart';
import 'package:ht_authentication_repository/ht_authentication_repository.dart'; // Import the public API
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

// Mocks
class MockHtAuthenticationClient extends Mock
    implements HtAuthenticationClient {}

class MockUser extends Mock
    implements User {} // Add MockUser if needed for tests

// Helper to create exceptions with mock StackTrace
AuthException _createException(
  Object error,
  AuthException Function(Object, StackTrace) constructor,
) {
  return constructor(error, StackTrace.current);
}

void main() {
  group('HtAuthenticationRepository', () {
    late HtAuthenticationClient client;
    late HtAuthenticationRepository repository;
    late BehaviorSubject<User> userSubject; // Declare userSubject here

    setUp(() {
      client = MockHtAuthenticationClient();
      userSubject = BehaviorSubject<User>(); // Initialize userSubject
      // Mock client.user to return the stream from userSubject
      when(() => client.user).thenAnswer((_) => userSubject.stream);
      repository = HtAuthenticationRepository(authenticationClient: client);
    });

    // Add tearDown to close the subject
    tearDown(() {
      userSubject.close();
    });

    test('constructor', () {
      verify(() => client.user).called(1);
    });

    group('user', () {
      test('emits default user initially', () {
        expect(repository.user, emits(isA<User>()));
      });

      test('emits new user when client emits', () {
        final user1 = MockUser();
        final user2 = User(uid: 'test-uid'); // Use a concrete User or MockUser

        // Expect the stream from the repository (which gets from userSubject)
        expectLater(
          repository.user,
          // Seeded with default User(), then user1, then user2
          emitsInOrder(<Matcher>[isA<User>(), equals(user1), equals(user2)]),
        );

        // Add users to the subject the repository is listening to
        userSubject
          ..add(user1)
          ..add(user2);
      });
    });

    group('currentUser', () {
      // Renamed test for clarity
      test('reflects the latest user emitted by the stream', () async {
        final user = MockUser();
        // Optionally mock properties for better assertion
        when(() => user.uid).thenReturn('mock-user-id');

        // Add the mock user to the stream the repository is listening to
        userSubject.add(user);

        // Wait specifically for the 'user' we added to be emitted,
        // ignoring the initial default user.
        await expectLater(repository.user, emitsThrough(user));

        // Now assert against the synchronous getter, which should be updated
        expect(repository.currentUser, equals(user));
        // Optionally assert properties
        expect(repository.currentUser.uid, equals('mock-user-id'));
      });
    });

    group('sendSignInLinkToEmail', () {
      const email = 'test@example.com';

      test('calls client method', () async {
        when(
          () => client.sendSignInLinkToEmail(email: email),
        ).thenAnswer((_) async {});

        await repository.sendSignInLinkToEmail(email: email);

        verify(() => client.sendSignInLinkToEmail(email: email)).called(1);
      });

      test('throws SendSignInLinkException on client error', () async {
        final exception = _createException(
          Exception(),
          SendSignInLinkException.new,
        );
        when(
          () => client.sendSignInLinkToEmail(email: email),
        ).thenThrow(exception);

        expect(
          () => repository.sendSignInLinkToEmail(email: email),
          throwsA(isA<SendSignInLinkException>()),
        );
      });

      test('throws SendSignInLinkException on general error', () async {
        when(
          () => client.sendSignInLinkToEmail(email: email),
        ).thenThrow(Exception());

        expect(
          () => repository.sendSignInLinkToEmail(email: email),
          throwsA(isA<SendSignInLinkException>()),
        );
      });
    });

    group('signInWithEmailLink', () {
      const email = 'test@example.com';
      const link = 'https://example.com/link';

      test('calls client method', () async {
        when(
          () => client.signInWithEmailLink(email: email, emailLink: link),
        ).thenAnswer((_) async {});

        await repository.signInWithEmailLink(email: email, emailLink: link);

        verify(
          () => client.signInWithEmailLink(email: email, emailLink: link),
        ).called(1);
      });

      test('throws InvalidSignInLinkException on client error', () async {
        final exception = _createException(
          Exception(),
          InvalidSignInLinkException.new,
        );
        when(
          () => client.signInWithEmailLink(email: email, emailLink: link),
        ).thenThrow(exception);

        expect(
          () => repository.signInWithEmailLink(email: email, emailLink: link),
          throwsA(isA<InvalidSignInLinkException>()),
        );
      });

      test('throws UserNotFoundException on client error', () async {
        final exception = _createException(
          Exception(),
          UserNotFoundException.new,
        );
        when(
          () => client.signInWithEmailLink(email: email, emailLink: link),
        ).thenThrow(exception);

        expect(
          () => repository.signInWithEmailLink(email: email, emailLink: link),
          throwsA(isA<UserNotFoundException>()),
        );
      });

      test('throws InvalidSignInLinkException on general error', () async {
        when(
          () => client.signInWithEmailLink(email: email, emailLink: link),
        ).thenThrow(Exception());

        // Repository wraps general errors into InvalidSignInLinkException
        expect(
          () => repository.signInWithEmailLink(email: email, emailLink: link),
          throwsA(isA<InvalidSignInLinkException>()),
        );
      });
    });

    group('signInWithGoogle', () {
      test('calls client method', () async {
        when(() => client.signInWithGoogle()).thenAnswer((_) async {});

        await repository.signInWithGoogle();

        verify(() => client.signInWithGoogle()).called(1);
      });

      test('throws GoogleSignInException on client error', () async {
        final exception = _createException(
          Exception(),
          GoogleSignInException.new,
        );
        when(() => client.signInWithGoogle()).thenThrow(exception);

        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<GoogleSignInException>()),
        );
      });

      test('throws GoogleSignInException on general error', () async {
        when(() => client.signInWithGoogle()).thenThrow(Exception());

        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<GoogleSignInException>()),
        );
      });
    });

    group('signInAnonymously', () {
      test('calls client method', () async {
        when(() => client.signInAnonymously()).thenAnswer((_) async {});

        await repository.signInAnonymously();

        verify(() => client.signInAnonymously()).called(1);
      });

      test('throws AnonymousLoginException on client error', () async {
        final exception = _createException(
          Exception(),
          AnonymousLoginException.new,
        );
        when(() => client.signInAnonymously()).thenThrow(exception);

        expect(
          () => repository.signInAnonymously(),
          throwsA(isA<AnonymousLoginException>()),
        );
      });

      test('throws AnonymousLoginException on general error', () async {
        when(() => client.signInAnonymously()).thenThrow(Exception());

        expect(
          () => repository.signInAnonymously(),
          throwsA(isA<AnonymousLoginException>()),
        );
      });
    });

    group('signOut', () {
      test('calls client method', () async {
        when(() => client.signOut()).thenAnswer((_) async {});

        await repository.signOut();

        verify(() => client.signOut()).called(1);
      });

      test('throws LogoutException on client error', () async {
        final exception = _createException(Exception(), LogoutException.new);
        when(() => client.signOut()).thenThrow(exception);

        expect(() => repository.signOut(), throwsA(isA<LogoutException>()));
      });

      test('throws LogoutException on general error', () async {
        when(() => client.signOut()).thenThrow(Exception());

        expect(() => repository.signOut(), throwsA(isA<LogoutException>()));
      });
    });

    group('deleteAccount', () {
      test('calls client method', () async {
        when(() => client.deleteAccount()).thenAnswer((_) async {});

        await repository.deleteAccount();

        verify(() => client.deleteAccount()).called(1);
      });

      test('throws DeleteAccountException on client error', () async {
        final exception = _createException(
          Exception(),
          DeleteAccountException.new,
        );
        when(() => client.deleteAccount()).thenThrow(exception);

        expect(
          () => repository.deleteAccount(),
          throwsA(isA<DeleteAccountException>()),
        );
      });

      test('throws DeleteAccountException on general error', () async {
        when(() => client.deleteAccount()).thenThrow(Exception());

        expect(
          () => repository.deleteAccount(),
          throwsA(isA<DeleteAccountException>()),
        );
      });
    });
  });
}
