Require Export ListExtra.

Definition Disjoint {A : Type} (l l' : list A) : Prop :=
  (forall a, a ∈ l -> a ∉ l').

Lemma disjoint_cons1 {A : Type} (a : A) l l' :
  Disjoint (a :: l) l' <-> ~ In a l' /\ Disjoint l l'.
Proof.
  split; revert l.
  - induction l'; intros l; firstorder.
  - intros l [nin disj].
    + intros b in' N.
      destruct in'.
      * destruct H. contradiction.
      * specialize (disj _ H). contradiction.
Qed.

Lemma disjoint_cons2 {A : Type} (a : A) l l' :
  Disjoint l (a :: l') <-> ~ In a l /\ Disjoint l l'.
Proof.
  split; revert l.
  - induction l'; intros l; firstorder.
  - intros l [nin disj].
    + intros b in' N.
      destruct N.
      * destruct H. contradiction.
      * unfold Disjoint in disj. specialize (disj _ in'). contradiction.
Qed.

Lemma disjoint_subset (A : Type) (l1 l1' l2 l2' : list A)
  : l1 ⊆ l1' -> l2 ⊆ l2' -> Disjoint l1' l2' -> Disjoint l1 l2.
Proof.
  intros Hsub1 Hsub2 Hdisj.
  unfold Disjoint in *. firstorder.
Qed.

Lemma Disjoint_sym {A : Type} (l l' : list A)
      (Hdisj : Disjoint l l')
  : Disjoint l' l.
Proof.
  unfold Disjoint in *.
  firstorder.
Qed.

Lemma disjoint2 {A : Type} `{EqDec A} (l1 l2 : list A)
  : Disjoint l1 l2 <-> forall x y, x ∈ l1 -> y ∈ l2 -> x <> y.
Proof.
  split;unfold Disjoint;intros.
  - intro N. subst x. firstorder.
  - intros;intro N;eapply H0;eauto.
Qed.

Lemma disjoint1 (A : Type) (l1 l2 : list A)
  : Disjoint l1 l2 <-> Disjoint l1 l2 /\ Disjoint l2 l1.
Proof.
  split;intros;auto.
  - split;auto using Disjoint_sym.
  - destructH. auto.
Qed.

Lemma Disjoint_map_inj (A B : Type) (f : A -> B) (Hinj : injective f) (l l' : list A)
  : Disjoint (map f l) (map f l') -> Disjoint l l'.
Proof.
  intros.
  unfold Disjoint in *.
  intros a Hel Hel'. eapply H;eauto.
  1,2: eapply in_map;eauto.
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

Lemma Disjoint_nil1 (A : Type) (l : list A)
  : Disjoint [] l.
Proof.
  unfold Disjoint. intros. contradiction.
Qed.

Lemma Disjoint_nil2 (A : Type) (l : list A)
  : Disjoint l [].
Proof.
  eapply Disjoint_sym. eapply Disjoint_nil1.
Qed.
