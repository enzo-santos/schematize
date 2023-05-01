# Schematize

A Dart object validator, similar to JSON schemas.

## Disclaimer

While Schematize's syntax and behavior are inspired by JSON Schema, it is important to note that this library
is *not* a JSON Schema implementation. For this purpose, you can use the following libraries:

- [`json_schema_document`](https://pub.dev/packages/json_schema_document)
- [`json_schema`](https://pub.dev/packages/json_schema)
- [`json_schema2`](https://pub.dev/packages/json_schema2)
- [`json_schema3`](https://pub.dev/packages/json_schema3)
- [`flutter_json_schema_form`](https://pub.dev/packages/flutter_json_schema_form)

Schematize is designed specifically for use with Dart, and leverages Dart's static-typing and strong type system to
provide *compile-time validation* of the schema and *run-time validation* of the instance.

## Motivation

Schematize is a flexible Dart library designed to help developers validate and manipulate complex Dart objects with
ease. Whether you're working on a small or large project, ensuring that your data adheres to certain standards and
expectations is crucial for maintaining its quality and preventing errors. This library simplifies this process by
providing a flexible and easy-to-use tool for defining and validating Dart objects based on a set of rules and
constraints.

Schematize is inspired by JSON schemas, which have become a popular way to describe and validate JSON data structures.
End-users of this library can define and validate Dart objects using a similar approach, making it easier to maintain
consistent data structures across an entire project. It provides a variety of validation methods, including type
validation, range checking, pattern matching, and more, enabling developers to validate their objects against a wide
range of rules and criteria.

In this section, we will explore the motivation behind Schematize and why it is a valuable tool. We will look at the
challenges that developers face when working with complex Dart objects and how Schematize can help address these
challenges. Additionally, we will discuss some key features and benefits of Schematize, highlighting why it is a great
choice for any developer looking to simplify their object validation process.

### Definitions

Schematize works based on three key concepts: instances, schemas and validations.

#### Instance

An *instance* refers to any Dart object:

```dart

const Object? instance = 'abc';
```

#### Schema

A *schema* is a Dart object that can be created using the `Schema` class, exported by this library:

```dart

const Schema schema = Schema.string(minLength: 1, maxLength: 5);
```

It is a structured representation of the expected format and content of a given instance. A schema defines a set of
rules and constraints that an *instance* must conform to in order to be considered valid. It can include various types
of rules and constraints, such as data type, format, minimum and maximum values, required or optional fields, and
relationships between fields. By specifying a schema for an *instance*, we can ensure that this *instance* conforms to a
consistent structure and meets certain standards.

#### Validation

A *validation* is a *schema* accepting or rejecting a given *instance*, via the `validate` method of `Schema`:

```
final bool accepted = schema.validate(instance);
```

*To accept* means that the instance being validated conforms to the rules defined by the schema, and therefore, it is
considered valid. In other words, the instance satisfies all the constraints and requirements specified by the schema
and is therefore considered acceptable.

On the other hand, *to reject* means that the instance being validated fails to meet one or more of the rules defined by
the schema, and is therefore considered invalid. In other words, the instance does not conform to the requirements
specified by the schema and is therefore considered unacceptable.

### Use cases

With Schematize, developers can define a schema that describes the expected structure and validation rules for the form
data. This schema can then be used to validate the user's input, ensuring that it conforms to the expected format and
meets any relevant validation rules. By using this library in this way, developers can simplify the process of object
validation and reduce the risk of errors or inconsistencies in the data.

#### API validation

You can also use Schematize in the validation of JSON documents, such as those returned by an API:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:schematize/schematize.dart';

void main() async {
  const Schema schema = Schema.object({
    'id': Schema.of(int),
    'name': Schema.string(minLength: 2, maxLength: 50),
    'email': Schema.string(pattern: r'^[a-zA-Z0-9]@[a-z].[a-z]$'),
  });

  final http.Response response = await http.get(Uri.parse('https://example.com/api/data'));
  final Object? data = jsonDecode(response.body);
  if (schema.validate(data)) {
    print('JSON data is valid!');
  } else {
    print('JSON data is invalid!');
  }
}

```

#### Application configuration files validation

Another use case for Schematize is in the validation of application configuration files:

```dart
import 'dart:io';
import 'package:yaml/yaml.dart' as yaml;
import 'package:schematize/schematize.dart';

Future<Object?> loadConfig(String filename) async {
  final File file = File(filename);
  if (!await file.exists()) {
    throw Exception('Config file not found: $filename');
  }
  final String contents = await file.readAsString();
  final Object? config = yaml.loadYaml(contents);
  return config;
}

void main() async {
  const Schema schema = Schema.object({
    'host': Schema.of(String),
    'port': Schema.of(int),
    'database': Schema.object({
      'name': Schema.optional(Schema.of(String)),
      'user': Schema.of(String),
      'password': Schema.of(String),
    }),
  });

  final Object? config = await loadConfig('config.yaml');
  if (schema.validate(config)) {
    print('Config is valid!');
  } else {
    print('Config is invalid!');
  }
}
```

#### Form validation

One common use case for Schematize is in form validation, especially in frameworks such as `flutter_form_bloc`:

```dart
import 'package:flutter_form_bloc/flutter_form_bloc.dart' as ffb;
import 'package:schematize/schematize.dart';

class MyFormBloc extends ffb.FormBloc<String, String> {
  final Schema _schema = const Schema.object({
    'name': Schema.string(minLength: 2, maxLength: 50),
    'email': Schema.string(pattern: r'^[a-zA-Z0-9]@[a-z].[a-z]$'),
    'age': Schema.optional(Schema.number(minimum: 18, maximum: 99)),
  });

  final ffb.TextFieldBloc<void> name = ffb.TextFieldBloc(name: 'name');
  final ffb.TextFieldBloc<void> email = ffb.TextFieldBloc(name: 'email');
  final ffb.InputFieldBloc<int?, void> age = ffb.IntFieldBloc(name: 'age');

  MyFormBloc() {
    addFieldBlocs(fieldBlocs: [name, email, age]);
  }

  @override
  void onSubmitting() async {
    final ObjectNode node = _schema.trace(state.toJson());
    if (node.isValid) {
      emitSuccess();
    } else {
      emitFailure(failureResponse: node.reason);
    }
  }
}
```

## Usage

### Installing

Run the following commands on your command prompt:

```shell
dart pub add 'schematize{"git":"https://github.com/enzo-santos/schematize.git"}'
dart pub get
```

Now import the following in your Dart code:

```dart
import 'package:schematize/schematize.dart';
```

### The basics

The most common thing to do in a schema is to restrict to a specific type. The `Schema.of` is used for that:

```dart
void main() {
  // In the following, only strings are accepted
  const Schema schema = Schema.of(String);
  print(schema.validate("I'm a string")); // true
  print(schema.validate(42)); // false 
  print(schema.validate([])); // false 
}
```

To restrict to a subset of types, we can use `Schema.union`:

```dart
void main() {
  // In the following, only strings and integers are accepted
  const Schema schema = Schema.union([
    Schema.of(String),
    Schema.of(int),
  ]);
  print(schema.validate("I'm a string")); // true
  print(schema.validate(42)); // true
  print(schema.validate([])); // false
}
```

### Strings

You can use `Schema.string` for restricting a string instance more accurately.

The length of a string can be constrained using the `minLength` and `maxLength` parameters:

```dart
void main() {
  const Schema schema = Schema.string(minLength: 2, maxLength: 3);
  print(schema.validate('A')); // false
  print(schema.validate('AB')); // true
  print(schema.validate('ABC')); // true
  print(schema.validate('ABCD')); // false
}
```

The `pattern` parameter can be used to restrict an instance to a particular regular expression:

```dart
void main() {
  const Schema schema = Schema.string(pattern: r'^(\\([0-9]{3}\\))?[0-9]{3}-[0-9]{4}$');
  print(schema.validate('555-1212')); //  false
  print(schema.validate('(888)555-1212')); // true
  print(schema.validate('(888)555-1212 ext. 532')); // true
  print(schema.validate('(800)FLOWERS')); // false
}
```

### Numbers

You can use `Schema.number` for restricting a number instance more accurately.

The `multipleOf` parameter can be used to restrict to a multiple of a given number:

```dart
void main() {
  const Schema schema = Schema.number(multipleOf: 10);
  print(schema.validate(0)); //  false
  print(schema.validate(10)); // true
  print(schema.validate(20)); // true
  print(schema.validate(23)); // false
}
```

The `minimum` and `maximum` parameters can be used to specify a range of numbers (or `exclusiveMinimum` and
`exclusiveMaximum` for expressing exclusive range):

```dart
void main() {
  const Schema schema = Schema.number(minimum: 0, exclusiveMaximum: 100);
  print(schema.validate(-1)); // false
  print(schema.validate(0)); // true
  print(schema.validate(10)); // true
  print(schema.validate(99)); // true
  print(schema.validate(100)); // false
  print(schema.validate(101)); // false
}
```

### Lists

To work with lists (or arrays), we can use `Schema.array`:

```dart
void main() {
  const Schema schema = Schema.array([Schema.of(int)]);
  print(schema.validate([1, 2, 3])); // true
  print(schema.validate(['1', '2', '3'])); // false
}
```

### Maps

To work with maps (or objects), we can use `Schema.object`:

```dart
void main() {
  const Schema schema = Schema.object({});
  print(schema.validate({'key': 'value', 'anotherKey': 'anotherValue'})); // true
}
```

The properties on an object are defined using the `schemas` parameter:

```dart
void main() {
  const Schema schema = Schema.object({
    'number': Schema.number(),
    'streetName': Schema.string(),
    'streetType': Schema.enumeration({'Street', 'Avenue', 'Boulevard'}),
  });
  print(schema.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
  print(schema.validate({
    'number': '1600', // false (providing the wrong type)
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  }));
  print(schema.validate({
    'number': 1600,
    'streetName': 'Pennsylvania', // false (by default, leaving out properties)
  }));
  print(schema.validate({
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
  const Schema schema = Schema.object({
    'number': Schema.number(),
    'streetName': Schema.string(),
    'streetType': Schema.enumeration({'Street', 'Avenue', 'Boulevard'}),
  }, strict: true);
  print(schema.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
  print(schema.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
  })); // false
  print(schema.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
    'direction': 'NW', // false (providing additional properties on strict mode)
  }));
}
```

To make some properties optional, use the `Schema.optional` constructor:

```dart
void main() {
  const Schema schema = Schema.object({
    'number': Schema.optional(Schema.number()), // Number may be passed
    'streetName': Schema.string(),
    'streetType': Schema.enumeration({'Street', 'Avenue', 'Boulevard'}),
  });
  print(schema.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
  print(schema.validate({
    'number': 1600,
    'streetName': 'Pennsylvania',
  })); // false
  print(schema.validate({
    'number': null,
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
  print(schema.validate({
    'streetName': 'Pennsylvania',
    'streetType': 'Avenue',
  })); // true
}
```
