import 'package:flutter_test/flutter_test.dart';
import 'package:ht_authentication_client/ht_authentication_client.dart';
import 'package:ht_authentication_repository/src/ht_authentication_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

class MockHtAuthenticationClient extends Mock
    implements HtAuthenticationClient {}

void main() {
  group('HtAuthenticationRepository', () {
    late HtAuthenticationClient client;
    late HtAuthenticationRepository repository;

    setUp(() {
      client = MockHtAuthenticationClient();
      when(() => client.user).thenAnswer((_) => const Stream.empty());
      repository = HtAuthenticationRepository(authenticationClient: client);
    });

    test('constructor', () {
      verify(() => client.user).called(1);
    });

    group('user', () {
      test('emits default user initially', () {
        expect(repository.user, emits(isA<User>()));
      });

      test('emits new user when client emits', () {
        final user = User(uid: 'test-uid');
        final stream = BehaviorSubject<User>.seeded(user);
        when(() => client.user).thenAnswer((_) => stream);
        repository = HtAuthenticationRepository(authenticationClient: client);

        expect(repository.user, emitsInOrder([isA<User>(), user]));
      });
    });

    group('currentUser', () {
      test('returns current user', () {
        expect(repository.currentUser, isA<User>());
      });
    });

    group('signInWithEmailAndPassword', () {
      test('calls client method', () async {
        when(
          () => client.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {});

        await repository.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password',
        );

        verify(
          () => client.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          ),
        ).called(1);
      });

      test('throws EmailSignInException on client error', () async {
        final exception = EmailSignInException(Exception(), StackTrace.empty);
        when(
          () => client.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(exception);

        expect(
          () => repository.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          ),
          throwsA(isA<EmailSignInException>()),
        );
      });

      test('throws EmailSignInException on general error', () async {
        when(
          () => client.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception());

        expect(
          () => repository.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          ),
          throwsA(isA<EmailSignInException>()),
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
        final exception = GoogleSignInException(Exception(), StackTrace.empty);
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
        final exception = AnonymousLoginException(
          Exception(),
          StackTrace.empty,
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
        final exception = LogoutException(Exception(), StackTrace.empty);
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
        final exception = DeleteAccountException(Exception(), StackTrace.empty);
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
