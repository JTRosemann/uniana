Require Export Splits SplitsT TeqPaths TcfgDet.
Require Import Lia.

Definition inner' := fun (A : Type) (l : list A) => rev (tl (rev (tl l))).

Lemma inner_inner' (A : Type) (l : list A)
  : inner l = inner' l.
Proof.
  unfold inner, inner'.
  destruct l;cbn;eauto.
  destr_r' l;subst l;cbn;eauto.
  rewrite rev_rcons. cbn.
  rewrite rev_involutive.
  rewrite rev_rcons. cbn.
  rewrite rev_involutive.
  reflexivity.
Qed.

Lemma inner_rtl (A : Type) (l : list A) (a : A)
  : inner (a :: l) = r_tl l.
Proof.
  rewrite inner_inner'.
  unfold inner',r_tl in *.
  cbn.
  reflexivity.
Qed.

Lemma inner_tl (A : Type) (l : list A) (a : A)
  : inner (l ++ [a]) = tl l.
Proof.
  unfold inner.
  rewrite rev_rcons.
  cbn.
  rewrite rev_involutive.
  reflexivity.
Qed.

Lemma inner_eval_lr (A : Type) (l : list A) (a b : A)
  : inner (a :: l ++ [b]) = l.
Proof.
  rewrite <-cons_rcons_assoc.
  rewrite inner_tl.
  cbn.
  reflexivity.
Qed.

Lemma r_tl_rcons (A : Type) (l : list A) (a : A)
  : r_tl (l ++ [a]) = l.
Proof.
  unfold r_tl.
  rewrite rev_rcons. cbn.
  rewrite rev_involutive.
  reflexivity.
Qed.

Lemma inner_empty_iff (A : Type) (l : list A) (a b : A)
  : inner (a :: b :: l) = [] <-> l = nil.
Proof.
  destruct l;cbn.
  - firstorder.
  - split;intro H;[|congruence].
    specialize (cons_rcons a0 l) as Hspec. destructH. rewrite Hspec in H.
    rewrite inner_rtl in H.
    rewrite <-cons_rcons_assoc in H.
    rewrite r_tl_rcons in H.
    congruence.
Qed.

Lemma acyclic_path_NoDup (L : Type) `{EqDec L eq} (ed : L -> L -> Prop) (π : list L) p q
      (Hpath : Path ed p q π)
      (Hacy : acyclic ed)
  : NoDup π.
Proof.
  induction Hpath.
  - econstructor;eauto. econstructor.
  - econstructor;eauto.
    intro N.
    eapply path_from_elem in N;eauto.
    destructH.
    eapply Hacy;eauto.
Qed.

Lemma acy_path_incl_cons (L : Type) `{EqDec L eq} (ed : L -> L -> Prop) (π ϕ : list L) p q
      (Hpath : Path ed p q π)
      (Hincl : π ⊆ (q :: ϕ))
      (Hacy : acyclic ed)
  : tl π ⊆ ϕ.
Proof.
  inv_path Hpath;cbn;eauto.
  unfold incl in *.
  intros a Ha.
  specialize (Hincl a). exploit Hincl.
  destruct Hincl;subst.
  - eapply acyclic_path_NoDup in Hpath;eauto.
    inv Hpath. contradiction.
  - auto.
Qed.

Lemma path_acyclic_no_loop (L : Type) (e : L -> L -> Prop) (a b c : L) (π : list L)
      (Hacy : acyclic e)
  : ~ Path e a a (b :: c :: π).
Proof.
  intro N.
  inv_path N.
  eapply Hacy;eauto.
Qed.

Lemma disjoint_app_app (A : Type) (l1 l2 l3 l4 : list A)
  : Disjoint l1 l3
    -> Disjoint l1 l4
    -> Disjoint l2 l3
    -> Disjoint l2 l4
    -> Disjoint (l1 ++ l2) (l3 ++ l4).
Proof.
  revert l2 l3 l4.
  induction l1;intros;cbn.
  - induction l3;intros;cbn.
    + eauto.
    + eapply disjoint_cons2.
      eapply disjoint_cons2 in H1. destruct H1.
      split;eauto.
      eapply IHl3;eauto.
      firstorder.
  - eapply disjoint_cons1. eapply disjoint_cons1 in H. eapply disjoint_cons1 in H0.
    do 2 destructH.
    split.
    + intro N. eapply in_app_or in N. destruct N;contradiction.
    + eapply IHl1;eauto.
Qed.

(** ^ move somewhere else **)

Lemma diamond_teq `(C : redCFG)
      (s u1 u2 p1 p2 q1 q2 : Lab) (k i l1 l2 j1 j2 : Tag) r1 r2
      (Hdeq : deq_loop q1 s)
      (Hjle : j1 ⊴ j2)
      (D : DiamondPaths s u1 u2 p1 p2 q1 q2 k i l1 l2 j1 j2 ((q1,j1) :: r1) ((q2,j2) :: r2))
  : TeqPaths u1 u2 q1 q2 l1 l2 j1 j2 (r1) (r2).
Proof.
  copy D D'.
  destruct D.
  inv_path Dpath1. inv_path Dpath2.
  econstructor; eauto using tl_eq, lj_eq1, lj_eq2, jj_len, j_len1.
Qed.

Lemma loop_head_eq_loop_eq `(C : redCFG) h1 h2
          (Hloop1 : loop_head h1)
          (Hloop2 : loop_head h2)
          (Heq : eq_loop h1 h2)
  : h1 = h2.
Proof.
  destruct Heq.
  eapply loop_contains_Antisymmetric;eauto.
  1: eapply H0.
  2: eapply H.
  1,2: eapply loop_contains_self;eauto.
Qed.

Section splits_sound.
Context `{C : redCFG}.

  Infix "-->" := edge__P.
  Infix "-t>" := tcfg_edge (at level 70).
  Infix "-h>" := head_rewired_edge (at level 70).

  Lemma tag_exit_eq' h p q i j
        (Hedge : (p,i) -t> (q,j))
        (Hexit : exit_edge h p q)
    : exists n, i = n :: j.
  Admitted.

  Lemma tcfg_edge_eq_loop q1 q2 j p i
        (Hedge1 : (q1,j) -t> (p,i))
        (Hedge2 : (q2,j) -t> (p,i))
    : eq_loop q1 q2.
  Admitted.

  Lemma exit_edges_loop_eq h1 h2 e1 e2 q1 q2 p
        (Hexit1 : exit_edge h1 q1 e1)
        (Hexit2 : exit_edge h2 q2 e2)
        (Hin1 : loop_contains h1 p)
        (Hin2 : loop_contains h2 p)
        (Heq : eq_loop e1 e2)
    : eq_loop q1 q2.
  Admitted.

  Lemma teq_node_disj
        `(T : TeqPaths)
        (Hjeq : j1 = j2)
    : Disjoint (q1 :: map fst r1) (q2 :: map fst r2).
  Admitted.

  Lemma tpath_jeq_prefix u2 l2 q2 n2 j n1 r2
        (Tpath2 : TPath (u2, l2) (q2, n2 :: j) ((q2, n2 :: j) :: r2))
        (Tlj_eq2 : l2 = n1 :: j \/ l2 = 0 :: n1 :: j \/ loop_contains u2 q2)
        (Hlt : n1 < n2)
    : exists h r2',
      Prefix ((h,(S n1) :: j) :: r2') ((q2, n2 :: j) ::  r2)
      /\ innermost_loop h q2
      /\ forall x, x ∈ map fst r2' -> x <> h.
  Admitted.

  Lemma teq_jeq_prefix u1 u2 q1 q2 l1 l2 n1 n2 j r1 r2
        (T : TeqPaths u1 u2 q1 q2 l1 l2 (n1 :: j) (n2 :: j) r1 r2)
        (Hlt : n1 < n2)
    : exists h r2', Prefix (h :: map fst r2') (q2 :: map fst r2)
               /\ innermost_loop h q1
               /\ TeqPaths u1 u2 q1 h l1 l2 (n1 :: j) (n1 :: j) r1 r2'.
  Proof.
    destruct T.
  Admitted.

  Lemma diamond_qj_eq1 s u1 u2 p1 p2 q1 q2 k i l1 l2 j1 j2 qj1 r1 r2
        (D : DiamondPaths s u1 u2 p1 p2 q1 q2 k i l1 l2 j1 j2 (qj1 :: r1) r2)
    : qj1 = (q1,j1).
  Proof.
    destruct D. cbn in Dqj1. auto.
  Qed.

  Lemma diamond_qj_eq2 s u1 u2 p1 p2 q1 q2 k i l1 l2 j1 j2 qj2 r1 r2
        (D : DiamondPaths s u1 u2 p1 p2 q1 q2 k i l1 l2 j1 j2 r1 (qj2 :: r2))
    : qj2 = (q2,j2).
  Proof.
    destruct D. cbn in Dqj2. auto.
  Qed.

  Lemma node_disj
        `(D : DiamondPaths)
        (Hjeq : j1 = j2)
        (Hdeq : deq_loop q1 s)
    : Disjoint (map fst r1) (map fst r2).
  Proof.
    subst j2.
    destruct r1,r2.
    1-3: cbn; firstorder.
    diamond_subst_qj D.
    eapply teq_node_disj;eauto. eapply diamond_teq.
    - eassumption.
    - reflexivity.
    - exact D.
  Qed.

  Lemma TeqPaths_sym u1 u2 q1 q2 l1 l2 j r1 r2
        (T : TeqPaths u1 u2 q1 q2 l1 l2 j j r1 r2)
    : TeqPaths u2 u1 q2 q1 l2 l1 j j r2 r1.
  Proof.
    copy T T'.
    destruct T.
    econstructor;eauto.
    - eapply Disjoint_sym;eauto.
    - symmetry. eauto.
    - destruct Tlj_eq2;[firstorder|].
      destruct H;[right;auto|].
      exfalso. eapply teq_no_back2 in T';eauto.
      eapply TPath_CPath in Tpath2. cbn in Tpath2. eapply path_contains_back;eauto.
    - destruct Tlj_eq1;[left|right];firstorder.
    - rewrite <-Tloop. eauto.
  Qed.

  Lemma expand_hpath (π : list Lab) q p
        (Hπ : HPath q p π)
    : exists ϕ, CPath q p ϕ /\ π ⊆ ϕ.
  Proof.
    induction Hπ.
    - exists [a]. split; [ constructor | auto ].
    - unfold head_rewired_edge in H.
      destruct H as [ [ H _ ] | H ].
      + destruct IHHπ as [ ϕ [ Hϕ Hsub ]].
        exists (c :: ϕ). split.
        * econstructor; eassumption.
        * unfold incl in *. firstorder.
      + unfold exited in H.
        unfold exit_edge in H.
        destruct H as [p [Hcont [Hncont Hedge]]].
        eapply loop_reachs_member in Hcont.
        destruct Hcont as [σ Hσ].
        destruct IHHπ as [ϕ [Hϕ Hincl]].
        exists (c :: σ ++ tl ϕ).
        split.
        * econstructor.
          -- eapply path_app'. eassumption.
             eauto using subgraph_path'.
          -- eassumption.
        * unfold incl in *. intros.
          destruct H.
          -- subst. eauto.
          -- eapply Hincl in H. simpl. right.
             eapply in_or_app.
             destruct ϕ; [ inversion H |].
             eapply in_inv in H.
             destruct H.
             ++ left. subst. inv Hϕ; eauto using path_contains_back.
             ++ right. eauto.
  Qed.

  Lemma incl_app c
        (π ϕ : list Lab)
        (Hincl : π ⊆ ϕ)
    : (c :: π) ⊆ (c :: ϕ).
  Proof.
    unfold incl in *. firstorder.
  Qed.

  Lemma basic_edge_loop_contains a b x
        (Hedge : basic_edge a b)
        (Hinner : loop_contains x a)
    : loop_contains x b.
  Proof.
    specialize (loop_contains_loop_head Hinner) as Hhead.
    destruct Hedge as [Hedge _].
    eauto using loop_contains_deq_loop, deq_loop_head_loop_contains, eq_loop1.
  Qed.

  Lemma back_edge_loop_contains a b x
        (Hedge : back_edge a b)
        (Hinner : loop_contains x a)
    : loop_contains x b.
  Proof.
    specialize (loop_contains_loop_head Hinner) as Hhead.
    eauto using loop_contains_deq_loop, back_edge_eq_loop, deq_loop_head_loop_contains, eq_loop1.
  Qed.

  Lemma back_edge_innermost h l
        (Hbe : back_edge l h)
    : innermost_loop h l.
  Proof.
    destruct (back_edge_eq_loop Hbe) as [H1 H2].
    unfold innermost_loop.
    eauto using loop_contains_ledge.
  Qed.

  Lemma innermost_unique a b c
        (Ha : innermost_loop a c)
        (Hb : innermost_loop b c)
    : a = b.
  Proof.
    destruct Ha as [Ha Ha'].
    destruct Hb as [Hb Hb'].
    unfold deq_loop in *.
    eauto using loop_contains_Antisymmetric.
  Qed.

  Lemma innermost_unique' a b c d
        (Ha : innermost_loop a c)
        (Hb : innermost_loop b d)
        (Heq : eq_loop c d)
    : a = b.
  Proof.
    destruct Ha as [Ha Ha'].
    destruct Hb as [Hb Hb'].
    destruct Heq.
    unfold deq_loop in *.
    eapply loop_contains_Antisymmetric; eauto.
  Qed.

  Lemma back_edge_src_no_loop_head
        a b
        (Hbe : back_edge b a)
    : ~ loop_head b.
  Proof.
    intro. eapply no_self_loops.
    - eapply Hbe.
    - eapply innermost_unique. unfold innermost_loop. unfold deq_loop.
      eauto using loop_contains_self.
      eauto using back_edge_innermost.
  Qed.

  Lemma in_path_ex_prefix_not_in p q π x
        (Hπ : CPath p q π)
        (Hin : x ∈ π)
        : exists ϕ, Prefix (x :: ϕ) π /\ x ∉ ϕ.
  Proof.
    revert dependent q.
    induction π.
    - inv Hin.
    - intros.
      replace a with q in *.
      + decide (x ∈ π).
        * destruct π; [ inv i |].
          destruct (IHπ i e) as [ϕ [Hpre Hnin]].
          -- inv Hπ. enough (b = e).
             ++ subst. eassumption.
             ++ eauto using path_front.
          -- exists ϕ. split; [| eassumption ].
             econstructor. eassumption.
        * inv Hin.
          -- exists π. split; [ econstructor | eassumption ].
          -- contradiction.
      + eauto using path_front.
  Qed.

  Lemma prefix_singleton p q π h
        (Hπ : CPath p q π)
        (Hpre : Prefix [h] π)
    : p = h.
  Proof.
    induction Hπ.
    - inv Hpre.
      + reflexivity.
      + inv H1.
    - inv Hpre.
      + inv Hπ.
      + eauto.
  Qed.

  Lemma head_unique h b x y
        (Hh : loop_contains h x)
        (Hb : loop_contains b y)
        (Heq : eq_loop h b)
    : h = b.
  Proof.
    unfold eq_loop in Heq.
    unfold deq_loop in *.
    destruct Heq as [H1 H2].
    eapply loop_contains_Antisymmetric; eauto using loop_contains_loop_head, loop_contains_self.
  Qed.

  Lemma prefix_edge_exists a b p q π ϕ
        (Hπ : Path edge__P p q π)
        (Hpre : Prefix (a :: b :: ϕ) π)
    : b --> a.
  Proof.
    induction Hπ.
    - inv Hpre. inv H1.
    - inversion Hpre; [| eauto ].
      subst. inv Hπ; eauto.
  Qed.

  Lemma in_postfix_in l l' (a : Lab)
     :  a ∈ l -> Postfix l l' -> a ∈ l'.
  Proof.
    intros Hin Hpost.
    revert dependent l.
    induction l'.
    - intros. eapply postfix_nil_nil in Hpost. subst. inv Hin.
    - intros.
      destruct l as [| b  l].
      + inv Hin.
      + simpl in Hin.
        destruct Hin.
        * left. symmetry. rewrite H in Hpost. eauto using postfix_hd_eq.
        * right. eauto using cons_postfix.
  Qed.

  Lemma path_prefix_path' p q r π ϕ
    : Path edge__P p q π -> Prefix (r :: ϕ) π -> Path edge__P p r (r :: ϕ).
  Proof.
    eapply path_prefix_path.
    intros. unfold dec. decide (x --> y); firstorder.
  Qed.

  Lemma enter_exit_same e h b c
        (Hentry : entry_edge e h)
        (Hexit: exit_edge h b c)
    : eq_loop c e.
  Proof.
    enough (forall h, loop_contains h e <-> loop_contains h c).
    - unfold eq_loop, deq_loop.
      firstorder.
    - intros h'. split; intros.
      + eapply exit_edge_in_loop; try eassumption.
        * eapply deq_loop_entry in Hentry. unfold deq_loop in Hentry. eauto.
        * intro. subst. eapply Hentry. assumption.
      + specialize (deq_loop_exited' Hexit) as Hdeq. unfold deq_loop in Hdeq.
        edestruct (deq_loop_entry_or Hentry); eauto.
        subst. unfold exit_edge in Hexit.
        exfalso. destruct Hexit as [_ [Hexit _]]. contradiction.
  Qed.

  Lemma path_no_loop_head_deq p e h π
        (Hπ : Path edge__P p e π)
        (Hinner : innermost_loop h e)
        (Hnin : h ∉ π)
    : forall x, x ∈ π -> deq_loop x e.
  Proof.
    intros.
    decide (deq_loop x e); try eassumption.
    rename n into Hndeq.
    exfalso.
    assert (Hncont : ~ loop_contains h x). {
      eauto using innermost_loop_deq_loop.
    }
    eapply path_from_elem in H; try eauto.
    destruct H as [ϕ [Hϕ Hpost]].
    eapply Hnin.
    destruct Hinner.
    eapply in_postfix_in; try eassumption.
    eapply dom_loop_contains; try eassumption.
  Qed.

  Lemma contract_cpath (π : list Lab) p q
           (Hπ : CPath p q π)
           (Hdeq : forall x, x ∈ π -> deq_loop x q)
           (Hnin : forall x, x ∈ tl π -> ~ loop_contains x q) (* Header of q is not on π *)
    : exists ϕ, HPath p q ϕ /\ ϕ ⊆ π.
  Proof.
    revert dependent q. revert dependent π.
    specialize (well_founded_ind (R:=(@StrictPrefix' Lab)) (@StrictPrefix_well_founded Lab)
                                 (fun π : list Lab => forall q, CPath p q π ->
                                                        (forall x, x ∈ π -> deq_loop x q) ->
                                                        (forall x, x ∈ tl π -> ~ loop_contains x q) ->
                                                        exists ϕ, HPath p q ϕ /\ ϕ ⊆ π))
      as WFind.
    eapply WFind.
    intros π IH q Hπ Hdeq Hnin. clear WFind.
    inv Hπ.
    - exists [q]. unfold incl. split; eauto; econstructor.
    - specialize (edge_Edge H0) as Hedge.
      rename H into Hπ. rename q into c. rename π0 into π.
      assert (Hprefix : StrictPrefix' π (c :: π)) by (repeat econstructor).
      simpl in Hnin.
      inv Hedge.
      + edestruct IH as [ϕ [Hϕ Hincl]]; try eauto.
        * unfold deq_loop in *. eauto using basic_edge_loop_contains.
        * intros. intro. eapply Hnin. simpl. eapply in_tl_in. eassumption.
          eauto using basic_edge_loop_contains.
        * exists (c :: ϕ). split; [| eauto using incl_app ].
          econstructor; [ eassumption |].
          left. split; [ eassumption |].
          intro.  eapply (Hnin b). eauto using path_contains_front.
          eauto using loop_contains_self, basic_edge_loop_contains.
      + edestruct IH as [ϕ [Hϕ Hincl]]; try eauto.
        * unfold deq_loop in *. eauto using back_edge_loop_contains.
        * intros. intro. eapply Hnin. simpl. eapply in_tl_in. eassumption.
          eauto using back_edge_loop_contains.
        * exists (c :: ϕ). split; [| eauto using incl_app ].
          econstructor; [ eassumption |].
          left. split; eauto using back_edge_src_no_loop_head.
      + unfold entry_edge in H. destruct H as [Hhead [H _]].
        exfalso. apply H. unfold deq_loop in Hdeq.
        eauto using loop_contains_self, in_cons, path_contains_front.
      + destruct H as [h Hexit].
        decide (h ∈ π) as [ Hhin | Hhnin ].
        * specialize (in_path_ex_prefix_not_in Hπ Hhin) as Hfirst.
          destruct Hfirst as [ϕ [Hpre Hninϕ]].
          destruct ϕ as [ | e ϕ ].
          -- assert (Heq : p = h) by (eauto using prefix_singleton).
             subst p. exists [c; h]. split.
             ++ econstructor; [ econstructor |]. right. exists b. eassumption.
             ++ unfold incl. intros. inversion H.
                ** subst. eauto.
                ** inversion H1. subst. eauto. inversion H2.
          -- assert (Hedge : e --> h) by (eauto using prefix_edge_exists).

             assert (Hedge' : entry_edge e h \/ back_edge e h). {
               eapply edge_Edge in Hedge.
               inv Hedge; try eauto.
               - exfalso. eapply basic_edge_no_loop2. eapply H.
                 eapply loop_contains_loop_head. eapply Hexit.
               - destruct H as [h' H]. eapply no_exit_head in H.
                 exfalso. apply H. unfold loop_contains in Hexit. unfold loop_head. firstorder.
             }

             destruct Hedge' as [Hent | Hback].
             ++ edestruct (@IH (e :: ϕ)) as [ϕ' [Hϕ' Hincl']].
                ** econstructor. eapply PreStep. eassumption.
                ** eapply prefix_cons in Hpre. eapply path_prefix_path'; try eassumption.
                ** intros. eapply eq_loop2.
                   --- eauto using enter_exit_same.
                   --- eapply Hdeq. eauto using in_prefix_in.
                ** simpl. intros. intro. eapply Hnin. eapply in_prefix_in. eapply H.
                   eauto using prefix_cons. eapply eq_loop2. eauto using enter_exit_same.
                   eapply deq_loop_refl. eassumption.
                ** exists (c :: h :: ϕ'). split.
                   --- econstructor. econstructor. eapply Hϕ'.
                       +++ left. split; [ eauto |].
                           intro. eapply (Hnin e).
                           *** eauto using prefix_cons, in_prefix_in.
                           *** eauto using deq_loop_head_loop_contains, eq_loop2, enter_exit_same.
                       +++ right. exists b. eassumption.
                   --- intros x Hx.
                       destruct Hx.
                       +++ subst. left;auto.
                       +++ destruct H.
                           *** subst. right;auto.
                           *** right. eapply prefix_incl;eauto.

             ++ assert (Hnin2 : forall x, x ∈ (e :: ϕ) -> ~ loop_contains x e). {
                  intros. intro. eapply Hnin. eapply in_prefix_in.
                  2: eapply Hpre.
                  1: eapply in_cons. eassumption.
                  specialize (back_edge_innermost Hback) as Hinner1.
                  - enough (x <> h).
                    + eapply (exit_edge_in_loop Hexit); try eassumption.
                      eauto using back_edge_loop_contains, eq_loop2.
                    + intro. subst. contradiction.
                }

                edestruct (@IH (e :: ϕ)) as [ϕ' [Hϕ' Hincl']].
                ** econstructor. eapply PreStep. eassumption.
                ** eapply prefix_cons in Hpre. eapply path_prefix_path'; try eassumption.
                ** eauto using exit_edge_innermost, back_edge_innermost,
                   path_no_loop_head_deq, prefix_cons, path_prefix_path' .
                ** eauto.
                ** exists (c :: h :: ϕ'). split.
                   --- econstructor. econstructor. eapply Hϕ'.
                       +++ left. split; [ eauto |].
                           decide (loop_head e); [| eassumption ]. exfalso.
                           eapply (Hnin2 e); eauto using loop_contains_self.
                       +++ right. exists b. eassumption.
                   --- intros x Hx.
                       destruct Hx.
                       +++ subst. left;auto.
                       +++ destruct H.
                           *** subst. right; auto.
                           *** right. eapply prefix_incl; eauto.
        * edestruct (IH π) as [ϕ [Hϕ Hincl]].
          -- econstructor. econstructor.
          -- eauto.
          -- eauto using exit_edge_innermost, back_edge_innermost, path_no_loop_head_deq.
          -- intros. intro. eapply Hnin. simpl. eapply in_tl_in. eassumption.
             edestruct (deq_loop_exit_or Hexit); try eassumption.
             subst. exfalso. eauto using in_tl_in.
          -- exists (c :: ϕ). split; [| eauto using incl_app ].
             econstructor; [ eassumption |]. left. split; [ assumption |]. intro.
             enough (h = b).
             ++ subst b. eauto using path_contains_front.
             ++ assert (Heq : eq_loop h b) by (eauto using eq_loop_exiting).
                assert (Hinner : innermost_loop h b) by (eauto using exit_edge_innermost).
                eapply loop_contains_self in H.
                destruct Hinner as [Hinner _].
                eauto using head_unique.
  Qed.

  Lemma contract_cpath' (π : list Lab) q p
           (Hπ : CPath p q π)
           (Hdeq : deq_loop p q)
           (Hnin : forall x, x ∈ tl π -> ~ loop_contains x q)
    : exists ϕ, HPath p q ϕ /\ ϕ ⊆ π.
  Proof.
    eapply contract_cpath;eauto.
    unfold deq_loop. intros x Hxin h Hhcont.
    decide (loop_contains h x) as [Htmp | Hxcont]; [ assumption |].
    exfalso.
    destruct π as [|l π']; [ contradiction |].
    replace l with q in * by (eauto using path_front).
    simpl in Hnin.
    inversion Hπ; subst. {
      inv Hxin. contradiction. inv H.
    }
    rename H3 into Hedge. rename H0 into Hπ'.
    destruct Hxin as [Htmp | Hxin]. {
      subst. contradiction.
    }
    decide (loop_contains q q) as [Hhead | Hnhead ].
    - (* if q is a loop header, we cannot use Hnin to create a contradiction because it
         is only applicable to tl π. We essentially need to show that there is a header
         that contains q and lies on π' that contains all nodes on π'.
         We get that header using p_p_ex_head. Then, the fact that this header
         contains all other loops is in contradiction with Hnin. *)
      edestruct loop_reachs_member as [ρ Hρ].
      eapply (deq_loop_head_loop_contains Hdeq).
      eauto using loop_contains_loop_head.
      remember ((q :: π') ++ tl ρ) as σ.
      assert (Hσ : CPath q q σ). {
        rewrite Heqσ.
        eapply path_app'.
        - eapply subgraph_path'; eauto using a_edge_incl.
        - eassumption.
      }
      edestruct (p_p_ex_head Hσ) as [ho [Hin Hcont]]. {
        rewrite Heqσ. simpl.
        induction π'; try contradiction.
        simpl. lia.
      }
      assert (Hne : q <> ho). {
        intro. subst ho.
        eapply Hxcont.
        eapply loop_contains_trans.
        eapply Hhcont. eapply Hcont.
        rewrite Heqσ.
        eauto using in_or_app.
      }
      assert (Hoinπ' : ho ∈ π'). {
        (* Show that ho is on the π' part of σ.
           Essentially by constructing an acyclic path from ho to ho. *)
        assert (Hinσ := Hin).
        rewrite Heqσ in Hin. simpl in Hin.
        destruct Hin.
        - exfalso. eauto.
        - eapply in_app_or in H.
          destruct H;[ eassumption |].
          exfalso.
          edestruct loop_reachs_member as [τ Hτ]. {
            eapply Hcont. rewrite Heqσ. simpl. left. reflexivity.
          }
          eapply in_tl_in in H.
          edestruct (path_to_elem Hρ H) as [ω [Hω _]].
          eapply (path_path_acyclic Hτ Hω); eauto.
      }
      eapply (Hnin _ Hoinπ').
      eapply Hcont.
      rewrite Heqσ. eauto.
    - (* the other case is simple. The path needs to go through the loop header h
         to reach p. This header contradicts Hnin. *)
      eapply path_from_elem in Hπ'; try eauto.
      destruct Hπ' as [ϕ [Hϕ Hpost]].
      eapply (Hnin h); try eassumption.
      eapply in_postfix_in; try eassumption.
      eapply (dom_loop_contains).
      2: eapply Hxcont.
      2: eapply Hϕ.
      eapply (preds_in_same_loop Hhcont). {
        intro. subst. eauto.
      }
      eassumption.
   Qed.

  Lemma path_to_cons_path (L : Type) (ed : L -> L -> Prop) p q π
        (Hpath : Path ed p q π)
    : exists ϕ, π = q :: ϕ.
  Proof.
    inv_path Hpath;cbn;eexists;eauto.
  Qed.

  Ltac to_cons_path H :=
    lazymatch type of H with
    | Path _ _ ?q ?r
      => let Q := fresh "Q" in
        let r2 := fresh "r" in
        eapply path_to_cons_path in H as Q;
        destruct Q as [r2 Q];
        subst r;
        rename r2 into r
    end.

  Lemma len_tl_neq_cons (A : Type) (l l' : list A)
    : |l| = |l'| -> tl l = tl l' -> l <> l' -> exists a a' l'', l = a :: l'' /\ l' = a' :: l''.
  Proof.
    intros.
    destruct l,l';cbn in *;try congruence.
    subst l'.
    exists a, a0, l.
    split;eauto.
  Qed.

  Lemma teq_node_disj_hpath' u1 u2 q1 q2 l1 l2 j r1 r2
        (T : TeqPaths u1 u2 q1 q2 l1 l2 j j (r1) (r2))
        p1 p2
        (Hedge1 : q1 -h> p1)
        (Hedge2 : q2 -h> p2)
    : exists r1' r2', HPath u1 p1 (p1 :: q1 :: r1')
                 /\ HPath u2 p2 (p2 :: q2 :: r2')
                 /\ Disjoint (q1 :: r1') (q2 :: r2')
                 /\ (q1 :: r1') ⊆ (q1 :: map fst r1)
                 /\ (q2 :: r2') ⊆ (q2 :: map fst r2).
  Proof.
    eapply teq_node_disj in T as Hndisj;eauto.
    cbn in Hndisj.
    copy T T'.
    destruct T.
    eapply TPath_CPath in Tpath1.  cbn in Tpath1.
    eapply TPath_CPath in Tpath2. cbn in Tpath2.
    eapply contract_cpath' in Tpath1.
    eapply contract_cpath' in Tpath2.
    2: { rewrite <-Tloop. eapply teq_u2_deq_q;eauto. }
    3: eauto with teq.
    2,3: cbn.
    3: intros; eapply teq_no_back;eauto.
    2: intros; rewrite <-Tloop; eapply teq_no_back2;eauto.
    repeat destructH.
    unfold HPath in *.
    to_cons_path Tpath2.
    to_cons_path Tpath0.
    exists ϕ0, ϕ.
    split_conj;eauto.
    1,2: econstructor;eauto.
    eapply disjoint_subset;eauto.
  Qed.

  Lemma teq_node_disj_hpath u1 u2 q1 q2 l1 l2 j r1 r2
        (T : TeqPaths u1 u2 q1 q2 l1 l2 j j (r1) (r2))
        p1 p2 i
        (Hedge1 : (q1,j) -t> (p1,i))
        (Hedge2 : (q2,j) -t> (p2,i))
    : exists r1' r2', HPath u1 p1 (p1 :: q1 :: r1')
                 /\ HPath u2 p2 (p2 :: q2 :: r2')
                 /\ Disjoint (q1 :: r1') (q2 :: r2')
                 /\ (q1 :: r1') ⊆ (q1 :: map fst r1)
                 /\ (q2 :: r2') ⊆ (q2 :: map fst r2).
  Proof.
    eapply teq_node_disj_hpath';eauto.
    1,2: left;split;destruct Hedge1,Hedge2;eauto.
    1,2: intro N.
    - eapply teq_no_back;eauto using loop_contains_self.
    - eapply teq_no_back2;eauto. rewrite Tloop.
      eapply loop_contains_self;eauto.
  Qed.

  Lemma tag_cons_exit q p n i
        (Hedge : (q,n :: i) -t> (p,i))
    : exists h, exit_edge h q p.
  Admitted.

  Lemma teq_node_disj_prefix_hpath u1 u2 q1 q2 l1 l2 r1 r2 n1 n2 i
        (T : TeqPaths u1 u2 q1 q2 l1 l2 (n1 :: i) (n2 :: i) (r1) (r2))
        p1 p2
        (Hedge1 : (q1,n1 :: i) -t> (p1,i))
        (Hedge2 : (q2,n2 :: i) -t> (p2,i))
        (Hlt : n1 < n2)
    : exists r1' r2', HPath u1 p1 (p1 :: r1')
                 /\ HPath u2 p2 (p2 :: r2')
                 /\ Disjoint (r1') (r2')
                 /\ (r1') ⊆ (q1 :: map fst r1)
                 /\ (r2') ⊆ (q2 :: map fst r2).
  Proof.
    eapply teq_jeq_prefix in Hlt;eauto.
    destructH.
    eapply teq_node_disj_hpath' in Hlt3;eauto.
    - destructH.
      do 2 eexists;split_conj;eauto.
      eapply prefix_incl in Hlt0.
      transitivity (h :: map fst r2');eauto.
    - left;split;destruct Hedge1,Hedge2;eauto;intro N.
      eapply teq_no_back;eauto using loop_contains_self.
    - right. exists q2.
      eapply tag_cons_exit in Hedge2. destructH.
      replace h with h0;eauto.
      eapply loop_head_eq_loop_eq.
      + destruct Hedge2. eapply loop_contains_loop_head;eauto.
      + destruct Hlt2. eapply loop_contains_loop_head;eauto.
      + eapply innermost_eq_loop in Hlt2. rewrite Hlt2.
        eapply eq_loop_exiting in Hedge2.
        rewrite Hedge2.
        symmetry. eapply Tloop.
  Qed.

  Lemma tagle_monotone q1 q2 j1 j2 r
        (Hpath : TPath (q1,j1) (q2,j2) r)
        (Hin : forall x, x ∈ map fst r -> deq_loop x q1)
        (Heq : eq_loop q1 q2)
    : j1 ⊴ j2.
  Admitted.

  Lemma le_cons_tagle n1 n2 i
        (Hlt : n1 <= n2)
    : n1 :: i ⊴ n2 :: i.
  Proof.
  Admitted.

  Lemma lt_cons_ntagle n1 n2 i
        (Hlt : n2 < n1)
    : ~ n1 :: i ⊴ n2 :: i.
  Admitted.

  Lemma node_disj_prefix_hpath s u1 u2 p1 p2 q1 q2 k i l1 l2 n1 n2 r1 r2
        (D : DiamondPaths s u1 u2 p1 p2 q1 q2 k i l1 l2 (n1 :: i) (n2 :: i) r1 r2)
        (Hdeq : deq_loop q1 s)
        (Hlt : n1 < n2)
    : exists r1' r2', HPath u1 p1 (p1 :: r1')
                 /\ HPath u2 p2 (p2 :: r2')
                 /\ Disjoint (r1') (r2')
                 /\ r1' ⊆ map fst r1
                 /\ r2' ⊆ map fst r2.
  Proof.
    destruct r1,r2.
    - exfalso.
      destruct D. cbn in *. inv Dqj1; inv Dqj2. lia.
    - copy D D'.
      destruct D'.
      cbn in Dqj1.
      eapply path_single in Dpath1. destruct Dpath1 as [Dpath1 _]. inv Dpath1. inv Dqj1.
      cbn in Dqj2. subst p.
      inv_path Dpath2.
      eapply tpath_jeq_prefix in H as Hpre;eauto.
      2: rewrite <-Dloop; eapply lj_eq2;eauto.
      2: eapply le_cons_tagle;lia.
      destructH.
      eapply path_prefix_path in H;eauto.
      eapply TPath_CPath in H. cbn in H.
      eapply contract_cpath' in H.
      + destructH.
        exists [], ϕ.
        split_conj;eauto.
        * econstructor.
        * econstructor;eauto.
          eapply tag_cons_exit in H0. destructH.
          replace h0 with h in H0.
          -- right. eexists;eauto.
          -- eapply loop_head_eq_loop_eq.
             1,2: destruct Hpre2,H0;eauto using loop_contains_loop_head.
             eapply eq_loop_exiting in H0. rewrite H0. eapply innermost_eq_loop in Hpre2.
             rewrite Hpre2. reflexivity.
        * firstorder 0.
        * cbn. eapply prefix_incl in Hpre0. eapply incl_map with (f:=fst) in Hpre0.
          cbn in Hpre0. transitivity (h :: map fst r2');eauto.
      + eapply innermost_eq_loop in Hpre2. rewrite Hpre2.
        rewrite <-Dloop. eapply u2_deq_q;eauto. congruence.
      + cbn. intros. intro N. eapply Hpre3;eauto.
        eapply loop_head_eq_loop_eq;[|destruct Hpre2|];eauto using loop_contains_loop_head.
        split.
        * eapply innermost_eq_loop in Hpre2. rewrite Hpre2. rewrite <-Dloop.
          eapply r2_incl_head_q;eauto.
          eapply prefix_incl in Hpre0.
          eapply incl_map with (f:=fst) in Hpre0. cbn in Hpre0. cbn. eapply Hpre0. right. auto.
        * eapply loop_contains_deq_loop;eauto.
    - exfalso.
      copy D D'.
      destruct D.
      cbn in Dqj1,Dqj2.
      subst p. inv Dqj2.
      eapply path_single in Dpath2. destruct Dpath2 as [Dpath2 _]. inv Dpath2.
      inv_path Dpath1.
      eapply path_rcons in Dsk1;eauto.
      eapply tagle_monotone in Dsk1.
      + eapply lt_cons_ntagle;eauto.
      + cbn. rewrite map_rcons. cbn. intros. rewrite In_rcons in H1.
        destruct H1 as [H1|[H1|H1]]. 1,2: subst x0.
        * destruct Dloop;eauto.
        * reflexivity.
        * rewrite <-Dloop. eapply r1_incl_head_q;eauto. cbn. right. eauto.
      + symmetry. eauto.
    - diamond_subst_qj D. eapply diamond_teq in D as T;eauto.
      2: eapply le_cons_tagle;lia.
      eapply teq_node_disj_prefix_hpath in T;eauto.
      1,2: destruct D;inv_path Dpath1; inv_path Dpath2;eauto.
  Qed.

  Lemma node_disj_hpath s p1 p2 u1 u2 q1 q2 k i l1 l2 j1 j2 r1 r2
        (D : DiamondPaths s u1 u2 p1 p2 q1 q2 k i l1 l2 j1 j2 r1 r2)
        (Hdeq : deq_loop q1 s)
        (Hjeq : j1 = j2)
    : exists r1' r2', HPath u1 p1 (p1 :: r1')
                 /\ HPath u2 p2 (p2 :: r2')
                 /\ Disjoint r1' r2'
                 /\ r1' ⊆ map fst r1
                 /\ r2' ⊆ map fst r2.
  Proof.
    destruct r1,r2.
    - exists [],[].
      destruct D.
      eapply path_single in Dpath1. destruct Dpath1. inv H.
      eapply path_single in Dpath2. destruct Dpath2. inv H.
      split_conj. 1,2: econstructor.
      all: cbn;firstorder 0.
    - copy D D'. destruct D.
      eapply path_single in Dpath1. destruct Dpath1. inv H.
      eapply TPath_CPath in Dpath2. destruct p as [q j]. cbn in Dpath2. inv_path Dpath2.
      cbn in Dqj1, Dqj2. inv Dqj1. inv Dqj2.
      eapply contract_cpath' in H.
      + cbn in Dpath2. destructH.
        exists [], ϕ.
        split_conj. 3,4: cbn;firstorder 0.
        * econstructor.
        * econstructor;eauto. unfold head_rewired_edge. left;split;eauto.
          intros N. eapply no_back2;eauto. rewrite Dloop. eapply loop_contains_self;eauto.
        * cbn. eassumption.
      + rewrite <-Dloop. eapply u2_deq_q; eauto. congruence.
      + cbn. intros. rewrite <-Dloop. eapply no_back2;eauto.
        right. cbn. right. auto.
    - copy D D'. destruct D.
      eapply path_single in Dpath2. destruct Dpath2. inv H.
      eapply TPath_CPath in Dpath1. destruct p as [q j]. cbn in Dpath1. inv_path Dpath1.
      cbn in Dqj1, Dqj2. inv Dqj1. inv Dqj2.
      eapply contract_cpath' in H.
      + cbn in Dpath1. destructH.
        exists ϕ, [].
        split_conj. 3,5: cbn;firstorder 0.
        * econstructor;eauto. unfold head_rewired_edge. left;split;eauto.
          intros N. eapply no_back;eauto;[reflexivity|]. eapply loop_contains_self;eauto.
        * econstructor.
        * cbn. eassumption.
    + eapply u1_deq_q; eauto. congruence.
    + cbn. intros. eapply no_back;eauto;[reflexivity|].
      right. cbn. right. auto.
    - diamond_subst_qj D. subst j2.
      eapply diamond_teq in D as T;eauto;[|reflexivity].
      destruct D.
      eapply teq_node_disj_hpath in T.
      2,3: inv_path Dpath1;inv_path Dpath2;eauto.
      destructH.
      eexists;eexists;split_conj;eauto.
  Qed.
(*
  Lemma teq_node_disj_prefix `(TeqPaths) n1 n2 i
        (Hn1 : j1 = n1 :: i)
        (Hn2 : j2 = n2 :: i)
        (Hlt : n1 < n2)
    : exists h r2', innermost_loop h q1
               /\ Prefix r2' (map fst r2) /\ CPath u2 h r2'
               /\ Disjoint (map fst r1) r2'.
  Admitted.*)

  Lemma tcfg_acyclic
    : acyclic tcfg_edge.
    (* FIXME: tcfg_edge is NOT acyclic (although *rooted* TPaths are) *)
  Admitted.

  Lemma tcfg_edge_edge (q p : Lab) (i j : Tag)
        (Hedge : (q,j) -t> (p,i))
    : q --> p.
  Admitted.

  Hint Resolve tcfg_edge_edge : tcfg.

  Definition nexit_edge q p := forall h, ~ exit_edge h q p.

  Lemma two_edge_exit_cases (q1 q2 p : Lab)
        (Hedge1 : q1 --> p)
        (Hedge2 : q2 --> p)
    : (exists h, exit_edge h q1 p /\ exit_edge h q2 p)
      \/ nexit_edge q1 p /\ nexit_edge q2 p.
  Proof.
  Admitted.

  Lemma nexit_injective q1 q2 p1 p2 j1 j2 i
        (Hedge1 : (q1,j1) -t> (p1,i))
        (Hedge2 : (q2,j2) -t> (p2,i))
        (Hnexit1 : nexit_edge q1 p1)
    : j1 = j2.
  Admitted.
  Ltac spot_path := admit.

  Lemma not_deq_edge_is_exit a b h
        (Edge : a --> b)
        (Hinner : innermost_loop h a)
        (Hndeq : ~ deq_loop b a)
    : exit_edge h a b.
  Proof.
    eapply edge_Edge in Edge.
    inv Edge.
    - exfalso. destruct H as [H _]. eapply Hndeq. eapply eq_loop1. eapply H. reflexivity.
    - exfalso. eapply back_edge_eq_loop in H. eapply Hndeq. eapply eq_loop1. eapply H. reflexivity.
    - exfalso. eapply deq_loop_entry in H. contradiction.
    - destruct H as [h' Hexit].
      enough (h = h').
      + subst h'. eassumption.
      + eauto using exit_edge_innermost, innermost_unique.
  Qed.

  Lemma contains_entry_or_contains_head  a b i m h r
        (Hr : TPath (a,i) (b,m) ((b,m) :: r))
        (Hinner : innermost_loop h b)
    : (exists r' pre, Prefix ((h,0 :: tl m) :: (pre, tl m) :: r') ((b, m) :: r) /\ TPath (a,i) (h, 0 :: tl m) ((h, 0 :: tl m) :: (pre, tl m) :: r') /\ entry_edge pre h)
      \/ forall q, q ∈ map fst r -> loop_contains h q.
  Proof.
  Admitted.

  Lemma prefix_fst_prefix {S T : Type} (a b : list (S * T))
        (Hprefix: Prefix a b)
    : Prefix (map fst a) (map fst b).
  Proof.
    induction Hprefix.
    - econstructor.
    - simpl. econstructor. eauto.
  Qed.

  Lemma map_rcons {A B : Type} (a : A) (r : list A) (f : A -> B)
    : map f (r :r: a) = (map f r) ++ (map f [a]).
  Proof.
    induction r.
    - reflexivity.
    - simpl. rewrite IHr. f_equal.
  Qed.

  Lemma exit_tag_all_contained h q j b n s k r
        (Hpath : TPath (s, k) (q, j) ((q,j) :: (b,n :: j) :: r))
        (Hexit : exit_edge h b q)
        (Hallin : forall q, q ∈ map fst ((b, n :: j) :: r) -> loop_contains h q)
    : exists k', k = k' ++ j.
  Proof.
  Admitted.

  Lemma is_entry_edge h a b
        (Hcont : loop_contains h b)
        (Hncont : ~ loop_contains h a)
        (Hedge : a --> b)
    : entry_edge a b /\ b = h.
  Proof.
    eapply edge_Edge in Hedge.
    inv Hedge.
    - destruct H as [H _]. rewrite H in Hncont. contradiction.
    - eapply back_edge_eq_loop in H. rewrite H in Hncont. contradiction.
    - split; try eassumption. unfold entry_edge in H.
      destruct H as [_ [Hncontba Hedge]].
      eauto using entry_through_header.
    - destruct H as [h' Hexit].
      eapply deq_loop_exited in Hexit.
      exfalso. unfold deq_loop in Hexit. eauto.
  Qed.

  Lemma find_last_exit p q u s k i l j r
        (Hedge : (s,k) -t> (u,l))
        (Dlen: | k | = depth s)
        (Hpath : TPath (u,l) (p,i) ((p,i) :: (q,j) :: r))
        (Hsinq : deq_loop s q)
        (Hndeq : ~ deq_loop q s)
        (Hallin : forall x : Lab, x ∈ map fst ((q, j) :: r) -> deq_loop x q)
    : exists e h qe r' r'' n (m : Tag), r = r'' ++ r'
                                   /\ eq_loop e q
                                   /\ loop_contains h s
                                   /\ exit_edge h qe e
                                   /\ (forall x, x ∈ (q :: map fst r'') -> ~ deq_loop x qe)
                                   /\ take_r (depth h - 1) k = take_r (depth h - 1) m
                                   /\ tl m = tl j
                                   /\ hd (s,k) r' = (qe, n :: m)
                                   /\ TPath (e,m) (p,i) ((p,i) :: (q,j) :: r'')
                                   /\ TPath (u,l) (e,m) ((e,m) :: r').
  Proof.
    revert dependent j.
    revert dependent i.
    revert dependent q.
    revert dependent p.
    specialize (well_founded_ind (R:=(@StrictPrefix' (Lab * Tag))) (@StrictPrefix_well_founded (Lab * Tag))
                                 (fun r => forall p q : Lab,
                                      deq_loop s q ->
                                      ~ deq_loop q s ->
                                      forall i j : Tag,
                                        TPath (u, l) (p, i) ((p, i) :: (q, j) :: r) ->
                                        (forall x : Lab, x ∈ map fst ((q, j) :: r) -> deq_loop x q) ->
                                        exists (e h qe : Lab) (r' r'' : list (Lab * Tag)) (n : nat) (m : Tag),
                                          r = r'' ++ r'
                                          /\ eq_loop e q
                                          /\ loop_contains h s
                                          /\ exit_edge h qe e
                                          /\ (forall x : Lab, x ∈ (q :: map fst r'') -> ~ deq_loop x qe)
                                          /\ take_r (depth h - 1) k = take_r (depth h - 1) m
                                          /\ tl m = tl j
                                          /\ hd (s, k) r' = (qe, n :: m)
                                          /\ TPath (e, m) (p, i) ((p, i) :: (q, j) :: r'')
                                          /\ TPath (u, l) (e, m) ((e, m) :: r'))) as WFind.
    eapply WFind.
    intros r' H p q Hsinq Hndeq i j Hpath Hallin.
    clear WFind.
    unfold TPath in Hpath.

    inv Hpath.
    rename H1 into Hpath. rename H4 into Edge1.
    eapply path_front in Hpath as Htmp; subst b.
    inv Hpath.
    - clear H Hallin.
      assert (Hcont' := Hndeq).
      do 2 (simpl_dec' Hcont').
      destruct Hcont' as [h' [Hcont' _]].
      edestruct loop_contains_innermost as [h Hinner]; try eassumption.
      clear h' Hcont'.
      assert (Hhscont : loop_contains h s) by firstorder.
      assert (Hexit : exit_edge h s q). {
        destruct Hedge. eauto using not_deq_edge_is_exit.
      }
      destruct k as [| n j']. {
        eapply loop_contains_depth_lt in Hhscont. rewrite <- Dlen in Hhscont. inv Hhscont.
      }
      replace j' with j in *.
      2: {
        eapply tag_exit_eq in Hexit; try eassumption. simpl in Hexit. eassumption.
      }
      exists q, h, s, [], [], n, j.
      do 4 (split; eauto; try reflexivity).
      split. {
        intros. simpl in H. inv H; [ eassumption | contradiction ].
      }
      split. {
        admit.
      }
      do 2 (split; [ reflexivity |]).
      split; repeat (econstructor; eassumption).
      econstructor; [ econstructor | eassumption ].
    - rename H1 into Hpath. rename H4 into Edge2.
      destruct b as [b m].
      destruct r' as [| x rb]; [ inv Hpath |].
      eapply path_front in Hpath as Htmp; subst x.
      assert (Hdeqbq : deq_loop b q). {
        eapply Hallin. simpl. eauto.
      }
      assert (Hnoentry : ~ entry_edge b q). {
        intro Hent. destruct Hent as [Hhead [Hent _]].
        apply Hent. unfold deq_loop in Hallin. eapply Hallin.
        simpl. eauto. eauto using loop_contains_self.
      }
      decide (eq_loop q b) as [ Heqqb | Hneqqb ].
      + clear Hdeqbq.
        assert (Hprefix : StrictPrefix' rb ((b, m) :: rb)) by (repeat econstructor).
        edestruct H as [e [h [qe [r' [r'' [n' [m' [Hcons [Heq [Hcont [Hexit [Hndeq' [Hk [Htail [Hhd [Hp1 Hp2]]]]]]]]]]]]]]]].
        * eapply Hprefix.
        * rewrite Heqqb in Hsinq. eapply Hsinq.
        * symmetry in Heqqb. eauto using eq_loop1.
        * econstructor. eapply Hpath. eassumption.
        * intros. eapply eq_loop2. eassumption. eapply Hallin. simpl. eauto.
        * clear H.
          exists e, h, qe, r'. eexists. exists n', m'.
          split. {
            rewrite Hcons. eapply app_comm_cons.
          }
          split. {
            rewrite Heqqb. eassumption.
          }
          split; [ eassumption |].
          split; [ eassumption |].
          split. {
            intros x Hxin. eapply in_inv in Hxin.
            destruct Hxin; [| eauto ].
            subst x. intro. eapply (Hndeq' b); eauto using eq_loop1.
          }
          split; [ eassumption |].
          split. {
            rewrite Htail.
            destruct Edge2 as [Edge2 Heff].
            unfold eff_tag in Heff. decide (b --> q); [| contradiction ].
            destruct (edge_Edge e0).
            - inv Heff. reflexivity.
            - destruct m; inv Heff. reflexivity.
            - exfalso. eauto.
            - exfalso. destruct e1 as [h' Hexit']. destruct Hexit'. eapply H0.
              rewrite Heqqb. eassumption.
          }

          split; [ eassumption |].
          split; [| eassumption ].
          econstructor; eassumption.
      + assert (Hexit : eexit_edge b q). {
          destruct Edge2 as [He Heff].
          eapply edge_Edge in He.
          inv He.
          - destruct H0 as [H0 _]. symmetry in H0. contradiction.
          - eapply back_edge_eq_loop in H0. symmetry in H0. contradiction.
          - contradiction.
          - eassumption.
        }
        destruct Hexit as [h Hexit].
        * edestruct (contains_entry_or_contains_head) with (h := h) (r := rb) as
              [ Hh | Hcontu ]; eauto using exit_edge_innermost.
          -- destruct Hh as [r' [pre [Hpre [Hr' Hentry]]]].
             assert (Hprefix : StrictPrefix' ( r') ((b,m) :: rb)). {
               exists (pre, tl m). eauto using prefix_cons.
             }
             assert (Hpreeqq : eq_loop q pre) by (eauto using enter_exit_same).
             edestruct (H r') as [e [h' [qe [r'' [r''' [n' [m' [Hcons [Heq [Hcont [Hexit' [Hndeq' [Hk [Htail [Hhd [Hp1 Hp2]]]]]]]]]]]]]]]].
             ++ eapply Hprefix.
             ++ rewrite Hpreeqq in Hsinq. eapply Hsinq.
             ++ intro. eapply Hndeq. eapply eq_loop1. symmetry in Hpreeqq. eassumption. eassumption.
             ++ eassumption.
             ++ intros. rewrite <- Hpreeqq. eapply Hallin.
                eapply in_prefix_in. eapply H0. eapply prefix_fst_prefix.
                constructor. eapply prefix_cons in Hpre. eassumption.
             ++ (* exists e, h', qe, , r2, n', m'.
                    split; try eassumption.  *)
               admit.
          -- clear H.
             assert (Hconts : loop_contains h s). {
               decide (loop_contains h s) as [ Hcont | Hncont ]; try eassumption. exfalso.
               edestruct (@is_entry_edge h s u); try eassumption.
               - eapply path_contains_back in Hpath. inv Hpath.
                 * inv H. destruct Hexit. firstorder.
                 * eapply Hcontu. eapply (in_map fst) in H. simpl in H. eassumption.
               - destruct Hedge. eassumption.
               - subst h.
                 enough (eq_loop q s) as Heq.
                 * destruct Heq. contradiction.
                 * eapply enter_exit_same; try eassumption.
             }
             edestruct (tag_exit_eq' Edge2 Hexit) as [n Hn].
             rewrite Hn in *.
             exists q, h, b, ((b, n :: j) :: rb), [], n, j.
             do 4 (split; [ try reflexivity; eauto |]).
             split. {
               intros. destruct H; [| inv H]. subst x. unfold eq_loop in Hneqqb. firstorder.
             }
             split. {
                admit.
                (*
                eapply exit_tag_all_contained.
                ** econstructor; [| eassumption ].
                   eapply path_app in Hedge.
                   2: econstructor.
                   2: eassumption.
                   rewrite cons_rcons_assoc in Hedge. eassumption.
                ** eassumption.
                ** intros. inv H.
                   --- simpl. unfold exit_edge in Hexit. firstorder.
                   --- rewrite map_rcons in H0. simpl in H0. eapply in_app_or in H0. inv H0; eauto.
                       inv H. eauto. inv H0.
*)
             }
             do 2 (split; try reflexivity).
             split.
             ++ econstructor; [ econstructor | eassumption ].
             ++ econstructor; eassumption.
  Admitted.

 Lemma split_DiamondPaths s u1 u2 p1 p2 q1 q2 k i l1 l2 j1 j2 r1 r2
       (Hndeq : ~ deq_loop q1 s)
       (Htagle : j1 ⊴ j2)
       (D : DiamondPaths s u1 u2 p1 p2 q1 q2 k i l1 l2 j1 j2 ((q1,j1) :: r1) ((q2,j2) :: r2))
   : exists r1' r2' r1'' r2'' e1 e2 n1 n2 q1' q2',
     r1 = r1'' ++ r1'
     /\ r2 = r2'' ++ r2'
     /\ DiamondPaths s u1 u2 e1 e2 q1' q2' k j1 l1 l2 (n1 :: j1) (n2 :: j1) r1'  r2'
     /\ TeqPaths e1 e2 q1 q2 j1 j1 j1 j2 r1'' r2''
     /\ (forall x, x ∈ (q1 :: map fst r1'') -> ~ deq_loop x q1')
     /\ (forall x, x ∈ (q2 :: map fst r2'') -> ~ deq_loop x q2')
     /\ eexit_edge q1' e1
     /\ eexit_edge q2' e2.
 Proof.
 Admitted.

 Lemma inhom_loop_exits_step_lt
       (s u1 u2 q1 q2 e1 e2 : Lab)
       (k l1 l2 i : Tag)
       (m n1 n2 : nat)
       (IHm : forall (q1 q2 e1 e2 : Lab) (r1 r2 : list (Lab * Tag)) (n1 n2 : nat) (i : Tag),
           DiamondPaths s u1 u2 e1 e2 q1 q2 k i l1 l2 (n1 :: i) (n2 :: i) r1 r2 ->
           m = depth s - depth q1 ->
           exists r1' r2' : list Lab,
             HPath u1 e1 (e1 :: r1') /\
             HPath u2 e2 (e2 :: r2') /\ Disjoint r1' r2' /\ r1' <<= map fst r1 /\ r2' <<= map fst r2)
       (r1 r2 : list (Lab * Tag))
       (D : DiamondPaths s u1 u2 e1 e2 q1 q2 k i l1 l2 (n1 :: i) (n2 :: i) ((q1, n1 :: i) :: r1)
                         ((q2, n2 :: i) :: r2))
       (Heqm : S m = depth s - depth q1)
       (Hqs : ~ deq_loop q1 s)
       (Hlt : n1 < n2)
   : exists r1' r2' : list Lab,
     HPath u1 e1 (e1 :: r1') /\
     HPath u2 e2 (e2 :: r2') /\
     Disjoint r1' r2' /\
     r1' <<= map fst ((q1, n1 :: i) :: r1) /\ r2' <<= map fst ((q2, n2 :: i) :: r2).
 Proof.
   eapply split_DiamondPaths in D as Dsplit;eauto.
   2: { eapply le_cons_tagle. lia. }
   destructH.
   subst r1 r2.
   eapply IHm in Dsplit1 as Hinhom.
   2: {
     enough (depth q1' = S (depth q1)).
     - clear - Heqm H.
       rewrite H. lia.
     - copy Dsplit6 Hexit.
       eapply depth_exit in Dsplit6. rewrite Dsplit6. f_equal. eapply eq_loop_depth.
       destruct Hexit.
       eapply u1_exit_eq_q;eauto.
   }
   destructH.
   assert ((q1, n1 :: i) -t> (e1, i)) as Hedge1.
   { destruct D. inv_path Dpath1;eauto. }
   assert ((q2, n2 :: i) -t> (e2, i)) as Hedge2.
   { destruct D. inv_path Dpath2;eauto. }
   eapply teq_node_disj_prefix_hpath in Dsplit3 as Dinst;eauto.
   destructH.
   exists (r1'1 ++ tl (e0 :: r1'0)), (r2'1 ++ tl (e3 :: r2'0)).
   split_conj.
   - rewrite app_comm_cons. eapply path_app';eauto.
   - rewrite app_comm_cons. eapply path_app';eauto.
   - cbn.
      eapply disjoint_app_app;eauto.
      + intros x Hx.
         eapply Dinst3 in Hx.
         specialize (Dsplit4 x Hx).
         intro N.
         eapply Hinhom5 in N.
         eapply r2_incl_head_q in N;eauto.
      + eapply Disjoint_sym.
         intros x Hx.
         eapply Dinst5 in Hx.
         specialize (Dsplit5 x Hx).
         intro N.
         eapply Hinhom3 in N.
         eapply r2_incl_head_q in N;eauto.
         eapply DiamondPaths_sym. eauto.
   - cbn. rewrite map_app. rewrite app_comm_cons.
      eapply incl_app_app;eauto.
   - cbn. rewrite map_app. rewrite app_comm_cons.
     eapply incl_app_app;eauto.
 Qed.

 Lemma inhom_loop_exits (s u1 u2 q1 q2 e1 e2 : Lab) r1 r2 (k i l1 l2 : Tag) (n1 n2 : nat)
        (D : DiamondPaths s u1 u2 e1 e2 q1 q2 k i l1 l2 (n1 :: i) (n2 :: i) r1 r2)
    : exists r1' r2', HPath u1 e1 (e1 :: r1') /\ HPath u2 e2 (e2 :: r2')
                 /\ Disjoint r1' r2'
                 /\ r1' ⊆ map fst r1 /\ r2' ⊆ map fst r2.
 Proof.
   remember (depth s - depth q1) as m.
   revert q1 q2 e1 e2 r1 r2 n1 n2 i D Heqm.
   induction m;intros.
   - assert (depth s = depth q1) as Hseqq.
     {
       enough(depth q1 <= depth s);[lia|].
       eapply deq_loop_depth. eauto using s_deq_q.
     }
     assert (deq_loop q1 s) as Hdeq.
     { eapply deq_loop_depth_eq;eauto using s_deq_q. }
     specialize (Nat.lt_trichotomy n1 n2) as Htri. destruct Htri as [Hlt|[Heq|Hlt]];cycle 1.
     + subst n2. eapply node_disj_hpath in D as Hndisj;eauto.
     + eapply DiamondPaths_sym in D.
       eapply node_disj_prefix_hpath in D as Hndisj;eauto.
       2: eapply eq_loop1;eauto;symmetry; eauto using Dloop.
       destructH.
       exists r2', r1'.
       split_conj;eauto.
       eapply Disjoint_sym;eauto.
     + eapply node_disj_prefix_hpath in D as Hndisj;eauto.
   - destruct r1,r2. (* all nil cases can be contradicted *)
     1-3: exfalso;destruct D; cbn in Dqj1,Dqj2.
     1,2: inv Dqj1. 1,3: inv Dqj2.
     1-3: tryif lia then idtac else rewrite Dloop in Heqm;lia.
     diamond_subst_qj D.
     assert (~ deq_loop q1 s) as Hqs.
     { intro N. eapply deq_loop_depth in N. lia. }
     specialize (Nat.lt_trichotomy n1 n2) as [Hlt|[Hlt|Hlt]].
     + eapply inhom_loop_exits_step_lt;eauto.
     + eapply split_DiamondPaths in D as Dsplit;eauto.
       2: { eapply le_cons_tagle. lia. }
       destructH.
       subst r1 r2 n2.
       eapply IHm in Dsplit1 as Hinhom.
       2: {
         enough (depth q1' = S (depth q1)).
         - clear - Heqm H.
           rewrite H. lia.
         - copy Dsplit6 Hexit.
           eapply depth_exit in Dsplit6. rewrite Dsplit6. f_equal. eapply eq_loop_depth.
           destruct Hexit.
           eapply u1_exit_eq_q;eauto.
       }
       destructH.
       assert ((q1, n1 :: i) -t> (e1, i)) as Hedge1.
       { destruct D. inv_path Dpath1;eauto. }
       assert ((q2, n1 :: i) -t> (e2, i)) as Hedge2.
       { destruct D. inv_path Dpath2;eauto. }
       eapply teq_node_disj_hpath in Dsplit3 as Dinst;eauto.
       destructH.
       exists ((q1 :: r1'1) ++ tl (e0 :: r1'0)), ((q2 :: r2'1) ++ tl (e3 :: r2'0)).
       split_conj.
       -- rewrite app_comm_cons. eapply path_app';eauto.
       -- rewrite app_comm_cons. eapply path_app';eauto.
       -- cbn.
          do 2 rewrite app_comm_cons.
          eapply disjoint_app_app;eauto.
          ++ intros x Hx.
             eapply Dinst3 in Hx.
             specialize (Dsplit4 x Hx).
             intro N.
             eapply Hinhom5 in N.
             eapply r2_incl_head_q in N;eauto.
          ++ eapply Disjoint_sym.
             intros x Hx.
             eapply Dinst5 in Hx.
             specialize (Dsplit5 x Hx).
             intro N.
             eapply Hinhom3 in N.
             eapply r2_incl_head_q in N;eauto.
             eapply DiamondPaths_sym. eauto.
   -- cbn. rewrite map_app. rewrite app_comm_cons.
      rewrite app_comm_cons. eapply incl_app_app;eauto.
   -- cbn. rewrite map_app. rewrite app_comm_cons.
      rewrite app_comm_cons. eapply incl_app_app;eauto.
     + copy D D'.
       eapply DiamondPaths_sym in D.
       eapply inhom_loop_exits_step_lt in D.
       * destructH. repeat eexists;eauto. eapply Disjoint_sym;eauto.
       * intros.
         enough (exists r2' r1' : list Lab,
                    HPath u1 e3 (e3 :: r2')
                    /\ HPath u2 e0 (e0 :: r1')
                    /\ Disjoint r2' r1'
                    /\ r2' <<= map fst r3
                    /\ r1' <<= map fst r0).
         { clear - H1. firstorder. }
         eapply IHm.
         -- eapply DiamondPaths_sym. exact H.
         -- destruct H. rewrite <-Dloop. eauto.
       * rewrite <-Dloop. eauto.
       * intro N. eapply eq_loop1 in N;[eauto|symmetry;eauto]. eapply Dloop.
       * eauto.
 Qed.


  Lemma contract_one_empty s u2 p i q2 r2 k l2
        (Hin2 : Path tcfg_edge (u2, l2) (p, i) ((p, i) :: (q2, k) :: r2))
        (Hin4 : (s, k) -t> (u2, l2))
        (Hqp1 : (s, k) -t> (p, i))
        (D : DiamondPaths s p u2 p p s q2 k i i l2 k k [] ((q2, k) :: r2))
    : exists (π ϕ : list Lab) (u u' : Lab),
      HPath u p π /\
      HPath u' p ϕ /\ Disjoint (tl π) (tl ϕ) /\ s --> u /\ s --> u' /\ (tl π <> [] \/ tl ϕ <> []).
  Proof.
    eapply TPath_CPath in Hin2. cbn in Hin2. inv_path Hin2.
    eapply contract_cpath' in H.
    - cbn in Hin2. destructH.
      exists (p :: ϕ), [p], u2, p.
      split_conj.
      + econstructor;eauto. unfold head_rewired_edge. left;split;eauto.
         intros N. eapply no_back2;eauto. rewrite Dloop. eapply loop_contains_self;eauto.
      + econstructor.
      + cbn. unfold Disjoint. firstorder.
      + destruct Hin4;eauto.
      + destruct Hqp1;eauto.
      + cbn. left. inv_path H1; congruence.
    - cbn. rewrite <-Dloop. eapply u2_deq_q; eauto. congruence.
    - cbn. intros. rewrite <-Dloop. eapply no_back2;eauto.
      right. cbn. right. auto.
  Qed.

  Theorem splits_sound p
    : splitsT p ⊆ splits p.
  Proof.
    intros s Hin.
    eapply splitsT_spec in Hin.
    destructH.
    (* contradict π and ϕ (the paths from (u,l) to (p,i)) being empty *)
    destruct π as [|pi1 r1]; destruct ϕ as [|pi2 r2]; cbn in Hin1, Hin5.
    1: tauto.
    1: inversion Hin0.
    1: inversion Hin2.
    unfold TPath in Hin0. path_simpl' Hin0.
    unfold TPath in Hin2. path_simpl' Hin2.
    eapply edge_path_hd_edge in Hin0 as Hqp1;eauto.
    eapply edge_path_hd_edge in Hin2 as Hqp2;eauto.
    rewrite hd_map_fst_snd in Hqp1, Hqp2.
    set (q1 := hd s (map fst r1)) in *.
    set (q2 := hd s (map fst r2)) in *.
    set (j1 := hd k (map snd r1)) in *.
    set (j2 := hd k (map snd r2)) in *.
    specialize (@two_edge_exit_cases q1 q2 p) as Hcase.
    exploit Hcase.
    1: eapply TPath_CPath in Hin0.
    2: eapply TPath_CPath in Hin2.
    1,2: cbn in Hin0,Hin2.
    1: eapply edge_path_hd_edge in Hin0;subst q1;eauto.
    2: eapply edge_path_hd_edge in Hin2;subst q2;eauto.
    1,2: destruct Hin3,Hin4;eauto.
    eassert (DiamondPaths s u1 u2 p p q1 q2 k i l1 l2 j1 j2 (r1) (r2)) as D.
    {
      econstructor. 3: eapply Hin0. 3: eapply Hin2.
      all:cbn;eauto.
      1,2: subst q1 q2 j1 j2;eapply hd_map_fst_snd.
      destruct Hcase.
      - destructH. eapply eq_loop_exiting in H0. eapply eq_loop_exiting in H1.
        rewrite <-H0. rewrite <-H1. reflexivity.
      - destructH.
        eapply nexit_injective in H0;eauto. subst j1 j2.
        eapply tcfg_edge_eq_loop;eauto. rewrite H0. eauto.
    }
    destruct Hcase.
    - destructH.
      eapply tag_exit_eq' in H0 as Hn1;eauto. destruct Hn1 as [n1 Hn1].
      eapply tag_exit_eq' in H1 as Hn2;eauto. destruct Hn2 as [n2 Hn2].
      subst j1 j2. rewrite Hn1 in D. rewrite Hn2 in D.
      eapply inhom_loop_exits in D as Hinhom.
      destructH.
      eapply splits_spec.
      exists (p :: r1'), (p :: r2'), u1, u2.
      split_conj;eauto;cbn.
      1,2: destruct Hin3,Hin4;eauto.
      destruct r1';[|left;congruence].
      destruct r2';[|right;congruence].
      exfalso.
      eapply path_single in Hinhom0. destruct Hinhom0 as [Hinhom0 _]. subst u1.
      eapply path_single in Hinhom2. destruct Hinhom2 as [Hinhom2 _]. subst u2.
      eapply tcfg_edge_det in Hin3;eauto. subst l2.
      inv_path Hin0; inv_path Hin2.
      + tauto.
      + subst q1. destruct r2;[inv H|]. eapply path_acyclic_no_loop. 2: eapply Hin2.
        eapply tcfg_acyclic.
      + subst q2. destruct r1;[inv H|]. eapply path_acyclic_no_loop. 2: eapply Hin0.
        eapply tcfg_acyclic.
      + eapply Hin1.
        1,2: eapply path_contains_back;eauto.
    - destructH.
      subst q1 q2 j1 j2.
      eapply nexit_injective in H0;eauto.
      rewrite <-hd_map_fst_snd in Hqp1,Hqp2.
      destruct r1 as [|[q1 j1] r1]; destruct r2 as [|[q2 j2] r2];
        unfold hd in Hqp1,Hqp2.
      + tauto.
      + cbn in D,H0. subst j2.
        eapply splits_spec. eapply path_single in Hin0. destruct Hin0. inversion H. subst.
        clear H0 H1 Hin1 Hin3 Hin5 H. clear Hqp2.
        eapply contract_one_empty;eauto.
      + eapply DiamondPaths_sym in D.
        cbn in D,H0. subst j1.
        eapply splits_spec. eapply path_single in Hin2. destruct Hin2. inversion H. subst.
        eapply contract_one_empty;eauto.
      + cbn in H0. subst j2.
        decide (deq_loop q1 s).
        * eapply (diamond_teq) in D as T;eauto. 2: reflexivity.
          eapply teq_node_disj_hpath in T as Hdisj;eauto.
          destructH.
          eapply splits_spec.
          repeat eexists;split_conj.
          1: eapply Hdisj0. 1: eapply Hdisj2.
          all: cbn;eauto.
          1,2: destruct Hin3,Hin4;eauto.
          left. congruence.
        * eapply split_DiamondPaths in D;eauto. 2: reflexivity.
          destructH. subst r1 r2.
          eapply inhom_loop_exits in D1 as Hinhom.
          eapply splits_spec.
          destructH.
          eapply teq_node_disj_hpath in D3 as Dinst;eauto.
          destructH.
          exists ((p :: q1 :: r1'1) ++ tl (e1 :: r1'0)), ((p :: q2 :: r2'1) ++ tl (e2 :: r2'0)), u1, u2.
          split_conj. 4,5: destruct Hin3,Hin4;eauto.
          -- eapply path_app';eauto.
          -- eapply path_app';eauto.
          -- cbn.
             do 2 rewrite app_comm_cons.
             eapply disjoint_app_app;eauto.
             ++ intros x Hx.
                eapply Dinst3 in Hx.
                specialize (D4 x Hx).
                intro N.
                eapply Hinhom5 in N.
                eapply r2_incl_head_q in N;eauto.
             ++ eapply Disjoint_sym.
                intros x Hx.
                eapply Dinst5 in Hx.
                specialize (D5 x Hx).
                intro N.
                eapply Hinhom3 in N.
                eapply r2_incl_head_q in N;eauto.
                eapply DiamondPaths_sym. eauto.
          -- cbn. left. congruence.
  Qed.

End splits_sound.
