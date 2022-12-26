open Arg
open Camlcoq
open Core (* Jane Street Core, not ITree.Core! *)
open Tests
open Data
open Format

let verbose = ref false
let printtests = ref false
let single = ref ""
let justcompile = ref false
let standalone = ref false
let output_file_prefix = "test_"

module AT = ANSITerminal

let int_of_Int64 x =
  Z.to_int (Int64asNT.Int64.intval x)

let output_ll_file filename ast =
  let open Format in
  let channel = Out_channel.create filename in
  let ppf = formatter_of_out_channel channel in
  Llvm_printer.toplevel_entities ppf ast;
  pp_force_newline ppf ();
  pp_print_flush ppf () ;
  Out_channel.close channel

let gsize t =
  let open FSigmaHCOL.FHCOL in
  match t with
  | DSHnat -> 1
  | DSHCType -> 1
  | DSHPtr n -> int_of_Int64 n

let string_of_FloatV fv =
  Float.to_string (camlfloat_of_coqfloat fv)

let randomFloat range =
  Random.float
    (if Random.bool ()
     then range
     else Float.neg range)

let string_of_float_full f =
  (* Due to the limited number of bits in the representation of doubles, the maximal precision is 324. See Wikipedia. *)
  let s = sprintf "%.350f" f in
  Str.global_replace (Str.regexp "0+$") "" s

let pp_binary64 ppf v =
    fprintf ppf "%s" (string_of_float_full (camlfloat_of_coqfloat v))

let inp_size t =
  int_of_Int64 t.o + int_of_Int64 t.i + (List.fold t.globals ~init:0 ~f:(fun v (_,g) -> v + gsize g ))

let gen_randoms t =
  Random.self_init () ;
  let rs = inp_size t in
  let randoms = List.init rs ~f:(fun _ -> coqfloat_of_camlfloat (randomFloat 3.14E8)) in
  randoms

let process_test t inp =
  let oname = camlstring_of_coqstring t.name in
  if !Interpreter.debug_flag then
    begin
      Printf.printf "Testing with %d floats:\n" (List.length inp) ;
      List.iteri inp ~f:(fun i v -> Printf.printf "\t%d\t-\t%s\n" i (string_of_FloatV v))
    end ;
  if List.length inp <> inp_size t
  then raise (Failure "Incorrect input vector size") ;
  begin
    if !justcompile then
      let rres = if !standalone
                 then Tests.compileFSHCOL_standalone t inp
                 else Tests.runFSHCOLTest t !justcompile inp
      in
      match rres with
      | ((None, _) , msg) ->
         AT.printf [AT.white; AT.on_red] "Error" ;
         AT.printf [AT.yellow] ": %s" oname ;
         AT.printf [] " F-HCOL Compilation failed:" ;
         AT.printf [AT.magenta] " %s\n" (camlstring_of_coqstring msg)  ;
         false
      | ((Some ast, _), _) ->
         output_ll_file (output_file_prefix ^ oname ^ ".ll") ast ;
         true
    else
      let eres = Tests.evalFSHCOLTest t inp in
      let rres = Tests.runFSHCOLTest t !justcompile inp in

      let print_eres v =
        AT.printf [AT.green] "Evaluation Result:\n" ;
        let ppf = std_formatter in
        pp_print_list ~pp_sep:Llvm_printer.pp_comma_space pp_binary64 ppf v ;
        pp_force_newline ppf ();
        pp_print_flush ppf () in

      let print_dv dv =
        AT.printf [AT.green] "Interpretation Result:\n" ;
        let ppf = std_formatter in
        Interpreter.pp_uvalue ppf dv ;
        pp_force_newline ppf ();
        pp_print_flush ppf ()  in

      AT.printf [AT.yellow] "\n%s:\n" oname ;

      (* Compilation *)
      let cflag =
        (match rres with
         | ((Some _, _), _) ->
            AT.printf [AT.black; AT.on_green] "OK" ;
            AT.printf [] " F-HCOL Compilation passed\n" ;
            true
         | ((None, _) , msg) ->
            AT.printf [AT.white; AT.on_red] "Error" ;
            AT.printf [AT.yellow] " F-HCOL Compilation failed:" ;
            AT.printf [AT.magenta] " %s\n" (camlstring_of_coqstring msg)  ;
            false
        ) in
      (* Interpretation *)
      let (iflag,tres) =
        (match rres with
         | ((_, Some trace), _) ->
            begin
              let tres = Interpreter.step trace in
              match tres with
              | Error msg ->
                 AT.printf [AT.white; AT.on_red] "Error";
                 AT.printf [] " LLVM Intepretation failed with: %s\n" msg ;
                 (false, tres)
              | Ok (UVALUE_Array _) ->
                 AT.printf [AT.black; AT.on_green] "OK" ;
                 AT.printf [] " Interpretation passed\n" ;
                 (true, tres)
              | Ok dv ->
                 AT.printf [AT.white; AT.on_red] "Error";
                 AT.printf [] " LLVM Intepretation did not produce array\n";
                 print_dv dv;
                 (false, tres)
            end
         | ((_, None), msg) ->
            AT.printf [AT.white; AT.on_red] "Error" ;
            AT.printf [] " F-HCOL Interpretation did not produce trace:" ;
            AT.printf [AT.magenta] " %s\n" (camlstring_of_coqstring msg)  ;
            (false, Error "no trace produced")
        ) in
      let eflag =
        (match eres with
         | Coq_inr _ ->
            AT.printf [AT.black; AT.on_green] "OK" ;
            AT.printf [] " Evaluation passed\n" ;
            true
         | Coq_inl msg ->
            AT.printf [AT.white; AT.on_red] "Error" ;
            AT.printf [] " F-HCOL Evaluation failed:" ;
            AT.printf [AT.magenta] " %s\n" (camlstring_of_coqstring msg)  ;
            false
        ) in

      let dflag =
        (match tres, eres with
         | Ok (UVALUE_Array arr), Coq_inr v ->
            begin
              match List.fold2 v arr ~init:true ~f:(fun p ve de ->
                        match de with
                        | UVALUE_Double d -> p && (Floats.Float.cmp Ceq d ve)
                        | _ -> false
                      ) with
              | Ok bv ->
                 if bv then
                   begin
                     AT.printf [AT.black; AT.on_green] "OK" ;
                     AT.printf [] " Results match\n" ;
                     if !Interpreter.debug_flag then
                       begin
                         print_dv (UVALUE_Array arr) ;
                         print_eres v ;
                       end ;
                     true
                   end
                 else
                   begin
                     AT.printf [AT.white; AT.on_red] "Error" ;
                     AT.printf [] " Value comparison failed: values differ\n" ;
                     print_dv (UVALUE_Array arr) ;
                     print_eres v ;
                     false
                   end
              | Unequal_lengths ->
                 AT.printf [AT.white; AT.on_red] "Error" ;
                 AT.printf [] " Value comparison failed: different vector length\n" ;
                 print_dv (UVALUE_Array arr) ;
                 print_eres v ;
                 false
            end
         | _,_ ->
            false
        ) in

      (cflag && iflag && eflag && dflag)
  end

let random_test t =
  process_test t (gen_randoms t)

let args =
  [
    ("-t", Set_string single, "run single test") ;
    ("-c", Set justcompile, "save IR code to file and exit") ;
    ("-v", Set verbose, "enables more verbose compilation output");
    ("-d", Set Interpreter.debug_flag, "enables debuging output");
    ("-p", Set printtests, "print names of all tests (for automation)");
    ("-s", Set standalone, "save standalone IR code (with main) (assuming [-c])");
  ]

(* for a hack to run non-random tests, see [experiments/dynwin_testeval.ml] *)
let _ =
  Arg.parse args (fun _ -> ())  "USAGE: ./testcomp [-vcds] [-p] [-t <name>]\n";
  if !printtests
  then
    begin
      ignore (List.map all_tests
                ~f:(fun t -> Printf.printf "%s\n" (camlstring_of_coqstring (name t))));
      exit 0
    end
  else
    let open Core.String in
    let t = if !single = "" then all_tests
            else List.filter all_tests ~f:(fun x -> camlstring_of_coqstring (name x) = !single) in
    exit (if List.fold (List.map t ~f:random_test) ~init:true ~f:(&&)
          then 0 else 1)
