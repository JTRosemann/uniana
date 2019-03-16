Require Import Coq.Classes.EquivDec.
Require Import Coq.Classes.RelationClasses.
Require Import Coq.Bool.Bool.
Require Import Coq.Logic.Eqdep.
Require Import Coq.Logic.Eqdep_dec.
Require Import Coq.Logic.Decidable.
Require Import Coq.Program.Equality.
Require Import Coq.Program.Utils.
Require Import Lists.ListSet.
Require Import List.
Require Import Nat.
Require Import Omega.

Require Import Disjoint Unchanged.

Section uniana.

  Context `(C : redCFG).    
  
  (** definitions **)
  Parameter branch: Lab -> option Var.

  Definition is_branch br x := branch br = Some x.

  Parameter val_true : Val -> bool.

  Parameter branch_spec :
    forall p, match branch p with
         | Some x => exists q q', q <> q' /\ forall s,
                        if val_true (s x)
                        then exists r, eff' (p,s) = Some (q, r)
                        else exists r', eff' (p,s) = Some (q',r')                                
         | None => forall q q', p --> q -> p --> q' -> q = q'
         end.

  Parameter root_no_pred' : forall p, p --> root -> False.

  (* not used:
    Parameter init_uni : Var -> Prop.
   *)

  Definition UniState := Var -> bool.
  
  Parameter abs_uni_eff : UniState -> UniState.

  Definition uni_state_concr (uni : UniState) : State -> State -> Prop :=
    fun s => fun s' => forall x, uni x = true -> s x = s' x.

  Parameter local_uni_corr : forall uni p i q j s s' qs qs', 
      uni_state_concr uni s s' ->
      eff (p, i, s) = Some (q, j, qs) ->
      eff (p, i, s') = Some (q, j, qs') ->
      uni_state_concr (abs_uni_eff uni) qs qs'.

  Definition Uni := Lab -> Var -> bool.

  Definition uni_concr (u : Uni) : Hyper :=
    fun ts => forall t t', ts t -> ts t' ->
                   forall x p i s s', In (p, i, s) (`t) ->
                                 In (p, i, s') (`t') ->
                                 u p x = true -> s x = s' x.

  Definition uni_branch (uni : Uni) :=
    (fun s : Lab
     => match (branch s) with
       | Some x => uni s x
       | None => false
       end
    ).
  
  Definition uni_trans (uni : Uni) (unch : Unch) : Uni :=
    fun p
    => if p == root then uni root
      else fun x => (join_andb (map ((uni_branch uni) ∘ fst ∘ fst) (splits p)))
                   (* the predecessor is only included in split set if p is an exit *)
                   && (join_andb (map (fun q => abs_uni_eff (uni q) x) (preds p)))
                 || join_orb (map (fun q => (q <>b p)
                                          && uni q x
                                          && join_andb (map ((uni_branch uni) ∘ fst ∘ fst)
                                                            (rel_splits p q)))
                                 (unch_trans unch p x)).

  Lemma uni_trans_root_inv :
    forall uni unch x, uni_trans uni unch root x = uni root x.
  Proof.
    intros.
    unfold uni_trans.
    destruct (equiv_dec root root).
    reflexivity.
    exfalso. apply c. reflexivity.
  Qed.

  (* unused : 
    Definition sub_traces (ts ts' : Traces) : Prop := forall t, ts t -> exists t', ts' t' /\ Prefix (`t) (`t').

    Lemma uni_concr_sub_traces ts ts' uni
          (Hsub : sub_traces ts ts')
          (Huni : uni_concr uni ts')
      : uni_concr uni ts.
    Proof.
      unfold uni_concr in *. unfold sub_traces in Hsub.
      intros. specialize (Hsub t H) as Hsub1. specialize (Hsub t' H0) as Hsub2. destructH. destructH.
      eapply (Huni t'1 t'0); eauto.
      - eapply in_prefix_in;eauto.
      - eapply in_prefix_in;eauto.
    Qed.
   *)
  
  Lemma uni_branch_uni_succ p br q1 q2 i k j1 j2 s1 s2 uni l1 l2 
        (Hpath1 : Tr ((p,i,s1) :< l1))
        (Hpath2 : Tr ((p,i,s2) :< l2))
        (Hsucc1 : ((p,i) :: map fst l1) ⊢ (q1,j1) ≻ (br,k))
        (Hsucc2 : ((p,i) :: map fst l2) ⊢ (q2,j2) ≻ (br,k))
        (Hunibr : uni_branch uni br = true)
        (HCuni : forall (x : Var) (p : Lab) (i : Tag) (s s' : State),
            (p, i, s) ∈ l1 -> (p, i, s') ∈ l2 -> uni p x = true -> s x = s' x)
    : q1 = q2.
  Proof.
    unfold uni_branch in Hunibr. cbn in Hunibr.
    specialize (branch_spec br) as Hbr.
    destruct (branch br) eqn:E; [|congruence]. destructH.
    replace ((p,i) :: map fst l1) with (map fst ((p,i,s1) :: l1)) in Hsucc1 by (cbn;eauto).
    replace ((p,i) :: map fst l2) with (map fst ((p,i,s2) :: l2)) in Hsucc2 by (cbn;eauto).
    rewrite nlcons_to_list in Hsucc1, Hsucc2.
    eapply2 tr_lift_succ Hsucc1 Hsucc2;eauto. do 2 destructH.
    specialize (HCuni v br k r0 r).
    exploit HCuni.
    1,2: eapply in_succ_in2;simpl_nl' Hsucc1; simpl_nl' Hsucc2;eauto.
    specialize (Hbr1 r0) as Hbr1'.
    specialize (Hbr1 r). 
    destruct (val_true (r0 v)) eqn:Heq1, (val_true (r v)) eqn:Heq2.
    2,3: rewrite HCuni in Heq1; congruence.
    all:do 2 destructH.
    - enough (q1 = q /\ q2 = q) by (subst';eauto).
      split.
      eapply tr_succ_eff' with (s:=s1) (q'0:=q);eauto.
      eapply tr_succ_eff' with (s:=s2) (q'0:=q);eauto.
    - enough (q1 = q' /\ q2 = q') by (subst';eauto).
      split.
      eapply tr_succ_eff' with (s:=s1) (q'0:=q');eauto.
      eapply tr_succ_eff' with (s:=s2) (q'0:=q');eauto.
  Qed.
  
  Lemma uni_branch_uni_succ' p br q1 q2 i k j1 j2 uni l1 l2 s1 s2
        (Hpath1 : Tr ((p,i,s1) :< l1))
        (Hpath2 : Tr ((p,i,s2) :< l2))
        (Hsucc1 : ((p,i) :: map fst l1) ⊢ (q1,j1) ≻ (br,k))
        (Hsucc2 : ((p,i) :: map fst l2) ⊢ (q2,j2) ≻ (br,k))
        (Hunibr : uni_branch uni br = true)
        (HCuni : forall (x : Var) (p : Lab) (i : Tag) (s s' : State),
            (p, i, s) ∈ l1 -> (p, i, s') ∈ l2 -> uni p x = true -> s x = s' x)
    : q1 = q2 /\ j1 = j2.
  Proof.
    assert (q1 = q2) by (eapply uni_branch_uni_succ with (q1:=q1) (l1:=l1) ;eauto).
    split;[eauto|subst].
    eapply eff_tag_det.
    2: eapply succ_in_tpath_eff_tag;[clear Hpath1;spot_path|];eauto;cbn;simpl_nl;
      eauto using succ_in_cons_cons.
    eapply succ_in_tpath_eff_tag;[spot_path|];clear Hpath2 Hsucc2;eauto;cbn;simpl_nl;eauto.
  Qed.
  
  Lemma uni_branch_succ_p p q br i j k s1 s2 r r' l1 l2 l2' uni
        (Htr1 : Tr ((p, i,s1) :<: (q, j,r) :< l1))
        (Htr2 : Tr ((p, i,s2) :<: (br, k,r') :< l2))
        (Hsplit : uni_branch uni br = true)
        (HCuni : forall (x : Var) (p : Lab) (i : Tag) (s s' : State),
            (p, i, s) ∈ ((q, j, r) :: l1) ->
            (p, i, s') ∈ ((br, k, r') :: l2) -> uni p x = true -> s x = s' x)
        (Hpost : Postfix (((q, j) :: l2') :r: (br, k)) ((q, j) :: map fst l1))
    : False.
  Proof.
    destruct (hd (q, j) (rev ((q, j) :: l2'))) eqn:E.
    assert (((q, j) :: map fst l1) ⊢ (l, t) ≻ (br, k)) as Hsucc1.
    {
      eapply postfix_succ_in;eauto.
      rewrite cons_rcons'.
      fold (rcons (rev (tl (rev ((q, j) :: l2'))) :r: hd (q, j) (rev ((q, j) :: l2')))
                  (br, k)).
      rewrite E.
      eapply succ_in_rcons2.
    } 
    eapply uni_branch_uni_succ' with (q1:=l) (q2:=p) (j1:=t) (j2:=i) in HCuni;cbn;eauto.
    * subst'.
      eapply2 tr_tpath_cons2 Htr1 Htr2;eauto.
      eapply tpath_NoDup in Htr1.
      inversion  Htr1. eapply H1. simpl_nl. eapply postfix_incl;eauto. fold (rcons l2' (br,k)).
      eapply In_rcons. right.
      rewrite cons_rcons'. eapply In_rcons. left. eauto.
    * eapply succ_cons. eauto.
    * cbn. eapply succ_in_cons_cons.
  Qed.
  
  Lemma uni_branch_non_disj p i br k s1 s2 l1 l2 l1' l2' uni
        (Hpath1 : Tr ((p,i,s1) :< l1))
        (Hpath2 : Tr ((p,i,s2) :< l2))
        (Hpost1 : Postfix (l1' :>: (br, k)) (map fst l1))
        (Hpost2 : Postfix (l2' :>: (br, k)) (map fst l2))
        (Hdisj : Disjoint l1' l2')
        (Hsplit : uni_branch uni br = true)
        (HCuni : forall (x : Var) (p : Lab) (i : Tag) (s s' : State),
            (p, i, s) ∈ l1 ->
            (p, i, s') ∈ l2 -> uni p x = true -> s x = s' x)
    : False.
  Proof.
    enough (ne_back l1' = ne_back l2').
    - eapply Hdisj.
      + eapply in_ne_back.
      + rewrite <-H; eapply in_ne_back.
    - destruct (ne_back l1') as [q1 j1] eqn:Heq1.
      destruct (ne_back l2') as [q2 j2] eqn:Heq2.
      eapply uni_branch_uni_succ' with (q1:=q1) (q2:=q2) (j1:=j1) (j2:=j2) (l1:=l1) in Hsplit;eauto.
      1: subst';reflexivity.
      1,2: eapply succ_cons; eapply postfix_succ_in;eauto;
        eapply ne_back_E_rcons in Heq1; eapply ne_back_E_rcons in Heq2; destructH; destructH;
          simpl_nl; only 1: rewrite <- Heq1; only 2: rewrite <- Heq2; eapply succ_in_rcons2.
  Qed.
  
  Lemma uni_same_tag p q i j1 j2 s1 s2 r1 r2 uni l1 l2
        (Htr1 : Tr ((p,i,s1) :<: (q,j1,r1) :< l1))
        (Htr2 : Tr ((p,i,s2) :<: (q,j2,r2) :< l2))
        (Hsplit : (join_andb (map ((uni_branch uni) ∘ fst ∘ fst) (splits p))) = true)
        (HCuni : forall (x : Var) (p : Lab) (i : Tag) (s s' : State),
            (p, i, s) ∈ ((q,j1,r1)::l1) ->
            (p, i, s') ∈ ((q,j2,r2)::l2) ->
            uni p x = true -> s x = s' x)
    : j2 = j1.
  Proof.
    decide' (j1 == j2);[reflexivity|exfalso].
    assert (forall s j r l (Htr : Tr ((p, i, s) :<: (q, j, r) :< l)),
               tcfg_edge (q, j) (p, i) = true) as Htcfg.
    {
      clear. intros. 
      eapply Tr_EPath in Htr;[|cbn;eauto]. destructH. eapply EPath_TPath in Htr. cbn in Htr.
      inversion Htr. cbn in H.
      inversion H0;subst; [simpl_nl' H7;destruct l;cbn in H7;[|congruence]|].
      + inversion H7;subst;eauto.
      + simpl_nl' H4; cbn in H4. destruct l; cbn in H4;[congruence|]. inversion H4;subst;eauto.
    }
    copy c Hneq.
    eapply (tag_eq_loop_exit p q i) in c. 2,3: eapply Htcfg;eauto. clear Htcfg.
    eapply tr_lc_lt with (j3:=j1) (j4:=j2) in Htr1 as Hlc;eauto;destructH' Hlc.
    eapply lc_disj_exit_lsplits in c as Hsplits;eauto; cycle 1.
    - spot_path. 
    - spot_path.
    - destructH.
      eapply join_andb_true_iff in Hsplit;eauto;cycle 1.
      {
        rewrite splits_spec. right. left.
        exists (get_innermost_loop q). split;[unfold exited;eauto|].
        rewrite splits'_spec. left. unfold loop_splits__imp.
        eapply loop_splits_impl_invariant;eauto.
      }      
      unfold last_common in Hlc. destructH.
      destruct l1',l2'.
      + cbn in *. eapply2 postfix_hd_eq Hlc0 Hlc2.
        subst'. congruence.
      + cbn in Hlc0.
        destruct p0.
        eapply2' postfix_hd_eq Hlc0 Hlc2 Hlc0' Hlc2'. symmetry in Hlc0'. subst'.
        clear Hlc0 Hlc1 Hlc3 Hlc5.
        eapply uni_branch_succ_p with (j:=j2);eauto. intros;symmetry;eapply HCuni;eauto.
      + cbn in Hlc2.
        destruct p0. 
        eapply2' postfix_hd_eq Hlc0 Hlc2 Hlc0' Hlc2'. subst'.
        clear Hlc2 Hlc1 Hlc3 Hlc5.
        eapply uni_branch_succ_p with (j:=j1);eauto. 
      + eapply (uni_branch_non_disj p i br k _ _
                                    ((q,j1,r1)::l1) ((q,j2,r2)::l2) (p0:<l1') (p1:<l2'));
          cbn;simpl_nl;eauto.
  Qed.

  
  Lemma unch_dom u p x unch (* TODO: this will need a unch_concr assumption *)
        (Hunch : u ∈ unch_trans unch p x)
    : Dom edge root u p.
    unfold unch_trans,unch_trans_ptw in Hunch. unfold unch_trans_local in Hunch.
  Admitted.

  
  Hint Unfold Coord.
  

  Hint Resolve tpath_tpath'.
  Hint Resolve precedes_in.



  
  Lemma find_divergent_branch u p l1 l2 i j1 j2 
        (Hunch : Dom edge root u p)
        (Hprec1 : Precedes fst l1 (u, j1))
        (Hprec2 : Precedes fst l2 (u, j2))
        (Htr1 : TPath (root, start_tag) (p, i) ((p, i) :< l1))
        (Htr2 : TPath (root, start_tag) (p, i) ((p, i) :< l2))
        (Hneq : p <> u)
        (Hjneq : j1 =/= j2)
    : exists br qq qq' : Lab,
      (br, qq, qq') ∈ rel_splits p u /\
      (exists (k k' : Tag) (q1 q2 : Lab),
          l1 ⊢ (q1, k') ≻ (br, k) /\ l2 ⊢ (q2, k') ≻ (br, k) /\ q1 <> q2).
  Proof.
    specialize (ex_near_ancestor u p) as [a [Hanc Ha_near]].
    eapply ancestor_dom1 in Hanc as Hanc1. eapply ancestor_dom2 in Hanc as Hanc2.
    eapply dom_tpath_prec with (l:=(p,i) :< l1) in Hanc2 as Hanc21;eauto. destructH' Hanc21.
    eapply dom_tpath_prec with (l:=(p,i) :< l2) in Hanc2 as Hanc22;eauto. destructH' Hanc22.
    
    assert (j0 = j); [|subst j0].
    {
      eapply ancestor_sym in Hanc;eapply tag_prefix_ancestor in Hanc21 as Ha_pre1;eauto.
      eapply tag_prefix_ancestor in Hanc22 as Ha_pre2; eauto.
      simpl_nl' Hanc21. simpl_nl' Hanc22.
      eapply prec_tpath_tpath in Hanc21;eauto. destructH.
      eapply prec_tpath_tpath in Hanc22;eauto. destructH.
      eapply prefix_length_eq;eauto;eapply tpath_tag_len_eq;eauto.
    }

    enough ((p,i) :: l1 ⊢ (a,j) ≺* (u,j1)) as Hib1.
    enough ((p,i) :: l2 ⊢ (a,j) ≺* (u,j2)) as Hib2.
    2: eapply dom_dom_in_between with (l:= (p,i) :< l2) in Hunch;eauto.
    4: eapply dom_dom_in_between with (l:= (p,i) :< l1) in Hunch;eauto.
    2,4: simpl_nl' Hunch;destruct Hunch;eauto.
    2,3: eapply tpath_NoDup;eauto. 

    assert (Prefix j i) as Hprei by (eapply tag_prefix_ancestor;[eapply ancestor_sym| |];eauto).
    assert (Prefix j j1) as Hprej1
        by (simpl_nl' Hanc21;eapply tag_prefix_ancestor_elem with (l:=l1);eauto).
    assert (Prefix j j2) as Hprej2
        by (simpl_nl' Hanc22;eapply tag_prefix_ancestor_elem with (l:=l2);eauto).

    assert (exists j1', j1 = j1' ++ j) as [j1' Hj1] by (eapply prefix_eq;eauto).
    assert (exists j2', j2 = j2' ++ j) as [j2' Hj2] by (eapply prefix_eq;eauto).

    assert (j1' <> j2') as c'.
    {
      subst j1 j2. intro c'. rewrite c' in Hjneq. eapply Hjneq. reflexivity.
    } 

    eapply Pr_cont with (c:=(p,i)) in Hprec1;[|cbn;eauto].
    eapply Pr_cont with (c:=(p,i)) in Hprec2;[|cbn;eauto].
    (* find the first difference in the tag suffices *)
    eapply first_diff in c'. 
    2,3: intro N; eapply c'; subst;
      eapply precedes_in in Hprec1;eapply precedes_in in Hprec2;
        rewrite nlcons_to_list in Hprec1; rewrite nlcons_to_list in Hprec2;
          eapply tpath_tag_len_eq_elem in Hprec1;eauto;simpl_nl;
            do 2 rewrite app_length in Hprec1;exfalso.
    3:destruct j1';cbn in Hprec1; [congruence|omega]. 
    2:destruct j2';cbn in Hprec1;[congruence|omega].
    rename c' into Htag. destructH.
    subst j1' j2'. rewrite <-app_assoc in Hj1,Hj2. rewrite <-app_comm_cons in Hj1,Hj2.
    (* find the head of the divergent loop *)
    eapply first_occ_tag_elem with (t:=(p,i) :< l1) in Hj1 as Hocc1;eauto;
      simpl_nl;eauto using precedes_in.
    eapply first_occ_tag_elem in Hj2 as Hocc2;eauto;
      simpl_nl;eauto using precedes_in.
    do 2 destructH.
    (* show that it is the same head in both traces *)
    assert (h0 = h);[eapply tag_prefix_same_head_elem
                       with (h1:=h0) (t1:=(p,i):<l1) (j3:=j1) (j4:=j2);
                     eauto;simpl_nl;eauto|subst h0].
    1: eapply tpath_tag_len_eq_elem with (l3:=(p,i):<l1);eauto;simpl_nl;eauto.
    (* find node on ancestor-depth that is between u & p *)
    eapply2 ancestor_level_connector Hanc21 Hanc22.
    4,8: split;[eapply ancestor_sym|];eauto. all: simpl_nl;eauto.
    destruct Hanc21 as [a1' [Hanc21 Hanc11]]. destruct Hanc22 as [a2' [Hanc22 Hanc12]].
    assert (Prefix j (l' ++ j)) as Hexit1.
    { eapply prefix_eq. eexists;reflexivity. }
    copy Hexit1 Hexit2.
    eapply find_loop_exit with (a0:=a1') (n:=a1) (h0:=h) (l:= (p,i):<l1) in Hexit1;eauto.
    eapply find_loop_exit with (a0:=a2') (n:=a2) in Hexit2;eauto.
    2,3: eapply in_before_trans;[eapply tpath_NoDup;eauto|eauto|
                                 unfold in_between in Hanc11,Hanc12; destruct Hanc11,Hanc12;eauto].
    destruct Hexit1 as [qe1 [e1 [Hexit__seq1 [Hexit__succ1 Hexit__edge1]]]].
    destruct Hexit2 as [qe2 [e2 [Hexit__seq2 [Hexit__succ2 Hexit__edge2]]]].

    eapply in_between_in2 in Hexit__seq1 as Hin1.
    eapply in_between_in2 in Hexit__seq2 as Hin2.
    eapply2 path_to_elem Hin1 Hin2; eauto.
    destruct Hin1 as [η1 [Hη1 Hpreη1]]. destruct Hin2 as [η2 [Hη2 Hprenη2]].
    assert (exists brk, last_common η1 η2 brk) as Hlc.
    {
      eapply ne_last_common. clear - Hη1 Hη2. eapply2 path_back Hη1 Hη2.
      rewrite Hη1,Hη2. reflexivity.
    }
    destruct Hlc as [[br k] Hlc].
    enough (η1 = (qe1, a1 :: l' ++ j) :< tl η1) as ηeq1.
    enough (η2 = (qe2, a2 :: l' ++ j) :< tl η2) as ηeq2.
    rewrite ηeq1 in Hlc; rewrite ηeq2 in Hlc.
    2,3: let f := fun Q => clear - Q; inversion Q;subst;cbn;simpl_nl;eauto in
         only 2:f Hη1; f Hη2.
    simpl_nl' Hlc.
    eapply lc_disj_exits_lsplits with (h0:=h) (e3:=e1) (e4:=e2) (i0:=l'++j) in Hlc as Hsplit;eauto.
    all: cycle 1.
    {
      clear - ηeq1 Hη1 Hexit__edge1 Hexit__succ1 Htr1. unfold TPath'. econstructor. cbn.
      + rewrite ηeq1 in Hη1. replace (ne_back (_ :< tl η1)) with (root,start_tag);eauto.
        symmetry. eapply path_back;eauto.
      + eapply succ_in_path_edge;cycle 1;eauto.
    } 
    {
      clear - ηeq2 Hη2 Hexit__edge2 Hexit__succ2 Htr2. unfold TPath'. econstructor. cbn.
      + rewrite ηeq2 in Hη2. replace (ne_back (_ :< tl η2)) with (root,start_tag);eauto.
        symmetry. eapply path_back;eauto.
      + eapply succ_in_path_edge;cycle 1;eauto.
    } 
    destructH.
    exists br, qq, qq';split.
    - eapply rel_splits_spec. exists h.
      eapply in_app_or in Hsplit. destruct Hsplit as [Hsplit|Hsplit].
      + exists e1. split_conj;eauto.
        1,2: unfold exited;eauto.
        * assert (deq_loop u e1) as Hdeq by admit.
          eapply loop_cutting_elem.
          -- spot_path.
          -- admit. (* consequence from some succ & in_before propositions *)
          -- intros h0 Hloop0. eapply Hdeq in Hloop0. eapply exit_cascade in Hunch;eauto.
             ++ contradict Hunch. admit. (* possibly I have to switch to tpath bc they are NoDup *)
             ++ instantiate (1:= map fst l1). clear - Hprec1 Hneq.
                inversion Hprec1;subst;[contradiction|].
                cbn in *. clear Hprec1. induction l1;cbn in *.
                ** inversion H3.
                ** destruct a. decide' (l == u).
                   --- cbn. econstructor.
                   --- econstructor;[cbn;eauto|]. eapply IHl1.
                       inversion H3;subst;[congruence|eauto].
             ++ spot_path.
        * (* something with ancestors *) admit.
      + exists e2. split_conj;eauto.
        1,2: unfold exited;eauto.
        * (* same as *) admit.
        * (*  above  *) admit.           
    - exists k, (l' ++ j).
      destruct η1,η2;cbn in *.
      + cbn in Hlc.
        eapply last_common_singleton1 in Hlc as Hleft.
        eapply last_common_singleton2 in Hlc as Hright.
        inversion Hleft; inversion Hright; subst. congruence.
      + exists e1. (* br = qe1, thus successor is e1, the successor in l2 is in inside the loop,
                 thus they are unequal *) admit.
      + (* analogous to the one above *) admit. 
      + (* because successors are inside the last_common *) admit.
  Admitted.
  
  Lemma unch_same_tag p u i s1 s2 j1 j2 r1 r2 l1 l2 x uni unch
        (Hunibr : join_andb (map ((uni_branch uni) ∘ fst ∘ fst) (rel_splits p u)) = true)
        (Hunch : u ∈ unch_trans unch p x)
        (Hprec1 : Precedes lab_of l1 (u, j1, r1))
        (Hprec2 : Precedes lab_of l2 (u, j2, r2))
        (HCuni : forall (x : Var) (p : Lab) (i : Tag) (s s' : State),
            (p, i, s) ∈ l1 -> (p, i, s') ∈ l2 -> uni p x = true -> s x = s' x)
        (Htr1 : Tr ((p, i, s1) :< l1))
        (Htr2 : Tr ((p, i, s2) :< l2))
        (Hneq : p <> u)
    : j1 = j2.
  Proof.
    assert (forall p i s l (Htr : Tr ((p, i, s) :< l)),
               TPath (root, start_tag) (p, i) ((p, i) :< map fst l)) as Htr_path.
    {
      clear;intros.
      eapply Tr_EPath in Htr;[|simpl_nl;reflexivity]. destructH.
      eapply EPath_TPath' in Htr;simpl_nl;cbn. 2-4: reflexivity. assumption.
    }
    decide' (j1 == j2);[eauto|exfalso].
    eapply find_divergent_branch with (l1:=map fst l1) in c as Hwit;eauto.
    - destructH.
      (*eapply succ_cons in Hwit1. eapply succ_cons in Hwit2.*)
      eapply join_andb_true_iff in Hunibr;eauto. (*rewrite nlcons_to_list in Hwit1,Hwit2.*)
      eapply uni_branch_uni_succ 
        with (q1:=q1) (q2:=q2) (uni:=uni) in HCuni;eauto.
      1,2: eapply succ_cons;eauto.      
    - eapply unch_dom;eauto.
    - eapply prec_lab_prec_fst;eauto.
    - eapply prec_lab_prec_fst;eauto.
      Unshelve. all:eauto.      
  Qed.

  Lemma uni_same_lab p q1 q2 i j1 j2 s1 s2 r1 r2 uni l1 l2
        (Htr1 : Tr ((p,i,s1) :<: (q1,j1,r1) :< l1))
        (Htr2 : Tr ((p,i,s2) :<: (q2,j2,r2) :< l2))
        (Hsplit : (join_andb (map ((uni_branch uni) ∘ fst ∘ fst) (splits p))) = true)
        (HCuni : forall (x : Var) (p : Lab) (i : Tag) (s s' : State),
            (p, i, s) ∈ ((q1,j1,r1)::l1) -> (p, i, s') ∈ ((q2,j2,r2)::l2)
            -> uni p x = true -> s x = s' x)
    : q2 = q1.
  Proof.
    eapply tr_lc_lt in Htr1 as LC_lt;eauto. destructH' LC_lt.
    destruct (q2 == q1) as [ Heq | Hneq ]; [ eauto | exfalso ].
    symmetry in Hneq.
    eapply last_common_sym in LC_lt.
    eapply lc_join_split in LC_lt as LC_join;eauto.
    Unshelve. all:cycle 3. exact p. exact i.
    - destructH.
      unfold last_common in LC_lt. destructH.
      eapply join_andb_true_iff in Hsplit;eauto.
      destruct l1',l2'.
      (* we have l1 = nil -> (br,k) = (q1,j1). but:  l1' = nil <-> (br,k) = (q1,j1) *)
      + cbn in *. eapply2 postfix_hd_eq LC_lt0 LC_lt2.
        subst'. congruence.
      + (* since (br,k) = (q1,j1) & uniform, we have that (p,i) succeeds (br,k) thus
         (p,i) ∈ l2, thus double occurence of the same instance in t2 --> contradiction *)
        cbn in LC_lt0.
        destruct p0.
        eapply2' postfix_hd_eq LC_lt0 LC_lt2 LC_lt0' LC_lt2'. symmetry in LC_lt0'. subst'.
        clear LC_lt0 LC_lt1 LC_lt3 LC_lt5.
        eapply uni_branch_succ_p with (q:=q2) (br:=br);eauto.
        intros;symmetry;eapply HCuni;eauto.
      + (* since (br,k) = (q2,j2) & uniform, we have that (p,i) succeeds (br,k) thus
         (p,i) ∈ l1, thus double occurence of the same instance in t1 --> contradiction *)
        cbn in LC_lt0.
        destruct p0.
        eapply2' postfix_hd_eq LC_lt0 LC_lt2 LC_lt0' LC_lt2'. symmetry in LC_lt2'. subst'.
        clear LC_lt2 LC_lt1 LC_lt3 LC_lt5.
        eapply (uni_branch_succ_p p q1 br i j1 k s1 s2 r1 r2);eauto.
      + (* successor of br is the same because of uniformity and in l1' & l2', 
           thus l1' & l2' are not disjoint --> contradiction *)
        eapply (uni_branch_non_disj p i br k _ _ ((q1,j1,r1)::l1)
                                    ((q2,j2,r2)::l2) (p0:<l1') (p1:<l2'));
          cbn;simpl_nl;eauto.
    - spot_path. 
    - spot_path. 
  Qed.

  
  Ltac reduce_uni_concr HCuni Hpre1 Hpre2 :=
    clear - HCuni Hpre1 Hpre2; eapply2 prefix_incl Hpre1 Hpre2; intros; eapply HCuni;eauto.
  
  Lemma uni_correct :
    forall uni unch ts,
      sem_hyper (red_prod (uni_concr uni) (lift (unch_concr unch))) ts ->
      uni_concr (uni_trans uni unch) ts.
  Proof.
    intros uni unch ts Hred.
    unfold sem_hyper in Hred.
    destruct Hred as [ts' [Hconcr Hstep]].
    unfold uni_concr.
    intros t t' Hsem Hsem' x p i s s' HIn HIn' Htrans.

    assert (unch_concr (unch_trans unch) t) as HCunch. {
      destruct Hconcr as [_ Hunch].
      unfold lift in *; subst.
      apply unch_correct; [eapply root_no_pred'|]. assumption.
    } 
    
    assert (unch_concr (unch_trans unch) t') as HCunch'. {
      destruct Hconcr as [ _ Hunch].
      unfold lift in *; subst.
      apply unch_correct; [eapply root_no_pred'|]. assumption.
    }

    destruct Hconcr as [HCuni  _].

    subst.
    unfold uni_trans in Htrans. 
    assert (X := Hsem). destruct X as [t1 [k1 [Hts1 Hteq1]]].
    assert (X := Hsem'). destruct X as [t2 [k2 [Hts2 Hteq2]]].
    destruct (p == root); [ subst | ].
    - rewrite e in *; clear e. 
      eapply HCuni; [eapply Hts1|apply Hts2| | | apply Htrans].
      + specialize (root_prefix t1) as [s0 rp]. apply root_start_tag in HIn as rst. subst i.
        eapply prefix_cons_in in rp as rp'.
        assert (Prefix (`t1) (`t)) as pre_t.
        { rewrite Hteq1. cbn. econstructor. econstructor. }
        eapply prefix_trans with (l2:=`t1) (l3:=`t) in rp; eauto. 
        apply prefix_cons_in in rp. eapply tag_inj in HIn; [| apply rp].
        subst s0. eauto.
      + specialize (root_prefix t2) as [s0 rp]. apply root_start_tag in HIn as rst. subst i.
        eapply prefix_cons_in in rp as rp'.
        assert (Prefix (`t2) (`t')) as pre_t.
        { rewrite Hteq2. cbn. econstructor. econstructor. }
        eapply prefix_trans with (l2:=`t2) (l3:=`t') in rp; eauto.
        apply prefix_cons_in in rp. eapply tag_inj in HIn'; [| apply rp].
        subst s0. eauto. 
    - conv_bool.
      destruct Htrans as [[Htrans Hpred] | Hunch].
      (* The uni/hom case *)
      + rewrite Hteq1 in HIn. rewrite Hteq2 in HIn'.
        eapply in_pred_exists in HIn; try eassumption;
          [|setoid_rewrite <-Hteq1; exact (proj2_sig t)].
        eapply in_pred_exists in HIn'; try eassumption;
          [|setoid_rewrite <-Hteq2; exact (proj2_sig t')].
        destruct HIn as [q [j [r [HIn Hstep]]]].
        destruct HIn' as [q' [j' [r' [HIn' Hstep']]]].
        assert (q ∈ (preds p)) as Hqpred
            by (eapply in_preds;eauto using step_conf_implies_edge,root_no_pred').

        eapply prefix_in_list in HIn as Hpre1. destruct Hpre1 as [l1 Hpre1].
        eapply prefix_in_list in HIn' as Hpre2. destruct Hpre2 as  [l2 Hpre2].
        
        rewrite nlcons_to_list in Hpre1.
        eapply prefix_trace in Hpre1 as Htr1 ; [|destruct t1; eauto].

        rewrite nlcons_to_list in Hpre2.
        eapply prefix_trace in Hpre2 as Htr2; [|destruct t2;eauto].
        simpl_nl' Hpre1. simpl_nl' Hpre2.
        specialize (HCuni t1 t2 Hts1 Hts2).          
        cut (q' = q); intros; subst.
        * cut (j' = j); intros; subst.
          -- eapply (local_uni_corr (uni q) q j p i r r' s s'); try eassumption.
             ** unfold uni_state_concr. intros.
                unfold uni_concr in HCuni .
                eapply (HCuni x0 q j); eassumption.
             ** eapply join_andb_true_iff in Hpred; try eassumption.
          -- eapply uni_same_tag;eauto.
             1,2: econstructor;eauto;simpl_nl;eauto.
             reduce_uni_concr HCuni Hpre1 Hpre2.  
        * clear HCunch HCunch'.
          eapply uni_same_lab ; eauto.
          1,2: econstructor;eauto;simpl_nl;eauto. cbn in HCuni.
          reduce_uni_concr HCuni Hpre1 Hpre2.
      (* The unch case *)
      + rename Hunch into H.
        eapply join_orb_true_iff in H.
        destruct H as [u H].
        conv_bool.
        destruct H as [Hunch [[Hneq' Huni] Hunibr]].
        specialize (HCunch p i s u x HIn Hunch).
        specialize (HCunch' p i s' u x HIn' Hunch).
        destruct HCunch as [j [r [Hprec Heq]]]; try eassumption.
        destruct HCunch' as [j' [r' [Hprec' Heq']]]; try eassumption.
        (* TODO: we'll need HCunch' for unch_dom *)
        rewrite <- Heq. rewrite <- Heq'.
        cut (j = j'); intros.
        * subst j'. eapply HCuni. eapply Hts1. eapply Hts2. 3: eauto.
          all: eapply precedes_step_inv.
          -- rewrite <-nlcons_to_list. setoid_rewrite Hteq1 in Hprec. apply Hprec.
          -- rewrite <-nlcons_necons, <-Hteq1. destruct t; eauto.
          -- cbn. eauto.
          -- rewrite <-nlcons_to_list. setoid_rewrite Hteq2 in Hprec'. apply Hprec'.
          -- rewrite <-nlcons_necons, <-Hteq2. destruct t'; eauto.
          -- cbn;eauto.
        * unfold Precedes' in Hprec,Hprec'. destructH' Hprec. destructH' Hprec'.
          rewrite nlcons_to_list in Hprec0.
          eapply prefix_trace in Hprec0 as Htr1 ; [|destruct t; eauto].
          rewrite nlcons_to_list in Hprec'0.
          eapply prefix_trace in Hprec'0 as Htr2; [|destruct t';eauto].
          rewrite Hteq1 in Hprec0. simpl_nl' Hprec0. cbn in Hprec0.
          eapply prefix_cons_cons in Hprec0. 
          rewrite Hteq2 in Hprec'0. simpl_nl' Hprec'0. cbn in Hprec'0.
          eapply prefix_cons_cons in Hprec'0.
          eapply unch_same_tag with (l1:=l').
          1,2,6-8: eauto.
          -- inversion Hprec1;subst;eauto;congruence.
          -- inversion Hprec'1;subst;eauto;congruence.
          -- specialize (HCuni t1 t2 Hts1 Hts2).
             reduce_uni_concr HCuni Hprec0 Hprec'0.  
  Qed.
  
End uniana.