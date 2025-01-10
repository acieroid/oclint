  $ dune build
  $ dune build @lint
  File "./test.ml", line 3, characters 5-14:
  3 | type notOkType = Not_ok_constructor
           ^^^^^^^^^
  Alert oclint:improper-casing: Type declaration does not have proper case
  File "./test.ml", line 3, characters 17-35:
  3 | type notOkType = Not_ok_constructor
                       ^^^^^^^^^^^^^^^^^^
  Alert oclint:improper-casing: Type constructor does not have proper case
  File "./test.ml", line 5, characters 4-15:
  5 | let invalidCase = 1
          ^^^^^^^^^^^
  Alert oclint:improper-casing: Binding does not have proper case
  [1]
