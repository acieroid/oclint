  $ dune build
  $ dune build @lint
  File "./test.ml", line 1, characters 4-5:
  1 | let f x = x
          ^
  Alert oclint:function-without-type-annotation: Top-level function 'f' is missing type annotations (either for its arguments or for its return type)
  File "./test.ml", line 3, characters 4-5:
  3 | let g = fun x -> x
          ^
  Alert oclint:function-without-type-annotation: Top-level function 'g' is missing type annotations (either for its arguments or for its return type)
  File "./test.ml", line 5, characters 4-5:
  5 | let h = function x -> x
          ^
  Alert oclint:function-without-type-annotation: Top-level function 'h' is defined with the 'function' keyword. You cannot declare the return type this way, so prefer using 'fun'
  File "./test.ml", line 7, characters 4-5:
  7 | let i = function
          ^
  Alert oclint:function-without-type-annotation: Top-level function 'i' is defined with the 'function' keyword. You cannot declare the return type this way, so prefer using 'fun'
  File "./test.ml", line 12, characters 4-5:
  12 | let j = fun (x : int) -> x
           ^
  Alert oclint:function-without-type-annotation: Top-level function 'j' is missing type annotations (either for its arguments or for its return type)
  File "./test.ml", line 14, characters 4-5:
  14 | let k = function (x : int) -> x
           ^
  Alert oclint:function-without-type-annotation: Top-level function 'k' is defined with the 'function' keyword. You cannot declare the return type this way, so prefer using 'fun'
  File "./test.ml", line 16, characters 4-5:
  16 | let l (x : int) = x
           ^
  Alert oclint:function-without-type-annotation: Top-level function 'l' is missing type annotations (either for its arguments or for its return type)
  [1]
