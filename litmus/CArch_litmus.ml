(****************************************************************************)
(*                           the diy toolsuite                              *)
(*                                                                          *)
(* Jade Alglave, University College London, UK.                             *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                          *)
(*                                                                          *)
(* Copyright 2017-present Institut National de Recherche en Informatique et *)
(* en Automatique and the authors. All rights reserved.                     *)
(*                                                                          *)
(* This software is governed by the CeCILL-B license under French law and   *)
(* abiding by the rules of distribution of free software. You can use,      *)
(* modify and/ or redistribute the software under the terms of the CeCILL-B *)
(* license as circulated by CEA, CNRS and INRIA at the following URL        *)
(* "http://www.cecill.info". We also give a copy in LICENSE.txt.            *)
(****************************************************************************)

module Make(O:sig val memory : Memory.t val hexa : bool val mode : Mode.t end) = struct
  module V = Int32Constant

  module type SmallBase = sig
    val base_type : CType.t

    type reg = string
    type instruction
  end

  include (CBase : SmallBase)
  module RegSet = StringSet
  module RegMap = StringMap

  let vToName =
    let open Constant in
    function
      | Concrete i -> "addr_" ^ V.Scalar.pp O.hexa i
      | Symbolic (Virtual {name=s; tag=None; cap=0L;_ })-> s
      | Label _|Symbolic _|Tag _|ConcreteVector _| PteVal _|Instruction _ -> assert false

  module Internal = struct
    type arch_reg = reg
    let pp_reg x = x
    let reg_compare = String.compare
    module G = Global_litmus
    type arch_global = G.t
    let pp_global = G.pp
    let global_compare = G.compare

    let arch = `C
  end

  include Location.Make(Internal)

  let is_pte_loc _ = false
  let parse_reg x = Some x
  let reg_compare = Internal.reg_compare

  type state = (location * V.v) list

  let debug_state st =
    String.concat " "
      (List.map
         (fun (loc,v) -> Printf.sprintf "<%s -> %s>" (pp_location loc) (V.pp_v v))
         st)

  type fullstate = (location * (TestType.t * V.v)) list

  module Out = struct
    module V = V
    include CTarget
    include OutUtils.Make(O)(V)

    let dump_init_val = dump_v
  end

  let dump_loc_tag loc =
    let module G = Global_litmus in
    match loc with
    | Location_reg (proc,reg) -> Out.dump_out_reg proc reg
    | Location_global (G.Addr s) -> s
    | Location_global (G.Pte s) -> Printf.sprintf "pte_%s" s
    | Location_global (G.Phy _)
      -> assert false

  let dump_rloc_tag =
    ConstrGen.match_rloc
      dump_loc_tag
      (fun loc i -> Printf.sprintf "%s__%02d" (dump_loc_tag loc) i)

  let location_of_addr a = Location_global (Global_litmus.Addr a)

  let arch = Internal.arch

  let rec find_in_state loc = function
    | [] -> V.zero
    | (loc2,v)::rem ->
        if location_compare loc loc2 = 0 then v
        else find_in_state loc rem
  let get_label_init _ = []

  let pp_reg x = x

  let rec count_procs = function
    | CAst.Test _::xs -> 1 + count_procs xs
    | CAst.Global _::xs -> count_procs xs
    | [] -> 0

  let type_reg r = CBase.type_reg r

  let features = []
end
