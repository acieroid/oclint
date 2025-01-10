  $ dune build
  $ dune build @lint
  File "test.ml", line 1, characters 8-15:
  Alert oclint:forbidden-function: Unsafe function being used: Stdlib.List.hd. List.hd raises Failure if the list is empty. Use pattern matching instead and deal with the empty list case.
  File "test.ml", line 3, characters 8-15:
  Alert oclint:forbidden-function: Unsafe function being used: Stdlib.List.tl. List.tl raises Failure if the list is empty. Use pattern matching instead and deal with the empty list case.
  File "test.ml", line 5, characters 8-16:
  Alert oclint:forbidden-function: Unsafe function being used: Stdlib.List.nth. List.nth raises Failure if the list is too short. Avoid it.
  File "test.ml", line 7, characters 8-17:
  Alert oclint:forbidden-function: Unsafe function being used: Stdlib.List.find. List.find raises Not_found if the element is not found. Prefer List.find_opt.
  File "test.ml", line 9, characters 8-18:
  Alert oclint:forbidden-function: Unsafe function being used: Stdlib.List.assoc. List.assoc raises Not_found if the element is not found. Prefer List.assoc_opt
  File "test.ml", line 12, characters 8-13:
  Alert oclint:forbidden-function: Unsafe function being used: Stdlib.raise. Exceptions are not functionally pure
  File "test.ml", line 14, characters 8-16:
  Alert oclint:forbidden-function: Unsafe function being used: Stdlib.failwith. Exceptions are not functionally pure
  File "test.ml", line 20, characters 8-11:
  Alert oclint:forbidden-function: Unsafe function being used: Stdlib.ref. references are not functionally pure
  [1]
