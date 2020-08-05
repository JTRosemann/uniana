(**  ListExtra
    - includes some useful facts about lists
**)
Require Import Program.Equality Lia.
Require Export List.

Require Export Take.

Require Export Util UtilTac.

(**  Notations for lists used as sets **)

Infix "∈" := In (at level 50).
Notation "a '∉' l" := (~ a ∈ l) (at level 50).
Infix "⊆" := incl (at level 50).

Definition set_eq {A : Type} (a b : list A) := a ⊆ b /\ b ⊆ a.

Infix "='" := (set_eq) (at level 50).

(**  Facts about lists used as sets **)

Section Facts.

  Variables (A B : Type).

  Lemma list_emp_in : forall l, (forall (a: A), ~ List.In a l) -> l = nil.
  Proof.
    intros.
    induction l.
    - reflexivity.
    - cut (forall a, ~ List.In a l).
      + intros.
        apply IHl in H0.
        subst. specialize (H a).
        exfalso. simpl in H. auto.
      + intros. specialize (H a0).
        simpl in H. auto.
  Qed.

  Lemma in_fst a (l : list (A * B)) :
    In a (map fst l)
    -> exists b, In (a,b) l.
  Proof.
    intros.
    induction l;cbn in *;[contradiction|].
    destruct H.
    - exists (snd a0). left. rewrite <-H. eapply surjective_pairing.
    - eapply IHl in H. destruct H. exists x; right;eauto.
  Qed.

  Fixpoint list_is_set (l : list A) : Prop :=
    match l with
    | x :: xs => list_is_set xs /\ ~ In x xs
    | nil => True
    end.

  Lemma incl_cons (l l' : list A) (a : A) :
    incl (a :: l) l' -> incl l l'.
  Proof.
    unfold incl. cbn. firstorder.
  Qed.

  Lemma eq_incl (l l':list A) :
    l = l' -> incl l l'.
  Proof.
    intros Heql; rewrite Heql;unfold incl; tauto.
  Qed.

  Lemma tl_incl (l : list A)
    : tl l ⊆ l.
  Proof.
    induction l;cbn;firstorder.
  Qed.

  Lemma hd_tl_len_eq (l l' : list A) (a : A)
        (Hheq : hd a l = hd a l')
        (Hteq : tl l = tl l')
        (Hleq : | l | = | l' |)
    : l = l'.
  Proof.
    clear - Hheq Hteq Hleq.
    revert dependent l'. induction l; intros; destruct l';cbn in *;eauto. 1,2: congruence.
    f_equal;eauto.
  Qed.

End Facts.

(**  iter **)

Fixpoint iter {X : Type} (f : X -> X) (l : X) (n : nat) : X
  := match n with
     | O => l
     | S n => iter f (f l) n
     end.

(**  rcons **)

Notation "l ':r:' a" := (l ++ [a]) (at level 50).

Section Rcons.

  Variables (A B : Type).

  Lemma rev_cons (a : A) l : rev (a :: l) = (rev l) :r: a.
    induction l; cbn; eauto.
  Qed.

  Lemma cons_rcons_assoc (a b : A) l : (a :: l) :r: b = a :: (l :r: b).
    induction l; cbn; eauto.
  Qed.

  Lemma rev_rcons (a : A) l : rev (l :r: a) = a :: (rev l).
    induction l; cbn; eauto. rewrite IHl; eauto using  cons_rcons_assoc.
  Qed.

  Lemma tl_rcons (a : A) l : length l > 0 -> tl (l :r: a) = tl l :r: a.
    induction l; intros; cbn in *; eauto. lia.
  Qed.

  Lemma hd_rcons (a x y : A) l : length l > 0 -> hd x (l :r: a) = hd y l.
    induction l; intros; cbn in *; eauto. lia.
  Qed.

  Lemma In_rcons (a b : A) l :
    In a (l :r: b) <-> a = b \/ In a l.
  Proof.
    split.
    - induction l; cbn; firstorder.
    - intros. destruct H; induction l; cbn; firstorder.
  Qed.

  Lemma cons_rcons' (a : A) l :
    (a :: l) = (rev (tl (rev (a :: l))) :r: hd a (rev (a :: l))).
  Proof.
    revert a; induction l; intros b; [ cbn in *; eauto|].
    rewrite rev_cons. rewrite tl_rcons.
    - rewrite rev_rcons. erewrite hd_rcons.
      + rewrite cons_rcons_assoc. f_equal. apply IHl.
      + rewrite rev_length; cbn; lia.
    - rewrite rev_length; cbn; lia.
  Qed.

  Lemma cons_rcons (a : A) l : exists a' l', (a :: l) = (l' :r: a').
  Proof.
    exists (hd a (rev (a :: l))). exists (rev (tl (rev (a :: l)))).
    apply cons_rcons'.
  Qed.

  (*  Lemma rcons_cons (a : A) l : exists a' l', (l :r: a) = (a' :: l').
    remember (@cons_rcons A) as H.*)

  Ltac rem_cons_rcons a l H :=
    let a' := fresh a in
    let l' := fresh l in
    specialize (cons_rcons a l) as [a' [l' H]].

  Lemma rev_nil (l : list A) : rev l = nil <-> l = nil.
  Proof.
    split; induction l; cbn in *; eauto; intros.
    - exfalso. induction (rev l); cbn in *; congruence.
    - congruence.
  Qed.

  (*  Lemma rev_inj (l l': list A) : rev l = rev l' -> l = l'.*)

  Lemma rcons_destruct (l : list A) : l = nil \/ exists a l', l = l' :r: a.
  Proof.
    destruct l.
    - left. reflexivity.
    - right. apply cons_rcons.
  Qed.

  Lemma rcons_not_nil (l : list A) a : l :r: a <> nil.
  Proof.
    intro N. induction l; cbn in *; congruence.
  Qed.

  Lemma length_rcons l (a : A) : length (l :r: a) = S (length l).
  Proof.
    induction l; cbn; eauto.
  Qed.

  Lemma rcons_length n (l l' : list A) a :
    S n = length l -> l = l' :r: a -> n = length l'.
  Proof.
    revert l l'.
    induction n; intros; cbn in *; eauto; subst l; rewrite length_rcons in H; lia.
  Qed.

  Lemma rcons_ind
    : forall (P : list A -> Prop),
      P nil -> (forall (a : A) (l : list A), P l -> P (l :r: a)) -> forall l : list A, P l.
  Proof.
    intros.
    remember (length l) as n.
    revert l n Heqn.
    refine ((fix F (l : list A) (n : nat) {struct n} : n = length l -> P l :=
               match rcons_destruct l,n with
               | or_introl lnil,  O => (fun (Hnl : O = length l) => _)
               | or_intror (ex_intro _ a (ex_intro _ _ _)), S n => fun (Hnl : (S n) = length l) => _
               | _,_ => _
               end)).
    - subst l. eauto.
    - clear F. intros. subst l. eauto.
    - clear F. intros. destruct l; eauto using rcons_not_nil. cbn in H1. congruence.
    - rewrite e1. apply H0. apply (F l0 n).
      eapply rcons_length; eauto.
  Qed.

  Lemma app_cons_assoc (a : A) l l'
  : l ++ a :: l' = l :r: a ++ l'.
  Proof.
    induction l; cbn; eauto.
    f_equal. rewrite IHl. reflexivity.
  Qed.

  Lemma incl_cons_hd  (a : A) l l'
        (Hincl : (a :: l) ⊆ l')
    : a ∈ l'.
  Proof.
    induction l;cbn in *;unfold incl in Hincl;eauto;firstorder.
  Qed.

  (** map facts **)

  Lemma map_rcons (f : A -> B) :
    forall a l, map f (l :r: a) = map f l :r: f a.
  Proof.
    intros. induction l;cbn;eauto. rewrite IHl. reflexivity.
  Qed.

  Lemma map_inj_in (f : A -> B) (Hinj : injective f) (l : list A) (a : A)
    : (f a) ∈ map f l -> a ∈ l.
  Proof.
    induction l;intros;cbn in *.
    - contradiction.
    - destruct H.
      + eapply Hinj in H. subst. left;auto.
      + right;eauto.
  Qed.

  Lemma map_inj_incl (f : A -> B) (Hinj : injective f) (l l' : list A)
    : map f l ⊆ map f l' -> l ⊆ l'.
  Proof.
    revert l'.
    induction l;intros;cbn in *.
    - eauto.
    - intros b Hb. destruct Hb.
      + subst. eapply map_inj_in;eauto.
      + eapply IHl;eauto. intros c Hc. eapply H. right. auto.
  Qed.

End Rcons.

Ltac congruence' :=
  lazymatch goal with
  | [ H : ?l ++ (?a :: ?l') = nil |- _ ] => destruct l; cbn in H; congruence
  | [ H : (?l ++ ?l') :: ?a :: ?l'' = nil |- _ ] => destruct l; cbn in H; congruence
  | [ H : ?l :r: ?a = nil |- _ ] => eapply rcons_not_nil in H; contradiction
  | [ H : nil = ?l ++ (?a :: ?l') |- _ ] => destruct l; cbn in H; congruence
  | [ H : nil = (?l ++ ?l') :: ?a :: ?l'' |- _ ] => destruct l; cbn in H; congruence
  | [ H : nil = ?l :r: ?a |- _ ] => symmetry in H; eapply rcons_not_nil in H; contradiction
  end.

Ltac fold_rcons H :=
  match type of H with
  | context C [?a :: ?b :: nil] => fold (app (a :: nil) (b :: nil)) in H;
                                  fold ((a :: nil) :r: b) in H;
                                  repeat rewrite <-cons_rcons_assoc in H
  | context C [?l ++ ?a :: nil] => fold (l :r: a) in H
  end.

Section Rcons.

  Lemma rcons_eq1 {A : Type} (l l' : list A) (a a' : A)
    : l :r: a = l' :r: a' -> l = l'.
  Proof.
    revert l'; induction l; intros; destruct l'; cbn in *; inversion H; eauto; try congruence'.
    f_equal. eapply IHl. repeat fold_rcons H2. auto.
  Qed.

  Lemma rcons_eq2 {A : Type} (l l' : list A) (a a' : A)
    : l :r: a = l' :r: a' -> a = a'.
  Proof.
    revert l'; induction l; intros; destruct l'; cbn in *; inversion H; eauto; congruence'.
  Qed.

  Lemma rev_injective {A : Type} (l l' : list A)
    : rev l = rev l' -> l = l'.
  Proof.
    revert l. induction l'; intros; cbn in *.
    - destruct l;[reflexivity|cbn in *;congruence'].
    - destruct l;cbn in *;[congruence'|].
      repeat fold_rcons H.
      f_equal;[eapply rcons_eq2;eauto|apply IHl';eapply rcons_eq1;eauto].
  Qed.

  Lemma rev_rev_eq (A : Type) (l l' : list A)
    : l = l' <-> rev l = rev l'.
  Proof.
    revert l l'.
    enough (forall (l l' : list A), l = l' -> rev l = rev l').
    { split;eauto. intros. rewrite <-rev_involutive. rewrite <-rev_involutive at 1. eauto. }
    intros ? ? Hll.
    subst. reflexivity.
  Qed.

  Lemma NoDup_rcons (A : Type) (x : A) (l : list A)
    : x ∉ l -> NoDup l -> NoDup (l :r: x).
  Proof.
    intros Hnin Hnd. revert x Hnin.
    induction Hnd; intros y Hnin; cbn.
    - econstructor; eauto. econstructor.
    - econstructor.
      + rewrite in_app_iff. contradict Hnin. destruct Hnin; [contradiction|firstorder].
      + eapply IHHnd. contradict Hnin. right; assumption.
  Qed.

  Lemma NoDup_nin_rcons (A : Type) (x : A) (l : list A)
    : NoDup (l :r: x) -> x ∉ l.
  Proof.
    intros Hnd Hin.
    dependent induction l.
    - destruct Hin.
    - destruct Hin; rewrite cons_rcons_assoc in Hnd; inversion Hnd.
      + subst a. eapply H2. apply In_rcons;firstorder.
      + eapply IHl; eauto.
  Qed.

  Lemma NoDup_app (A : Type) (l l' : list A)
    : NoDup (l ++ l') -> forall a, a ∈ l -> a ∉ l'.
  Proof.
    induction l; intros; cbn; [contradiction|].
    inversion H;subst.
    destruct H0; subst.
    - contradict H3. eapply in_app_iff. firstorder.
    - eapply IHl;auto.
  Qed.

  Lemma NoDup_iff_dupfree (A : Type) (l : list A)
    : NoDup l <-> dupfree l.
  Proof.
    split;intro H; induction H;try econstructor;eauto.
  Qed.

End Rcons.

(** take_r
    - 'take_r' is the dual variant to 'take'
**)

Section Take_r.

  Variable (A : Type).

  Definition take_r (A : Type) (n : nat) (l : list A) := rev (take n (rev l)).

  Lemma take_tl (n : nat) (l : list A)
        (Hn : S n = |l|)
    : take n l = rev (tl (rev l)).
  Proof.
    revert dependent n.
    induction l;intros;cbn in *.
    - congruence.
    - destruct n;cbn.
      + inversion Hn;subst. symmetry in H0. rewrite length_zero_iff_nil in H0. subst l. cbn. reflexivity.
      + inversion Hn;subst. exploit IHl. rewrite IHl.
        fold (rev l :r: a). rewrite tl_rcons.
        * rewrite rev_rcons. reflexivity.
        * rewrite rev_length. lia.
  Qed.

  Lemma take_r_tl (n : nat) (l : list A)
        (Hn : S n = |l|)
    : take_r n l = tl l.
  Proof.
    unfold take_r. rewrite take_tl; [|rewrite rev_length;eauto].
    do 2 rewrite rev_involutive. reflexivity.
  Qed.

End Take_r.

Ltac destr_r' l :=
  let H := fresh "Hl" in
  let x := fresh "x" in
  let l' := fresh "l" in
  let Hlx := fresh "Hx" in
  specialize (rcons_destruct l) as H;
  destruct H as [H|[x [l' Hlx]]].

Lemma nin_tl_iff (A : Type) `{EqDec A eq} (a : A) (l : list A)
  : a ∉ tl (rev l) -> a ∉ l \/ Some a = hd_error (rev l).
Proof.
  intros.
  destr_r' l;subst.
  - left. cbn. exact id.
  - rewrite rev_rcons in H0. cbn in H0.
    rewrite rev_rcons. cbn.
    destruct (x == a).
    + right. rewrite e. reflexivity.
    + left. contradict H0. rewrite <-in_rev. eapply  In_rcons in H0. destruct H0. subst.
      * exfalso;apply c; reflexivity.
      * auto.
Qed.
