import 'dart:html';
import 'package:reactify/reactify.dart' as reactify;

void main() {
  document.getElementById("root").replaceWith(UI.initialize());
}

final UI = reactify.UserInterface(components: [Root]);

final Root = reactify.Component(
    id: 'root',
    template: (self) => DivElement()
      ..style.textAlign = 'center'
      ..style.paddingTop = '100px'
      ..style.display = 'flex'
      ..style.justifyContent = 'center'
      ..children.add(DivElement()
        ..style.border = '1px solid black'
        ..children.addAll([
          DivElement()
            ..text = 'Root count: ${self.getState('count')}'
            ..style.fontWeight = 'bold',
          self.injectComponent(Child)
        ])),
    state: {
      'count': 0
    },
    handlers: {
      'incrementCount': (_) =>
          (self) => self.setState('count', self.getState('count') + 1),
      'resetCount': (_) => (self) => self.setState('count', 0)
    });

final Child = reactify.Component(
    id: 'child',
    template: (self) => DivElement()
      ..style.border = '1px dashed black'
      ..style.margin = '10px'
      ..style.padding = '10px'
      ..children.addAll([
        DivElement()
          ..text = 'Child count (=root*2): ${self.getComputed('computed')}',
        ButtonElement()
          ..text = '+1 to root count'
          ..onClick.listen((_) => self.getHandler('incrementCount', _)),
        ButtonElement()
          ..text = 'reset'
          ..onClick.listen((_) => self.getHandler('resetCount', _)),
      ]),
    computedState: {'computed': (self) => self.getState('count') * 2});
