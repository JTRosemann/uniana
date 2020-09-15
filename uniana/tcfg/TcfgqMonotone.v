Require Export TcfgLoop.
Require Import Lia.

Section cfg.

  Context `(C : redCFG).

  Lemma tcfg_reachability q j
        (Hlen : | j | = depth q)
    : exists t, TPath (root,start_tag) (q,j) t.
  Proof.
    specialize (reachability q) as Hreach.
    destructH.
    revert q j Hlen Hreach.
    induction π;intros.
    - inv Hreach.
    - destruct π.
      + path_simpl' Hreach.
        rewrite depth_root in Hlen. destruct j;[|cbn in Hlen;congruence].
        eexists;econstructor;eauto.
      + admit.
  Admitted.

  Lemma tag_depth_unroot p q i j t
        (Hpath : TPath (q,j) (p,i) t)
        (Hlen : |j| = depth q)
    : |i| = depth p.
  Proof.
    eapply tcfg_reachability in Hlen.
    destructH.
    eapply path_app' in Hpath;eauto.
    eapply tag_depth';eauto.
  Qed.

  Lemma take_r_leq_cons (A : Type) (a : A) l n
        (Hlen : n <= |l|)
    : take_r n (a :: l) = take_r n l.
  Admitted.

  Lemma take_r_leq_cons2 (A : Type) (a b : A) l n
        (Hlen : n <= |l|)
    : take_r n (a :: l) = take_r n (b :: l).
  Admitted.

  Lemma tagle_take_r i j n
        (Htagle : i ⊴ j)
    : take_r n i ⊴ take_r n j.
  Admitted.

  (* the more general formulation with deq_loop is wrong *)
  Lemma tpath_tag_take_r_eq p i q j t h n
        (Hlen : |j| = depth q)
        (Hpath : TPath (q,j) (p,i) t)
        (Hincl : forall r, r ∈ map fst t -> deq_loop r h)
        (Hdep : depth h = n)
    : take_r (n-1) j = take_r (n-1) i.
  Proof.
    revert p i Hpath.
    induction t;intros; inv_path Hpath.
    - reflexivity.
    - case (depth h) eqn:E.
      { cbn. reflexivity. }
      exploit' IHt.
      { intros. eapply Hincl. right. auto. }
      destruct x.
      copy Hincl Hincl'.
      eapply deq_loop_depth in Hincl.
      2: { right. eapply path_contains_front in H. eapply in_map with (f:=fst) in H. cbn in H;eauto. }
      eapply tcfg_edge_destruct' in H0.
      eapply tag_depth_unroot in H as Htagt0;eauto.
      destruct H0 as [[H0 Q0]|[[H0 Q0]|[[H0 Q0]|[H0 Q0]]]].
      + subst. eapply IHt;eauto.
      + subst.
        eapply depth_entry in Q0.
        rewrite take_r_leq_cons.
        * eapply IHt;eauto.
        * rewrite Htagt0. lia.
      + destruct t0.
        { cbn in Htagt0. lia. }
        cbn in H0. subst i.
        erewrite take_r_leq_cons2.
        * eapply IHt;eauto.
        * cbn in Htagt0. clear - E Hincl Htagt0. rewrite E in Hincl. rewrite <-Htagt0 in Hincl. lia.
      + destruct t0. 1:cbn in Htagt0;lia.
        cbn in H0. subst.
        setoid_rewrite <-take_r_leq_cons at 2.
        * eapply IHt;eauto.
        * cbn in Htagt0. lia.
  Qed.

  Lemma weak_monotonicity q j p i t h n
        (Hlen : |j| = depth q)
        (Hpath : TPath (q,j) (p,i) t)
        (Hincl : forall r, r ∈ map fst t -> deq_loop r h)
        (Hdep : depth h = n)
    : take_r n j ⊴ take_r n i.
  Proof.
    revert p i Hpath.
    induction t;intros; inv_path Hpath.
    - reflexivity.
    - case (depth h) eqn:E.
      { cbn. reflexivity. }
      exploit' IHt.
      { intros. eapply Hincl. right. auto. }
      destruct x.
      copy Hincl Hincl'.
      eapply deq_loop_depth in Hincl.
      2: { right. eapply path_contains_front in H. eapply in_map with (f:=fst) in H. cbn in H;eauto. }
      eapply tcfg_edge_destruct' in H0.
      eapply tag_depth_unroot in H as Htagt0;eauto.
      destruct H0 as [[H0 Q0]|[[H0 Q0]|[[H0 Q0]|[H0 Q0]]]].
      + subst. eapply IHt;eauto.
      + subst.
        eapply depth_entry in Q0.
        setoid_rewrite take_r_leq_cons.
        * eapply IHt;eauto.
        * rewrite Htagt0. lia.
      + destruct t0.
        { cbn in Htagt0. lia. }
        rewrite H0.
        transitivity (take_r (S n) (n0 :: t0)).
        * eapply IHt;eauto.
        * unfold STag.
          eapply tagle_take_r.
          econstructor.
          econstructor.
          lia.
      + specialize (Hincl' p). exploit Hincl'. 1: left;cbn;eauto.
        destruct t0. 1:cbn in Htagt0;lia.
        cbn in H0. subst.
        setoid_rewrite <-take_r_leq_cons at 2.
        * eapply IHt;eauto.
        * cbn in Htagt0.
          eapply depth_exit in Q0.
          eapply deq_loop_depth in Hincl'.
          rewrite Q0 in Htagt0. lia.
  Qed.

  Lemma non_entry_head_back_edge p h
        (Hedge : edge__P p h)
        (Hloop : loop_contains h p)
    : p ↪ h.
  Admitted.

  Lemma prefix_map_fst (A B : Type) (l l' : list (A * B))
        (Hpre: Prefix l l')
    : Prefix (map fst l) (map fst l').
  Proof.
    induction Hpre.
    - econstructor.
    - destruct a. cbn. econstructor;eauto.
  Qed.

  Lemma postfix_map_fst (A B : Type) (l l' : list (A * B))
        (Hpre: Postfix l l')
    : Postfix (map fst l) (map fst l').
  Proof.
    eapply prefix_rev_postfix'.
    do 2 rewrite <-map_rev.
    eapply prefix_map_fst.
    eapply postfix_rev_prefix;eauto.
  Qed.

  Lemma taglt_stag n (i : Tag)
    : n :: i ◁ STag (n :: i).
  Proof.
    cbn. econstructor. auto.
  Qed.
  Lemma taglt_tagle_trans (i j k : Tag)
    : i ◁ j -> j ⊴ k -> i ◁ k.
  Admitted.
  Lemma tagle_taglt_trans (i j k : Tag)
    : i ⊴ j -> j ◁ k -> i ◁ k.
  Admitted.
  Lemma take_r_geq (A : Type) n (l : list A)
        (Hgeq : n >= | l |)
    : take_r n l = l.
  Admitted.

  Lemma tcfg_edge_depth_iff p q i j
        (Hedge : tcfg_edge (p,i) (q,j))
    : | i | = depth p <-> | j | = depth q.
  Admitted.

  Lemma taglt_take_r_taglt i j n
        (Hlt : take_r n i ◁ take_r n j)
        (Hlen : | i | = | j |)
    : i ◁ j.
  Admitted.

  Lemma tagle_neq_taglt (i j : Tag)
    : i ⊴ j -> i <> j -> i ◁ j.
  Admitted.

  Lemma tcfg_fresh p i j t
        (Hpath : TPath (p,i) (p,j) t)
        (Hdep : | i | = depth p)
        (Hlen : | t | >= 2)
    : i ◁ j.
  Proof.
    eapply TPath_CPath in Hpath as Hpp.
    eapply p_p_ex_head in Hpp.
    2: rewrite map_length;eauto.
    destructH.
    destruct t. 1: inv Hpath.
    eapply in_fst in Hpp0. destruct Hpp0 as [k Hpp0].
    unfold TPath in *. path_simpl' Hpath.
    eapply path_from_elem' in Hpp0 as Hπ;eauto.
    destructH.
    eapply postfix_eq in Hπ1.
    destruct Hπ1 as [ϕ Hπ1].
    rewrite <-app_assoc in Hπ1.
    unfold app at 2 in Hπ1.
    assert (Prefix ((h,k) :: ϕ) ((p,j) :: t)) as Hpreϕ.
    { eapply prefix_eq. eexists;eauto. }
    eapply path_prefix_path in Hpath as Hϕ;eauto.
    inv_path Hϕ.
    {
      cbn in Hπ1.
      destruct equiv_dec in Hπ1.
      - cbn in Hπ1.
        destruct t;[|congruence]. cbn in Hlen. lia.
      - eapply tagle_neq_taglt.
        + erewrite <-take_r_geq with (n:=depth h).
          2: { erewrite tag_depth_unroot;eauto. }
          rewrite <-take_r_geq with (n:=depth h) at 1.
          2: { erewrite tag_depth_unroot;eauto. }
          eapply weak_monotonicity in Hpath. all:eauto.
          eauto using loop_contains_deq_loop.
        + contradict c0. intro. subst. apply H. reflexivity.
    }
    destruct x.
    assert (e ↪ h) as Hback.
    { eapply non_entry_head_back_edge. 1: destruct H0;eauto.
      eapply Hpp1. fold (fst (e,t0)). eapply in_map. eapply prefix_incl;eauto.
      right. eapply path_contains_front;eauto.
    }
    eapply weak_monotonicity in H;eauto.
    2: { intros. eapply loop_contains_deq_loop. eapply Hpp1. eapply prefix_incl;eauto.
         eapply prefix_map_fst;eauto. eapply prefix_cons;eauto.
    }
    eapply weak_monotonicity in Hπ0;eauto.
    3: {
      intros. eapply loop_contains_deq_loop. eapply Hpp1. eapply postfix_incl;eauto.
      eapply postfix_map_fst.
      eapply postfix_nincl_spec;eauto.
    }
    2: { eapply tag_depth_unroot in Hdep;eauto. }
    assert (| k | = depth h) as Hhdep.
    { eapply tag_depth_unroot;eauto. }
    destruct t0.
    { eapply back_edge_eq_loop in Hback. eapply tcfg_edge_depth_iff in Hhdep;eauto.
      rewrite Hback  in Hhdep. cbn in Hhdep.
      enough (0 > 0) by lia.
      rewrite Hhdep at 1. eapply depth_loop_head.
      eapply loop_contains_loop_head. eapply Hpp1. fold (fst (h,k)). eapply in_map. eauto.
    }
    eapply tag_back_edge_iff in Hback;eauto.
    specialize (taglt_stag n t0) as Hlt. subst k.
    rewrite take_r_geq in Hπ0. 2: setoid_rewrite Hhdep; lia.
    setoid_rewrite take_r_geq in H at 2. 2: setoid_rewrite Hhdep; lia.
    eapply tagle_taglt_trans in Hlt;eauto.
    eapply taglt_tagle_trans in Hlt;eauto.
    eapply taglt_take_r_taglt;eauto.
    rewrite Hdep.
    erewrite tag_depth_unroot;eauto.
  Qed.

  Lemma basic_edge_eq_loop p q
        (Hedge : basic_edge p q)
    : eq_loop p q.
  Proof.
    destruct Hedge;auto.
  Qed.

  (* (tl (take_r (depth h) j)) *)
  Lemma ex_entry (h p q : Lab) (i j : Tag) n t
        (Hlen : | i | = depth p)
        (Hin : loop_contains h q)
        (Hnin : ~ loop_contains h p)
        (Hpath : TPath (p,i) (q,j) t)
        (Hdep : depth h = n)
    : (h,0 :: (take_r (n-1) j)) ∈ t.
  Proof.
  Admitted.

  Lemma ex_entry_rooted (h q : Lab) (j : Tag) n t
        (Hin : loop_contains h q)
        (Hpath : TPath (root,start_tag) (q,j) t)
        (Hdep : depth h = n)
    : (h,0 :: (take_r (n-1) j)) ∈ t.
  Proof.
  Admitted.

  Lemma taglt_leq i j m n
        (Htaglt : take_r m j ◁ take_r m i)
        (Hleq : m <= n)
    : take_r n j ◁ take_r n i.
  Admitted.

  Lemma taglt_cons i j n
    : n :: i ◁ n :: j <-> i ◁ j.
  Admitted.

  Lemma taglt_cons_cons i j n m
        (Htaglt : i ◁ j)
    : n :: i ◁ m :: j.
  Admitted.

  Lemma take_r_len (A : Type) n (l : list A)
        (H : n <= | l |)
    : | take_r n l | = n.
  Admitted.

  Lemma take_r_self (A : Type) (l : list A)
    : take_r (|l|) l = l.
  Admitted.

  Lemma taglt_tagle (i j : Tag)
    : i ◁ j -> i ⊴ j.
  Proof.
    intros. left. auto.
  Qed.

  Lemma take_r_take_r_leq (A : Type) (l : list A) n m
        (Hle : n <= m)
    : take_r n (take_r m l) = take_r n l.
  Admitted.

  Lemma monotone q j p i t h n
        (Hlen : |j| = depth q)
        (Hpath : TPath (q,j) (p,i) t)
        (Hdeqq : deq_loop q h)
        (Hdeqp : deq_loop p h)
        (Hdep : depth h = n)
    : take_r n j ⊴ take_r n i.
  Proof.
    revert n h p i Hpath Hdeqp Hdeqq Hdep.
    induction t;intros; inv_path Hpath.
    - reflexivity.
    - case (depth h) eqn:E.
      { cbn. reflexivity. }
      destruct x.
      eapply tcfg_edge_destruct' in H0.
      eapply tag_depth_unroot in H as Htagt0;eauto.
      destruct H0 as [[H0 Q0]|[[H0 Q0]|[[H0 Q0]|[H0 Q0]]]].
      + subst. eapply IHt;eauto.
        eapply basic_edge_eq_loop in Q0. symmetry in Q0. eapply eq_loop1;eauto.
      + decide (loop_contains p q).
        * subst i.
          specialize (tcfg_reachability Hlen) as Hreach.
          destructH.
          eapply ex_entry_rooted in Hreach as Hentry;eauto.
          eapply path_from_elem in Hentry;eauto.
          destructH.
          eapply path_app' in Hpath;eauto.
          eapply depth_entry in Q0 as Q1.
          eapply loop_contains_deq_loop in l as Hdeppq. eapply deq_loop_depth in Hdeppq.
          assert (depth p - 1 = depth e) as Hdeppe by lia.
          eapply deq_loop_depth in Hdeqq as Hdepq.
          eapply deq_loop_depth in Hdeqp as Hdepp.
          eapply tcfg_fresh in Hpath.
          2: {
            cbn.
            rewrite take_r_len.
            1: lia.
            lia.
          }
          2: { cbn. destruct t;[inv H|]. cbn. lia. }
          rewrite taglt_cons in Hpath.
          decide (depth p - 1 <= S n).
          -- left.
             eapply taglt_leq with (m:=depth p - 1).
             2: lia.
             rewrite take_r_leq_cons.
             2: lia.
             rewrite Hdeppe at 2. rewrite <-Htagt0.
             rewrite take_r_self. eassumption.
          -- eapply taglt_tagle in Hpath. eapply tagle_take_r with (n:=S n) in Hpath.
             rewrite take_r_leq_cons.
             2: lia.
             rewrite take_r_take_r_leq in Hpath.
             2: lia.
             eassumption.
        * subst i.
          assert (deq_loop e h) as Hdeqe.
          {
            intros h' Hh'.
             eapply deq_loop_entry_or in Q0;cycle 1.
             { eapply Hdeqp;eauto. }
             destruct Q0.
             - auto.
             - exfalso.
               subst p. eapply n0. eauto using loop_contains_deq_loop.
          }
          rewrite take_r_leq_cons.
          -- eapply IHt;eauto.
          -- rewrite Htagt0. rewrite <-E. eapply deq_loop_depth. auto.
      + destruct t0.
        { exfalso. cbn in Htagt0. eapply back_edge_eq_loop in Q0.
          rewrite Q0 in Htagt0. enough (depth p > 0) by lia.
          eapply deq_loop_depth in Hdeqp. lia.
        }
        rewrite H0.
        transitivity (take_r (S n) (n0 :: t0)).
        * eapply IHt;eauto.
          eapply back_edge_eq_loop in Q0. symmetry in Q0. eapply eq_loop1;eauto.
        * unfold STag.
          eapply tagle_take_r.
          econstructor.
          econstructor.
          lia.
      + destruct t0.
        {
          exfalso.
          cbn in Htagt0.
          eapply depth_exit in Q0.
          lia.
        }
        eapply IHt in H;eauto.
        * cbn in H0. subst t0.
          setoid_rewrite <-take_r_leq_cons at 2;eauto.
          eapply deq_loop_depth in Hdeqp.
          erewrite tag_depth_unroot;eauto. lia.
        * transitivity p;eauto.
          destruct Q0. eapply deq_loop_exited;eauto.
  Qed.

End cfg.