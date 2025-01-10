oclint is a simple linter for OCaml. 

# Goals

- Be a linter to check educational functional programming projects
- The linter should be easy to run as a `dune` target
- Remain simple to ease evolution when compiler-lib does breaking changes. We total less than 500 LOC, while in comparison Zanuda has almost 7kLOC of code in `.ml` files.

# Installation

``` sh
$ opam pin add oclint https://github.com/acieroid/oclint.git
```

# How to use

Add this to your `dune` file:

```
(rule
  (alias lint)
  (action (run oclint .)))
```

Then, you can run the linter as: 

``` sh
$ dune build @lint
```

# Customizing lints

Currently, the list of lints and their option is fixed and it is not possible to change them without recompiling oclint. It should not be hard to add. PRs welcome!

# Adding a lint

The process is usually the following:

- Decide whether this is a lint that is best expressed as:
  - a query over the file content: use a `CMD_LINT`
  - a query over the parse tree (without type information): use a `UNTYPED_LINT`
  - a query over the typed tree: use a `TYPED_LINT`
- Add a test to express what you want to detect (and to not detect):
  - `cp -r ./test/toplevel-eval.t/ ./test/my-lint.t/`
  - add examples to `./test/my-lint.t/test.ml`
- Express the lint into `./bin/oclint.ml` and add it to either `cmd_lints`, `untyped_lints`, or `typed_lints`.
  - A look at the parse/typed tree for expression your queries will help. You can inspect them with:
  ```
  $ ocamlc -dparsetree ./test/my-lint/test.ml
  $ ocamlc -dtypedtree ./test/my-lint/test.ml
  ```

# Other linters for OCaml

There are other attempts at linting OCaml:

- [Zanuda](https://github.com/Kakadu/zanuda) is the only living alternative. It is more complete and mature, but I found it cumbersome to make it fit with my use case. We used Zanuda as inspiration.
- [Camelot](https://github.com/upenn-cis1xx/camelot) is another alternative, but it is outdated and not compatible with OCaml 4.14.x
