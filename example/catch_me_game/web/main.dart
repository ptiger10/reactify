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
      'guess': 1,
      'target': 0,
      'moves': 0,
      'boundary': 20,
    },
    handlers: {
      'increment': (_) =>
          (self) => self.setState('currentNumber', self.getState('guess')),
      'changeGuess': (e) => (self) =>
          self.setState('guess', int.parse((e.target as InputElement).value)),
      'initialize': (_) => (self) {
            self.setState('target', self.getComputed('setTarget'));
            self.setState('moves', 0);
            self.setState('currentNumber', 0);
            self.setState('guess', 1);
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
      ..id = 'loggedIn'
      ..children.addAll([
        self.injectComponent(Title),
        DivElement()
          ..className = 'gameBox'
          ..style.backgroundColor =
              self.getComputed('atTarget') ? 'gold' : 'white'
          ..children.addAll([
            self.injectComponent(guess),
            self.injectComponent(Status),
            self.injectComponent(Reset),
            self.injectComponent(Score),
          ]),
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

final guess = reactify.Component(
    id: 'guess',
    template: (self) => DivElement()
      ..className = 'guess'
      ..children.addAll([
        LabelElement()
          ..htmlFor = 'guessInput'
          ..text = 'Pick a number:',
        InputElement(type: 'range')
          ..min = '-20'
          ..max = '19'
          ..id = 'guessInput'
          ..value = self.getState('guess').toString()
          ..autocomplete = 'off'
          ..onClick.listen((e) => (e.target as InputElement).select())
          ..onInput.listen((e) => self.getHandler('changeGuess', e)),
        // DivElement()
        //   ..className = 'annotation'
        //   ..text = "may be positive or negative",
        ButtonElement()
          ..text = "Set current number to ${self.getState('guess')}"
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
