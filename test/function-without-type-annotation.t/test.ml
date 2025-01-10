let f x = x

let g = fun x -> x

let h = function x -> x

let i = function
  | 0 -> 0
  | 1 -> 1
  | x -> x

let j = fun (x : int) -> x

let k = function (x : int) -> x

let l (x : int) = x

let ok (x : int) : int -> int =
  (* This is OK, we only want top-level annotations *)
  let g y = x + y in
  g

let ok2 (_ : int) : int = 5

let ok3 () : int = 5

let ok4 = fun (_ : int) : int -> 42
