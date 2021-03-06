Require Export CFGinnermost CFGgeneral EEdge.

Section hr_cfg.
  Context `{C : redCFG}.

  Definition head_rewired_edge q p : Prop
    := edge__P q p /\ ~ loop_head q \/ exited q p.

  Infix "-h>" := (head_rewired_edge) (at level 70).

  (* the head rewired DAG is not a redCFG (because of unreachability) *)

  Definition HPath := Path head_rewired_edge.

  Lemma head_rewired_not_contains p q
        (Hedge : head_rewired_edge p q)
    : ~ loop_contains p q.
  Proof.
    destruct Hedge.
    - destructH. contradict H1. eapply loop_contains_loop_head;eauto.
    - destruct H. destruct H. destructH. assumption.
  Qed.

  Lemma head_rewired_no_self p
        (Hedge : head_rewired_edge p p)
    : False.
  Proof.
    destruct Hedge.
    - destruct H. eapply no_self_loops;eauto.
    - destruct H. destruct H. destruct H0. eauto using loop_contains_self, loop_contains_loop_head.
  Qed.

  Lemma head_rewired_head_no_entry h p t
        (Hloop : loop_contains h p)
        (Hpath : HPath h p t)
    : h = p.
  Proof.
    revert p Hpath Hloop.
    induction t;intros;inv_path Hpath.
    - reflexivity.
    - decide (loop_contains h x).
      + exfalso.
        eapply IHt in H;subst;eauto.
        eapply head_rewired_not_contains;eauto.
      + destruct H0.
        * destruct H0. eapply entry_through_header in n;eauto.
        * destruct H0. eapply deq_loop_exited' in H0. eapply H0 in Hloop. contradiction.
  Qed.

  Lemma head_rewired_cycle_not_contains p q t
        (Hpath : HPath p q t)
        (Hedge : q -h> p) x y
        (Hinx : x ∈ t)
        (Hiny : y ∈ t)
        (Hloop : loop_contains x y)
    : x = y.
  Proof.
    eapply in_split in Hinx as Hsplitx.
    destructH.
    rewrite Hsplitx in Hiny.
    eapply in_app_or in Hiny.
    cbn in Hiny.
    eapply path_postfix_path in Hpath as Hx;eauto.
    2: { rewrite postfix_eq. setoid_rewrite <-app_cons_assoc. exists l2. eassumption. }
    destruct Hiny as [Hiny|[Hiny|Hiny]];[|assumption|].
    - eapply in_split in Hiny as Hsplity.
      destructH.
      eapply path_prefix_path in Hpath as Hy;eauto.
      2: { eapply prefix_eq. exists l0. rewrite Hsplity in Hsplitx. rewrite <-app_assoc in Hsplitx.
           cbn in Hsplitx. eassumption.
      }
      eapply head_rewired_head_no_entry;eauto.
      eapply path_app;eauto.
    - eapply in_split in Hiny as Hsplity.
      destructH.
      eapply path_prefix_path in Hpath as Hy;eauto.
      2: { eapply prefix_eq. exists (l1 ++ x :: l0). rewrite Hsplity in Hsplitx.
           rewrite <-app_assoc. cbn. eassumption.
      }
      eapply head_rewired_head_no_entry;eauto.
      eapply path_app;eauto.
  Qed.

  Lemma head_rewired_entry_eq h p q t
        (Hpath : HPath q p t)
        (Hnin : ~ loop_contains h q)
        (Hin : loop_contains h p)
    : h = p.
  Proof.
    revert p Hin Hpath.
    induction t;intros;inv_path Hpath.
    - exfalso. contradiction.
    - decide (loop_contains h x).
      + exfalso.
        eapply IHt in H;subst;eauto.
        eapply head_rewired_not_contains;eauto.
      + destruct H0.
        * destruct H0. eapply entry_through_header in n;eauto.
        * destruct H0. eapply deq_loop_exited' in H0. eapply H0 in Hin. contradiction.
  Qed.


  Lemma acyclic_head_rewired_edge
    : acyclic head_rewired_edge.
  Proof.
    intros p q π Hedge Hpath.
    specialize (head_rewired_cycle_not_contains) with (p:=q) (q:=p) (t:=π) as Hnl.
    do 2 exploit' Hnl.
    enough (q -a>* p) as Hacy.
    {
      destruct Hedge.
      - destruct Hacy.
        eapply a_edge_acyclic;eauto.
        destruct H.
        decide (back_edge p q).
        + exfalso. eapply loop_contains_ledge in b. eapply Hnl in b.
          * subst. eapply no_self_loops;eauto.
          * eapply path_contains_back;eauto.
          * eapply path_contains_front;eauto.
        + do 2 simpl_dec' n. destruct n;firstorder.
      - copy H Hexit.
        destruct Hexit as [pq Hexit].
        eapply loop_reachs_exit in Hexit.
        destruct Hacy. destruct Hexit.
        inv_path H0.
        + eapply head_rewired_no_self;right;eauto.
        + eapply a_edge_acyclic;eauto.
          eapply path_app';eauto.
    }
    clear Hedge.
    induction Hpath.
    - eexists;econstructor.
    - exploit IHHpath. destruct IHHpath.
      destruct H.
      + exists (c :: x).
        econstructor;eauto.
        decide (back_edge b c). 2: { destruct H. do 2 simpl_dec' n. destruct n;[contradiction|auto]. }
        exfalso.
        eapply loop_contains_ledge in b0.
        eapply Hnl in b0. 2: auto. 2: right;eapply path_contains_front;eauto.
        subst.
        eapply head_rewired_no_self. left;eauto.
      +
        destruct H.
        eapply loop_reachs_exit in H. destruct H.
        eexists.
        eapply path_app';eauto.
  Qed.

  Lemma acyclic_HPath p q π
        (Hpath : HPath p q π)
    : NoDup π.
  Proof.
    eapply acyclic_NoDup; eauto using acyclic_head_rewired_edge.
  Qed.

  Lemma head_rewired_final_exit e p t q h
        (Hpath : HPath e p t)
        (Hexit : exit_edge h q e)
        (Hloop : loop_contains h p)
    : False.
  Proof.
    eapply head_rewired_entry_eq in Hloop;eauto.
    2: destruct Hexit as [? [Hexit _]];eauto.
    subst p.
    specialize (path_rcons) with (r:=h) as Hpath'.
    specialize Hpath' with (edge:=head_rewired_edge).
    eapply Hpath' in Hpath as Hpath''.
    - eapply acyclic_HPath in Hpath'' as Hnd.
      eapply NoDup_nin_rcons;eauto.
      destruct t;[inv Hpath|].
      cbn in Hpath''. path_simpl' Hpath''. left. reflexivity.
    - right. eexists;eauto.
  Qed.

  Lemma head_rewired_final_exit_elem e p t q h x
        (Hpath : HPath e p t)
        (Hexit : exit_edge h q e)
        (Hin : x ∈ t)
        (Hloop : loop_contains h x)
    : False.
  Proof.
    eapply path_to_elem in Hpath;eauto. destructH.
    eapply head_rewired_final_exit;eauto.
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

End hr_cfg.
