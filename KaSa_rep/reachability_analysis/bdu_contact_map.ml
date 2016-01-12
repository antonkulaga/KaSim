 (**
  * bdu_contact_map.ml
  * openkappa
  * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
  * 
  * Creation: 2015, the 11th of September
  * Last modification: 
  * 
  * Compute the contact map 
  * 
  * Copyright 2010,2011,2012,2013,2014 Institut National de Recherche en Informatique et   
  * en Automatique.  All rights reserved.  This file is distributed     
  * under the terms of the GNU Library General Public License *)

open Bdu_analysis_type
open Int_storage
open Cckappa_sig

let warn parameters mh message exn default =
  Exception.warn parameters mh (Some "Contact Map") message exn
                 (fun () -> default)                

let trace = false

(*****************************************************************************************)
(*contact map without state information: this computation consider both
  binding in the lhs and rhs.
  For instance:

  r1: A(x), B(x) -> A(x!1), B(x!1)
  r2: A(y!1), C(x!1) -> A(y), C(x)

  The result is:
  - A bond to B; B bond to A
  and 
  - A bond to C; C bond to A.
*)

(************************************************************************************)

(*let compute_contact_map_aux parameter error rule_id rule handler store_result =
  let add_link rule_id (agent, site, state) store_result =
    let error, (l, old) =
      match Int2Map_syn.Map.find_option rule_id store_result with
      | None -> error, ([], Set_triple.Set.empty)
      | Some (l, s) -> error, (l, s)
    in
    let set = Set_triple.Set.add (agent, site, state) Set_triple.Set.empty in
    let union_set = Set_triple.Set.union set old in
    if Set_triple.Set.equal union_set old
    then error, store_result
    else
      let add_map =
        Int2Map_syn.Map.add rule_id (l, union_set) store_result
      in
      error, add_map
  in  
  (*-----------------------------------------------------------------------*)
  (*folding this solution with the information in dual*)
  let error, (store_result1, store_result2) =
    AgentMap.fold parameter error 
      (fun parameter error agent_id agent store_result ->
        match agent with
        | Unknown_agent _ | Dead_agent _ ->
	  warn parameter error (Some "line 64, dead agents/sites should not occur in rhs") 
            Exit store_result 
	| Ghost-> error, store_result
        | Agent agent ->
          List.fold_left (fun (error, (store_result1, store_result2)) 
            (site_add1, site_add2) ->
            let agent_index1 = site_add1.agent_index in
            let agent1 = site_add1.agent_type in
            let site1 = site_add1.site in
            let agent2 = site_add2.agent_type in
            let site2 = site_add2.site in
            let agent_index2 = site_add2.agent_index in
            (*-----------------------------------------------------------------------*)
            let error, map1 =
              Site_map_and_set.Map.fold
                (fun site port (error, store_result) ->
                  let state = port.site_state.max in
                  if agent_id = agent_index1 && state > 0
                  then
                    add_link rule_id (agent1, site1, state) store_result
                  else
                    error, store_result
                ) agent.agent_interface (error, store_result1)
            in
            (*-----------------------------------------------------------------------*)
            let error, map2 = 
              Site_map_and_set.Map.fold
                (fun site port (error, store_result) ->
                  let state = port.site_state.max in
                  if agent_id = agent_index2 && state > 0
                  then
                    add_link rule_id (agent2, site2, state) store_result
                  else
                    error, store_result
                ) agent.agent_interface (error, store_result2)
            in
            error, (map1, map2)
          ) (error, store_result) rule.actions.bind
      ) rule.rule_rhs.views store_result
  in
  (*-----------------------------------------------------------------------*)
  let store_result1 = 
    Int2Map_syn.Map.map (fun (l, x) -> List.rev l, x) store_result1
  in
  let store_result2 = 
    Int2Map_syn.Map.map (fun (l, x) -> List.rev l, x) store_result2
  in
  error, (store_result1, store_result2)*)

(************************************************************************************)
(*TODO*)

let compute_contact_map parameter error rule store_result =
  let add_link set1 set2 store_result =
    let error, old =
      match Int2Map_CM_Syntactic.Map.find_option set1 store_result with
      | None -> error, Set_triple.Set.empty
      | Some s -> error, s
    in
    let union_set = Set_triple.Set.union set2 old in
    let store_result =
      Int2Map_CM_Syntactic.Map.add set1 union_set store_result
    in
    error, store_result
  in
  List.fold_left (fun (error, store_result) (site_add1, site_add2) ->
    let agent_index1 = site_add1.agent_index in
    let agent_type1 = site_add1.agent_type in
    let site1 = site_add1.site in
    let agent_type2 = site_add2.agent_type in
    let site2 = site_add2.site in
    let agent_index2 = site_add2.agent_index in
    (*find state for each agent*)
    let error, agent1 =
      match AgentMap.get parameter error agent_index1 rule.rule_rhs.views
      with
      | error, None -> warn parameter error (Some "line 141") Exit Ghost
      | error, Some agent -> error, agent
    in
    let error, agent2 =
      match AgentMap.get parameter error agent_index2 rule.rule_rhs.views
      with
      | error, None -> warn parameter error (Some "line 147") Exit Ghost
      | error, Some agent -> error, agent
    in
    match agent1, agent2 with
    | Unknown_agent _, Unknown_agent _ | Dead_agent _, Dead_agent _ ->
      warn parameter error (Some "line 152") Exit store_result
    | (Agent _, (Ghost|Dead_agent _|Unknown_agent _))
    | (Ghost, (Agent _|Dead_agent _|Unknown_agent _))
    | (Dead_agent _, (Ghost|Agent _|Unknown_agent _))
    | (Unknown_agent _, (Ghost|Agent _|Dead_agent _))
    | Ghost, Ghost -> error, store_result
    | Agent agent1, Agent agent2 ->
    let error, set1 =
      Site_map_and_set.Map.fold
        (fun _ port1 (error, store_result) ->
          let state1 = port1.site_state.max in
          if state1 > 0
          then
            let set = Set_triple.Set.add (agent_type1, site1, state1) store_result in
            error, set
          else
            error, store_result
        ) agent1.agent_interface (error, Set_triple.Set.empty)
    in
    let error, set2 =
      Site_map_and_set.Map.fold
        (fun _ port2 (error, store_result) ->
          let state2 = port2.site_state.max in
          if state2 > 0
          then
            let set = Set_triple.Set.add (agent_type2, site2, state2) store_result in
            error, set
          else
            error, store_result
        ) agent2.agent_interface (error, Set_triple.Set.empty)
    in
    let error, store_result =
      add_link set1 set2 store_result
    in
    error, store_result
  ) (error, store_result) rule.actions.bind      

(************************************************************************************)
(*get the binding in initial state*)

(*TODO*)
let collect_init_map parameter error compiled store_result =
  let add_link set1 set2 store_result =
    let error, old =
      match Int2Map_CM_Syntactic.Map.find_option set1 store_result with
      | None -> error, Set_triple.Set.empty
      | Some s -> error, s
    in
    let union_set = Set_triple.Set.union set2 old in
    let store_result =
      Int2Map_CM_Syntactic.Map.add set1 union_set store_result
    in
    error, store_result
  in
  Nearly_inf_Imperatif.fold parameter error
    (fun parameter error index init store_result ->
      AgentMap.fold parameter error
        (fun parameter error agent_id bonds_map store_result ->
          (*let error, store_result =
            Site_map_and_set.Map.fold
              (fun site_type_source site_add (error, store_result) ->
                (*Move this out*)
                let agent_index_target = site_add.agent_index in
                let agent_type_target = site_add.agent_type in
                let site_type_target = site_add.site in
                let error, agent =
                  match AgentMap.get parameter error agent_id
                    init.e_init_c_mixture.views 
                  with
                  | error, None -> exit 0 
                  | error, Some a -> error, a
                in
                match agent with
                | Ghost | Unknown_agent _
                | Dead_agent _ -> error, store_result
                | Agent agent ->
                  let agent_type_source = agent.agent_name in
                  let port_source =
                    match Site_map_and_set.Map.find_option parameter error site_type_source
                      agent.agent_interface
                    with
                    | error, None -> exit 0
                    | error, Some port -> port
                  in
                  let port_target =
                    match Site_map_and_set.Map.find_option parameter error site_type_target
                      agent.agent_interface
                    with
                    | error, None -> exit 0
                    | error, Some port -> port
                  in
                  (*let error, set =
                    Site_map_and_set.Map.fold
                      (fun _ port (error, store_result) ->
                        let state = port.site_state.max in
                        if state > 0
                        then
                          let error, set = Site_map_and_set.Set.add 
                            parameter error state store_result
                          in                            
                          error, set
                        else 
                          error, store_result
                      ) agent.agent_interface (error, Site_map_and_set.Set.empty)
                  in*)
                  let state_source = port_source.site_state.max in
                  let state_target = port_target.site_state.max in
                  let set1 =
                    Set_triple.Set.add (agent_type_source, site_type_source, state_source)
                  in
                  let set2 =
                    Set_triple.Set.add (agent_type_target, site_type_target, state_target)
                  in
                  let error, store_result =
                    add_link set1 set2 store_result
                  in
                  error, store_result
              ) bonds_map (error, store_result)
          in*)
          error, store_result         
        ) 
        init.e_init_c_mixture.bonds
        store_result
    ) compiled.init store_result

(************************************************************************************)
(*contact map*)

let compute_contact_map_full parameter error handler rule =
  let add_link (agent, site, state) set store_result =
    let old =
      Int2Map_CM_state.Map.find_default Set_triple.Set.empty (agent, site, state)
        store_result
    in
    (*let set = Set_triple.Set.add (agent', site', state') Set_triple.Set.empty in*)
    let union_set = Set_triple.Set.union old set in
    if Set_triple.Set.equal union_set old
    then 
      error, store_result
    else
      let add_map =
        Int2Map_CM_state.Map.add (agent, site, state) union_set store_result
      in
      error, add_map
  in
  (*-----------------------------------------------------------------------*)
  (*folding this solution with the information in dual*)
  let error, store_result =
    Int_storage.Nearly_Inf_Int_Int_Int_storage_Imperatif_Imperatif_Imperatif.fold
      parameter error
      (fun parameter error (agent, (site, state)) (agent', site', state') store_result ->
        let set = Set_triple.Set.add (agent', site', state') Set_triple.Set.empty in
        let error, store_result =
          add_link (agent, site, state) set store_result
	in
	error, store_result
      ) handler.dual Int2Map_CM_state.Map.empty
  in
  error, store_result

(************************************************************************************)

(*let collect_contact_map parameter error rule_id rule handler store_result =
  let add_link rule_id ((agent_type1, site_type1, state1), (agent_type2, site_type2, state2))
      store_result =
    let old = Int2Map_syn.Map.find_default Set_pair.Set.empty rule_id
      store_result
    in
    let set = Set_pair.Set.add
      ((agent_type1, site_type1, state1), (agent_type2, site_type2, state2))
      Set_pair.Set.empty 
    in
    let union_set = Set_pair.Set.union old set in
    (*check if it is a bond that is discovered for the first time*)
    if Set_pair.Set.equal union_set old
    then
      error, false, store_result
    else 
      let store_result = Int2Map_syn.Map.add rule_id union_set store_result in
      error, true, store_result
  in
  (*-----------------------------------------------------------------------*)
  let error, (map1, map2) =
    compute_contact_map_aux
      parameter
      error
      rule_id
      rule
      handler
      (Int2Map_syn.Map.empty, Int2Map_syn.Map.empty)
  in
  (*-----------------------------------------------------------------------*)
  let error, (is_new_bond, store_result) =
    Int2Map_syn.Map.monadic_fold2_sparse parameter error
      (fun parameter error rule_id (_, set1) (_, set2) (b, store_result) ->
        Set_triple.Set.fold (fun (agent_type1, site_type1, state1) 
          (error, (b, store_result)) ->
            Set_triple.Set.fold (fun (agent_type2, site_type2, state2) 
              (error, (b, store_result)) ->
                let error, is_new_bond, store_result =
                  add_link rule_id 
                    ((agent_type1, site_type1, state1), (agent_type2, site_type2, state2))
                    store_result
                in
                error, (is_new_bond, store_result)
            ) set2 (error, (b, store_result))
        ) set1 (error, (b, store_result))
      ) map1 map2 store_result
  in
  error, (is_new_bond, store_result)*)
    
(*****************************************************************************************)
(*compute initial state where there is/are binding agent(s)*)

(*let collect_init_map_aux parameter error compil store_result =
  Nearly_inf_Imperatif.fold parameter error
    (fun parameter error rule_id rule store_result ->
      AgentMap.fold2_common parameter error
        (fun parameter error agent_id agent site_add_map store_result ->
          



        ) rule.e_init_c_mixtire.views rule.e_init_c_mixture.bonds store_result      
    ) compil.init store_result*)


