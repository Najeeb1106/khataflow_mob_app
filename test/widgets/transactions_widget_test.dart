import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khata_app/features/transactions/presentation/screens/quick_add_transaction_screen.dart';
import 'package:khata_app/features/people/presentation/providers/people_providers.dart';
import 'package:khata_app/features/khata/presentation/providers/khata_providers.dart';
import 'package:khata_app/features/people/data/models/person.dart';
import 'package:khata_app/features/khata/data/models/khata.dart';
import 'package:khata_app/features/people/data/repositories/person_repository.dart';
import 'package:khata_app/features/khata/data/repositories/khata_repository.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockKhataRepository extends Mock implements KhataRepository {}

void main() {
  late MockPersonRepository mockPersonRepo;
  late MockKhataRepository mockKhataRepo;
  late Person testPerson;

  setUpAll(() {
    registerFallbackValue(Person());
    registerFallbackValue(Khata());
  });

  setUp(() {
    mockPersonRepo = MockPersonRepository();
    mockKhataRepo = MockKhataRepository();

    testPerson = Person()
      ..uuid = 'p-1'
      ..name = 'Usman Ali'
      ..phone = '03129876543'
      ..isDeleted = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  });

  group('QuickAddTransactionScreen Widget Tests', () {
    testWidgets('renders initial quick add screen options', (
      WidgetTester tester,
    ) async {
      when(
        () => mockPersonRepo.getPeople(
          includeDeleted: any(named: 'includeDeleted'),
        ),
      ).thenAnswer((_) async => [testPerson]);

      final router = GoRouter(
        initialLocation: '/transaction/quick-add',
        routes: [
          GoRoute(
            path: '/transaction/quick-add',
            builder: (context, state) => const QuickAddTransactionScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            personRepositoryProvider.overrideWithValue(mockPersonRepo),
            khataRepositoryProvider.overrideWithValue(mockKhataRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify page layout sections
      expect(find.text('Quick Add Transaction'), findsOneWidget);
      expect(find.text('1. Select Contact'), findsOneWidget);
      expect(find.text('3. Enter Amount'), findsOneWidget);
      expect(find.text('4. Transaction Type'), findsOneWidget);
      expect(find.text('GAVE (Lent)'), findsOneWidget);
      expect(find.text('RECEIVED'), findsOneWidget);
    });
  });
}
