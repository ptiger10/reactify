@TestOn('browser')
import "package:test/test.dart";
import 'package:reactify/reactify.dart';
import 'dart:html';

void main() {
  setUp(() {
    document.body.replaceWith(BodyElement());
  });
  group('Expected exceptions: UserInterface', () {
    test(
        ".getGlobal() with no global state",
        () => expect(() => UserInterface()..getGlobal('test'),
            throwsA(TypeMatcher<ValueException>())));

    test(
        ".getGlobal() with unset key",
        () => expect(() => UserInterface(globalState: {})..getGlobal('test'),
            throwsA(TypeMatcher<KeyException>())));

    test(
        ".setGlobal() with no global state",
        () => expect(() => UserInterface()..setGlobal('test', '123'),
            throwsA(TypeMatcher<ValueException>())));

    test(
        ".setGlobal() with unset key",
        () => expect(
            () => UserInterface(globalState: {})..setGlobal('test', '123'),
            throwsA(TypeMatcher<KeyException>())));

    test(
        ".refreshAll() with no components",
        () => expect(() => UserInterface()..refreshAll(),
            throwsA(TypeMatcher<ValueException>())));

    test(".refreshAll() prior to initialize()", () {
      var c1 = Component(id: '1', template: (_) => DivElement());
      var UI = UserInterface(components: [c1]);
      expect(() => UI.refreshAll(), throwsA((TypeMatcher<ValueException>())));
    });

    test(
        ".initialize() with no components",
        () => expect(() => UserInterface()..initialize(),
            throwsA(TypeMatcher<ValueException>())));
  });
  group('Expected exceptions: Component', () {
    test(
        ".render() with no template",
        () => expect(() => Component(template: null).render(),
            throwsA(TypeMatcher<ValueException>())));

    test(".render(): template without `()=>` syntax and no return value", () {
      var c = Component(template: (_) {
        DivElement();
      });
      expect(() => c.render(), throwsA(TypeMatcher<ValueException>()));
    });

    test(".render(): root component with no id", () {
      var c = Component(template: (_) => DivElement());
      expect(() => c.refresh(), throwsA(TypeMatcher<ValueException>()));
    });

    test(".refresh(): root component with updated id", () {
      var c = Component(id: "original", template: (self) => DivElement());
      c.id = "new";
      expect(() => c.refresh(), throwsA(TypeMatcher<ValueException>()));
    });
    test(".getState() with null state", () {
      var c = Component(template: (self) => DivElement());
      expect(() => c.getState('noSuchKey'),
          throwsA(TypeMatcher<ValueException>()));
    });

    test(".getState() with unset key", () {
      var c =
          Component(template: (self) => DivElement(), state: {'test': true});
      expect(
          () => c.getState('noSuchKey'), throwsA(TypeMatcher<KeyException>()));
    });

    test(".setState() with null state", () {
      var c = Component(template: (self) => DivElement());
      expect(() => c.setState('noSuchKey', false),
          throwsA(TypeMatcher<ValueException>()));
    });

    test(".setState() with missing key", () {
      var c =
          Component(template: (self) => DivElement(), state: {'test': true});
      expect(() => c.setState('noSuchKey', false),
          throwsA(TypeMatcher<KeyException>()));
    });

    test(".getComputed() with null computedState", () {
      var c = Component(template: (self) => DivElement());
      expect(() => c.getComputed('noSuchKey'),
          throwsA(TypeMatcher<ValueException>()));
    });

    test(".getComputed() with missing key", () {
      var c = Component(
          template: (self) => DivElement(),
          computedState: {'test': (_) => false});
      expect(() => c.getComputed('noSuchKey'),
          throwsA(TypeMatcher<KeyException>()));
    });

    test(".getComputed() with no return", () {
      var c = Component(template: (self) => DivElement(), computedState: {
        'test': (_) {
          false;
        }
      });
      expect(
          () => c.getComputed('test'), throwsA(TypeMatcher<ValueException>()));
    });

    test(".getHandlers() with null handlers", () {
      var event = Event('test');
      var c = Component(template: (self) => DivElement());
      expect(() => c.getHandler('test', event),
          throwsA(TypeMatcher<ValueException>()));
    });
    test(".getHandlers() with missing key", () {
      var event = Event('test');
      var c = Component(
          template: (self) => DivElement(),
          handlers: {'test': (_) => (self) => false});
      expect(() => c.getHandler('noSuchKey', event),
          throwsA(TypeMatcher<KeyException>()));
    });
    test(".injectComponent() calling overwritten sub-component state", () {
      // sub state is replaced completely
      var sub = Component(
          id: 'sub',
          template: (self) => DivElement()
            ..className = 'sub'
            ..text = self.getState('sub'),
          state: {'sub': 'willBeDeleted'});

      var root = Component(
          id: 'root',
          template: (self) => self.injectComponent(sub),
          state: {'root': 'notDeleted'});
      expect(() => root.render(), throwsA(TypeMatcher<KeyException>()));
    });
  });

  group('Working correctly: UserInterface', () {
    test(".setGlobal()", () {
      var UI = UserInterface(globalState: {'loggedIn': false})
        ..setGlobal('loggedIn', true);
      expect(UI.getGlobal('loggedIn'), equals(true));
    });
    test(".initialize()", () {
      var c1 = Component(template: (_) => DivElement());
      var c2 = Component(template: (_) => ButtonElement());

      var UI = UserInterface(components: [c1, c2]);
      var want = DivElement()
        ..id = 'root'
        ..children.addAll([DivElement(), ButtonElement()]);
      expect(UI.initialize().outerHtml, equals(want.outerHtml));
    });

    test(".refreshAll()", () {
      var c1 = Component(id: '1', template: (_) => DivElement());
      var UI = UserInterface(components: [c1]);
      document.body.children.add(UI.initialize());

      UI.initialize();
      var c2 = Component(id: '1', template: (_) => ButtonElement());
      UI.components[0] = c2;

      UI.refreshAll();
      expect(
          UI.components[0].render().outerHtml, equals(c2.render().outerHtml));
    });
  });

  group('Working correctly: Component', () {
    test(".render()", () {
      var c =
          Component(id: '1', template: (_) => DivElement()..className = 'test');
      var want = DivElement()
        ..className = 'test'
        ..id = 'component-1';
      expect(c.render().outerHtml, equals(want.outerHtml));
    });

    // unexpected: this test inserts the updatedTest node in front of originalTest
    // when run outside of test framework, updatedTest node replaces origianlTest completely
    test(".refresh()", () {
      var c = Component(
          id: '1', template: (_) => DivElement()..className = 'originalTest');
      document.body.children.add(c.render());
      var want = DivElement()..className = 'updatedTest';
      c.template = (_) => want;
      c.refresh();
      expect(document.body.children.first.outerHtml, equals(want.outerHtml));
    });

    test(".getState()", () {
      var c = Component(
          template: (self) =>
              DivElement()..text = self.getState('test').toString(),
          state: {'test': 123});
      document.body.children.add(c.render());
      var want = DivElement()..text = "123";
      expect(document.body.children.first.outerHtml, equals(want.outerHtml));
    });

    test(".setState()", () {
      var c = Component(
          id: '1',
          template: (self) =>
              DivElement()..onClick.listen((_) => self.setState('test', true)),
          state: {'test': false});
      document.body.children.add(c.render());
      expect(c.state['test'], false);
      querySelector("#component-1").dispatchEvent(MouseEvent('click'));
      expect(c.state['test'], true);
    });

    test(".getComputed()", () {
      var c = Component(
          id: '1',
          template: (self) => DivElement()
            ..text = self.getComputed('conditionalOnState')
            ..className = 'root'
            ..onClick.listen((_) => self.setState('bool', false)),
          state: {
            'bool': true
          },
          computedState: {
            'conditionalOnState': (self) {
              if (self.getState('bool')) {
                return 'original';
              }
              return 'modified';
            }
          });
      document.body.children.add(c.render());
      expect(
          document.body.children.first.text, equals("original"));
      querySelector('#component-1.root').dispatchEvent(MouseEvent('click'));
      expect(
          document.body.children.first.text, equals("modified"));
    });

    test(".getHandler()", () {
      var c = Component(
          id: "1",
          template: (self) =>
              InputElement()..onClick.listen((e) => self.getHandler('test', e)),
          state: {
            'test': ""
          },
          handlers: {
            'test': (e) => (self) =>
                self.setState('test', (e.target as InputElement).value)
          });
      document.body.children.add(c.render());

      var wantBefore = InputElement()
        ..text = ""
        ..id = 'component-1';
      expect(
          document.body.children.first.outerHtml, equals(wantBefore.outerHtml));
      querySelector("#component-1").dispatchEvent(MouseEvent('click'));

      var wantAfter = InputElement()
        ..text = "working"
        ..id = 'component-1';
      expect(
          document.body.children.first.outerHtml, equals(wantAfter.outerHtml));
    });
    test(".injectComponent()", () {
      // sub computedState with same name as root is overwritten
      // sub computedState with independent name is retained
      var sub = Component(
        id: 'sub',
        template: (self) => DivElement()
          ..text = self.getState('root')
          ..children.add(DivElement()
            ..className = 'child'
            ..text = self.getComputed('root')
            ..onClick.listen((_) => self.getHandler('root', _))
            ..children.add(DivElement()..text = self.getComputed('sub'))),
        computedState: {
          'root': (self) => 'willBeOverwritten',
          'sub': (self) => "subComputed"
        },
      );

      var root = Component(
          id: 'root',
          template: (self) => self.injectComponent(sub),
          state: {
            'root': "original"
          },
          computedState: {
            'root': (self) => "rootComputed"
          },
          handlers: {
            'root': (_) => (self) => self.setState('root', 'updated')
          });

      document.body.children.add(root.render());
      querySelector("#component-root .child")
          .dispatchEvent(MouseEvent('click'));
      var want = DivElement()
        ..id = 'component-root'
        ..text = "updated"
        ..children.add(DivElement()
          ..className = 'child'
          ..text = 'rootComputed'
          ..children.add(DivElement()..text = 'subComputed'));
      expect(document.body.children.first.outerHtml, equals(want.outerHtml));
    });
  });
}
