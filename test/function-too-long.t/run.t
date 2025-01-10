  $ dune build
  File "test.ml", lines 2-33, characters 2-3:
   2 | ..[x;
   3 |    x;
   4 |    x;
   5 |    x;
   6 |    x;
  ...
  30 |    x;
  31 |    x;
  32 |    x;
  33 |   ]
  Error: This expression has type 'a list
         but an expression was expected of type int
  [1]
  $ dune build @lint
  File "./test.ml", lines 1-33, characters 0-3:
   1 | let f (x : int) : int =
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
  Failed
  [1]
