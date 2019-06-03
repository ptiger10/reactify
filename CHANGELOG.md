## 1.0.0

- Initial version

## 1.0.1

- Added CHANGELOG
- Added more hyperlinks to README and docstrings
- Added `meta` dependency to identify `@required` arguments in class constructors

## 1.0.2

- Added main.dart.js files to examples so that one can view them simply by opening index.html in a browser'

## 1.0.3

- Added hosted links to examples

## 1.1.0

- Introduced a private reconciliation algorithm (_reconcile) that compares the virtual DOM before and after state change, and only performs DOM manipulation on elements that have changed. Rules for _reconcile:
  - If two nodes are of different types, replace the entire remaining tree with the replacement node
  - If two nodes have a different number of direct children, replace the entire remaining tree with the replacement node
  - If two nodes have different outer HTML, check for different text (specifically, check for different childNode[0].nodeValue) and different attributes. Wherever there is a discrepancy between prior and replacement, overwrite with the values from replacement
  - Apply _reconcile recursively, so that the same type/numberChildren/text/attribute check is applied to all child elements with different outer HTML
- Updated _refresh to delegate upwards so that _reconcile is called on root components only  