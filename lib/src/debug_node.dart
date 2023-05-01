/// Represents a node in a JSON tree.
///
/// In the JSON
///
/// ```dart
/// final Map<String, Object> data = {
///   'person': {
///      'name': 'John',
///      'age': 30,
///      'height': 1.75,
///   },
///   'address': {
///     'street': 'Main Street',
///     'number': 123,
///     'city': 'New York'
///   }
/// }
/// ```
///
/// the [ObjectNode] equivalent to `'John'` is
///
/// ```dart
/// final DebugNode node = DebugNode(path: 'person.name');
/// print(node.path);       // 'person.name'
/// print(node.isValid);    // true
/// print(node.reason);     // null
/// ```
///
/// Let's suppose this node must pass through a validation process, where a name
/// must always start with a uppercase letter. You can validate a node by
/// passing a [reason] explaining the result of the validation. For example:
///
/// ```dart
/// final String name = (data['person'] as Map)['name'] as String;
///
/// DebugNode node = DebugNode(path: 'person.name');
/// if (name[0].toUpperCase() == name[0]) {
///   node = node.validate('starts with an uppercase letter');
/// } else {
///   node = node.invalidate('starts with an lowercase letter');
/// }
/// print(node.path);       // 'person.name'
/// print(node.isValid);    // true
/// print(node.reason);     // starts with an uppercase letter
/// ```
class ObjectNode {
  /// Path of this node in the JSON tree.
  ///
  /// If null, this is the root node.
  final String? path;

  /// Whether the value at the JSON [path] is valid or not.
  final bool isValid;

  /// Description of why the JSON is valid or invalid.
  ///
  /// If null, this node was not validated yet. A validated node can be created
  /// by calling [validate] or [invalidate] on any [ObjectNode].
  final String? reason;

  /// Creates a [ObjectNode] from its attributes.
  const ObjectNode({this.path, this.reason, this.isValid = true});

  /// Creates a new [ObjectNode] one [level] deep from this node.
  ///
  /// ```dart
  /// const DebugNode root = DebugNode();
  /// DebugNode node = root.child('person');
  /// print(node.path);    // person
  /// node = node.child('age');
  /// print(node.path);    // person.age
  /// ```
  ObjectNode child(String level) {
    final String? path = this.path;
    return ObjectNode(
      path: [if (path != null) path, level].join('.'),
      reason: reason,
      isValid: isValid,
    );
  }

  /// Creates a [ObjectNode] accepting the current [path] with the given [reason].
  ///
  /// ```dart
  /// const DebugNode root = DebugNode();
  ///
  /// final DebugNode node = root
  ///     .child('person')
  ///     .validate('Person object is valid');
  ///
  /// print(node.path);       // person
  /// print(node.isValid);    // true
  /// print(node.reason);     // Person object is valid
  /// ```
  ObjectNode validate(String reason) {
    return ObjectNode(path: path, isValid: true, reason: reason);
  }

  /// Creates a [ObjectNode] rejecting the current [path] with the given [reason].
  ///
  /// ```dart
  /// const DebugNode root = DebugNode(path: 'person');
  ///
  /// final DebugNode node = root
  ///   .child('age')
  ///   .invalidate('Age must be a positive integer');
  ///
  /// print(node.path);       // person.age
  /// print(node.isValid);    // false
  /// print(node.reason);     // Age must be a positive integer
  /// ```
  ObjectNode invalidate(String reason) {
    return ObjectNode(path: path, isValid: false, reason: reason);
  }

  @override
  String toString() => '$path: $reason';
}
