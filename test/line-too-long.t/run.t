  $ dune build
  $ dune build @lint
  File "./test.ml", line 1, characters 0-21:
  1 | print_endline "hello"
      ^^^^^^^^^^^^^^^^^^^^^
  Alert oclint:toplevel-eval: Top-level evaluation should not be used.
  [1]
