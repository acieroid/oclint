  $ dune build
  $ dune build @lint
  File "./test.ml", line 2, characters 2-37:
  2 |   for i = 1 to 10 do print_int i done;
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Alert oclint:imperative-constructs: Usage of 'for' loop is not functionally pure.
  File "./test.ml", line 3, characters 2-43:
  3 |   while false do print_endline "hello" done
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Alert oclint:imperative-constructs: Usage of 'while' loop is not functionally pure.
  [1]
