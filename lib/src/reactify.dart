import 'dart:html';

// [START UserInterface]
/// A UserInterface is a list of root [Component]s and a `globalState` Map. There should be only one UserInterface per program.
///
/// Upon initialization, it renders every root [Component] as an HTML Element.
///
/// Use the `globalState` Map to track UI properties that affect every [Component]. Common examples: `loggedIn`, `userRole`, `nightMode`.
class UserInterface {
  List<Component> components;
  Map<String, dynamic> globalState;
  bool _initialized;

  UserInterface({List<Component> components, Map<String, dynamic> globalState}) {
   this.components = components;
   this.globalState = globalState;
   _initialized = false;
  }

  /// initialize renders every root [Component] in the [UserInterface].
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

  /// getGlobal gets a property on the UserInterface object.
  /// If globalState has not been initialized or key does not exist, throws an exception.
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

  /// setGlobal sets a property on the UserInterface object then re-renders every Component.
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

  /// refreshAll re-renders every component registered in the UserInterface.
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
/// A Component is a building block of a UserInterface. Every Component should have a template that renders a vanilla Dart HTML element.
/// 
/// A Component with a null `root` property is considered a "root component" and may have independent `state`, `computedState`, and `handlers`.
/// Components with a non-null `root` are considered "sub-components." They receive `state`, `computedState` and `handlers` that from their root parent.
/// Whenever a sub-component calls `.setState()`, it is actually setting the state of its root component.
/// Sub-components may retain their own `computedState` values, as long as they are differently named from their root.
class Component {
  String id;

  /// A template is a callback function that returns a standard Dart HTML Element when called by `Component.render()`.
  Element Function(Component) template;

  /// The state Map identifies state values, which are any values that can be referenced or updated directly.
  ///
  /// Get a state value with `Component.getState("key")` and set one with `Component.setState("key", newValue)`.
  Map<String, dynamic> state;

  /// The computedState Map identifies callback functions that can reference the root Component, including its state.
  ///
  /// A computed callback is called by `Component.getComputed("...")`. Computed callback functions cannot be updated directly.
  Map<String, dynamic Function(Component)> computedState;

  /// A handler is an event listener that returns a callback function.
  ///
  /// A handler should be called in tandem with an event listener like so: `.listen((e) => self.getHandler('key', e)) `
  Map<String, void Function(Component) Function(Event)> handlers;
  Component _root;


  Component(
      {this.id,
      this.template,
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

  /// refresh re-renders a root Component and replaces it in HTML using a DOM selector.
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

  /// getState fetches a state value on a root component.
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

  /// setState changes a state value on a root component and then re-renders from the root.
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

  /// getComputed calculates a component value.
  ///
  /// Useful for making a composite value from existing state values or external values.
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

  /// getHandler returns a handler function and inserts an event into it.
  ///
  /// Useful for triggering a state change on a root component from a sub-component.
  ///
  /// It should only be used as the return value in an event listener callback function.
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
  /// First injects the current component's state, computedState, and handlers,
  /// and then renders the sub-component's template as an Element.
  /// If the instance component has no root, then it will serve as the root for all sub-components.
  /// The root will overwrite all sub-component states and handlers, but the sub-component may define its own computed states.


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
abstract class ReactifyException implements Exception {
  String message;
  Component component;
  ReactifyException(this.message, [this.component]);
  String toString() {
    if (component != null) {
      return "${this.runtimeType} with $component\n$message";
    } else {
      return '${this.runtimeType}: $message';
    }
  }
}

class KeyException extends ReactifyException {
  KeyException(String message, [Component component])
      : super(message, component);
}

class ValueException extends ReactifyException {
  ValueException(String message, [Component component])
      : super(message, component);
}
// [END Exceptions]