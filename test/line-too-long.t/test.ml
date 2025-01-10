let rec factorial (n : int) : int = if n == 0 then 0 else n * factorial (n - 1) (* this is a long line that should be split upon multiple lines for readability *)
