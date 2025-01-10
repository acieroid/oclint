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

module type TYPED_LINT = sig
  val lint : Tast_iterator.iterator -> Tast_iterator.iterator
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

  let max_length = 20

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

  let lint super =
    { super with
      structure_item = (fun self item ->
          begin match item.pstr_desc with
            | Pstr_value (_, bindings) ->
              List.iter (fun binding ->
                          match binding.pvb_pat.ppat_desc with
                          | Ppat_var { txt; loc } ->
                            begin match binding.pvb_expr.pexp_desc with
                              | Pexp_constraint _ ->
                                error name loc (Printf.sprintf "Top-level function '%s' is missing a type annotation" txt)
                              | _ -> ()
                            end
                          | _ -> ())
                bindings
            | _ -> ()
          end;
          super.structure_item self item);
    }
                              

end

let untyped_lints =
  Ast_iterator.default_iterator
  |> ImperativeConstructs.lint
  |> FunctionTooLong.lint
  |> FunctionWithoutTypeAnnotation.lint 

module ForbiddenFunction : TYPED_LINT = struct
  open Tast_iterator

  let name = "forbidden-function"

  let forbidden =
    let function_ name = fun path -> Path.name path = name in
    let module_ name = fun path -> Path.last path = name in
    [
      (function_ "Stdlib.List.hd", "List.hd raises Failure if the list is empty. Use pattern matching instead and deal with the empty list case.");
      (function_ "Stdlib.List.tl", "List.hd raises Failure if the list is empty. Use pattern matching instead and deal with the empty list case.");
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

module MutableField : TYPED_LINT = struct
  open Tast_iterator

  let name = "mutable-field"

  (* TODO: problem with this lint *)
  let lint super =
    { super with
      structure = (fun self item ->
          List.iter
            (function
              | Typedtree.{ str_desc = Tstr_type (_, type_decls); _ } ->
                List.iter (fun decl ->
                    let open Typedtree in
                    match decl.typ_type.type_kind with
                    | Types.Type_record (labels, _) ->
                      Printf.printf "type\n";
                      List.iter
                        (fun label ->
                           if label.Types.ld_mutable = Mutable then
                             error name label.Types.ld_loc "Usage of 'mutable' keyword is not functionally pure")
                        labels
                    | _ -> ())
                  type_decls
              | _ -> ())
            item.str_items;
          super.structure self item);
    }
      
end

let typed_lints =
  Tast_iterator.default_iterator
  |> ForbiddenFunction.lint
  |> MutableField.lint

let rec process (path : string) : unit =
  if Sys.file_exists path then begin
    if Sys.is_directory path then
      process_directory path
    else if Filename.check_suffix path ".ml" || Filename.check_suffix path ".cmt" then
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
      let parsed = Parse.implementation lexbuf in
      untyped_lints.structure untyped_lints parsed
    with
    | Location.Error e ->
      Location.print_report Format.err_formatter e;
      Format.pp_print_flush Format.err_formatter ()
    | e ->
      Printf.eprintf "Failed to parse file %s: %s\n" path (Printexc.to_string e)
  else if Filename.check_suffix path ".cmt" then
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
    Printf.eprintf "Usage: linter <file.ml | directory>";
    exit 1
  end;
  let target = Sys.argv.(1) in
  process target;
  if !errors_found > 0 then
    exit 1
