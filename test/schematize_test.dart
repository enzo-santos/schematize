import 'package:schematize/schematize.dart';
import 'package:test/test.dart';

void main() {
  group('validate', () {
    test('of', () {
      final Schema type = Schema.of(double);
      expect(type.validate(42.0), true);
      expect(type.validate(null), false);
      expect(type.validate(42), false);
      expect(type.validate('42.0'), false);
      expect(type.validate([42.0]), false);
      expect(type.validate({'number': 42.0}), false);
    });
    test('of with subtype', () {
      final Schema type = Schema.of(num);
      expect(type.validate(1), false);
      expect(type.validate(3.14), false);
    });
    test('union', () {
      final Schema type = Schema.union([Schema.of(int), Schema.of(double)]);
      expect(type.validate(42.0), true);
      expect(type.validate(null), false);
      expect(type.validate(42), true);
      expect(type.validate('42.0'), false);
      expect(type.validate([42.0]), false);
      expect(type.validate({'number': 42.0}), false);
    });
    test('object', () {
      final Schema type = Schema.object({
        'name': Schema.of(String),
        'age': Schema.of(int),
        'height': Schema.of(double),
        'isStudent': Schema.of(bool),
      });
      expect(type.validate(42.0), false);
      expect(type.validate(null), false);
      expect(type.validate([42.0]), false);
      expect(type.validate({'number': 42.0}), false);
      expect(type.validate({'name': 'John'}), false);
      expect(type.validate({'name': 'John', 'age': 30}), false);
      expect(type.validate({'name': 'John', 'age': 30, 'height': 1.75}), false);
      expect(
          type.validate(
              {'name': 'John', 'age': 30, 'height': 1.75, 'isStudent': true}),
          true);
      expect(
        type.validate({
          'name': 'John',
          'age': 30,
          'height': 1.75,
          'isStudent': true,
          'grades': [8, 9, 10]
        }),
        true,
      );
    });
    test('collection', () {
      final Schema type = Schema.collection(Schema.of(double));
      expect(type.validate(42.0), false);
      expect(type.validate(null), false);
      expect(type.validate({'number': 42.0}), true);
      expect(type.validate([]), true);
      expect(type.validate([42.0]), true);
      expect(type.validate([42.0, 42]), false);
    });
  });
}
