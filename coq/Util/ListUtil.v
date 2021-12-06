Require Import Coq.Arith.Arith.
Require Import Coq.Lists.List.

Require Import ExtLib.Data.ListNth.

Require Import Helix.Util.OptionSetoid.
Require Import Helix.Tactics.HelixTactics.


Import ListNotations.

Fixpoint fold_left_rev
         {A B : Type}
         (f : A -> B -> A) (a : A) (l : list B)
  : A
  := match l with
     | List.nil => a
     | List.cons b l => f (fold_left_rev f a l) b
     end.

Program Fixpoint Lbuild {A: Type}
        (n : nat)
        (gen : forall i, i < n -> A) {struct n}: list A :=
  match n with
  | O => List.nil
  | S p =>
    let gen' := fun i ip => gen (S i) _ in
    List.cons (gen 0 _) (@Lbuild A p gen')
  end.
Next Obligation. apply lt_n_S, ip. Qed.
Next Obligation. apply Nat.lt_0_succ. Qed.

Lemma nth_error_Sn {A:Type} (x:A) (xs:list A) (n:nat):
  nth_error (x::xs) (S n) = nth_error xs n.
Proof.
  reflexivity.
Qed.

Lemma rev_nil (A:Type) (x:list A):
  rev x = nil -> x = nil.
Proof.
  intros H.
  destruct x.
  -
    reflexivity.
  -
    simpl in H.
    symmetry in H.
    contradict H.
    apply app_cons_not_nil.
Qed.

(* List elements unique wrt projection [p] using [eq] *)
Definition list_uniq {A B:Type} (p: A -> B) (l:list A): Prop
  := forall x y a b,
    List.nth_error l x = Some a ->
    List.nth_error l y = Some b ->
    (p a) = (p b) -> x=y.

Lemma list_uniq_nil {A B:Type} (p: A -> B):
  list_uniq p (@nil A).
Proof.
  unfold list_uniq.
  intros x y a b H H0 H1.
  rewrite nth_error_nil in H.
  inversion H.
Qed.

Lemma list_uniq_de_cons {A B:Type} (p: A -> B) (a:A) (l:list A):
  list_uniq p (a :: l) ->
  list_uniq p l.
Proof.
  intros H.
  unfold list_uniq in *.
  intros x y a0 b H0 H1 H2.
  cut (S x = S y). auto.
  eapply H; eauto.
Qed.

Lemma list_uniq_cons {A B:Type} (p: A -> B) (a:A) (l:list A):
  list_uniq p l /\
  not (exists j x, nth_error l j = Some x /\ p x = p a) <->
  list_uniq p (a :: l).
Proof.
  split.
  -
    intros [U E].
    unfold list_uniq in *.
    intros x y a0 b H H0 H1.
    destruct x,y; cbn in *.
    +
      reflexivity.
    +
      inversion H; subst.
      contradict E.
      exists y, b.
      auto.
    +
      inversion H0; subst.
      contradict E.
      exists x, a0.
      auto.
    +
      apply eq_S.
      eapply U; eauto.
  -
    intros H.
    split ; [eapply list_uniq_de_cons; eauto|].

    intros C.
    destruct C as (j & x & C0 & C1).
    unfold list_uniq in H.
    specialize (H 0 (S j)).
    cbn in H.
    specialize (H a x).
    cut(0 = S j). intros. inv H0.
    apply H; auto.
Qed.

Lemma app_nth_error2 :
  forall {A: Type} (l:list A) l' n, n >= List.length l -> nth_error (l++l') n = nth_error l' (n-length l).
Proof.
  induction l; intros l' d [|n]; auto;
    cbn; rewrite IHl; auto with arith.
Qed.

Lemma app_nth_error1 :
  forall {A:Type} (l:list A) l' n, n < length l -> nth_error (l++l') n = nth_error l n.
Proof.
  induction l.
  - inversion 1.
  - intros l' n H.
    cbn.
    destruct n; [reflexivity|].
    rewrite 2!nth_error_Sn.
    apply IHl.
    cbn in H.
    auto with arith.
Qed.

Lemma rev_nth_error : forall {A:Type} (l:list A) n,
    (n < List.length l)%nat ->
    nth_error (rev l) n = nth_error l (List.length l - S n) .
Proof.
  induction l.
  intros; inversion H.
  intros.
  simpl in H.
  simpl (rev (a :: l)).
  simpl (List.length (a :: l) - S n).
  inversion H.
  rewrite <- minus_n_n; simpl.
  rewrite <- rev_length.
  rewrite app_nth_error2; auto.
  rewrite <- minus_n_n; auto.
  rewrite app_nth_error1; auto.
  rewrite (minus_plus_simpl_l_reverse (length l) n 1).
  replace (1 + length l) with (S (length l)); auto with arith.
  rewrite <- minus_Sn_m; auto with arith.
  apply IHl ; auto with arith.
  rewrite rev_length; auto.
Qed.

Lemma fold_left_rev_def {A B : Type} (l : list B) (e : A) (f : A -> B -> A) :
  fold_left_rev f e l = fold_left f (rev l) e.
Proof.
  induction l.
  -
    reflexivity.
  -
    cbn.
    rewrite fold_left_app, IHl.
    reflexivity.
Qed.

Lemma fold_left_fold_left_rev
      {A : Type}
      (l : list A)
      (e : A)
      (f : A -> A -> A)
      (f_commut : forall x y, f x y = f y x)
      (f_assoc : forall x y z, f x (f y z) = f (f x y) z)
  :
    fold_left_rev f e l = fold_left f l e.
Proof.
  rewrite fold_left_rev_def.
  rewrite <-fold_left_rev_right.
  rewrite rev_involutive.
  induction l; [reflexivity |].
  cbn.
  rewrite_clear IHl.
  generalize dependent a.
  induction l; [reflexivity |].
  cbn.
  congruence.
Qed.

Lemma fold_left_preservation
      {A : Type}
      (f : A -> A -> A)
      (init : A)
      (l : list A)
      (P : A -> Prop)
      (PP : forall a b, P a \/ P b -> P (f a b))
  :
    (P init \/ exists a, P a /\ In a l) ->
    P (fold_left f l init).
Proof.
  intros.
  generalize dependent init.
  induction l.
  -
    intros.
    intuition.
    destruct H0.
    intuition.
  -
    intros.
    cbn.
    apply IHl.
    destruct H as [I | [a' [Pa' La']]]; auto.
    inversion La'.
    subst; auto.
    right.
    exists a'.
    auto.
Qed.

Lemma fold_left_emergence

      {A : Type}
      (f : A -> A -> A)
      (init : A)
      (l : list A)
      (P : A -> Prop)
      (PE : forall a b, P (f a b) -> P a \/ P b)
  :
    P (fold_left f l init) ->
    (P init \/ exists a, P a /\ In a l).
Proof.
  intros.
  generalize dependent init.
  induction l.
  -
    intros.
    intuition.
  -
    intros.
    cbn in H.
    apply IHl in H.
    destruct H as [I | [a' [Pa' La']]].
    +
      apply PE in I.
      destruct I; auto.
      right.
      exists a.
      cbn.
      auto.
    +
      right.
      exists a'.
      cbn.
      auto.
Qed.

Lemma fold_left_invariant
      {A : Type}
      (f : A -> A -> A)
      (init : A)
      (l : list A)
      (P : A -> Prop)
      (PI : forall a b, P (f a b) <-> P a \/ P b)
  :
    P (fold_left f l init) <-> (P init \/ exists a, P a /\ In a l).
Proof.
  split; intros.
  -
    apply fold_left_emergence with (f0:=f).
    apply PI.
    assumption.
  -
    apply fold_left_preservation with (f0:=f).
    apply PI.
    assumption.
Qed.

Lemma Forall2_firstn
      {A B : Type}
      (R : A -> B -> Prop)
      (l1 : list A)
      (l2 : list B)
      (n : nat)
  :
    Forall2 R l1 l2 ->
    Forall2 R (firstn n l1) (firstn n l2).
Proof.
  intros I.
  generalize dependent n.
  induction I;
    intro n.
  -
    now rewrite !firstn_nil.
  -
    destruct n.
    +
      constructor.
    +
      cbn; constructor.
      assumption.
      apply IHI.
Qed.

Lemma Forall2_skipn
      {A B : Type}
      (R : A -> B -> Prop)
      (l1 : list A)
      (l2 : list B)
      (n : nat)
  :
    Forall2 R l1 l2 ->
    Forall2 R (skipn n l1) (skipn n l2).
Proof.
  intros I.
  generalize dependent n.
  induction I;
    intro n.
  -
    now rewrite !skipn_nil.
  -
    destruct n.
    now constructor.
    apply IHI.
Qed.

Lemma Forall2_nth_error
      {A B : Type}
      (n : nat)
      (P : A -> B -> Prop)
      (l1 : list A)
      (l2 : list B)
  :
    Forall2 P l1 l2 ->
    hopt_r P (nth_error l1 n) (nth_error l2 n).
Proof.
  revert l2.
  induction l1;
    intros l2 F.
  -
    admit.
  -
    inversion F; subst.
    rename a into e1', y into e2', l' into l2.
    admit.
Admitted.

Lemma firstn_app_exact {A : Type} (l1 l2 : list A) (n : nat) :
  n = length l1 ->
  firstn n (l1 ++ l2) = l1.
Proof.
  intros L.
  subst.
  rewrite <-PeanoNat.Nat.add_0_r with (n:=length l1).
  rewrite firstn_app_2, firstn_O, app_nil_r.
  reflexivity.
Qed.

Lemma skipn_app_exact {A : Type} (l1 l2 : list A) (n : nat) :
  n = length l1 ->
  skipn n (l1 ++ l2) = l2.
Proof.
  intros L.
  subst.
  rewrite skipn_app.
  rewrite PeanoNat.Nat.sub_diag.
  rewrite skipn_all, skipn_O, app_nil_l.
  reflexivity.
Qed.
