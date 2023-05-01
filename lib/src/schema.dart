import 'debug_node.dart';

/// A schema that validate Dart objects.
///
/// To validate a Dart object, call [validate] on it. It'll return a simple
/// [bool] indicating if that object was accepted or rejected. To know the
/// reason why a Dart object was rejected during the validation in a
/// human-readable way, call [trace] on it. It'll return a [ObjectNode]
/// containing the reason and the path in the Dart object where the rejection
/// occurred.
///
/// To create a [Schema], use its constant factory constructors.
abstract class Schema {
  /// Accepts any value of runtime type *exactly* equal to [type].
  ///
  /// ```dart
  /// const Schema schema = Schema.of(int);
  /// print(schema.validate(1));       // true
  /// print(schema.validate(3.14));    // false
  /// ```
  ///
  /// Note that calling [Schema.of] on an abstract type will always reject,
  /// since Dart does not have a way to check if one [Type] inherits from
  /// another:
  ///
  /// ```dart
  /// const Schema schema = Schema.of(num);
  /// print(schema.validate(1));       // false
  /// print(schema.validate(3.14));    // false
  /// ```
  ///
  /// You can bypass this by creating a [Schema.union], for example:
  ///
  /// ```dart
  /// const Schema numType = Schema.union([
  ///   Schema.of(int),
  ///   Schema.of(double),
  /// ]);
  /// print(numType.validate(1));       // true
  /// print(numType.validate(3.14));    // true
  /// print(numType.validate('2'));     // false
  /// ```
  const factory Schema.of(Type type) = _SimpleSchema;

  /// A special case of [Schema.of] for strings.
  ///
  /// It accepts any input value of type [String]. However, it acceptance
  /// depends on the values of
  ///
  /// - [minLength] (only accepts if its length is less than or equal to the
  ///   value of this argument)
  /// - [maxLength] (only accepts if its length is greater than or equal to the
  ///   value of this argument); and
  /// - [pattern] (only accepts if the regular expression defined by the value
  ///   of this argument matches it successfully).
  ///
  /// ```dart
  /// Schema schema = Schema.string();
  /// print(schema.validate(''));         // true
  /// print(schema.validate('abc'));      // true
  /// print(schema.validate('12345'));    // true
  ///
  /// schema = Schema.string(minLength: 2);
  /// print(schema.validate(''));         // false
  /// print(schema.validate('abc'));      // true
  /// print(schema.validate('12345'));    // true
  ///
  /// schema = Schema.string(pattern: r'[0-9]+');
  /// print(schema.validate(''));         // false
  /// print(schema.validate('abc'));      // false
  /// print(schema.validate('123'));      // true
  ///
  /// schema = Schema.string(maxLength: 4);
  /// print(schema.validate(''));           // true
  /// print(schema.validate('abc'));        // true
  /// print(schema.validate('12345'));      // false
  /// ```
  const factory Schema.string({
    int minLength,
    int? maxLength,
    String? pattern,
  }) = _StringSchema;

  /// A special case of [Schema.of] for numbers.
  ///
  /// It accepts any input value of type [num], including [int]s and [double]s.
  /// However, it acceptance depends on the values of
  ///
  /// - [multipleOf] (only accepts if the division by this argument's value
  ///   results in an integer);
  /// - [maximum] (only accepts if the value is less than or exactly equal to
  ///   this argument);
  /// - [exclusiveMaximum] (only accepts if the value is strictly less than this
  ///   argument);
  /// - [minimum] (only accepts if the value is greater than or exactly equal to
  ///   this argument); and
  /// - [exclusiveMinimum] (only accepts if the value is strictly greater than
  ///   this argument).
  const factory Schema.number({
    num? multipleOf,
    num? maximum,
    num? exclusiveMaximum,
    num? minimum,
    num? exclusiveMinimum,
  }) = _NumberSchema;

  /// Accepts any input value that is inside [values].
  ///
  /// ```dart
  /// const Schema schema = Schema.enumeration({'red', 42, 'green'});
  /// print(schema.validate('red'));      // true
  /// print(schema.validate(42));         // true
  /// print(schema.validate('green'));    // true
  /// print(schema.validate('blue'));     // false
  /// ```
  const factory Schema.enumeration(Set<Object> values) = _EnumSchema;

  /// Makes a [schema] accept null.
  ///
  /// ```dart
  /// Schema schema = const Schema.of(int);
  /// print(schema.validate(1));       // true
  /// print(schema.validate(null));    // false
  ///
  /// schema = Schema.optional(schema);
  /// print(schema.validate(1));       // true
  /// print(schema.validate(null));    // true
  /// ```
  ///
  /// If a [schema] is not given, it'll accept any value.
  ///
  /// ```dart
  /// const Schema schema = Schema.optional();
  /// print(schema.validate(null));    // true
  /// print(schema.validate(1));       // true
  /// print(schema.validate('az'));    // true
  /// ```
  const factory Schema.optional([Schema? schema]) = _OptionalSchema;

  /// Accepts any value that is accepted by any of [schemas].
  ///
  /// ```dart
  /// const Schema schema = Schema.union([
  ///   Schema.of(String),
  ///   Schema.of(int),
  /// ]);
  /// print(schema.validate('abc'));    // true
  /// print(schema.validate(123));      // true
  /// print(schema.validate(true));     // false
  /// ```
  const factory Schema.union(List<Schema> schemas) = _UnionSchema;

  /// Accepts any value that is accepted by all of [schemas].
  ///
  /// ```dart
  /// const Schema schema = Schema.intersection([
  ///   Schema.object({'a': Schema.of(int)}),
  ///   Schema.object({'b': Schema.of(double)}),
  /// ]);
  /// print(schema.validate({'a': 1}));               // false
  /// print(schema.validate({'b': 3.14}));            // false
  /// print(schema.validate({'a': 1, 'b': 3.14}));    // true
  /// ```
  const factory Schema.intersection(
    List<Schema> schemas,
  ) = _IntersectionSchema;

  /// Accepts any [Map] whose keys are [String] and their respective values
  /// match the ones associated with their keys on [schemas].
  ///
  /// ```dart
  /// const Schema schema = Schema.object({
  ///   'name': Schema.string(),
  ///   'age': Schema.of(int),
  ///   'height': Schema.of(double),
  ///   'isStudent': Schema.of(bool),
  /// });
  /// const Map<String, Object> input = {
  ///   'name': 'John',
  ///   'age': 30,
  ///   'height': 1.75,
  ///   'isStudent': true,
  /// };
  /// print(schema.validate(input));    // true
  /// ```
  ///
  /// In [strict] mode, it'll reject any extraneous keys on the input [Map]:
  ///
  /// ```dart
  /// const Schema schema = Schema.object({
  ///   'name': Schema.of(String),
  ///   'age': Schema.of(int),
  ///   'height': Schema.of(double),
  ///   'isStudent': Schema.of(bool),
  /// }, strict: true);
  /// const Map<String, Object> input = {
  ///   'name': 'John',
  ///   'age': 30,
  ///   'height': 1.75,
  ///   'isStudent': true,
  ///   'grades': [8, 9, 10],
  /// };
  /// print(schema.validate(input));    // false
  /// ```
  ///
  /// If any value on [schemas] is [Schema.optional] and their respective key
  /// on the input [Map] is missing, it'll be accepted:
  ///
  /// ```dart
  /// const Schema schema = Schema.object({
  ///   'name': Schema.of(String),
  ///   'age': Schema.of(int),
  ///   'height': Schema.of(double),
  ///   'isStudent': Schema.optional(Schema.of(bool)),
  /// });
  /// const Map<String, Object> input = {
  ///   'name': 'John',
  ///   'age': 30,
  ///   'height': 1.75,
  /// };
  /// print(schema.validate(input));    // true
  /// ```
  const factory Schema.object(
    Map<String, Schema> schemas, {
    bool strict,
  }) = _ObjectSchema;

  /// Accepts any [List] whose all elements match [schema].
  ///
  /// ```dart
  /// const Schema schema = Schema.array(Schema.number());
  /// print(schema.validate([]));                          // true
  /// print(schema.validate(['1', '2', '3']));             // false
  /// print(schema.validate([1, 2, 3]));                   // true
  /// print(schema.validate({'a': 1, 'b': 2, 'c': 3}));    // false
  /// ```
  ///
  /// It acceptance depends on the values of
  ///
  /// - [minItems] (only accepts if the list's length is greater than or
  ///   equal to this argument);
  /// - [maxItems] (only accepts if the list's length is less than or
  ///   equal to this argument); and
  /// - [uniqueItems] (only accepts if the elements of the list are unique
  ///   according to their [Object.==] and [Object.hashCode].
  const factory Schema.array(
    Schema schema, {
    int minItems,
    int? maxItems,
    bool uniqueItems,
  }) = _ArraySchema;

  /// Accepts a collection of values accepted by [schema].
  ///
  /// If the instance is a [Map], each value will be evaluated.
  /// If the instance is a [List], each element will be evaluated.
  /// Otherwise, the instance will be rejected.
  ///
  /// ```dart
  /// const Schema schema = Schema.collection(Schema.number());
  /// print(schema.validate([]));                          // true
  /// print(schema.validate(['1', '2', '3']));             // false
  /// print(schema.validate([1, 2, 3]));                   // true
  /// print(schema.validate({'a': 1, 'b': 2, 'c': 3}));    // true
  /// ```
  ///
  /// It acceptance depends on the values of
  ///
  /// - [minItems] (only accepts if the collection's length is greater than or
  ///   equal to this argument);
  /// - [maxItems] (only accepts if the collection's length is less than or
  ///   equal to this argument); and
  /// - [uniqueItems] (only accepts if the elements of the collection are unique
  ///   according to their [Object.==] and [Object.hashCode].
  const factory Schema.collection(
    Schema schema, {
    int minItems,
    int? maxItems,
    bool uniqueItems,
  }) = _CollectionSchema;

  /// Accepts any value that [callback] returns true.
  ///
  /// ```dart
  /// final Schema schema = Schema.custom((value) => value is num);
  /// print(schema.validate(4));       // true
  /// print(schema.validate(3.0));     // true
  /// print(schema.validate('ab'));    // false
  /// ```
  const factory Schema.custom(
    bool Function(Object? value) callback,
  ) = _CustomSchema;

  const Schema._();

  /// Creates a [ObjectNode] containing information about the validation of [value].
  ///
  /// If the returned node has its [ObjectNode.isValid] true, then the whole
  /// instance is accepted. Otherwise, if the returned nod ahs its
  /// [ObjectNode.isValid] false, the instance is rejected and more information
  /// about the rejection can be found on its [ObjectNode.reason] (why?) and its
  /// [ObjectNode.path] (where?) properties.
  ///
  /// If [parent] is not provided, it'll be considered the root node.
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()});

  /// Calculates whether a [value] is accepted or rejected using this schema.
  ///
  /// To know more information about the validation, use [trace].
  bool validate(Object? value) => trace(value).isValid;
}

class _OptionalSchema extends Schema {
  final Schema? schema;

  const _OptionalSchema([this.schema]) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    if (value == null) return parent.validate('value is null');
    final Schema? schema = this.schema;
    if (schema == null) {
      return parent.validate('no wrapped schema was provided on $value');
    }
    return schema.trace(value, parent: parent.child('?'));
  }
}

class _SimpleSchema extends Schema {
  final Type type;

  const _SimpleSchema(this.type) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    final bool result = value.runtimeType == type;
    if (result) return parent.validate('found $type');
    return parent.invalidate('expected $type, found ${value.runtimeType}');
  }
}

class _UnionSchema extends Schema {
  final List<Schema> schemas;

  const _UnionSchema(this.schemas) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    for (Schema schema in schemas) {
      final ObjectNode node = schema.trace(value, parent: parent);
      if (node.isValid) return node;
    }
    return parent
        .invalidate('no schema could be matched: ${schemas.join(', ')}');
  }
}

class _IntersectionSchema extends Schema {
  final List<Schema> schemas;

  const _IntersectionSchema(this.schemas) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    for (Schema schema in schemas) {
      final ObjectNode node = schema.trace(value, parent: parent);
      if (!node.isValid) return node;
    }
    return parent.validate('all schemas matched');
  }
}

class _ObjectSchema extends Schema {
  final Map<String, Schema> schema;
  final bool strict;

  const _ObjectSchema(this.schema, {this.strict = false}) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    if (value is! Map<String, Object?>) {
      return parent.invalidate('not a object: $value');
    }
    if (strict) {
      final Set<String> incomingKeys = Set.of(value.keys);
      final Set<String> baseKeys = Set.of(schema.keys);
      final Set<String> extraneousKeys = incomingKeys.difference(baseKeys);
      if (extraneousKeys.isNotEmpty) {
        return parent
            .invalidate('extraneous keys: ${extraneousKeys.join(', ')}');
      }
    }

    for (MapEntry<String, Schema> entry in schema.entries) {
      final String fieldName = entry.key;
      final Schema expectedType = entry.value;

      final Object? childValue = value[fieldName];
      final ObjectNode node = expectedType.trace(
        childValue,
        parent: parent.child(fieldName),
      );
      if (!node.isValid) return node;
    }
    return parent.validate('all matched');
  }
}

class _CollectionSchema extends Schema {
  final Schema schema;
  final bool uniqueItems;
  final int minItems;
  final int? maxItems;

  const _CollectionSchema(
    this.schema, {
    this.minItems = 0,
    this.maxItems,
    this.uniqueItems = true,
  }) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    final bool uniqueItems = this.uniqueItems;
    final int minItems = this.minItems;
    final int? maxItems = this.maxItems;

    final Map<String, Object?> data;
    if (value is List<Object?>) {
      data = {for (int i = 0; i < value.length; i++) '$i': value[i]};
    } else if (value is Map<Object?, Object?>) {
      data = value.map((key, value) => MapEntry('$key', value));
    } else {
      return parent.invalidate('expected a Map or a List, found $value');
    }

    final int length = data.length;
    if (length < minItems) {
      return parent.invalidate(
          'value is too short (minimum: $minItems, actual: $length)');
    }
    if (maxItems != null && length > maxItems) {
      return parent.invalidate(
          'value is too long (maximum: $maxItems, actual: $length)');
    }
    if (uniqueItems) {
      final int expectedLength = data.values.toSet().length;
      if (length != expectedLength) {
        return parent.invalidate(
            'value is not unique (expected: $expectedLength, actual: $length)');
      }
    }
    for (MapEntry<String, Object?> entry in data.entries) {
      final Object? element = entry.value;
      final ObjectNode node = schema.trace(
        element,
        parent: parent.child(entry.key),
      );
      if (!node.isValid) return node;
    }
    return parent.validate('value $value matched the wrapped schema');
  }
}

class _ArraySchema extends _CollectionSchema {
  const _ArraySchema(
    super.schema, {
    super.minItems,
    super.maxItems,
    super.uniqueItems,
  });

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    if (value is! List<Object?>) return parent.invalidate('not an array');
    return super.trace(value, parent: parent);
  }
}

class _StringSchema extends Schema {
  final int minLength;
  final int? maxLength;
  final String? pattern;

  const _StringSchema({
    this.minLength = 0,
    this.maxLength,
    this.pattern,
  }) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    if (value is! String) return parent.invalidate('not a string: $value');

    final int minLength = this.minLength;
    final int? maxLength = this.maxLength;
    final String? pattern = this.pattern;

    final int length = value.length;
    if (length < minLength) {
      return parent.invalidate('value\'s length is too short '
          '(minimum: $minLength, actual: $length)');
    }
    if (maxLength != null && length > maxLength) {
      return parent.invalidate('value\'s length is too large '
          '(maximum: $minLength, actual: $length)');
    }
    if (pattern != null && !RegExp(pattern).hasMatch(value)) {
      return parent.invalidate('value did not match '
          '(pattern: \'$pattern\', actual: $value)');
    }
    return parent.validate('\'$value\'');
  }
}

class _NumberSchema extends Schema {
  final num? multipleOf;
  final num? maximum;
  final num? exclusiveMaximum;
  final num? minimum;
  final num? exclusiveMinimum;

  const _NumberSchema({
    this.multipleOf,
    this.maximum,
    this.exclusiveMaximum,
    this.minimum,
    this.exclusiveMinimum,
  }) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    if (value is! num) return parent.invalidate('not a number: $value');

    final num? multipleOf = this.multipleOf;
    final num? maximum = this.maximum;
    final num? exclusiveMaximum = this.exclusiveMaximum;
    final num? minimum = this.minimum;
    final num? exclusiveMinimum = this.exclusiveMinimum;
    if (multipleOf != null && value % multipleOf != 0) {
      return parent.invalidate('$value is not divisible by $multipleOf');
    }
    if (maximum != null && value > maximum) {
      return parent.invalidate('$value is greater than $maximum');
    }
    if (exclusiveMaximum != null && value >= exclusiveMaximum) {
      return parent
          .invalidate('$value is greater or equal to $exclusiveMaximum');
    }
    if (minimum != null && value < minimum) {
      return parent.invalidate('$value is lesser than $minimum');
    }
    if (exclusiveMinimum != null && value <= exclusiveMinimum) {
      return parent
          .invalidate('$value is lesser or equal to $exclusiveMinimum');
    }
    return parent.validate('$value is valid');
  }
}

class _EnumSchema extends Schema {
  final Set<Object> values;

  const _EnumSchema(this.values) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    final bool result = values.contains(value);
    final String enumRepr = '[${values.join(', ')}]';
    if (result) return parent.validate('$value is in the enum $enumRepr');
    return parent.invalidate('$value is not in the enum $enumRepr');
  }
}

class _CustomSchema extends Schema {
  final bool Function(Object? value) callback;

  const _CustomSchema(this.callback) : super._();

  @override
  ObjectNode trace(Object? value, {ObjectNode parent = const ObjectNode()}) {
    return callback(value)
        ? parent.validate('callback $callback accepted')
        : parent.invalidate('callback $callback rejected');
  }
}
