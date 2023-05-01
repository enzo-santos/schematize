# Schematize

A Dart object validator, similar to JSON schemas.

## Definitions

### Instance

An *instance* refers to a Dart object, such as numbers, strings, booleans, lists or maps. A number instance can be
represented  as any valid numeric value, such as an `int` or a `double`. A string instance represents a sequence of
characters enclosed in quotes, while a boolean instance can have one of two values - either `true` or `false`. A List is
an ordered collection of values enclosed in square brackets, where each value is an instance in its own. Maps, on the
other hand, are unordered collections of key-value pairs enclosed in curly braces. The keys and the values can be 
instances of any type.

### Schema

A *schema* is a structured representation of the expected format and content of data. A schema defines a set of rules
and constraints that data must conform to in order to be considered valid. It can include various types of rules and
constraints, such as data type, format, minimum and maximum values, required or optional fields, and relationships
between fields. By specifying a schema for data, we can ensure that data conforms to a consistent structure and meets
certain quality standards.

### Schema actions

*To accept* means that the instance being validated conforms to the rules defined by the schema, and therefore, it is
considered valid. In other words, the instance satisfies all the constraints and requirements specified by the schema
and is therefore considered acceptable.

On the other hand, *to reject* means that the instance being validated fails to meet one or more of the rules defined by
the schema, and is therefore considered invalid. In other words, the instance does not conform to the requirements
specified by the schema and is therefore considered unacceptable.

## Implementation

### The basics

The most common thing to do in a schema is to restrict to a specific type. The `SchemaType.of` is used for that:

```dart
void main() {
  // In the following, only strings are accepted
  const SchemaType type = SchemaType.of(String);
  print(type.validate("I'm a string")); // true
  print(type.validate(42)); // false 
  print(type.validate([])); // false 
}
```

To restrict to a subset of types, we can use `SchemaType.union`:

```dart
void main() {
  // In the following, only strings and integers are accepted
  const SchemaType type = SchemaType.union([
    SchemaType.of(String),
    SchemaType.of(int),
  ]);
  print(type.validate("I'm a string")); // true
  print(type.validate(42)); // true
  print(type.validate([])); // false
}
```

### Strings

The length of a string can be constrained using the `minLength` and `maxLength` parameters:

```dart
void main() {
  const SchemaType type = SchemaType.string(minLength: 2, maxLength: 3);
  print(type.validate('A')); // false
  print(type.validate('AB')); // true
  print(type.validate('ABC')); // true
  print(type.validate('ABCD')); // false
}
```

The `pattern` parameter can be used to restrict an instance to a particular regular expression:

```dart
void main() {
  const SchemaType type = SchemaType.string(pattern: r'^(\\([0-9]{3}\\))?[0-9]{3}-[0-9]{4}$');
  print(type.validate('555-1212')); //  false
  print(type.validate('(888)555-1212')); // true
  print(type.validate('(888)555-1212 ext. 532')); // true
  print(type.validate('(800)FLOWERS')); // false
}
```

### Numbers

The `multipleOf` parameter can be used to restrict to a multiple of a given number:

```dart
void main() {
  const SchemaType type = SchemaType.number(multipleOf: 10);
  print(type.validate(0)); //  false
  print(type.validate(10)); // true
  print(type.validate(20)); // true
  print(type.validate(23)); // false
}
```

The `minimum` and `maximum` parameters can be used to specify a range of numbers (or `exclusiveMinimum` and
`exclusiveMaximum` for expressing exclusive range):

```dart
void main() {
  const SchemaType type = SchemaType.number(minimum: 0, exclusiveMaximum: 100);
  print(type.validate(-1)); // false
  print(type.validate(0)); // true
  print(type.validate(10)); // true
  print(type.validate(99)); // true
  print(type.validate(100)); // false
  print(type.validate(101)); // false
}
```

### Maps

To work with maps (an object), we can use `SchemaType.object`:

```dart
void main() {
  const SchemaType type = SchemaType.object({});
  print(type.validate({'key': 'vale', 'anotherKey': 'anotherValue'})); // true
}
```

The properties on an object are defined using the `types` parameter:

```dart
void main() {
  const SchemaType type = SchemaType.object({
    'number': SchemaType.number(),
    'streetName': SchemaType.string(),
    'streetType': SchemaType.enumeration({'Street', 'Avenue', 'Boulevard'}),
  });
  print(type.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
  print(type.validate({
    'number': '1600', // false (providing the wrong type)
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  }));
  print(type.validate({
    'number': 1600,
    'streetName': 'Pennsylvania', // false (by default, leaving out properties)
  }));
  print(type.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
    'direction': 'NW', // true (by default, providing additional properties)
  }));
}
```

To reject additional properties, use the `strict` parameter:

```dart
void main() {
  const SchemaType type = SchemaType.object({
    'number': SchemaType.number(),
    'streetName': SchemaType.string(),
    'streetType': SchemaType.enumeration({'Street', 'Avenue', 'Boulevard'}),
  }, strict: true);
  print(type.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
  print(type.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
  })); // false
  print(type.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
    'direction': 'NW', // false (providing additional properties on strict mode)
  }));
}
```

To make some properties optional, use the `SchemaType.optional` constructor:

```dart
void main() {
  const SchemaType type = SchemaType.object({
    'number': SchemaType.optional(SchemaType.number()), // Number may be passed
    'streetName': SchemaType.string(),
    'streetType': SchemaType.enumeration({'Street', 'Avenue', 'Boulevard'}),
  });
  print(type.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
  print(type.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
  })); // false
  print(type.validate({
    'number': null,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
  print(type.validate({
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
}
```
