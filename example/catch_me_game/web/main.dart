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
          },
      'incrementMoves': (_) =>
          (self) => self.setState('moves', self.getState('moves') + 1),
    },
    computedState: {
      'setTarget': (self) {
        final r = Random(DateTime.now().millisecondsSinceEpoch);
        final boundary = self.getState('boundary');
        return r.nextInt(boundary * 2) - boundary;
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
              self.injectComponent(Message),
              self.injectComponent(Reset),
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
        DivElement()
          ..text =
              'A number is hidden between -${boundary + 1} and $boundary (exclusive).',
        DivElement()
          ..text =
              'You start at 0. To change your number, first specify the rate of change.',
        DivElement()..text = 'Find it in as few moves as possible.'
      ]));
});

final Incrementor = reactify.Component(
    template: (self) => DivElement()
      ..children.addAll([
        LabelElement()
          ..htmlFor = 'incrementor'
          ..text = 'Set the rate of change:'
          ..style.paddingRight = '5px',
        InputElement(type: 'text')
          ..id = 'incrementor'
          ..autocomplete = 'off'
          ..value = self.getState('incrementor').toString()
          ..onClick.listen((e) => (e.target as InputElement).select())
          ..onBlur.listen((e) => self.getHandler('changeIncrementor', e)),
        DivElement()
          ..className = 'annotation'
          ..text = "- may be positive or negative"
          ..style.display = 'inline',
        ButtonElement()
          ..text =
              "Click here to change current number by ${self.getState('incrementor')}"
          ..onClick.listen((_) => self.getHandler('increment', _))
          ..onClick.listen((_) => self.getHandler('incrementMoves', _)),
      ]));

final Reset = reactify.Component(
    template: (self) => DivElement()
      ..children.addAll([
        ButtonElement()
          ..text = "Reset"
          ..onClick.listen((_) => self.getHandler('initialize', _))
          ..style.display = 'inline',
        DivElement()
          ..className = 'annotation'
          ..text = "- re-hides the number and resets your moves"
          ..style.display = 'inline'
      ]));

final Message = reactify.Component(
    id: 'message',
    template: (self) => DivElement()
      ..innerHtml = self.getComputed('message')
      ..children.add(DivElement()..text = "Moves: ${self.getState('moves')}"),
    computedState: {
      'message': (self) {
        var currentNumber = self.getState('currentNumber');
        var t = self.getState('target');
        String preposition;
        if (currentNumber > t) {
          preposition = "above";
        } else if (currentNumber == t) {
          preposition = "at";
        } else {
          preposition = "below";
        }
        // var prepositionElem = DivElement()..text=preposition..style.fontWeight = 'bold';
        return 'Your current number is $currentNumber. You are <b>${preposition}</b> the hidden number.';
      }
    });

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
      ..text = 'Start the game...'
      ..onClick.listen((_) => UI.setGlobal('loggedIn', true))
      ..onClick.listen((_) => self.getHandler('initialize', _)));

final Deactivate = reactify.Component(
    template: (self) => DivElement()
      ..className = 'title'
      ..children.add(ButtonElement()
        ..text = 'Bored? Stop the game...'
        ..style.textAlign = 'center'
        ..onClick.listen((_) => UI.setGlobal('loggedIn', false))));
