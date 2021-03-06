(**
  * stochastic_classes.ml
  * openkappa
  * Jérôme Feret, projet Abstraction, INRIA Paris-Rocquencourt
  *
  * Creation: 2015, the 13th of March
  * Last modification:
  *
  * Compute the relations between sites in an agent.
  *
  * Copyright 2010,2011,2012,2013,2014 Institut National de Recherche en Informatique et
  * en Automatique.  All rights reserved.  This file is distributed
  * under the terms of the GNU Library General Public License *)

let warn parameters mh message exn default =
  Exception.warn parameters mh (Some "Stochastic_classes") message exn
    (fun () -> default)

let trace = false

(************************************************************************************)
(*TYPE*)

type stochastic_class =
  {
    stochastic_class : Ckappa_sig.c_site_name list Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.t
  }

(************************************************************************************)
(*RULE*)

let scan_rule parameter error _handler rule _classes =
  let error, store_result =
    Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.create parameter error 0
  in
  (*Compute the stochastic class in the case there is a new agent is created in the rhs*)
  let error, stochastic_class_rhs =
    List.fold_left
      (fun (error, store_result) (agent_id, agent_type) ->
         let error, agent =
           Ckappa_sig.Agent_id_quick_nearly_Inf_Int_storage_Imperatif.get
             parameter
             error
             agent_id
             rule.Cckappa_sig.rule_rhs.Cckappa_sig.views
         in
         match agent with
         | None
         | Some Cckappa_sig.Unknown_agent _
         | Some Cckappa_sig.Ghost -> error, store_result
         | Some Cckappa_sig.Dead_agent (agent,_,_,_)
         | Some Cckappa_sig.Agent agent ->
           let error, site_list =
             Ckappa_sig.Site_map_and_set.Map.fold
               (fun site _ (error, current_list) ->
                  let site_list = site :: current_list in
                  error, site_list
               ) agent.Cckappa_sig.agent_interface (error, [])
           in
           let error, old_list =
             match Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.unsafe_get
                     parameter error agent_type store_result
             with
             | error, None -> error, []
             | error, Some l -> error, l
           in
           let new_list = List.concat [site_list; old_list] in
           let error, store_result =
             Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.set
               parameter
               error
               agent_type
               new_list
               store_result
           in
           error, store_result
      ) (error, store_result) rule.Cckappa_sig.actions.Cckappa_sig.creation
  in
  (*compute the stochastic class *)
  let error, stochastic_classes =
    Ckappa_sig.Agent_id_quick_nearly_Inf_Int_storage_Imperatif.fold
      parameter error
      (fun parameter error _agent_id agent store_result ->
         match agent with
         | Cckappa_sig.Unknown_agent _
         | Cckappa_sig.Ghost -> error, store_result
         | Cckappa_sig.Dead_agent (agent,_,_,_)
         | Cckappa_sig.Agent agent ->
           let agent_type = agent.Cckappa_sig.agent_name in
           let error, site_list =
             Ckappa_sig.Site_map_and_set.Map.fold
               (fun site _ (error, current_list) ->
                  let site_list = site :: current_list in
                  error, site_list
               ) agent.Cckappa_sig.agent_interface (error, [])
           in
           let error, old_list =
             match Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.unsafe_get
                     parameter error agent_type store_result
             with
             | error, None -> error, []
             | error, Some l -> error, l
           in
           let new_list = List.concat [site_list; old_list] in
           let error, store_result =
             Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.set
               parameter
               error
               agent_type
               new_list
               store_result
           in
           error, store_result
      ) rule.Cckappa_sig.rule_lhs.Cckappa_sig.views stochastic_class_rhs
  in
  error,
  {
    stochastic_class = stochastic_classes;
  }

(************************************************************************************)
(*RULES*)

(*------------------------------------------------------------------------------*)
(*return a number of site in each agent.
  For example: A(x,y,z,t) => the number of site of A is: 4*)

let get_nsites parameter error key handler =
  let error, get_nsites =
    Ckappa_sig.Agent_type_nearly_Inf_Int_storage_Imperatif.unsafe_get
      parameter
      error
      key
      handler.Cckappa_sig.sites
  in
  let error, sites_dic =
    match get_nsites with
    | None -> warn parameter error (Some "line 143") Exit
                (Ckappa_sig.Dictionary_of_sites.init())
    | Some dic -> error, dic
  in
  let error, nsites =
    Ckappa_sig.Dictionary_of_sites.last_entry
      parameter
      error
      sites_dic
  in
  error, Ckappa_sig.next_site_name nsites

(*------------------------------------------------------------------------------*)
(*RULES*)

let scan_rule_set parameter error handler rules =
  let nagents = handler.Cckappa_sig.nagents in
  let error, init_stochastic_class =
    Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.create_biggest_key parameter error nagents
  in
  let error, init =
    Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.create parameter error 0
  in
  let init_stochastic =
    {
      stochastic_class = init_stochastic_class
    }
  in
  (*------------------------------------------------------------------------------*)
  let error, stochastic_class =
    Ckappa_sig.Rule_nearly_Inf_Int_storage_Imperatif.fold
      parameter error
      (fun parameter error _rule_id rule stochastic_class ->
         (*------------------------------------------------------------------------*)
         let error, map =
           scan_rule
             parameter
             error
             handler
             rule.Cckappa_sig.e_rule_c_rule
             init_stochastic
         in
         (*------------------------------------------------------------------------*)
         let error, store_result =
           Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.fold
             parameter error
             (fun parameter error agent_type sites_list store_result ->
                let error, nsites =
                  get_nsites
                    parameter
                    error
                    agent_type
                    handler
                in
                match sites_list with
                | [] | [_] -> error, store_result
                | _ ->
                  (*getting an array in the old_result*)
                  let error, get_array =
                    Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.unsafe_get
                      parameter
                      error
                      agent_type
                      store_result
                  in
                  let error, array =
                    match get_array with
                    | None -> Ckappa_sig.Site_union_find.create parameter error (Ckappa_sig.int_of_site_name nsites)
                    | Some a -> error, a
                  in
                  (*compute the union for the list of site*)
                  let error, union_array =
                    Ckappa_sig.Site_union_find.union_list
                      parameter
                      error
                      array
                      sites_list
                  in
                  (*store*)
                  let error, store_result =
                    Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.set
                      parameter
                      error
                      agent_type
                      union_array
                      store_result
                  in error, store_result
             ) map.stochastic_class stochastic_class
         in error, store_result
      ) rules init
  in error, stochastic_class

(************************************************************************************)
(*PRINT*)

let sprintf_array parameter error handler agent_type array =
  let acc = ref "[|" in
  let error =
    Ckappa_sig.Site_union_find.iteri
      parameter error
      (fun parameter error i site_type ->
         let error, site_string =
           try
             Handler.string_of_site parameter error handler agent_type site_type
           with
             _ -> warn parameter error (Some "line 231") Exit
                    (Ckappa_sig.string_of_site_name site_type)
         in
         let _ =
           acc := !acc ^ (* avoid this, this is very slow, Use Printf.fprintf directly *)
                  if Ckappa_sig.compare_site_name i Ckappa_sig.dummy_site_name <> 0
                  then Printf.sprintf "; %s:%s"
                      (Ckappa_sig.string_of_site_name site_type)
                      site_string
                  else
                    Printf.sprintf "%s:%s"
                      (Ckappa_sig.string_of_site_name site_type)
                      site_string
         in
         error
      ) array in
  error,
  !acc ^ "|]"

let print_array parameter error handler agent_type array =
  let error, output = sprintf_array parameter error handler agent_type array in
  let _ = Printf.fprintf stdout "%s\n" output in
  error

let print_stochastic_class parameter error handler result =
  Ckappa_sig.Agent_type_quick_nearly_Inf_Int_storage_Imperatif.iter
    parameter
    error
    (fun parameter error agent_type array_site_type ->
       let error =
         if Remanent_parameters.get_do_stochastic_flow_of_information parameter
         then
           let parameter =
             Remanent_parameters.update_prefix parameter ""
           in
           begin
             if Remanent_parameters.get_trace parameter
             then
               let error =
                 let error, agent_string =
                   try
                     Handler.string_of_agent parameter error handler agent_type
                   with
                     _ -> warn parameter error (Some "line 263") Exit
                            (Ckappa_sig.string_of_agent_name agent_type)
                 in
                 let _ =
                   Printf.fprintf stdout "agent_type:%s:%s\n"
                     (Ckappa_sig.string_of_agent_name agent_type)
                     agent_string
                 in
                 error
               in
               let _ = print_string "site_type:" in
               print_array parameter error handler agent_type array_site_type
             else error
           end
         else
           error
       in
       error)
    result

(************************************************************************************)
(*MAIN*)

let stochastic_classes parameter error handler cc_compil =
  let error, result =
    scan_rule_set parameter error handler cc_compil.Cckappa_sig.rules
  in
  let _ = print_stochastic_class parameter error handler result in
  error, result
