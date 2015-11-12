(**
   * setMap.ml
   * openkappa
   * Jérôme Feret, projet Abstraction, INRIA Paris-Rocquencourt
   * KaSim
   * Pierre Boutillier, PPS, CNRS - Univ Paris Diderot
   *
   * Creation: 2010, the 7th of July
   * Last modification: 2015, November 3rd
   *
   * This library provides primitives to deal with Set and Maps of of ordered
   * elements, in the fashion of Ocaml's Map; It provides efficient iterators
   *
   * Copyright 2010,2011,2012,2013 Institut National de Recherche en
   * Informatique et en Automatique.
   * Copyright 2015 Havard Medical School
   * All rights reserved.  This file is distributed under the terms of the GNU
   * Library General Public License *)

module type OrderedType =
  sig
    type t
    val compare : t -> t -> int
  end

module type Set =
  sig
    type elt
    type t

    val empty: t
    val is_empty: t -> bool
    val singleton: elt -> t
    val is_singleton: t -> bool

    val add: elt -> t -> t
    val add_safe:  ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> t -> 'error * t 
    val remove: elt -> t -> t
    val remove_safe: ('parameters -> 'error -> string -> string option  -> exn -> 'error) -> 'parameters -> 'error -> elt -> t -> 'error * t 			      
    val split: elt -> t -> (t * bool * t)
    val union: t -> t -> t
    val inter: t -> t -> t
    val minus: t -> t -> t		   
    (** [minus a b] contains elements of [a] that are not in [b] *)
    val diff: t -> t -> t
    (** [diff a b] = [minus (union a b) (inter a b)] *)
  (*  val union_safe: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> t -> t -> 'error * t 
    val inter_safe: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> t -> t -> 'error * t
    val diff_safe:  ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> t -> t -> 'error * t
    val split_safe: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> t -> 'error * ( t * bool * t)*)

    val cardinal: t -> int

    val mem: elt -> t -> bool
    val exists: (elt -> bool) -> t -> bool
    val filter: (elt -> bool) -> t -> t
    val for_all: (elt -> bool) -> t -> bool
    val partition: (elt -> bool) -> t -> t * t

    val compare: t -> t -> int
    val equal: t -> t -> bool
    val subset: t -> t -> bool

    val iter: (elt -> unit) -> t -> unit
    val fold: (elt -> 'a -> 'a) -> t -> 'a -> 'a
    val fold_inv: (elt -> 'a -> 'a) -> t -> 'a -> 'a

    val elements: t -> elt list

    val choose: t -> elt option
    val min_elt: t -> elt option
    val max_elt: t -> elt option
  end

module type Map =
  sig
    type elt
    type set
    type +'a t

    val empty: 'a t
    val is_empty: 'a t -> bool
    val size: 'a t -> int
    val root: 'a t -> (elt * 'a) option
    val max_key: 'a t -> elt option

    val add: elt -> 'a -> 'a t -> 'a t
    val remove: elt -> 'a t -> 'a t
    val pop: elt -> 'a t -> ('a option * 'a t)
    val merge: 'a t -> 'a t -> 'a t
    val min_elt: (elt -> 'a -> bool) -> 'a t -> elt option
    val find_option: elt -> 'a t -> 'a option
    val find_default: 'a -> elt -> 'a t -> 'a
    val find_option_safe: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> elt -> 'a t -> 'error * 'a option
    val find_default_safe: ('parameters -> 'error -> string -> string option -> exn -> 'error) -> 'parameters -> 'error -> 'a -> elt -> 'a t -> 'error * 'a
    val mem:  elt -> 'a t -> bool
    val diff: 'a t -> 'a t -> 'a t * 'a t
    val union: 'a t -> 'a t -> 'a t
    val update: 'a t -> 'a t -> 'a t
    val diff_pred: ('a -> 'a -> bool) -> 'a t -> 'a t -> 'a t * 'a t

    val iter: (elt -> 'a -> unit) -> 'a t -> unit
    val fold: (elt -> 'a -> 'b -> 'b) -> 'a t -> 'b -> 'b
    val monadic_fold2:
      'parameters -> 'method_handler ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'b -> 'c -> ('method_handler * 'c)) ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'c -> ('method_handler * 'c)) ->
      ('parameters -> 'method_handler ->
       elt -> 'b -> 'c -> ('method_handler * 'c)) ->
      'a t -> 'b t -> 'c -> ('method_handler * 'c)
    val monadic_fold2_sparse:
      'parameters -> 'method_handler ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'b -> 'c -> ('method_handler * 'c)) ->
      'a t -> 'b t -> 'c -> ('method_handler * 'c)
    val monadic_iter2_sparse:
      'parameters -> 'method_handler ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'b -> 'method_handler) ->
      'a t -> 'b t -> 'method_handler
    val monadic_fold_restriction:
      'parameters -> 'method_handler ->
      ('parameters -> 'method_handler ->
       elt -> 'a -> 'b -> ('method_handler * 'b)) ->
      set -> 'a t -> 'b -> 'method_handler * 'b

    val mapi: (elt -> 'a -> 'b) -> 'a t -> 'b t
    val map: ('a -> 'b) -> 'a t -> 'b t
    val map2: ('a -> 'a -> 'a) -> 'a t -> 'a t -> 'a t

    val for_all: (elt -> 'a -> bool) -> 'a t -> bool
    val compare: ('a -> 'a -> int) -> 'a t -> 'a t -> int
    val equal: ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
    val bindings : 'a t -> (elt * 'a) list
  end

module type S = sig
    type elt
    module Set : Set with type elt = elt
    module Map : Map with type elt = elt and type set = Set.t
  end

module Make(Ord:OrderedType): S with type elt = Ord.t =
  struct
    type elt = Ord.t

    module Set =
      struct
	type elt = Ord.t
	module Private :
	sig
	  type t = private Empty | Node of t * elt * t * int

	  val empty : t
	  val height : t -> int
	  val node : t -> elt -> t -> t
	end = struct
	    type t = Empty | Node of t * elt * t * int
	    let empty = Empty
 	    let height = function
              | Empty -> 0
              | Node(_,_,_,h) -> h
	    let node left value right =
	      Node(left,value,right,(max (height left) (height right))+1)
	  end

	type t = Private.t
	let empty = Private.empty
	let height = Private.height
	let node = Private.node

	let is_empty = function Private.Empty -> true | Private.Node _ -> false
	let singleton value = node empty value empty
	let is_singleton set =
	  match set with
            Private.Empty -> false
          | Private.Node (set1,_,set2,_) -> is_empty set1 && is_empty set2

	let rec cardinal = function
	  | Private.Empty -> 0
	  | Private.Node(left,_,right,_) -> cardinal left + 1 + cardinal right

        let balance_safe warn parameters error left value right =
	  let height_left = height left in
	  let height_right = height right in
	  if height_left > height_right + 2 then begin
              match left with
              | Private.Empty ->
		   let error = warn parameters error "setMap.ml" (Some "balance_set,line 94") (invalid_arg "Set_and_map.balance_set") in
		   error,empty
              | Private.Node(leftleft,leftvalue,leftright,_) ->
		 if height leftleft >= height leftright then
		   error,node leftleft leftvalue (node leftright value right)
		 else begin
		     match leftright with
                     | Private.Empty ->
			let error = warn parameters error "setMap.ml" (Some "balance_set,line 100") (invalid_arg "Set_and_Map.balance_set") in
			error,empty
                     | Private.Node(leftrightleft,leftrightvalue,leftrightright,_) ->
			(error,
			 node
			   (node leftleft leftvalue leftrightleft)
			   leftrightvalue
			   (node leftrightright value right))
		   end
	    end else if height_right > height_left + 2 then begin
              match right with
              | Private.Empty ->
		 let error = warn parameters error "setMap.ml" (Some  "balance_set,line 110") (invalid_arg "Set_and_Map.balance_set") in
		 error,empty
              | Private.Node (rightleft,rightvalue,rightright,_) ->
		 if height rightright >= height rightleft then
		   error,node (node left value rightleft) rightvalue rightright
		 else begin
              match rightleft with
              | Private.Empty ->
		 let error = warn parameters error "setMap.ml"
				  (Some "balance_set,line 116") (invalid_arg "Set_and_Map.balance_set") in
		 error,empty
              | Private.Node(rightleftleft,rightleftvalue,rightleftright,_) ->
                 error,node
                      (node left value rightleftleft)
                      rightleftvalue (node rightleftright rightvalue rightright)
		   end
	    end
	  else
            error,node left value right

	let balance left value right =
	  let height_left = height left in
	  let height_right = height right in
	  if height_left > height_right + 2 then
            match left with
            | Private.Empty ->
	       assert false (* height_left > height_right + 2 >= 2 *)
            | Private.Node(leftleft,leftvalue,leftright,_) ->
	       if height leftleft >= height leftright then
		 node leftleft leftvalue (node leftright value right)
	       else
		 match leftright with
                 | Private.Empty ->
		    assert false (* 0 <= height leftleft < height leftright *)
                 | Private.Node(leftrightleft,leftrightvalue,leftrightright,_) ->
		    node
		      (node leftleft leftvalue leftrightleft)
		      leftrightvalue
		      (node leftrightright value right)
	  else if height_right > height_left + 2 then
            match right with
            | Private.Empty ->
	       assert false (* height_right > height_left + 2 >= 2 *)
            | Private.Node(rightleft,rightvalue,rightright,_) ->
	       if height rightright >= height rightleft then
		 node (node left value rightleft) rightvalue rightright
	       else
		 match rightleft with
                 | Private.Empty ->
		    assert false (* 0 <= height rightright < height rightleft *)
                 | Private.Node(rightleftleft,rightleftvalue,rightleftright,_) ->
		    node
		      (node left value rightleftleft)
		      rightleftvalue
		      (node rightleftright rightvalue rightright)
	  else node left value right

	let rec add x = function
	  | Private.Empty -> singleton x
	  | Private.Node(l, v, r, _) as t ->
	     let c = Ord.compare x v in
	     if c = 0 then t else
	       if c < 0
	       then let o = add x l in if o == l then t else balance o v r
	       else let o = add x r in if o == r then t else balance l v o

	let rec add_safe warn parameters error new_value set =
	  match set with
          | Private.Empty -> error,singleton new_value
          | Private.Node(left,value_set,right,_) ->
          let c = Ord.compare new_value value_set in
          if c = 0 then error,set
          else if c<0 then
            let error', left' = add_safe warn parameters error new_value left in
            balance_safe warn parameters error' left' value_set right
          else
            let error', right' = add_safe warn parameters error new_value right in
            balance_safe warn parameters error' left value_set right'
	let rec join left value right =
	  match left,right with
          | Private.Empty,_ -> add value right
          | _,Private.Empty -> add value left
          | Private.Node(leftleft,leftvalue,leftright,leftheight),
            Private.Node(rightleft,rightvalue,rightright,rightheight) ->
             if leftheight > rightheight + 2 then
               let right' = join leftright value right in
               balance leftleft leftvalue right'
             else if rightheight > leftheight +2 then
               let left' = join left value rightleft in
               balance left' rightvalue rightright
             else node left value right

	let rec safe_extract_min_elt left value right =
	  match left with
	  | Private.Empty -> value,right
	  | Private.Node (leftleft,leftvalue,leftright,_) ->
	     let min,left' =
	       safe_extract_min_elt leftleft leftvalue leftright in
	     min,balance left' value right

	let rec min_elt_safe warn parameters error set  =
	  match set with
	  | Private.Empty ->
	     let error = warn parameters error "setMap.ml" (Some "min_elt_safe, line 303") Not_found in
	     error,None
	  | Private.Node(Private.Empty,v,_,_) -> error,Some v
	  | Private.Node(left,_,_,_) -> min_elt_safe warn parameters error left

	let rec remove_min_elt_safe warn parameters error set =
	  match set with
          | Private.Empty ->
	     let error = warn parameters error "setMap.ml" (Some "remove_min_elt_safe, line 311") Not_found in
	     error,empty
          | Private.Node(Private.Empty,_,right,_) -> error,right
          | Private.Node(left,value,right,_) ->
             let error, left' = remove_min_elt_safe warn parameters error left in
             balance_safe warn parameters error left' value right

	let merge set1 set2 =
	  match set1,set2 with
          | Private.Empty,_ -> set2
          | _,Private.Empty -> set1
          | Private.Node _, Private.Node (left2,value2,right2,_) ->
             let min2,set2' = safe_extract_min_elt left2 value2 right2 in
             balance set1 min2 set2'

	let merge_safe warn parameters error set1 set2 =
	  match set1,set2 with
          | Private.Empty,_ -> error,set2
	  | _,Private.Empty -> error,set1
	  | Private.Node _, Private.Node _ ->
             let error,left2 = remove_min_elt_safe warn parameters error set2 in
	     let error,elt_opt = min_elt_safe warn parameters error set2 in
	     begin
	       match
		 elt_opt
	       with
	       | None ->
		  let error = warn parameters error "setMap.ml" (Some "merge_sage,line 339") Not_found in
		  error,set1
	       | Some elt ->
		  balance_safe warn parameters error set1 elt left2
	     end
	let concat set1 set2 =
	  match set1,set2 with
	  |   Private.Empty,_ -> set2
	  | _,Private.Empty -> set1
	  | Private.Node _, Private.Node (left2,value2,right2,_) ->
             let min2,set2' = safe_extract_min_elt left2 value2 right2 in
             join set1 min2 set2'

	let rec remove value = function
          | Private.Empty as set -> set
          | Private.Node(left,value_set,right,_) as set ->
             let c = Ord.compare value value_set in
             if c = 0 then merge left right
             else if c < 0 then
	       let left' = remove value left in
	       if left == left' then set else balance left' value_set right
             else
	       let right' = remove value right in
	       if right == right' then set else balance left value_set right'

	let rec remove_safe warn parameters error value set =
	  match set with
	  | Private.Empty -> error,empty
          | Private.Node(left,value_set,right,_) ->
             let c = Ord.compare value value_set in
             if c = 0 then merge_safe warn parameters error left right
	     else if c < 0 then
            let error, left' = remove_safe warn parameters error value left in
            balance_safe warn parameters error left' value_set right
          else
            let error, right' = remove_safe warn parameters error value right in
            balance_safe warn parameters error left value_set right'

	let rec split split_value set =
	  match set with
          | Private.Empty -> (empty,false,empty)
          | Private.Node(left,set_value,right,_) ->
             let c = Ord.compare split_value set_value in
             if c=0 then (left,true,right)
             else if c<0 then
               let (leftleft,bool,rightleft) = split split_value left in
               let rightright = join rightleft set_value right in
               (leftleft,bool,rightright)
             else
               let (leftright,bool,rightright) = split split_value right in
               let leftleft = join left set_value leftright in
               (leftleft,bool,rightright)

	let rec union set1 set2 =
	  match set1,set2 with
          | Private.Empty,_ -> set2
          | _,Private.Empty -> set1
          | Private.Node(left1,value1,right1,height1),
	    Private.Node(left2,value2,right2,height2) ->
             if height1 > height2 then
               if height2 = 1 then add value2 set1
               else
		 let (left2,_,right2) = split value1 set2 in
		 let left' = union left1 left2 in
		 let right' = union right1 right2 in
		 join left' value1 right'
             else
               if height1 = 1 then add value1 set2
               else
		 let (left1,_,right1) = split value2 set1 in
		 let left' = union left1 left2 in
		 let right' = union right1 right2 in
		 join left' value2 right'

	let suture (left1,value1,right1) (left2,bool,right2) f =
	  let left' = f left1 left2 in
	  let right' = f right1 right2 in
	  if bool then join left' value1 right' else concat left' right'

	let suture_not (left1,value1,right1) (left2,bool,right2) f =
	  let left' = f left1 left2 in
	  let right' = f right1 right2 in
	  if bool then concat left' right' else join left' value1 right'

	let rec inter set1 set2 =
	  match set1,set2 with
          | Private.Empty,_
          | _,Private.Empty -> empty
          | Private.Node(left1,value1,right1,_),_ ->
             let triple2 = split value1 set2 in
             suture (left1,value1,right1) triple2 inter

	let rec diff set1 set2 =
	  match set1,set2 with
	  | Private.Empty,_ -> set2
	  | _,Private.Empty -> set1
	  | Private.Node(left1,value1,right1,_),_ ->
             let triple2 = split value1 set2 in
             suture_not (left1,value1,right1) triple2 diff

	let rec minus set1 set2 =
	  match set1,set2 with
	  | Private.Empty,_ -> empty
	  | _,Private.Empty -> set1
	  | Private.Node(left1,value1,right1,_),_ ->
             let triple2 = split value1 set2 in
             suture_not (left1,value1,right1) triple2 minus

	let rec mem searched_value = function
          | Private.Empty -> false
          | Private.Node(left,set_value,right,_) ->
             let c = Ord.compare searched_value set_value in
             c==0 || mem searched_value (if c < 0 then left else right)

	let filter p set =
	  let rec filt accu = function
            | Private.Empty -> accu
            | Private.Node(left,value,right,_) ->
               filt (filt (if p value then add value accu else accu) left) right
	  in filt empty set

	let partition p set =
	  let rec part (t,f as accu) = function
            | Private.Empty -> accu
            | Private.Node(left,value,right,_) ->
               part
		 (part
                    (if p value then add value t,f else t,add value f)
                    left)
		 right
	  in part (empty,empty) set

	type enumeration = End | More of elt * t * enumeration

	let rec cons_enum enum = function
          | Private.Empty -> enum
          | Private.Node(left,value,right,_) ->
	     cons_enum (More(value,right,enum)) left

	let rec compare_aux e1 e2 =
	  match e1,e2 with
          | End,End -> 0
          | End,_ -> -1
          | _ , End -> 1
          | More(v1,r1,e1),More(v2,r2,e2) ->
             let c = Ord.compare v1 v2 in
             if c<>0 then c
             else compare_aux (cons_enum e1 r1) (cons_enum e2 r2)

	let compare set1 set2 =
	  compare_aux (cons_enum End set1) (cons_enum End set2)

	let equal set1 set2 = compare set1 set2 == 0

	let rec subset set1 set2 =
	  match set1,set2 with
	  | Private.Empty,_ -> true
	  | _,Private.Empty -> false
	  | Private.Node(left1,value1,right1,_),
	    Private.Node(left2,value2,right2,_) ->
             let c = Ord.compare value1 value2 in
             if c=0 then
               subset left1 left2 && subset right1 right2
             else if c < 0 then
               subset (node left1 value1 empty) left2 && subset right1 set2
             else
               subset (node empty value1 right1) right2 && subset left1 set2

	let rec iter f = function
	  | Private.Empty -> ()
	  | Private.Node(left,value,right,_) ->
             let () = iter f left in let () = f value in iter f right

	let rec fold f set accu =
	  match set with
	  | Private.Empty -> accu
	  | Private.Node(left,value,right,_) ->
	     fold f right (f value (fold f left accu))

	let rec fold_inv f s accu =
	  match s with
            Private.Empty -> accu
	  | Private.Node(l, v, r, _) -> fold_inv f l (f v (fold_inv f r accu))

	let rec for_all p = function
	  | Private.Empty -> true
	  | Private.Node(left,value,right,_) ->
	     p value && for_all p left && for_all p right

	let rec exists p = function
	  | Private.Empty -> false
	  | Private.Node(left,value,right,_) ->
	     p value || exists p left || exists p right

	let elements set =
	  let rec elements_aux accu = function
            | Private.Empty -> accu
            | Private.Node(left,value,right,_) ->
	       elements_aux (value::(elements_aux accu right)) left
	  in elements_aux [] set

	let rec min_elt = function
	  | Private.Empty -> None
	  | Private.Node(Private.Empty,v,_,_) -> Some v
	  | Private.Node(left,_,_,_) -> min_elt left
	let rec max_elt = function
	  | Private.Empty -> None
	  | Private.Node(_,v,Private.Empty,_) -> Some v
	  | Private.Node(_,_,right,_) -> max_elt right
	let choose = (* function
	  | Private.Empty -> None
	  | Private.Node (_,v,_,_) -> Some v *) min_elt
      end

    (************************************************************************************)
    (* Map implementation*)

    module Map =
      struct
	type elt = Ord.t
	module Private :
	sig
	  type +'data t = private
		       | Empty
		       | Node of 'data t * elt * 'data * 'data t * int * int

	  val empty : 'a t
	  val height : 'a t -> int
	  val size : 'a t -> int
	  val node : 'a t -> elt -> 'a -> 'a t -> 'a t
	end = struct
	    type +'data t =
	      | Empty
	      | Node of 'data t * elt * 'data * 'data t * int * int

	    let empty = Empty
	    let height = function
              | Empty -> 0
              | Node(_,_,_,_,h,_) -> h
	    let size = function
              | Empty -> 0
              | Node(_,_,_,_,_,s) -> s
	    let node left key0 data right  =
	      Node (left,key0,data,right, 1 + max (height left) (height right),
		    1 + size left + size right)
	  end

	type +'a t = 'a Private.t
	let empty = Private.empty
	let height = Private.height
	let size = Private.size
	let node = Private.node

	type set = Set.t

	let is_empty = function Private.Empty -> true | Private.Node _ -> false

	let root = function
	  | Private.Empty -> None
	  | Private.Node (_,x,d,_,_,_) -> Some (x,d)

	let rec max_key = function
	  | Private.Empty -> None
	  | Private.Node (_,k,_,Private.Empty,_,_) -> Some k
	  | Private.Node (_,_,_,m,_,_) -> max_key m

	let balance left key data right =
	  let height_left = height left in
	  let height_right = height right in
	  if height_left > height_right + 2 then
	    match left with
            | Private.Empty ->
	       assert false (* height_left > height_right + 2 >= 2 *)
            | Private.Node (left0,key0,data0,right0,_,_) ->
               if height left0 >= height right0 then
		 node left0 key0 data0 (node right0 key data right)
               else
		 match right0 with
		 | Private.Empty ->
		    assert false (* 0 <= height left0 < height right0 *)
		 | Private.Node (left1,key1,data1,right1,_,_) ->
                    node (node left0 key0 data0 left1)
			 key1 data1
			 (node right1 key data right)
	  else
            if height_right > height_left + 2 then
              match right with
              | Private.Empty ->
		 assert false (* height_right > height_left + 2 >= 2 *)
              | Private.Node (left0,key0,data0,right0,_,_) ->
		 if height right0 >= height left0 then
		   node (node left key data left0) key0 data0 right0
		 else
		   match left0 with
		   | Private.Empty ->
		      assert false (* 0 <= height right0 < height left0 *)
		   | Private.Node (left1,key1,data1,right1,_,_) ->
                      node (node left key data left1)
			   key1 data1
			   (node right1 key0 data0 right0)
            else node left key data right

	let rec add key data = function
	  | Private.Empty -> node empty key data empty
	  | Private.Node (left,key_map,data_map,right,_,_) ->
             let cmp = Ord.compare key key_map in
             if cmp = 0 then node left key_map data right
             else if cmp < 0 then
	       balance (add key data left) key_map data_map right
             else balance left key_map data_map (add key data right)

	let rec extract_min_binding map key data map' =
	  match map with
	  | Private.Empty -> (key,data),map'
	  | Private.Node (left2,key2,data2,right2,_,_) ->
             let min, left' = extract_min_binding left2 key2 data2 right2 in
             min,balance left' key data map'

	let merge map1 map2 =
	  match map1 with
	  | Private.Empty -> map2
	  | Private.Node _ ->
             match map2 with
             | Private.Empty -> map1
             | Private.Node(left2,key2,data2,right2,_,_) ->
		let (key3,data3), left' =
		  extract_min_binding left2 key2 data2 right2 in
		balance map1 key3 data3 left'

	let rec remove key = function
	  | Private.Empty -> empty
	  | Private.Node (left,key_map,data,right,_,_) ->
             let cmp = Ord.compare key key_map in
             if cmp = 0 then merge left right
             else if cmp < 0 then balance (remove key left) key_map data right
             else balance left key_map data (remove key right)

	let rec pop x = function
	  | Private.Empty as m -> (None, m)
	  | Private.Node(l, v, d, r, _,_) as m ->
	    let c = Ord.compare x v in
	    if c = 0 then
	      (Some d,merge l r)
	    else if c < 0 then
	      match pop x l with
	      | None as o, _ -> (o, m)
	      | Some _ as o, t -> (o, balance t v d r)
	    else
	      match pop x r with
	      | None as o, _ -> (o, m)
	      | Some _ as o, t -> (o, balance l v d t)

	let rec join left key value right =
	  match balance left key value right with
          | Private.Empty -> assert false (* By case analysis *)
          | Private.Node (left2,key2,data2,right2,_,_) as map2 ->
             let h = height left2 - height right2 in
             if h > 2 || h< -2 then join left2 key2 data2 right2 else map2

	let rec split value = function
	  | Private.Empty -> (empty,None,empty)
	  | Private.Node (left1,key1,data1,right1,_,_) ->
             let cmp = Ord.compare value key1 in
             if cmp = 0 then (left1,Some data1,right1)
             else if cmp < 0 then
               let (left2,data2,right2) = split value left1 in
               let right2' = join right2 key1 data1 right1 in
               (left2,data2,right2')
             else
               let (left2,data2,right2) = split value right1 in
               let left2' = join left1 key1 data1 left2 in
               (left2',data2,right2)

	let rec diff map1 map2 =
	  match map1 with
	  | Private.Empty -> empty,map2
	  | Private.Node(left1,key1,data1,right1,_,_) ->
             let left2,data2,right2 = split key1 map2 in
             let oleft1,oleft2 = diff left1 left2 in
             let oright1,oright2 = diff right1 right2 in
             match data2 with
             | Some x when x = data1 ->
		merge oleft1 oright1, merge oleft2 oright2
             | Some data2  ->
		join oleft1 key1 data1 oright1, join oleft2 key1 data2 oright2
             | None ->
		join oleft1 key1 data1 oright1, merge oleft2 oright2

	let rec union map1 map2 =
	  match map1, map2 with
          | Private.Empty, _ -> map2
          | _, Private.Empty -> map1
          | Private.Node (left1, value1, data1, right1, height1,_),
            Private.Node (left2, value2, data2, right2, height2,_) ->
             if height1 >= height2 then
	       let left2, op_data2, right2 = split value1 map2 in
	       join (union left1 left2)
		    value1 (match op_data2 with None -> data1 | Some d2 -> d2)
		    (union right1 right2)
             else
	       let left1, op_data1, right1 = split value2 map1 in
	       join (union left1 left2)
		    value1 (match op_data1 with None -> data2 | Some d1 -> d1)
		    (union right1 right2)

	let rec update map1 map2 =
	  if map1==map2 then map2
	  else
            match map1 with
            | Private.Empty -> map2
            | Private.Node(left1,key1,data1,right1,_,_) ->
               let left2,data2,right2 = split key1 map2 in
               join (update left1 left2)
		    key1 (match data2 with None -> data1 | Some d2 -> d2)
		    (update right1 right2)

	let rec diff_pred pred map1 map2 =
	  match map1 with
          | Private.Empty -> empty,map2
          | Private.Node(left1,key1,data1,right1,_,_) ->
             let left2,data2,right2 = split key1 map2 in
             let oleft1,oleft2 = diff_pred pred left1 left2 in
             let oright1,oright2 = diff_pred pred right1 right2 in
             match data2 with
             | Some x when pred x data1 ->
                merge oleft1 oright1, merge oleft2 oright2
             | Some data2  ->
                join oleft1 key1 data1 oright1, join oleft2 key1 data2 oright2
             | None ->
                join oleft1 key1 data1 oright1, merge oleft2 oright2

	let rec min_elt p = function
          | Private.Empty -> None
          | Private.Node(left,key,data,right,_,_) ->
             match min_elt p left with
             | None -> if p key data then Some key else min_elt p right
             | some -> some

	let rec find_option key = function
	  | Private.Empty -> None
	  | Private.Node (left,key_map,data,right,_,_) ->
             let cmp = Ord.compare key key_map in
             if cmp = 0 then Some data
	     else find_option key (if cmp<0 then left else right)

	let rec find_default d key = function
	  | Private.Empty -> d
	  | Private.Node (left,key_map,data,right,_,_) ->
             let cmp = Ord.compare key key_map in
             if cmp = 0 then data
             else find_default d key (if cmp<0 then left else right)

	let rec find_option_safe warn parameter error key = function
	  | Private.Empty ->
	     let error = warn parameter error "setMap.ml" (Some "line 659") Not_found in
	     error,None
	  | Private.Node (left,key_map,data,right,_,_) ->
             let cmp = Ord.compare key key_map in
             if cmp = 0 then (error,Some data)
	     else find_option_safe warn parameter error key (if cmp<0 then left else right)


	let rec find_default_safe warn parameter error d key = function
	  | Private.Empty ->
	     let error = warn parameter error "setMap.ml" (Some "line 669") Not_found in
	     error,d
	  | Private.Node (left,key_map,data,right,_,_) ->
             let cmp = Ord.compare key key_map in
             if cmp = 0 then error,data
             else find_default_safe warn parameter error d key (if cmp<0 then left else right)

	let rec mem key = function
          | Private.Empty -> false
          | Private.Node (left,key_map,_,right,_,_) ->
             let cmp = Ord.compare key key_map in
             cmp == 0 ||
	       if cmp>0 then mem key right else mem key left

	let rec iter f = function
          | Private.Empty -> ()
          | Private.Node(left,key,data,right,_,_) ->
             let () = iter f left in let () = f key data in iter f right

	let rec fold f map value =
	  match map with
          | Private.Empty -> value
          | Private.Node(left,key,data,right,_,_) ->
             fold f right (f key data (fold f left value))

	let rec monadic_fold param err f map value =
	  match map with
	  | Private.Empty -> err,value
	  | Private.Node(left,key,data,right,_,_) ->
	     let err',value' = monadic_fold param err f left value in
	     let err'',value'' = f param err' key data value' in
	     monadic_fold param err'' f right value''

	let rec monadic_fold2 parameters rh f g h map1 map2 res =
	  match map1,map2 with
          | Private.Empty,Private.Empty -> rh,res
          | Private.Empty , _ -> monadic_fold parameters rh h map2 res
	  | _ , Private.Empty -> monadic_fold parameters rh g map1 res
          | Private.Node(left1,key1,data1,right1,_,_),_ ->
             let (left2,data2,right2) = split key1 map2 in
             match data2 with
             | None ->
		let rh', res' =
		  monadic_fold2 parameters rh f g h left1 left2 res in
                let rh'',res'' = g parameters rh' key1 data1 res' in
                monadic_fold2 parameters rh'' f g h right1 right2 res''
             | Some data2 ->
                let rh', res' = monadic_fold2 parameters rh f g h left1 left2 res in
                let rh'',res'' = f parameters rh' key1 data1 data2 res' in
                monadic_fold2 parameters rh'' f g h right1 right2 res''

	let monadic_fold2_sparse parameters rh f map1 map2 res =
	  let id _ x _ _ y = (x,y) in
	  monadic_fold2 parameters rh f id id map1 map2 res

	let monadic_iter2_sparse parameters rh f map1 map2 =
	  let error,() =
	    monadic_fold2_sparse
	      parameters rh
	      (fun p e k a b () -> (f p e k a b,())) map1 map2 () in
	  error

	let rec monadic_fold_restriction parameters rh f set map res =
	  match set with
	  | Set.Private.Empty -> rh,res
	  | Set.Private.Node(left1,key1,right1,_) ->
             let left2,data2,right2 = split key1 map in
             match data2 with
             | None ->
		let rh', res' =
		  monadic_fold_restriction parameters rh f left1 left2 res in
		monadic_fold_restriction parameters rh' f right1 right2 res'
             | Some data2 ->
		let rh', res' =
		  monadic_fold_restriction parameters rh f left1 left2 res in
		let rh'',res'' = f parameters rh' key1 data2 res' in
		monadic_fold_restriction parameters rh'' f right1 right2 res''

	let rec mapi f = function
	  | Private.Empty -> empty
	  | Private.Node(left,key,data,right,_,_) ->
             node (mapi f left) key (f key data) (mapi f right)

	let map f s = mapi (fun _ x -> f x) s

	let rec map2 f map map' =
	  match map with
	  | Private.Empty -> map'
	  | Private.Node(left1,key1,data1,right1,_,_) ->
             let left2,data2,right2 = split key1 map' in
             join (map2 f left1 left2)
		  key1 (match data2 with None -> data1 | Some d2 -> f data1 d2)
		  (map2 f right1 right2)

	let rec for_all p = function
          | Private.Empty -> true
          | Private.Node(left,key,data,right,_,_) ->
             p key data && for_all p right && for_all p left

	type 'a enumeration = End | More of elt * 'a * 'a t * 'a enumeration

	let rec cons_enum m e =
	  match m with
	    Private.Empty -> e
	  | Private.Node(l, v, d, r, _,_) -> cons_enum l (More(v, d, r, e))

	let compare cmp m1 m2 =
	  let rec compare_aux e1 e2 =
	    match (e1, e2) with
	      (End, End) -> 0
	    | (End, _) -> - 1
	    | (_, End) -> 1
	    | (More(v1, d1, r1, e1), More(v2, d2, r2, e2)) ->
	      let c = Ord.compare v1 v2 in
	      if c <> 0 then c else
		let c = cmp d1 d2 in
		if c <> 0 then c else
		  compare_aux (cons_enum r1 e1) (cons_enum r2 e2)
	  in compare_aux (cons_enum m1 End) (cons_enum m2 End)

	let equal cmp m1 m2 =
	  compare (fun x y -> if cmp x y then 0 else 1) m1 m2 == 0

	let rec bindings_aux accu = function
	  | Private.Empty -> accu
	  | Private.Node (l, v, d, r, _,_) ->
	     bindings_aux ((v, d) :: bindings_aux accu r) l

	let bindings s = bindings_aux [] s

	let random m =
	  let s = size m in
	  if s = 0 then raise Not_found
	  else
	    let rec find k m =
	      match m with
		Private.Empty -> failwith "BUG in Map_random.ramdom"
	      | Private.Node (l, key, v, r, _, _) ->
		 if k = 0 then (key, v)
		 else
		   let s = size l in
		   if k <= s then find (k - 1) l
		   else find (k - s - 1) r
	    in
	    find (Random.int (size m)) m
      end
  end
