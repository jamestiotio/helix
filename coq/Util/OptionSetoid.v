Require Import Coq.Classes.RelationClasses.
Require Import CoLoR.Util.Relation.RelUtil.

Require Import MathClasses.interfaces.canonical_names.
Require Import MathClasses.misc.util.
Require Import MathClasses.misc.decision.

Require Import ExtLib.Structures.Monads.
Require Import ExtLib.Data.Monads.OptionMonad.


Require Import Helix.Tactics.HelixTactics.

Global Instance option_Equiv {T:Type} `{Te:Equiv T}:
  Equiv (option T) := @opt_r T Te.

Global Instance option_Equivalence  `{Te: Equiv T} `{H: Equivalence T Te}
  : Equivalence (@option_Equiv T Te).
Proof.
  split.
  - apply opt_r_refl, H.
  - apply opt_r_sym, H.
  - apply opt_r_trans, H.
Qed.

Lemma Some_inj_eq {A:Type}:
  forall (a b:A), a ≡ b <-> Some a ≡ Some b.
Proof.
  intros a b.
  split; intros H.
  -
    f_equiv.
    apply H.
  -
    inversion H.
    auto.
Qed.

Lemma Some_inj_equiv `{E: Equiv A}:
  forall (a b:A), a = b <-> Some a = Some b.
Proof.
  intros a b.
  split; intros H.
  -
    f_equiv.
    apply H.
  -
    inversion H.
    auto.
Qed.

Global Instance Some_proper `{Equiv A}:
  Proper ((=) ==> (=)) (@Some A).
Proof.
  intros a b E.
  apply Some_prop, E.
Qed.

Ltac norm_some_none :=
  repeat
    match goal with
    | [H: is_Some (Some _) |- _ ] => clear H
    | [H: is_None (None) |- _ ] => clear H
    | [|- is_Some (None) ] => exfalso
    | [|- is_None (Some _)] => exfalso
    | [H: is_Some _ |- _ ] => apply is_Some_def in H; destruct H
    | [H: is_None _ |- _ ] => apply is_None_def in H; destruct H
    | [H: Some ≡ _ |- _ ] => symmetry in H
    | [H: None ≡ _ |- _ ] => symmetry in H
    end.

Ltac symmetry_option_hyp :=
  repeat  match goal with
          | [H: Some _ ≡ _ |- _ ] => symmetry in H
          | [H: None ≡ _  |- _ ] => symmetry in H
          end.

Lemma is_Some_ne_None `(x : option A) :
  is_Some x ↔ x ≢ None.
Proof.
  destruct x; intros; crush.
Qed.

Lemma Some_ne_None `(x : option A) y :
  x ≡ Some y → x ≢ None.
Proof. congruence. Qed.


Ltac some_none :=
  let H' := fresh in
  match goal with
  | [H1: ?x = None, H2: ?x ≠ None |- _] => congruence
  | [H1: ?x ≡ Some _, H2: ?x ≡ None |- _ ] => congruence
  | [H1: ?x = Some _, H2: ?x = None |- _ ] => rewrite H2 in H1; inversion H1
  | [H: is_Some None |- _ ] => inversion H
  | [H: is_None (Some _) |- _ ] => inversion H
  | [H: ¬ is_None None |- _] => unfold is_None in H; tauto
  | [H: Some _ = None |- _ ] => inversion H
  | [H: None = Some _ |- _ ] => inversion H
  | [H: Some _ ≡ None |- _ ] => inversion H
  | [H: None ≡ Some _ |- _ ] => inversion H
  | [ |- Some _ ≢ None ] => intros H'; inversion H'
  | [ |- None ≢ None ] => congruence
  | [ |- Some ?a ≢ Some ?a ] => congruence
  | [ |- Some _ ≠ None ] => intros H'; inversion H'
  | [ |- None ≠ Some _ ] => intros H'; inversion H'
  | [ |- None ≢ Some _ ] => intros H'; inversion H'
  | [ |- None = None ] => reflexivity
  | [ |- None ≡ None ] => reflexivity
  | [ |- Some ?a = Some ?a] => reflexivity
  | [ |- Some ?a ≡ Some ?a] => reflexivity
  | [ |- is_None None ] => apply is_None_def; reflexivity
  | [ |- is_Some (Some _)] => unfold is_Some; tauto
  | [H1: is_Some ?x, H2: is_None ?x |- _] =>
    apply is_Some_ne_None in H1; apply is_None_def in H2; congruence
  end.

Ltac some_inv :=
  match goal with
  | [H: Some ?A ≡ Some ?b |- _ ] => inversion H; clear H
  | [H: Some ?A = Some ?b |- _ ] => apply Some_inj_equiv in H
  end.

Ltac some_apply :=
  match goal with
  | [H: ?a = ?b |- Some ?a = Some ?b] => apply Some_inj_equiv in H; apply H
  | [H: Some ?a = Some ?b |- ?a = ?b] => apply Some_inj_equiv; apply H
  end.

Lemma Equiv_to_opt_r {A:Type} {a b: option A} `{Ae: Equiv A}:
  a = b <-> RelUtil.opt_r Ae a b.
Proof.
  split.
  -
    intros H.
    destruct a, b; try some_none; constructor.
    some_inv.
    apply H.
  -
    intros H.
    auto.
Qed.

Global Instance liftM_option_proper `{Ae:Equiv A} `{Be: Equiv B}:
  Proper (((=) ==> (=)) ==> (=) ==> (=)) (@liftM option Monad_option A B).
Proof.
  intros f f' Ef a a' Ea.
  simpl.
  destruct a, a'; try some_none; auto.
  -
    f_equiv.
    apply Ef.
    inversion Ea.
    auto.
  -
    apply opt_r_None.
Qed.

Lemma Option_equiv_eq
      {A: Type}
      `{Ae: Equiv A}
      `{Ar: Equivalence A Ae}
      (a b: option A) :
  (a ≡ b) -> (a = b).
Proof.
  intros H.
  rewrite H.
  reflexivity.
Qed.

Ltac eq_to_equiv_hyp :=
  repeat
    match goal with
    | [H: _ ≡ _ |- _] => apply Option_equiv_eq in H
    end.

Lemma None_nequiv_neq
      {A: Type}
      `{Ae: Equiv A}
      `{Ar: Equivalence A Ae}
      (a: option A) :
  (a ≢ None) <-> (a ≠ None).
Proof.
  destruct a; split; intros; try some_none; crush.
Qed.

Lemma None_equiv_eq
      {A: Type}
      `{Ae: Equiv A}
      `{Aee: Equivalence A Ae}
      {x: option A}:
  x ≡ None <-> x = None.
Proof.
  split.
  -
    intros H.
    rewrite H.
    reflexivity.
  -
    intros H.
    inversion H.
    reflexivity.
Qed.

Lemma Some_nequiv_None `(x : option A) `{Ae: Equiv A} y :
  x = Some y → x ≠ None.
Proof.
  intros H.
  intros H1.
  destruct x; some_none.
Qed.

Fact equiv_Some_is_Some `{Equiv A} (x:A) (y: option A):
  (y = Some x) -> is_Some y.
Proof.
  dep_destruct y.
  -
    crush.
  -
    intros H0.
    some_none.
Qed.

Fact eq_Some_is_Some {A:Type} (x:A) (y: option A):
  (y ≡ Some x) -> is_Some y.
Proof.
  crush.
Qed.

Lemma is_Some_equiv_def `{Ae: Equiv A} `{Equivalence A Ae} `(x : option A) :
  is_Some x ↔ ∃ y, x = Some y.
Proof.
  unfold is_Some.
  destruct x.
  -
    split; intros H0; auto.
    exists a.
    f_equiv.
  -
    split; intros H0; destruct H0.
    some_none.
Qed.

Lemma is_Some_nequiv_None
      (A : Type)
      `{Ae: Equiv A}
      (x : option A):
  is_Some x ↔ x ≠ None.
Proof.
  split; intros H.
  -
    destruct x.
    some_none.
    crush.
  -
    destruct x.
    + crush.
    + exfalso.
      unfold equiv, option_Equiv in H.
      contradict H.
      apply RelUtil.opt_r_None.
Qed.

Lemma Some_neq {T:Type} {a b: T}:
  (Some a ≢ Some b) <-> a ≢ b.
Proof.
  split;crush.
Qed.

Lemma None_nequiv_Some
      {A: Type} (x : option A) {Ae: Equiv A} (y : A):
  x = None → x ≠ Some y.
Proof.
  intros H H0.
  destruct x; some_none.
Qed.

Lemma is_None_equiv_def `(x : option A) `{Ae: Equiv A} `{H: Equivalence A Ae}:
  is_None x ↔ x = None.
Proof.
  unfold is_None.
  destruct x; split; intros; try some_none; try tauto.
Qed.

Lemma not_is_None_is_Some {A: Type} {x: option A}:
  ¬ is_None x <-> is_Some x.
Proof.
  split; intros.
  -
    destruct x; some_none.
  -
    intros H1.
    some_none.
Qed.

(* In monadic world `(f >=> g) ∘ Some` *)
Definition option_compose
           {A B C: Type}
           (f: B → option C)
           (g: A → option B): A → option C
  := fun x =>
       match g x with
       | None => None
       | Some y => f y
       end.

Global Instance option_compose_proper
       {A B C: Type}
       `{Ae: Equiv A} `{Equivalence A Ae}
       `{Be: Equiv B} `{Equivalence B Be}
       `{Ce: Equiv C} `{Equivalence C Ce}:
  Proper (
      (((@equiv B Be) ==> (@option_Equiv C Ce))
         ==>
         ((@equiv A Ae) ==> (@option_Equiv B Be))
         ==>
         (=)
         ==>
         (@option_Equiv C Ce))) (option_compose).
Proof.
  intros f f' Ef g g' Eg x x' E.
  unfold option_compose, option_Equiv.
  repeat break_match;
    apply Option_equiv_eq in Heqo;
    apply Option_equiv_eq in Heqo0;
    setoid_replace (g x) with (g' x') in Heqo by apply Eg, E;
    rewrite Heqo in Heqo0; try some_none.
  -
    some_inv.
    apply Ef, Heqo0.
  -
    reflexivity.
Qed.

Lemma option_eq_to_opt_r {A:Type} {a b: option A}:
  a ≡ b <-> RelUtil.opt_r eq a b.
Proof.
  split; intros H.
  -
    rewrite <- H.
    destruct a; constructor.
    reflexivity.
  -
    inv H; auto.
Qed.

Ltac destruct_opt_r_equiv :=
  match goal with
  | [ |- RelUtil.opt_r _ ?a ?b] =>
    let Ha := fresh "Ha" in
    let Hb := fresh "Hb" in
    destruct a eqn:Ha, b eqn:Hb;
    match goal with
    | [ |- RelUtil.opt_r _ (Some _) None] => exfalso
    | [ |- RelUtil.opt_r _ None (Some _)] => exfalso
    | [ |- RelUtil.opt_r _ (Some _) (Some _)]  =>
      apply RelUtil.opt_r_Some
    | [ |- RelUtil.opt_r _ None None] => reflexivity
    end
  end.

Ltac opt_hyp_to_equiv :=
  repeat match goal with
           [H: @eq (option _) _ _ |- _] => apply Option_equiv_eq in H
         end.


Lemma Some_nequiv {T:Type} `{Equiv T} {a b: T}:
  (Some a ≠ Some b) <-> a ≠ b.
Proof.
  split.
  -
    intros H0.
    intros N.
    contradict H0.
    f_equiv.
    assumption.
  -
    intros H0 N.
    contradict H0.
    some_inv.
    assumption.
Qed.

Program Instance option_equiv_dec
        `{Ae: Equiv A}
        `{Aeq: Equivalence A Ae} (* needed for reflexivity *)
        `(A_dec : ∀ x y : A, Decision (x = y))
  : ∀ x y : option A, Decision (x = y)
  := λ x y,
  match x with
  | Some r =>
    match y with
    | Some s => match A_dec r s with left _ => left _ | right _ => right _ end
    | None => right _
    end
  | None =>
    match y with
    | Some s => right _
    | None => left _
    end
  end.
Next Obligation. f_equiv; assumption. Qed.
Next Obligation. apply Some_nequiv; assumption. Qed.
Next Obligation. some_none. Qed.
Next Obligation. some_none. Qed.

Section opt_p.

  Variables (A : Type) (P : A -> Prop).

  (* lifting Predicate to option. error is not allowed *)
  Inductive opt_p : (option A) -> Prop :=
  | opt_p_intro : forall x, P x -> opt_p (Some x).

  (* lifting Predicate to option. errors is allowed *)
  Inductive opt_p_n : (option A) -> Prop :=
  | opt_p_None_intro: opt_p_n None
  | opt_p_Some_intro : forall x, P x -> opt_p_n (Some x).

  Global Instance opt_p_proper
         `{Ae: Equiv A}
         {Pp: Proper ((=) ==> (iff)) P}
    :
      Proper ((=) ==> (iff)) opt_p.
  Proof.
    intros a b E.
    split.
    -
      intros H.
      destruct a,b; try some_none.
      inversion H.
      subst x.
      constructor.
      some_inv.
      rewrite <- E.
      assumption.
      inversion H.
    -
      intros H.
      destruct a,b; try some_none.
      inversion H.
      subst x.
      constructor.
      some_inv.
      rewrite E.
      assumption.
      inversion H.
  Qed.

End opt_p.
Arguments opt_p {A} P.
Arguments opt_p_n {A} P.

(* Extension to [option _] of a heterogenous relation on [A] [B] *)
Section hopt.

  Variables (A B : Type) (R: A -> B -> Prop).

  (** Reflexive on [None]. *)
  Inductive hopt_r : (option A) -> (option B) -> Prop :=
  | hopt_r_None : hopt_r None None
  | hopt_r_Some : forall a b, R a b -> hopt_r (Some a) (Some b).

  (** Non-Reflexive on [None]. *)
  Inductive hopt : (option A) -> (option B) -> Prop :=
  | hopt_Some : forall a b, R a b -> hopt (Some a) (Some b).

  (** implication-like. *)
  Inductive hopt_i : (option A) -> (option B) -> Prop :=
  | hopt_i_None_None : hopt_i None None
  | hopt_i_None_Some : forall a, hopt_i None (Some a)
  | hopt_i_Some : forall a b, R a b -> hopt_i (Some a) (Some b).

  Global Instance hopt_proper
           `{EQa : Equiv A}
           `{EQb : Equiv B}
           {PR : Proper ((=) ==> (=) ==> (iff)) R} :
    Proper ((=) ==> (=) ==> (iff)) hopt.
  Proof.
    intros a1 a2 AE b1 b2 BE.
    destruct a1, a2, b1, b2;
      invc AE; invc BE.
    2-4: split; intro C; invc C.
    split.
    all: intro E; invc E; constructor.
    specialize (PR a a0 H1 b b0 H2).
    tauto.
    eapply PR; eassumption.
  Qed.

  Global Instance hopt_r_proper
           `{EQa : Equiv A}
           `{EQb : Equiv B}
           {PR : Proper ((=) ==> (=) ==> (iff)) R} :
    Proper ((=) ==> (=) ==> (iff)) hopt_r.
  Proof.
    intros [a1|] [a2|] AE [b1|] [b2|] BE;
      try some_none; repeat some_inv.
    all: split; intro H; invc H; constructor.
    apply PR in AE; apply AE in BE; tauto.
    apply PR in AE; apply AE in BE; tauto.
  Qed.

  Lemma hopt_r_OK_inv (a : A) (b : B) :
    hopt_r (Some a) (Some b) ->
    R a b.
  Proof.
    intros O; now invc O.
  Qed.

End hopt.
Arguments hopt {A B} R.
Arguments hopt_r {A B} R.
Arguments hopt_i {A B} R.
