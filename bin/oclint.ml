(* linter.ml *)
open Stdlib
open Parsetree

(** The number of errors reported *)
let errors_found : int ref = ref 0

(** [error loc message] reports an error *)
let error (lint_name : string) (location : Location.t) (message : string) : unit =
  errors_found := !errors_found + 1;
  let main = Location.mkloc (fun ppf -> Format.pp_print_string ppf message) location in
  let report = Location.{ sub = []; main; kind = Report_alert (Printf.sprintf "oclint:%s" lint_name) } in
  Location.print_report Format.std_formatter report

(** Untyped lints rely on [Ast_iterator] *)
module type UNTYPED_LINT = sig
  (** A lint is just an extension of an iterator, which will traverse the AST and call [error]. *)
  val lint : Ast_iterator.iterator -> Ast_iterator.iterator
end

(** Typed lints rely on [Tast_iterator] *)
module type TYPED_LINT = sig
  val lint : Tast_iterator.iterator -> Tast_iterator.iterator
end

(** Command lints are lints that require running a command (typically, grep) based on the filename *)
module type CMD_LINT = sig
  val lint : string -> unit
end

(** Check for the presence of forbidden imperative constructs *)
module ImperativeConstructs : UNTYPED_LINT = struct
  open Ast_iterator

  let name = "imperative-constructs"

  let lint super =
  { super with
    expr = (fun self expr ->
      (match expr.pexp_desc with
      | Pexp_for _ -> error name expr.pexp_loc "Usage of 'for' loop is not functionally pure."
      | Pexp_while _ -> error name expr.pexp_loc "Usage of 'while' loop is not functionally pure."
      | _ -> ());
      super.expr self expr);
  }
end

(** Check for functions that are too long *)
module FunctionTooLong : UNTYPED_LINT = struct
  open Ast_iterator

  let name = "function-too-long"

  let max_length = 30

  let lint super =
    { super with
      structure_item = (fun self item ->
          begin match item.pstr_desc with
              | Pstr_value (_, bindings) ->
                  List.iter (fun binding ->
                    let loc = binding.pvb_loc in
                    let lines = loc.loc_end.pos_lnum - loc.loc_start.pos_lnum in
                    if lines > max_length then
                      error name loc (Printf.sprintf "Function is too long (%d lines, max is %d)" lines max_length)
                  ) bindings
              | _ -> ()
          end;
          super.structure_item self item);
    }
end

(** Check for top-level function that do not have type annotations *)
module FunctionWithoutTypeAnnotation : UNTYPED_LINT = struct
  open Ast_iterator

  let name = "function-without-type-annotation"

  let is_untyped p =
    match p.ppat_desc with
    | Ppat_constraint _ ->
      (* A constraint means we have type information *)
      false
    | Ppat_constant _ | Ppat_construct _ ->
      (* A constant/constructor would either have to be totally matched,
         or would be caught as a warning by the compiler *)
      false
    | _ ->
      (* Anything else is considered untyped and reported *)
      true

  let rec check_fun txt p e =
    if is_untyped p then
      error name p.ppat_loc (Printf.sprintf "Top-level function '%s' is missing type annotations for an argument" txt)
    else
      match e.pexp_desc with
      | Pexp_constraint _ -> ()
      | Pexp_fun (_, _, p, e) -> check_fun txt p e
      | _ ->
        error name e.pexp_loc (Printf.sprintf "Top-level function '%s' is missing type annotations for its return type" txt)

  let lint super =
    { super with
      structure_item = (fun self item ->
          begin match item.pstr_desc with
            | Pstr_value (_, bindings) ->
              List.iter (fun binding ->
                          match binding.pvb_pat.ppat_desc with
                          | Ppat_var { txt; loc } ->
                            begin match binding.pvb_expr.pexp_desc with
                              | Pexp_fun (_, _, p, e) ->
                                check_fun txt p e
                              | Pexp_function _ ->
                                error name loc (Printf.sprintf "Top-level function '%s' is defined with the 'function' keyword. You cannot declare the return type this way, so prefer using 'fun'" txt)
                              | _ -> ()
                            end
                          | _ -> ())
                bindings
            | _ -> ()
          end;
          super.structure_item self item);
    }
end

(** Check for top-level evaluations *)
module TopLevelEval : UNTYPED_LINT = struct
  open Ast_iterator

  let name = "toplevel-eval"

  (* Adapted from Zanuda *)
  let lint super =
    { super with
      structure_item =
        (fun self item ->
           super.structure_item self item;
           match item.pstr_desc with
           | Pstr_eval (_, _) ->
             error name item.pstr_loc "Top-level evaluation should not be used."
           | _ -> ())
    ; expr = (fun self expr ->
        super.expr self expr;
        match expr.pexp_desc with
        | Pexp_extension (_, PStr [ { pstr_desc = Pstr_eval (ein, _); _ } ]) ->
          self.expr self ein
        | _ -> ())
    ; attribute =
        (fun _ attr ->
           super.attribute super attr)
    }
end

(** Check for improper casing *)
module ImproperCasing : UNTYPED_LINT = struct
  open Ast_iterator

  let name = "improper-casing"

  let is_snake_case s = String.lowercase_ascii s = s

  let is_pascal_case s = not (String.contains s '_')

  let lint super =
    { super with
      structure_item = (fun self item ->
          begin match item.pstr_desc with
            | Pstr_type (_, decls) ->
              List.iter (fun decl ->
                  if not (is_snake_case decl.ptype_name.txt) then
                    error name decl.ptype_name.loc "Type declaration does not have proper case";
                  match decl.ptype_kind with
                  | Ptype_variant constructors ->
                    List.iter (fun cons ->
                        if not (is_pascal_case cons.pcd_name.txt) then
                          error name cons.pcd_name.loc "Type constructor does not have proper case")
                      constructors
                  | _ -> ()
                )
                decls;

            | Pstr_value (_, bindings) ->
              List.iter (fun binding ->
                  match binding.pvb_pat.ppat_desc with
                  | Ppat_var v ->
                    if not (is_snake_case v.txt) then
                      error name v.loc "Binding does not have proper case"
                  | _ -> ())
                bindings
            | _ -> ()
          end;
          super.structure_item self item);
    }
end

(** Check for variables starting with _ but being used *)
module UnderscoreUsed : UNTYPED_LINT = struct
  open Ast_iterator

  let name = "undescore-used"

  let is_underscore_name s = String.starts_with ~prefix:"_" s

  (* This is mostly taken from Zanuda *)
  let lint super =
    { super with
      expr = (fun self expr ->
        let open Parsetree in
        begin match expr.pexp_desc with
        | Pexp_ident { loc; txt = Lident v } when is_underscore_name v ->
          error name loc "A binding starting with an underscore should not be used"
        | _ -> ()
        end;
        super.expr self expr)
    }

end

let untyped_lints =
  Ast_iterator.default_iterator
  |> ImperativeConstructs.lint
  (* |> FunctionTooLong.lint *)
  |> FunctionWithoutTypeAnnotation.lint
  |> TopLevelEval.lint
  |> ImproperCasing.lint
  |> UnderscoreUsed.lint

(** Check for a number of forbidden functions, because they are either non-pure, or unsafe *)
module ForbiddenFunction : TYPED_LINT = struct
  open Tast_iterator

  let name = "forbidden-function"

  let forbidden =
    let function_ name = fun path -> Path.name path = name in
    let module_ name = fun path -> Path.last path = name in
    [
      (function_ "Stdlib.List.hd", "List.hd raises Failure if the list is empty. Use pattern matching instead and deal with the empty list case.");
      (function_ "Stdlib.List.tl", "List.tl raises Failure if the list is empty. Use pattern matching instead and deal with the empty list case.");
      (function_ "Stdlib.List.nth", "List.nth raises Failure if the list is too short. Avoid it.");
      (function_ "Stdlib.List.find", "List.find raises Not_found if the element is not found. Prefer List.find_opt.");
      (function_ "Stdlib.List.assoc", "List.assoc raises Not_found if the element is not found. Prefer List.assoc_opt");

      (function_ "Stdlib.raise", "Exceptions are not functionally pure");
      (function_ "Stdlib.failwith", "Exceptions are not functionally pure");

      (function_ "Stdlib.(==)", "Physical equality is probably not what you want. Use structural equality (=) instead.");
      (function_ "Stdlib.(!=)", "Physical inequality is probably not what you want. Use structural inequality (!=) instead.");

      (function_ "Stdlib.ref", "references are not functionally pure");

      (module_ "Array", "This module is not functionally pure");
      (module_ "Hashtbl", "This module is not functionally pure");
      (module_ "Obj", "This module is not functionally pure");
      (module_ "Bytes", "This module is not functionally pure");
      (module_ "Random", "This module is not functionally pure");
      (module_ "Sys", "This module is not functionally pure");

    ]

  let lint super =
    { super with
      expr = (fun self expr ->
          begin match expr.exp_desc with
          | Texp_ident (path, _, _) ->
            begin match List.find_opt (fun (k, _) -> k path) forbidden with
              | Some (_, reason) -> error name expr.exp_loc (Printf.sprintf "Unsafe function being used: %s. %s" (Path.name path) reason)
              | None -> ();
            end
          | _ -> ()
          end;
          super.expr self expr);
    }
end

(** Check for records with mutable fields *)
module MutableField : TYPED_LINT = struct
  open Tast_iterator

  let name = "mutable-field"

  let lint super =
    { super with
      type_declaration = (fun self decl ->
          begin match decl.typ_kind with
          | Ttype_record elems ->
            let open Typedtree in
            List.iter (fun label ->
                if label.ld_mutable = Mutable then
                  error name label.ld_loc (Printf.sprintf "Mutable record label is forbidden in type %s" decl.typ_name.txt))
              elems
          | _ -> ()
          end;
        super.type_declaration self decl);
    }
      
end

let typed_lints =
  Tast_iterator.default_iterator
  |> ForbiddenFunction.lint
  |> MutableField.lint

(** Run grep, invoking [matching_line] for every line matching the pattern *)
let grep ~path ~pattern (matching_line : Location.t -> unit) =
  let command = Printf.sprintf "grep -n '%s' %s" pattern (Filename.quote path) in
  let ic = Unix.open_process_in command in
  let rec process () =
    match input_line ic with
    | line ->
      let portions = String.split_on_char ':' line in
      let line_number = int_of_string (List.hd portions) in
      let pos = Lexing.{ dummy_pos with pos_fname = path; pos_lnum = line_number } in
      let loc = Location.{ loc_start = pos; loc_end = pos; loc_ghost = true } in
      matching_line loc;
      process ()
    | exception End_of_file -> ()
  in
  process ();
  ignore (Unix.close_process_in ic)

(** Check for the use of ;; *)
module DoubleSemicolon : CMD_LINT = struct

  let name = "double-semicolon"

  let lint path =
    grep ~path ~pattern:";;" (fun loc ->
      error name loc "Usage of ;; is reserved to the top-level and should not be used in files");

end

(** Check for lines that are too long *)
module LineTooLong : CMD_LINT = struct

  let name = "line-too-long"

  let max_length = 120

  let lint path =
    grep ~path ~pattern:(Printf.sprintf ".\\{%d\\}" max_length) (fun loc ->
        error name loc (Printf.sprintf "Line is too long and should be shorter than %d characters." max_length))

end

let cmd_lints = fun path ->
  DoubleSemicolon.lint path;
  LineTooLong.lint path

let is_interesting_file (path : string) : bool =
  (not (Filename.check_suffix path "lexer.mll")) &&
  (not (Filename.check_suffix path "lexer.ml")) &&
  (not (Filename.check_suffix path "parser.ml")) &&
  ((Filename.check_suffix path ".ml" && not (Filename.check_suffix path ".pp.ml"))
   || Filename.check_suffix path ".cmt")

let rec process (path : string) : unit =
  if Sys.file_exists path then begin
    if Sys.is_directory path then
      process_directory path
    else if is_interesting_file path then
      process_file path
  end else begin
    Printf.eprintf "File or directory not found: %s\n" path;
  end
and process_file (path : string) : unit =
  if Filename.check_suffix path ".ml" then
    let ic = open_in path in
    let lexbuf = Lexing.from_channel ic in
    Location.input_name := path;
    Location.init lexbuf path;
    try
      cmd_lints path;
      let parsed = Parse.implementation lexbuf in
      untyped_lints.structure untyped_lints parsed
    with
    | Location.Error e ->
      Location.print_report Format.err_formatter e;
      Format.pp_print_flush Format.err_formatter ()
    | e ->
      Printf.eprintf "Failed to parse file %s: %s\n" path (Printexc.to_string e)
  else if Filename.check_suffix path ".cmt" then
    (* TODO: ideally, we want the cmt to be linked to the .ml *)
    let (_, cmt_infos) = Cmt_format.read path in
    Option.iter (fun cmt ->
        match cmt.Cmt_format.cmt_annots with
        | Cmt_format.Implementation typed ->
          typed_lints.structure typed_lints typed
        | _ ->
          Printf.eprintf "Failed\n") cmt_infos
and process_directory (path : string) : unit =
  Sys.readdir path
  |> Array.to_list
  |> List.map (Filename.concat path)
  |> List.iter process 

let () =
  if Array.length Sys.argv < 2 then begin
    Printf.eprintf "Usage: %s <file.ml | directory>" Sys.argv.(0);
    exit 1
  end;
  let target = Sys.argv.(1) in
  process target;
  if !errors_found > 0 then
    exit 1
