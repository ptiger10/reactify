# Dart UI Cookbook
Dart recipes for common UI needs

## Generic Dart
### Selecting all the text in an `<input>` element on click
`InputElement()..onClick.listen((e)=> (e.target as InputElement).select())`

### Triggering handler after losing focus on an element
`DivElement()..onBlur.listen((e) => ...)`

### Get random int between 0 and n 
```
final r = Random(DateTime.now().millisecondsSinceEpoch)
return r.nextInt(n)
```

### Add an element without an HTML file
`document.body.children.add(DivElement())`

### Formatting within text
`DivElement()..innerHtml = "This <b>works</b>"` instead of `DivElement()..text = "This <b>will not work</b>`

## Reactify
### Hide on condition
```
final IsEven = reactify.Component(
    id: 'score',
    template: (self) => ButtonElement()..text = 'Toggle: ${self.getState('count')}'
      ..onClick.listen((_) => self.setState('count', self.getState('count') + 1))
      ..children.add(DivElement()..text = 'Count is even: now you see me'
        ..style.display = self.getComputed('visible') ? 'block' : 'none'
      ),
    state: {'count': 0},
    computedState: {
      'visible': (self) => self.getState('count') % 2 == 0? true : false
    }
);
```

### Insert UserInterface into HTML 
**index.html**
```
<!DOCTYPE html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <script type="text/javascript" defer src="main.dart.js"></script>
</head>
<body>
  <div id="root"></div>
</body>
```

**main.dart**
```
void main() {
  document.getElementById("root").replaceWith(UI.initialize());
}

final UI = reactify.UserInterface(
    components: [
        Example
    ]
);

final Example = reactify.Component(
    id: 'example',
    template: (_) => DivElement()..text = 'Simple as you like'
);
```
