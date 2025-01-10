  $ dune build
  $ dune build @lint
  File "./test.ml", lines 1-33, characters 0-3:
   1 | let f x =
   2 |   [x;
   3 |    x;
   4 |    x;
   5 |    x;
  ...
  30 |    x;
  31 |    x;
  32 |    x;
  33 |   ]
  Alert oclint:function-too-long: Function is too long (32 lines, max is 20)
  [1]
