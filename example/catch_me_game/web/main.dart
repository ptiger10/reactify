import 'package:reactify/reactify.dart' as reactify;
import 'dart:html';
import 'dart:math';

void main() {
  document.getElementById("root").replaceWith(UI.initialize());
}

final UI = reactify.UserInterface(
    components: [Game], globalState: {'loggedIn': false});

final Game = reactify.Component(
    id: 'game',
    template: (self) {
      if (!UI.getGlobal('loggedIn')) {
        return self.injectComponent(LoggedOut);
      } else {
        return self.injectComponent(LoggedIn);
      }
    },
    state: {
      'currentNumber': 0,
      'incrementor': 1,
      'target': 0,
      'moves': 0,
      'boundary': 20,
    },
    handlers: {
      'increment': (_) => (self) => self.setState('currentNumber',
          self.getState('currentNumber') + self.getState('incrementor')),
      'changeIncrementor': (e) => (self) => self.setState(
          'incrementor', int.parse((e.target as InputElement).value)),
      'initialize': (_) => (self) {
            self.setState('target', self.getComputed('setTarget'));
            self.setState('moves', 0);
            self.setState('currentNumber', 0);
            self.setState('incrementor', 1);
          },
      'incrementMoves': (_) =>
          (self) => self.setState('moves', self.getState('moves') + 1),
    },
    computedState: {
      'setTarget': (self) {
        final r = Random(DateTime.now().millisecondsSinceEpoch);
        final boundary = self.getState('boundary');
        final target = r.nextInt(boundary * 2) - boundary;
        if (target == 0) {
          return self.getComputed('setTarget');
        }
        return target;
      },
      'atTarget': (self) =>
          self.getState('target') == self.getState('currentNumber')
    });

final LoggedOut = reactify.Component(
    template: (self) => DivElement()
      ..className = 'title'
      ..children.add(self.injectComponent(Activate)));

final LoggedIn = reactify.Component(
    template: (self) => DivElement()
      ..children.addAll([
        self.injectComponent(Title),
        DivElement()
          ..children.add(DivElement()
            ..className = 'main'
            ..style.backgroundColor =
                self.getComputed('atTarget') ? 'gold' : 'white'
            ..children.addAll([
              self.injectComponent(Incrementor),
              BRElement(),
              self.injectComponent(Status),
              BRElement(),
              self.injectComponent(Reset),
              BRElement(),
              self.injectComponent(Score),
            ])),
        self.injectComponent(Deactivate)
      ]));

final Title = reactify.Component(template: (self) {
  final boundary = self.getState('boundary');
  return DivElement()
    ..className = "title"
    ..text = "Catch Me If You Can!"
    ..children.add(DivElement()
      ..className = 'subtitle'
      ..children.addAll([
        UListElement()
          ..children.addAll([
            LIElement()
              ..text =
                  'I am a number between -${boundary + 1} and $boundary (exclusive)',
            LIElement()
              ..text = 'Starting from 0, find me in as few moves as possible'
          ])
      ]));
});

final Incrementor = reactify.Component(
    template: (self) => DivElement()
      ..children.addAll([
        LabelElement()
          ..htmlFor = 'incrementor'
          ..text = 'Set the rate of change:',
        InputElement(type: 'text')
          ..id = 'incrementor'
          ..autocomplete = 'off'
          ..value = self.getState('incrementor').toString()
          ..onClick.listen((e) => (e.target as InputElement).select())
          ..onBlur.listen((e) => self.getHandler('changeIncrementor', e)),
        DivElement()
          ..className = 'annotation'
          ..text = "may be positive or negative",
        ButtonElement()
          ..text = "Change current number by ${self.getState('incrementor')}"
          ..onClick.listen((_) => self.getHandler('increment', _))
          ..onClick.listen((_) => self.getHandler('incrementMoves', _)),
      ]));

final Status = reactify.Component(
    id: 'status',
    template: (self) => DivElement()
      ..children.addAll([
        DivElement()
          ..id = 'current-number'
          ..text = self.getState('currentNumber').toString(),
        DivElement()
          ..className = 'annotation'
          ..text = "Current Number",
        DivElement()..innerHtml = self.getComputed('over-under')
      ]),
    computedState: {
      'over-under': (self) {
        var currentNumber = self.getState('currentNumber');
        var t = self.getState('target');
        String preposition;
        if (currentNumber > t) {
          preposition = "Above";
        } else if (currentNumber == t) {
          preposition = "You found";
        } else {
          preposition = "Below";
        }
        return '<b>${preposition}</b> the hidden number.';
      }
    });

final Reset = reactify.Component(
    template: (self) => DivElement()
      ..children.addAll([
        ButtonElement()
          ..text = "RESET"
          ..onClick.listen((_) => self.getHandler('initialize', _))
          ..style.display = 'inline',
        DivElement()
          ..className = 'annotation'
          ..text = "re-hide the number & reset moves",
        DivElement()..text = "Total Moves: ${self.getState('moves')}",
      ]));

final Score = reactify.Component(
    id: 'score',
    template: (self) => DivElement()
      ..style.display = self.getComputed('visible') ? 'block' : 'none'
      ..text = self.getComputed('score'),
    computedState: {
      'visible': (self) =>
          self.getState('moves') > 0 && self.getComputed('atTarget'),
      'score': (self) {
        if (self.getState('moves') >= 5) {
          return "Come on - try to catch me in less than 5 moves!";
        } else {
          return 'Nice going!';
        }
      }
    });

final Activate = reactify.Component(
    template: (self) => ButtonElement()
      ..className = 'global'
      ..text = 'Start the game...'
      ..onClick.listen((_) => UI.setGlobal('loggedIn', true))
      ..onClick.listen((_) => self.getHandler('initialize', _)));

final Deactivate = reactify.Component(
    template: (self) => DivElement()
      ..className = 'title'
      ..children.add(ButtonElement()
        ..className = 'global'
        ..text = 'Bored? Stop the game...'
        ..onClick.listen((_) => UI.setGlobal('loggedIn', false))));
