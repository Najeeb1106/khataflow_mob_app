import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata_app/core/utils/phone_normalizer.dart';
import 'package:khata_app/core/utils/avatar_color_helper.dart';
import 'package:khata_app/core/services/contact_import_service.dart';
import 'package:khata_app/features/people/data/models/person.dart';

void main() {
  group('PhoneNormalizer Tests', () {
    test('normalize removes prefix +92 and leading digits correctly', () {
      expect(PhoneNormalizer.normalize('+923001234567'), '3001234567');
      expect(PhoneNormalizer.normalize('923001234567'), '3001234567');
      expect(PhoneNormalizer.normalize('03001234567'), '3001234567');
    });

    test('normalize removes spaces, dashes and brackets', () {
      expect(PhoneNormalizer.normalize('0300 123-4567'), '3001234567');
      expect(PhoneNormalizer.normalize(' +92-300-123-4567 '), '3001234567');
      expect(PhoneNormalizer.normalize('(0300)1234567'), '3001234567');
      expect(PhoneNormalizer.normalize('+92 300 123 45 67'), '3001234567');
    });

    test('normalize handles invalid or empty inputs gracefully', () {
      expect(PhoneNormalizer.normalize(''), '');
      expect(PhoneNormalizer.normalize(null), '');
      expect(PhoneNormalizer.normalize('invalid_phone'), '');
      expect(PhoneNormalizer.normalize('   '), '');
    });

    test('isSameNumber correctly compares different raw formats', () {
      expect(PhoneNormalizer.isSameNumber('+923001234567', '0300-123-4567'), true);
      expect(PhoneNormalizer.isSameNumber('03001234567', '3001234567'), true);
      expect(PhoneNormalizer.isSameNumber('03001234567', '03001234568'), false);
    });
  });

  group('AvatarColorHelper Tests', () {
    test('Same UUID yields identical color', () {
      final uuid = '550e8400-e29b-41d4-a716-446655440000';
      final color1 = AvatarColorHelper.forUuid(uuid);
      final color2 = AvatarColorHelper.forUuid(uuid);
      expect(color1, equals(color2));
    });

    test('Different UUIDs yield deterministic output colors', () {
      final uuidA = '550e8400-e29b-41d4-a716-446655440000';
      final uuidB = 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6';
      
      final colorA = AvatarColorHelper.forUuid(uuidA);
      final colorB = AvatarColorHelper.forUuid(uuidB);
      
      expect(colorA, isA<Color>());
      expect(colorB, isA<Color>());
      
      expect(AvatarColorHelper.forUuid(uuidA), equals(colorA));
      expect(AvatarColorHelper.forUuid(uuidB), equals(colorB));
    });

    test('Renaming contact does not affect color', () {
      final uuid = '550e8400-e29b-41d4-a716-446655440000';
      final person = Person()
        ..uuid = uuid
        ..name = 'Ali Ahmed';
      
      final colorBefore = AvatarColorHelper.forUuid(person.uuid);
      
      // Rename person
      person.name = 'Ali Raza';
      final colorAfter = AvatarColorHelper.forUuid(person.uuid);
      
      expect(colorBefore, equals(colorAfter));
    });
  });

  group('Duplicate Detection Tests', () {
    late List<Person> existingPeople;

    setUp(() {
      existingPeople = [
        Person()
          ..uuid = '1'
          ..name = 'Ali Ahmed'
          ..phone = '3001234567',
        Person()
          ..uuid = '2'
          ..name = 'Jane Doe'
          ..phone = null,
      ];
    });

    test('matches duplicate by normalized phone number (priority 1)', () {
      // Different name, same normalized phone
      final result = ContactImportService.findDuplicate(
        people: existingPeople,
        name: 'Ali New Name',
        phone: '+92 300 123-4567',
      );
      expect(result, isNotNull);
      expect(result!.uuid, '1');
      expect(result.name, 'Ali Ahmed');
    });

    test('matches duplicate by case-insensitive trimmed name (priority 2)', () {
      // Same name different case and whitespace, no phone matching
      final result1 = ContactImportService.findDuplicate(
        people: existingPeople,
        name: ' ali ahmed ',
        phone: null,
      );
      expect(result1, isNotNull);
      expect(result1!.uuid, '1');

      final result2 = ContactImportService.findDuplicate(
        people: existingPeople,
        name: 'Ali Ahmed',
        phone: '03339998888', // different phone, but name matches
      );
      expect(result2, isNotNull);
      expect(result2!.uuid, '1');
    });

    test('returns null when no duplicate exists', () {
      final result = ContactImportService.findDuplicate(
        people: existingPeople,
        name: 'John Smith',
        phone: '03123456789',
      );
      expect(result, isNull);
    });

    test('ignores self UUID during editing to prevent self-duplicates', () {
      // The person itself has uuid '1', and name 'Ali Ahmed', phone '3001234567'.
      // If we exclude uuid '1', it should not detect a duplicate.
      final result = ContactImportService.findDuplicate(
        people: existingPeople,
        name: 'Ali Ahmed',
        phone: '03001234567',
        excludeUuid: '1',
      );
      expect(result, isNull);
    });

    test('skips phone comparison when input phone is empty/null', () {
      // If phone is null, it should match Jane Doe by name but not trigger phone matching
      final result = ContactImportService.findDuplicate(
        people: existingPeople,
        name: 'jane doe',
        phone: null,
      );
      expect(result, isNotNull);
      expect(result!.uuid, '2');
    });
  });
}
