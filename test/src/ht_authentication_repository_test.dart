// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ht_authentication_client/ht_authentication_client.dart'; // Import client models and exceptions
import 'package:ht_authentication_repository/ht_authentication_repository.dart'; // Import the public API
import 'package:ht_kv_storage_service/ht_kv_storage_service.dart'; // Import storage service and keys
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

// Mocks
class MockHtAuthenticationClient extends Mock
    implements HtAuthenticationClient {}

class MockHtKVStorageService extends Mock implements HtKVStorageService {}

void main() {
  group('HtAuthenticationRepository', () {
    late HtAuthenticationClient client;
    late HtKVStorageService storageService; // Add storage service mock
    late HtAuthenticationRepository repository;
    late BehaviorSubject<User> userSubject;

    // Define a default user for seeding and initial state checks
    final defaultUser = User();
    final testUser1 = User(uid: 'test-uid-1', email: 'test1@example.com');
    final testUser2 = User(uid: 'test-uid-2', email: 'test2@example.com');

    setUp(() {
      client = MockHtAuthenticationClient();
      storageService = MockHtKVStorageService(); // Initialize storage mock
      userSubject = BehaviorSubject<User>.seeded(
        defaultUser,
      ); // Seed with default

      // Mock client.user to return the stream from userSubject
      when(() => client.user).thenAnswer((_) => userSubject.stream);

      // Provide both mocks to the repository constructor
      repository = HtAuthenticationRepository(
        authenticationClient: client,
        storageService: storageService,
      );
    });

    // Add tearDown to close the subject
    tearDown(() {
      userSubject.close();
    });

    test('constructor subscribes to client user stream', () {
      // Verification happens implicitly via the stream behavior in other tests
      // but we can keep this simple check.
      verify(() => client.user).called(1);
      // Check initial state
      expect(repository.currentUser, equals(defaultUser));
    });

    group('user stream', () {
      test('emits default user immediately upon listen', () {
        // The stream is seeded, so it emits the default user right away.
        expect(repository.user, emits(defaultUser));
      });

      test('emits new users when client stream emits', () async {
        // Expect the stream from the repository
        unawaited(
          expectLater(
            repository.user,
            // Seeded with defaultUser, then testUser1, then testUser2
            emitsInOrder(<Matcher>[
              equals(defaultUser),
              equals(testUser1),
              equals(testUser2),
            ]),
          ),
        );

        // Add users to the subject the repository is listening to
        userSubject
          ..add(testUser1)
          ..add(testUser2);
      });
    });

    group('currentUser getter', () {
      test('returns the default user initially', () {
        expect(repository.currentUser, equals(defaultUser));
      });

      test('returns the latest user emitted by the stream', () async {
        // Add a user to the stream
        // Add a user to the stream
        userSubject.add(testUser1);

        // Wait for the stream to emit the added user. Since it's seeded,
        // we expect the default user first, then the new one.
        // A short delay or listening for the specific event is needed.
        await repository.user.firstWhere((user) => user == testUser1);

        // Assert the getter reflects the latest emitted user
        expect(repository.currentUser, equals(testUser1));

        // Add another user
        userSubject.add(testUser2);
        await repository.user.firstWhere((user) => user == testUser2);
        expect(repository.currentUser, equals(testUser2));
      });
    });

    group('sendSignInLinkToEmail', () {
      const email = 'test@example.com';
      final storageKey = StorageKey.pendingSignInEmail.stringValue;

      test(
        'calls client.sendSignInLinkToEmail and storage.writeString on success',
        () async {
          // Arrange
          when(
            () => client.sendSignInLinkToEmail(email: email),
          ).thenAnswer((_) async {});
          when(
            () => storageService.writeString(key: storageKey, value: email),
          ).thenAnswer((_) async {});

          // Act
          await repository.sendSignInLinkToEmail(email: email);

          // Assert
          verify(() => client.sendSignInLinkToEmail(email: email)).called(1);
          verify(
            () => storageService.writeString(key: storageKey, value: email),
          ).called(1);
        },
      );

      test('throws SendSignInLinkException on client error', () async {
        // Arrange
        final exception = SendSignInLinkException(
          Exception(),
          StackTrace.current,
        );
        when(
          () => client.sendSignInLinkToEmail(email: email),
        ).thenThrow(exception);

        // Act & Assert
        expect(
          () => repository.sendSignInLinkToEmail(email: email),
          throwsA(isA<SendSignInLinkException>()),
        );
        verifyNever(
          () => storageService.writeString(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        );
      });

      test('throws SendSignInLinkException on storage write error', () async {
        // Arrange
        final exception = StorageWriteException(storageKey, email);
        when(
          () => client.sendSignInLinkToEmail(email: email),
        ).thenAnswer((_) async {}); // Client succeeds
        when(
          () => storageService.writeString(key: storageKey, value: email),
        ).thenThrow(exception); // Storage fails

        // Act & Assert
        expect(
          () => repository.sendSignInLinkToEmail(email: email),
          throwsA(
            isA<SendSignInLinkException>().having(
              (e) => e.error,
              'error',
              exception, // Check that the original storage exception is wrapped
            ),
          ),
        );
        verify(() => client.sendSignInLinkToEmail(email: email)).called(1);
      });

      test(
        'throws SendSignInLinkException on general error during client call',
        () async {
          // Arrange
          final exception = Exception('Something went wrong');
          when(
            () => client.sendSignInLinkToEmail(email: email),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => repository.sendSignInLinkToEmail(email: email),
            throwsA(isA<SendSignInLinkException>()),
          );
          verifyNever(
            () => storageService.writeString(
              key: any(named: 'key'),
              value: any(named: 'value'),
            ),
          );
        },
      );
    });

    group('isSignInWithEmailLink', () {
      const link = 'https://example.com/link';

      test(
        'calls client.isSignInWithEmailLink and returns its result',
        () async {
          // Arrange
          when(
            () => client.isSignInWithEmailLink(emailLink: link),
          ).thenAnswer((_) async => true);

          // Act
          final result = await repository.isSignInWithEmailLink(
            emailLink: link,
          );

          // Assert
          expect(result, isTrue);
          verify(() => client.isSignInWithEmailLink(emailLink: link)).called(1);

          // Arrange false case
          when(
            () => client.isSignInWithEmailLink(emailLink: link),
          ).thenAnswer((_) async => false);

          // Act
          final resultFalse = await repository.isSignInWithEmailLink(
            emailLink: link,
          );

          // Assert
          expect(resultFalse, isFalse);
        },
      );

      test('propagates exceptions from client', () async {
        // Arrange
        final exception = Exception('Client failed');
        when(
          () => client.isSignInWithEmailLink(emailLink: link),
        ).thenThrow(exception);

        // Act & Assert
        expect(
          () => repository.isSignInWithEmailLink(emailLink: link),
          throwsA(equals(exception)),
        );
      });
    });

    group('signInWithEmailLink', () {
      const storedEmail = 'test@example.com';
      const link = 'https://example.com/link';
      final storageKey = StorageKey.pendingSignInEmail.stringValue;

      setUp(() {
        // Common setup: Assume email is stored successfully before sign-in attempt
        when(
          () => storageService.readString(key: storageKey),
        ).thenAnswer((_) async => storedEmail);
        // Mock successful client sign-in by default
        when(
          () => client.signInWithEmailLink(email: storedEmail, emailLink: link),
        ).thenAnswer((_) async {});
        // Mock successful storage delete by default
        when(
          () => storageService.delete(key: storageKey),
        ).thenAnswer((_) async {});
      });

      test(
        'reads stored email, calls client.signIn, deletes stored email on success',
        () async {
          // Act
          await repository.signInWithEmailLink(emailLink: link);

          // Assert
          verifyInOrder([
            // 1. Read email
            () => storageService.readString(key: storageKey),
            // 2. Sign in with client
            () =>
                client.signInWithEmailLink(email: storedEmail, emailLink: link),
            // 3. Delete email
            () => storageService.delete(key: storageKey),
          ]);
        },
      );

      test(
        'throws InvalidSignInLinkException if stored email is null',
        () async {
          // Arrange: Override setup - storage returns null
          when(
            () => storageService.readString(key: storageKey),
          ).thenAnswer((_) async => null);

          // Act & Assert
          expect(
            () => repository.signInWithEmailLink(emailLink: link),
            throwsA(
              isA<InvalidSignInLinkException>().having(
                (e) => e.error,
                'error',
                isA<StorageKeyNotFoundException>(),
              ),
            ),
          );
          verifyNever(
            () => client.signInWithEmailLink(
              email: any(named: 'email'),
              emailLink: any(named: 'emailLink'),
            ),
          );
          verifyNever(() => storageService.delete(key: any(named: 'key')));
        },
      );

      test('throws InvalidSignInLinkException on storage read error', () async {
        // Arrange: Override setup - storage read throws
        final exception = StorageReadException(storageKey);
        when(
          () => storageService.readString(key: storageKey),
        ).thenThrow(exception);

        // Act & Assert
        expect(
          () => repository.signInWithEmailLink(emailLink: link),
          throwsA(
            isA<InvalidSignInLinkException>().having(
              (e) => e.error,
              'error',
              exception,
            ),
          ),
        );
        verifyNever(
          () => client.signInWithEmailLink(
            email: any(named: 'email'),
            emailLink: any(named: 'emailLink'),
          ),
        );
        verifyNever(() => storageService.delete(key: any(named: 'key')));
      });

      test(
        'throws InvalidSignInLinkException on client InvalidSignInLinkException',
        () async {
          // Arrange: Override setup - client throws InvalidSignInLinkException
          final exception = InvalidSignInLinkException(
            Exception(),
            StackTrace.current,
          );
          when(
            () =>
                client.signInWithEmailLink(email: storedEmail, emailLink: link),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => repository.signInWithEmailLink(emailLink: link),
            throwsA(exception), // Should rethrow the specific exception
          );
          // Verify read happened, but delete did not
          verify(() => storageService.readString(key: storageKey)).called(1);
          verifyNever(() => storageService.delete(key: storageKey));
        },
      );

      test(
        'throws UserNotFoundException on client UserNotFoundException',
        () async {
          // Arrange: Override setup - client throws UserNotFoundException
          final exception = UserNotFoundException(
            Exception(),
            StackTrace.current,
          );
          when(
            () =>
                client.signInWithEmailLink(email: storedEmail, emailLink: link),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => repository.signInWithEmailLink(emailLink: link),
            throwsA(exception), // Should rethrow the specific exception
          );
          // Verify read happened, but delete did not
          verify(() => storageService.readString(key: storageKey)).called(1);
          verifyNever(() => storageService.delete(key: storageKey));
        },
      );

      test(
        'throws InvalidSignInLinkException on storage delete error',
        () async {
          // Arrange: Override setup - storage delete throws
          final storageException = StorageDeleteException(storageKey);
          when(
            () => storageService.delete(key: storageKey),
          ).thenThrow(storageException);
          // Client sign-in succeeds (default mock in setUp)

          // Act
          InvalidSignInLinkException? caughtException;
          try {
            await repository.signInWithEmailLink(emailLink: link);
          } on InvalidSignInLinkException catch (e) {
            caughtException = e;
          }

          // Assert Exception
          expect(
            caughtException,
            isNotNull,
            reason: 'Expected InvalidSignInLinkException was not thrown.',
          );
          expect(caughtException, isA<InvalidSignInLinkException>());
          expect(
            caughtException!.error,
            equals(storageException),
            reason: 'Wrapped exception should be the StorageDeleteException.',
          );

          // Assert Verification (after catching)
          verify(() => storageService.readString(key: storageKey)).called(1);
          verify(
            () =>
                client.signInWithEmailLink(email: storedEmail, emailLink: link),
          ).called(1);
          verify(() => storageService.delete(key: storageKey)).called(1);
        },
      );

      test(
        'throws InvalidSignInLinkException on general error during client call',
        () async {
          // Arrange: Override setup - client throws general exception
          final exception = Exception('Client failed');
          when(
            () =>
                client.signInWithEmailLink(email: storedEmail, emailLink: link),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => repository.signInWithEmailLink(emailLink: link),
            throwsA(
              isA<InvalidSignInLinkException>().having(
                (e) => e.error,
                'error',
                exception, // Check original exception is wrapped
              ),
            ),
          );
          verify(() => storageService.readString(key: storageKey)).called(1);
          verifyNever(() => storageService.delete(key: storageKey));
        },
      );
    });

    // --- Other method tests remain largely the same, just update exception creation ---

    group('signInWithGoogle', () {
      test('calls client.signInWithGoogle', () async {
        when(() => client.signInWithGoogle()).thenAnswer((_) async {});
        await repository.signInWithGoogle();
        verify(() => client.signInWithGoogle()).called(1);
      });

      test('throws GoogleSignInException on client error', () async {
        final exception = GoogleSignInException(
          Exception(),
          StackTrace.current,
        );
        when(() => client.signInWithGoogle()).thenThrow(exception);
        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<GoogleSignInException>()),
        );
      });

      test('throws GoogleSignInException on general error', () async {
        final exception = Exception('Network error');
        when(() => client.signInWithGoogle()).thenThrow(exception);
        expect(
          () => repository.signInWithGoogle(),
          throwsA(
            isA<GoogleSignInException>().having(
              (e) => e.error,
              'error',
              exception,
            ),
          ),
        );
      });
    });

    group('signInAnonymously', () {
      test('calls client.signInAnonymously', () async {
        when(() => client.signInAnonymously()).thenAnswer((_) async {});
        await repository.signInAnonymously();
        verify(() => client.signInAnonymously()).called(1);
      });

      test('throws AnonymousLoginException on client error', () async {
        final exception = AnonymousLoginException(
          Exception(),
          StackTrace.current,
        );
        when(() => client.signInAnonymously()).thenThrow(exception);
        expect(
          () => repository.signInAnonymously(),
          throwsA(isA<AnonymousLoginException>()),
        );
      });

      test('throws AnonymousLoginException on general error', () async {
        final exception = Exception('Something failed');
        when(() => client.signInAnonymously()).thenThrow(exception);
        expect(
          () => repository.signInAnonymously(),
          throwsA(
            isA<AnonymousLoginException>().having(
              (e) => e.error,
              'error',
              exception,
            ),
          ),
        );
      });
    });

    group('signOut', () {
      test('calls client.signOut', () async {
        when(() => client.signOut()).thenAnswer((_) async {});
        await repository.signOut();
        verify(() => client.signOut()).called(1);
      });

      test('throws LogoutException on client error', () async {
        final exception = LogoutException(Exception(), StackTrace.current);
        when(() => client.signOut()).thenThrow(exception);
        expect(() => repository.signOut(), throwsA(isA<LogoutException>()));
      });

      test('throws LogoutException on general error', () async {
        final exception = Exception('Sign out failed');
        when(() => client.signOut()).thenThrow(exception);
        expect(
          () => repository.signOut(),
          throwsA(
            isA<LogoutException>().having((e) => e.error, 'error', exception),
          ),
        );
      });
    });

    group('deleteAccount', () {
      test('calls client.deleteAccount', () async {
        when(() => client.deleteAccount()).thenAnswer((_) async {});
        await repository.deleteAccount();
        verify(() => client.deleteAccount()).called(1);
      });

      test('throws DeleteAccountException on client error', () async {
        final exception = DeleteAccountException(
          Exception(),
          StackTrace.current,
        );
        when(() => client.deleteAccount()).thenThrow(exception);
        expect(
          () => repository.deleteAccount(),
          throwsA(isA<DeleteAccountException>()),
        );
      });

      test('throws DeleteAccountException on general error', () async {
        final exception = Exception('Deletion failed');
        when(() => client.deleteAccount()).thenThrow(exception);
        expect(
          () => repository.deleteAccount(),
          throwsA(
            isA<DeleteAccountException>().having(
              (e) => e.error,
              'error',
              exception,
            ),
          ),
        );
      });
    });
  });
}
