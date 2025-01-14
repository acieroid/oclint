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

let m (_ : int) (_ : int) (_ : int) = true

let o (_ : int) _ (_ : int) : bool = true

let p = fun (x : int) -> fun (y : int) -> x + y

let ok (x : int) : int -> int =
  (* This is OK, we only want top-level annotations *)
  let g y = x + y in
  g

let ok2 (_ : int) : int = 5

let ok3 () : int = 5

let ok4 = fun (_ : int) : int -> 42

let ok5 (s1 : string) (s2 : string) : bool =
  s1 = s2

let rec ok6 (x : int) (y : int) : int =
  if x < 0 then
    y
  else
    ok6 (x - 1) y

let ok7 (_ : int) (_ : int) (_ : int) (_ : int) (_ : int) : bool = true

let ok8 = fun (x : int) : (int -> int) ->
  fun y -> x+y
