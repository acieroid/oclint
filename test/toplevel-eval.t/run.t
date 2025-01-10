  $ dune build
  $ dune build @lint
  File "./test.ml", line 1:
  Alert oclint:double-semicolon: Usage of ;; is reserved to the top-level and should not be used in files
  File "./test.ml", line 3:
  Alert oclint:double-semicolon: Usage of ;; is reserved to the top-level and should not be used in files
  File "./test.ml", line 7:
  Alert oclint:double-semicolon: Usage of ;; is reserved to the top-level and should not be used in files
  File "./test.ml", line 1, characters 0-21:
  1 | print_endline "hello";;
      ^^^^^^^^^^^^^^^^^^^^^
  Alert oclint:toplevel-eval: Top-level evaluation should not be used.
  File "./test.ml", line 7, characters 0-21:
  7 | "But a string should";;
      ^^^^^^^^^^^^^^^^^^^^^
  Alert oclint:toplevel-eval: Top-level evaluation should not be used.
  [1]
