import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khata_app/features/people/presentation/screens/people_list_screen.dart';
import 'package:khata_app/features/people/presentation/providers/people_providers.dart';
import 'package:khata_app/features/people/data/models/person.dart';
import 'package:khata_app/features/people/data/repositories/person_repository.dart';
import 'package:khata_app/features/khata/data/repositories/khata_repository.dart';
import 'package:khata_app/features/transactions/data/repositories/transaction_repository.dart';
import 'package:khata_app/features/khata/presentation/providers/khata_providers.dart';
import 'package:khata_app/features/transactions/presentation/providers/transaction_providers.dart';

class MockPersonRepository extends Mock implements PersonRepository {}
class MockKhataRepository extends Mock implements KhataRepository {}
class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockPersonRepository mockPersonRepo;
  late MockKhataRepository mockKhataRepo;
  late MockTransactionRepository mockTxRepo;
  late Person testPerson;

  setUpAll(() {
    registerFallbackValue(Person());
  });

  setUp(() {
    mockPersonRepo = MockPersonRepository();
    mockKhataRepo = MockKhataRepository();
    mockTxRepo = MockTransactionRepository();

    testPerson = Person()
      ..uuid = 'p-1'
      ..name = 'Farhan Saeed'
      ..phone = '03451112222'
      ..isDeleted = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  });

  group('PeopleListScreen Widget Tests', () {
    testWidgets('renders list of contacts correctly', (WidgetTester tester) async {
      when(() => mockPersonRepo.getPeople(includeDeleted: false))
          .thenAnswer((_) async => [testPerson]);
      when(() => mockKhataRepo.getKhatasForPerson('p-1', includeDeleted: false))
          .thenAnswer((_) async => []);
      when(() => mockTxRepo.getTransactionsForKhata(any(), includeDeleted: any(named: 'includeDeleted')))
          .thenAnswer((_) async => []);

      final router = GoRouter(
        initialLocation: '/people',
        routes: [
          GoRoute(
            path: '/people',
            builder: (context, state) => const PeopleListScreen(),
          ),
          GoRoute(
            path: '/people/add',
            builder: (context, state) => const Scaffold(body: Text('Add Person Page')),
          ),
          GoRoute(
            path: '/people/:id',
            builder: (context, state) => Scaffold(body: Text('Person Details: ${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            personRepositoryProvider.overrideWithValue(mockPersonRepo),
            khataRepositoryProvider.overrideWithValue(mockKhataRepo),
            transactionRepositoryProvider.overrideWithValue(mockTxRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify contact shows in list
      expect(find.text('Farhan Saeed'), findsOneWidget);
      expect(find.text('03451112222'), findsOneWidget);

      // Verify floating button is visible and tap navigates
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Person Page'), findsOneWidget);
    });
  });
}
