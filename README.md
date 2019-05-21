# reactify
[![Pub](https://img.shields.io/pub/v/reactify.svg)](https://pub.dev/packages/reactify)
[![Docs](https://img.shields.io/badge/docs-reactify-blue.svg)](https://pub.dev/documentation/reactify/)
[![Build Status](https://travis-ci.com/ptiger10/reactify.svg?branch=master)](https://travis-ci.com/ptiger10/reactify)


Reactive user interface components in pure Dart

## Philosophy
Typed, tested, and tiny. 

 No framework, minimal dependencies, just two straightforward classes: [UserInterface][] and [Component][]. Harness Dart 2's powerful built-in `dart:html` library while utilizing reactive best practices:


- Everything is a Component, which renders as one or more vanilla HTML elements
- Instead of hard-coding values into components, read values from a "state" property
- State is passed downwards from root components to sub-components, never upwards
- Sub-components may be supplied with event listeners that emit state changes back upwards when they are triggered
- Anytime state is changed, re-render only the affected root component instead of reloading the whole page

Write in Dart, transpile to Javascript, then use in HTML just like you'd expect.

## Basic Usage
If you are unfamiliar with how Dart implements HTML elements and DOM manipulation with `dart:html`, you may want to reference the excellent official tutorial [here](https://dart.dev/tutorials/web/low-level-html/connect-dart-html).

Start with an HTML file with a script tag and a hookable element.
```
index.html

<!DOCTYPE html>
<head>
  <script type="text/javascript" defer src="main.dart.js"></script>
</head>
<body>
  <div id="root"></div>
</body>
```

Declare a [UserInterface][] with at least one [Component][] and insert it into the HTML.
```
main.dart

void main() {
  document.getElementById("root").replaceWith(ExampleUI.initialize());
}

final ExampleUI = reactify.UserInterface(components: [ExampleComponent]);

final ExampleComponent = reactify.Component(
    id: 'sample',
    template: (self) => DivElement()..text = self.getState('static'),
    state: {'static': 'This is a sample Component'});
```  

## Demystifying the callback properties
Reactive web development uses callback functions extensively, and you will find them in three Component properties. Because they are callbacks, they allow you to define interactions with a component's other properties, such as its `state`, *before* the component has been constructed.

### template
Every Component should have a `template`. This is a single callback function that gets rendered as an HTML element whenever 1) a [UserInterface][] containing the [Component][] is initialized, or 2) the Component's root state is changed at any point following initialization. The simplest template is `template: (_) => DivElement()`, which renders as `<div></div>`. 

The callback function accepts one argument, which is a reference to that component itself.  

While you may name it however you like, a helpful convention is to name this argument `_` if you do not need to acces it, and `self` if you do, as in: `template: (self) => DivElement()..text = self.getState('example')`.

### computedState
`computedState` is a map of callback functions that each return a dynamic value. As with template, each callback function accepts one argument, which is a reference to that component itself. These are useful for deriving a value from existing state values or external values.

### handlers
`handlers` is a map of handlers. Each `handler` is actually two callback functions chained together: an event listener (callback function #1), which returns a callback containing the component itself (callback function #2), which may trigger side effects but should return nothing. A helpful convention is to name the Event argument `_` if you do not need to access it, and `e` if you do, as in: `handlers: {'exampleHandler': (e) => (self) => self.setState('example', (e.target as InputElement).value)}`. This can then be called by a sub-component, as in: `InputElement()..onChange.listen((e) => self.getHandler('exampleHandler', e))`.


## Advanced Usage

Use `computedState` and `getComputed` if a value must be calculated.
```
final ExampleComponent = reactify.Component(
    id: 'sample',
    template: (self) => DivElement()..text = self.getComputed('computed'),
    computedState: {
      'computed': (_) {
        var calculation = 1 + 1;
        return 'This is a sample Component that equals $calculation';
      }
    });
```

Use `self.injectComponent(subComponent)` to insert a sub-component into a root component. 
```
final ExampleComponent = reactify.Component(
    id: 'sample',
    template: (self) => self.injectComponent(SubComponent),
    state: {'root': 'This state has been passed through to a sub-component!'});

final SubComponent = reactify.Component(
    template: (self) => DivElement()..text = self.getState('root'));
```

Use `handlers` and `getHandler` so that the sub-component can trigger changes to root state.
```
final ExampleComponent = reactify.Component(
    id: 'sample',
    template: (self) =>
        DivElement()..children.add(self.injectComponent(SubComponent)),
    state: {
      'count': 0
    },
    computedState: {
      'computed': (self) {
        var calculation = self.getState('count') + 1;
        return 'This is a computed state that equals $calculation and is updated by a handler callback on a sub-component';
      }
    },
    handlers: {
      'increment': (_) =>
          (self) => self.setState('count', self.getState('count') + 10)
    });

final SubComponent = reactify.Component(
  id: 'sub',
    template: (self) => DivElement()
      ..text = self.getComputed('computed')
      ..children.add(ButtonElement()
        ..text = "+10"
        ..onClick.listen((_) => self.getHandler('increment', _))));
```

For other snippets, see the [Dart UI cookbook](example/dart_ui_cookbook.md)


## Transpiling to Javascript
Dart is not supported by browsers natively, so must be converted to Javascript first. Two command line options for this:
- Option 1: `$ dart2js` ([docs](https://dart.dev/tools/dart2js)). If you prefer this route for development, I still recommend auto-transpiling on save.*
- Option 2:  `$ webdev serve` ([docs](https://dart.dev/tools/webdev#serve)) - enables faster load times, auto-transpiling, and page refreshing on save. Recommended for development, but be aware of the gotchas**. Notable requirements:
    -  Working directory must contain a `pubspec.yaml` file and a `/web` directory
    - `/web` must contain a file called `index.html` which serves as entrypoint for the server
    - `pubspec.yaml` must specify `build_runner` and `build_web_compilers` as dev_dependencies


*To customize on-save behavior in VSCode, you need a `build task` and a custom `Keyboard Shortcut`. A simple build task could be:
```
  "tasks": [
        {
            "label": "Run dart2js",
            "type": "shell",
            "command": "dart2js",

            "problemMatcher": [
                "$eslint-stylish"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "runOptions": {
                "runOn": "default"
            }
```
and a keyboard shortcut could be:
```
    {
        "key": "cmd+s",
        "command": "workbench.action.tasks.build",
        "when": "editorTextFocus && editorLangId == 'dart'"
    }
```

**Gotchas of `webdev serve`: if `/web` contains a `xxx.dart` file, by default it will be transpiled and saved as `xxx.dart.js` within a hidden output folder. The output folder can be changed, but it cannot be merged with your current working directory. Plus, the file naming convention cannot be changed. 

By contrast, `dart2js` saves the .js file within the current working directory, and the file naming convention can be changed with a flag. Thus, if you want to serve `index.html` yourself or load it manually in a browser, you can first run `dart2js` to create the `.js` file in the current directory.

 [UserInterface]: https://pub.dartlang.org/documentation/reactify/latest/reactify/UserInterface-class.html
 [Component]: https://pub.dartlang.org/documentation/reactify/latest/reactify/Component-class.html