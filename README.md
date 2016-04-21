# Parser

This is a work-in-progress project aiming constructing an easy to use recursive descent parser framework able to handle left-recursion.

- [ ] Handle left-recursion,
- [ ] Memoize partial parse results to improve performance

as described in [A New Top-Down Parsing Algorithm to Accommodate Ambiguity and Left Recursion in Polynomial Time](http://hafiz.myweb.cs.uwindsor.ca/pub/p46-frost.pdf) by Richard A. Frost and Rahmatullah Hafiz.

The desired fetures:

- [ ] Type-safety.
- [ ] Recursive descent, because of its simplicity.
- [ ] Support lexerless parsing.

# Open questions

- [ ] Grammar as an extension to the `ParserType`?

# License

This project is released under the MIT license. See `LICENSE` file for details.
