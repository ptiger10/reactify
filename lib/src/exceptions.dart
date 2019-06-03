import 'reactify.dart';

// [START Exceptions]
/// ReactifyException is an abstract base class for custom exceptions
abstract class _ReactifyException implements Exception {
  String message;
  Component component;
  _ReactifyException(this.message, [this.component]);
  String toString() {
    if (component != null) {
      return "${this.runtimeType} with $component\n$message";
    } else {
      return '${this.runtimeType}: $message';
    }
  }
}

/// A KeyException is thrown whenever a missing key has been referenced at runtime, such as in
/// [Component.getState], [Component.setState], [Component.getComputed], or [Component.getHandler].
class KeyException extends _ReactifyException {
  KeyException(String message, [Component component])
      : super(message, component);
}

/// A ValueException is thrown whenever an invalid value has been called,
/// such as initializing a [UserInterface] with no components.
class ValueException extends _ReactifyException {
  ValueException(String message, [Component component])
      : super(message, component);
}
// [END Exceptions]
