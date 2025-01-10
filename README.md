oclint is a simple linter for OCaml. 

# Goals

- Be a linter to check educational functional programming projects
- The linter should be easy to run as a `dune` target
- Remain simple to ease evolution when compiler-lib does breaking changes. We total less than 500 LOC, while in comparison Zanuda has almost 7kLOC of code in `.ml` files.

# Other linters for OCaml

There are other attempts at linting OCaml:

- [Zanuda](https://github.com/Kakadu/zanuda) is the only living alternative. It is more complete and mature, but I found it cumbersome to make it fit with my use case. We used Zanuda as inspiration.
- [Camelot](https://github.com/upenn-cis1xx/camelot) is another alternative, but it is outdated and not compatible with OCaml 4.14.x
