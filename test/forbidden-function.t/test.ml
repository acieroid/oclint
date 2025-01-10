let a = List.hd []

let b = List.tl []

let c = List.nth [] 5

let d = List.find (fun _ -> false) []

let e = List.assoc 'a' []

exception MyException
let f = raise MyException

let g = failwith "error"

let h = 5 == 5

let i = 5 != 5

let j = ref 5

let k = Array.make 5 0

let l : (int, int) Hashtbl.t = Hashtbl.create 5

let m = Obj.repr 5

let n = Bytes.make 5 'a'

let o = Random.int 42

let p = Sys.command "ls"
