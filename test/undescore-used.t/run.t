  $ dune build
  $ dune build @lint
  File "./test.ml", line 1, characters 25-27:
  1 | let f (_x : int) : int = _x
                               ^^
  Alert oclint:undescore-used: A binding starting with an underscore should not be used
  File "./test.ml", line 4, characters 8-10:
  4 |   match _x with
              ^^
  Alert oclint:undescore-used: A binding starting with an underscore should not be used
  File "./test.ml", line 9, characters 2-4:
  9 |   _y
        ^^
  Alert oclint:undescore-used: A binding starting with an underscore should not be used
  [1]
