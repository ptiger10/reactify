# Contributing
If you are interested in contributing, that's awesome! If you feel there is something missing or wrong, I want to hear about it in the Issues. 

If you can help with the current priority issue, it would be a huge boon to the project!

# Priority issue
How can we catch runtime errors more systemtically? Dart's static analyzer helps surface many errors at compile time, but the Reactify API exposes developers to two common runtime errors: 1) trying to get/set a key (which must be a String) that isn't in a Component property map (e.g., `state`, `computedState`, or `handlers`), and 2) forgetting to return a function for `template` or `computedState` when not using the `()=>` syntax. Whenever one of these two things happens, a custom exception is thrown in the Console (KeyException and ValueException, respectively). However, the developer won't know the problem exists until they encounter it, which could be costly and frequent on a large or complicated project.

A solution that I have considered is to have the caller extend a State() or Handlers() class, define custom properties on it, and reference that within their Component. The upside is that if the caller tried to reference a non-existing property, it would be flagged by the compiler. The downside is that it requires managing several additional pieces per-component outside of the component constructor and it is not clear how to standardize getter and setter behavior for custom properties. 

Ideally, I would like to add a UserInterface.test() function that visits all the Components contained within, renders them, and triggers all of the event listeners defined on their elements. If any exceptions are thrown, they are caught, consolidated, and printed in a single runtime report. 

# Philosophy on new features
The surface area of the package should remain tiny, and the bits that are exposed should be extensively tested. Pull Requests with new features should align with this by meeting an essential need for package users, sticking to conventional syntax, defining their own tests, and passing the existing CI tests.


