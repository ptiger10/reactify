import 'dart:html';
import 'package:meta/meta.dart';

// [START UserInterface]
/// A UserInterface is a List of root [Component]s and optional `globalState`.
///
/// Upon initialization, every [Component] is rendered as an HTML Element.
class UserInterface {
  /// The components List includes every root [Component] that will be rendered in the UI.
  List<Component> components;
  /// The globalState Map identifies UI-level properties that can affect every [Component]. Common keys: `loggedIn`, `userRole`, `nightMode`.
  Map<String, dynamic> globalState;
  bool _initialized;

  /// Creates a new UserInterface with optional `globalState`. 
  UserInterface({@required List<Component> components, Map<String, dynamic> globalState}) {
   this.components = components;
   this.globalState = globalState;
   _initialized = false;
  }

  /// initialize renders every root [Component] in the [UserInterface] for the first time.
  /// The results can easily be inserted into an HTML document: `document.getElementById("...").replaceWith(UI.initialize());`
  Element initialize() {
    if (components == null) {
      throw ValueException(
          'initialize() failed: UserInterface cannot be initialized without components');
    }
    _initialized = true;
    var root = DivElement()..id = 'root';
    for (final component in components) {
      root.children.add(component.render());
    }
    return root;
  }

  /// getGlobal gets a property from the [globalState] Map.
  /// If `globalState` is null or key does not exist, throws an exception.
  dynamic getGlobal(String key) {
    if (globalState == null) {
      throw ValueException(
          'getGlobal() failed: unable to get global state value: no globalState was initialized');
    }
    if (!globalState.containsKey(key)) {
      throw KeyException(
          'getGlobal() failed: unable to get global state value: $key not in globalState ${globalState.keys}');
    }
    return globalState[key];
  }

  /// setGlobal sets a property on the in the [globalState] Map, then re-renders every [Component] in the UI.
/// If `globalState` is null or key does not exist, throws an exception.
  void setGlobal(String key, dynamic value) {
    if (globalState == null) {
      throw ValueException(
          'setGlobal() failed: unable to set global state value: no globalState was initialized');
    }
    if (!globalState.containsKey(key)) {
      throw KeyException(
          'setGlobal() failed: unable to set global state value: $key not in globalState ${globalState.keys}');
    }
    globalState[key] = value;

      _refreshAll();

    return;
  }

  /// _refreshAll re-renders every component registered in the UserInterface.
  void _refreshAll() {
    if (components == null) {
      throw ValueException(
          'refreshAll() failed: components cannot be refreshed, since none have been added to the UserInterface');
    }
    if (!_initialized) {
      throw ValueException('refreshAll() failed: UserInterface has not been initialized');
    }
    for (var i = 0; i < components.length; i++) {
      components[i]._refresh();
    }
  }
}
// [END UserInterface]

// [START Component]
/// A Component is a building block of a [UserInterface]. Every Component should have a template that renders a vanilla Dart HTML element.
/// 
/// There are two types of Components: 
/// 
/// "root components" are standalone components that may be registered in a [UserInterface]. 
/// They have independent [state], [computedState], and [handlers].
/// They are not injected into other components.
/// 
/// "sub-components" are child components that are injected into either a root component or another sub-component with a root. 
/// They receive a copy of the root's `state`, `computedState` and `handlers`.
/// Whenever a sub-component calls [Component.setState], it is actually setting the `state` of its root component.
/// Sub-components may retain their own `computedState` values, as long as they are uniquely keyed from the root component.
class Component {
  /// An id that will be prepended with `component-` and added to the element in the DOM. `id: 'counter'` -> `<id=component-counter>`
  String id;

  /// A template is a callback function that returns a standard Dart HTML Element when called by [Component.render].
  Element Function(Component) template;

  /// The state Map identifies `state` values, which are any values that can be referenced or updated directly.
  ///
  /// Get a state value with [Component.getState] and set one with [Component.setState].
  Map<String, dynamic> state;

  /// The computedState Map identifies callback functions that can perform computations or access other [Component] properties, including `state`.
  ///
  /// A computed callback is called by [Component.getComputed]. Computed callback functions cannot be updated directly.
  Map<String, dynamic Function(Component)> computedState;

  /// A handler is an event listener that returns a callback function. Example: `key: (e) => (self) => self.setState('...', ...)`
  /// 
  /// A handler should be passed into a sub-component's event listener, like so: `onClick.listen((e) => self.getHandler('key', e))`
  Map<String, void Function(Component) Function(Event)> handlers;
  Component _root;

  /// Creates a new Component with a required [template]. 
  Component(
      {@required this.template,
      this.id,
      this.state,
      this.computedState,
      this.handlers});

  @override
  String toString() {
    return "Component(id: $id, root: $_root)";
  }

  /// render converts a Component's template into an HTML Element by calling the template's callback function.
  ///
  /// If a non-null id was supplied to the Component constructor, it is prepended with `component-` and set as the Element id in HTML.
  Element render() {
    if (template == null) {
      throw ValueException('render() failed: `template` must be defined', this);
    }
    var elem = template(this);
    if (elem == null) {
      throw ValueException(
          'render() failed: no return value for `template`.'
          'If it does not use the `() =>` syntax, it must have the `return` keyword',
          this);
    }
    if (id != null) {
      elem.id = "component-$id";
    }
    return elem;
  }

  /// _refresh re-renders a root Component and replaces it in HTML using a DOM selector.
  ///
  /// If a Component does not have a root, then it is considered a root itself.
  /// A root Component must have an id that is set during construction.
  /// If a root Component id has been changed outside the constructor function, this will likely throw an exception.
  void _refresh() {
    String selector;
    Element replacement;
    if (_root != null) {
      selector = "component-${_root.id}";
      replacement = _root.render();
    } else {
      selector = "component-$id";
      replacement = render();
    }

    var el = document.getElementById(selector);
    if (el == null) {
      throw ValueException(
          'refresh() failed: invalid id tag: "#$selector"', this);
    }
    el.replaceWith(replacement);
    return;
  }

  /// getState fetches a [state] value on a root component.
  /// If key does not exist in the root state, this throws an exception.
  dynamic getState(String key) {
    if (state == null) {
      throw ValueException('getState() failed: state cannot be null', this);
    }
    if (!state.containsKey(key)) {
      throw KeyException(
          'getState() failed: "$key" not in state ${state.keys}', this);
    }
    return state[key];
  }

  /// setState changes a [state] value on a root component and then re-renders from the root.
  /// If key does not exist in the root state, this throws an exception.
  void setState(String key, dynamic value) {
    if (state == null) {
      throw ValueException('setState() failed: state cannot be null', this);
    }
    if (!state.containsKey(key)) {
      throw KeyException(
          'setState() failed: "$key" not in state ${state.keys}', this);
    }
    state[key] = value;

    _refresh();
  }

  /// getComputed fetches a computed value from [computedState].
  ///
  /// Useful for deriving a value from existing [state] values or external values.
  dynamic getComputed(String key) {
    if (computedState == null) {
      throw ValueException(
          'getComputed() failed: computedState cannot be null', this);
    }
    if (!computedState.containsKey(key)) {
      throw KeyException(
          '"getComputed() failed: $key" not in computedState ${computedState.keys}',
          this);
    }
    final cb = computedState[key](this);
    if (cb == null) {
      throw ValueException(
          'getComputed() failed: no return value for computedState callback "$key".\n'
          'If it does not use the `() =>` syntax, it must have the `return` keyword\n',
          this);
    }
    return cb;
  }

  /// getHandler fetches a handler function from [handlers] and supplies an event into it.
  ///
  /// Useful for triggering a state change on a root component from a sub-component.
  ///
  /// A handler should be used as the return value in an event listener callback function.
  /// Example: `..onClick.listen((e) => self.getHandler('...', e))`
  void getHandler(String key, Event e) {
    if (handlers == null) {
      throw ValueException(
          'getHandler() failed: handlers cannot be null', this);
    }
    if (!handlers.containsKey(key)) {
      throw KeyException(
          'getHanlder() failed: "$key" not in handlers ${handlers.keys}', this);
    }
    return handlers[key](e)(this);
  }

  /// injectComponent adds a sub-component to the current component. 
  /// Useful for giving a sub-component access to root component properties.
  ///
  /// First injects the current component's [state], [computedState], and [handlers],
  /// and then renders the sub-component's template as an HTML Element.
  /// If the calling component is a root component, then the injected component and all its children will have it as their root.
  /// The root will overwrite all sub-component states and handlers, but the sub-component may maintain unique computedState keys.


  Element injectComponent(Component component) {
    if (computedState == null) {
      computedState = {};
    }
    if (component.computedState == null) {
      component.computedState = {};
    }
    for (final key in computedState.keys) {
      component.computedState[key] = computedState[key];
    }

    component.state = state;
    component.handlers = handlers;

    if (_root == null) {
      component._root = this;
    } else {
      component._root = _root;
    }
    return component.render();
  }
}
// [END Component]

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