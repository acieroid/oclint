let f (_x : int) : int = _x

let g = fun (_x : int) : int ->
  match _x with
  | _ -> 0

let h (_x : int) : int =
  let _y = 5 in
  _y

let i (_x : int) (_y : int) : int =
  _y

let ok (_x : int) : int = 5
