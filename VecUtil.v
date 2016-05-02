Require Import Coq.Arith.Arith.
Require Import Coq.Logic.ProofIrrelevance.
Require Import Coq.Program.Basics. (* for \circ notation *)
Require Import Coq.omega.Omega.

Require Export Coq.Vectors.Vector.
Require Export CoLoR.Util.Vector.VecUtil.
Import VectorNotations.

Require Import CaseNaming.
Require Import CpdtTactics.
Require Import JRWTactics.
Require Import SpiralTactics.


Local Open Scope program_scope. (* for \circ notation *)
Open Scope vector_scope.

(* Re-define :: List notation for vectors. Probably not such a good idea *)
Notation "h :: t" := (cons h t) (at level 60, right associativity)
                     : vector_scope.


Fixpoint take_plus {A} {m} (p:nat) : vector A (p+m) -> vector A p :=
  match p return vector A (p+m) -> vector A p with
    0%nat => fun _ => Vnil
  | S p' => fun a => Vcons (hd a) (take_plus p' (tl a))
  end.
Program Definition take A n p (a : vector A n) (H : p <= n) : vector A p :=
  take_plus (m := n - p) p a.
Next Obligation. auto with arith.
Defined.

Fixpoint drop_plus {A} {m} (p:nat) : vector A (p+m) -> vector A m :=
  match p return vector A (p+m) -> vector A m with
    0 => fun a => a
  | S p' => fun a => drop_plus p' (tl a)
  end.
Program Definition drop A n p (a : vector A n) (H : p <= n) : vector A (n-p) :=
  drop_plus (m := n - p) p a.
Next Obligation. auto with arith.
Defined.

(* Split vector into a pair: first  'p' elements and the rest. *)
Definition vector2pair {A:Type} (p:nat) {t:nat} (v:vector A (p+t)) : (vector A p)*(vector A t) :=
  @Vbreak A p t v.

(* Split vector into a pair: first  'p' elements and the rest. *)
Definition pair2vector {A:Type} {i j:nat} (p:(vector A i)*(vector A j)) : (vector A (i+j))  :=
  match p with
    (a,b) => Vapp a b
  end.

Lemma vp2pv: forall {T:Type} i1 i2 (p:((vector T i1)*(vector T i2))),
    vector2pair i1 (pair2vector p) = p.
Proof.
  intros.
  unfold vector2pair.
  destruct p.
  unfold pair2vector.
  apply Vbreak_app.
Qed.

(* reverse CONS, append single element to the end of the list *)
Program Fixpoint snoc {A} {n} (l:vector A n) (v:A) : (vector A (S n)) :=
  match l with
  | nil => [v]
  | h' :: t' => Vcons h' (snoc t' v)
  end.

Lemma hd_cons {A} {n} (h:A) {t: vector A n}: Vhead (Vcons h t) = h.
Proof.
  reflexivity.
Qed.

Lemma hd_snoc0: forall {A} (l:vector A 0) v, hd (snoc l v) = v.
Proof.
  intros.
  dep_destruct l.
  reflexivity.
Qed.

Lemma hd_snoc1: forall {A} {n} (l:vector A (S n)) v, hd (snoc l v) = hd l.
Proof.
  intros.
  dep_destruct l.
  reflexivity.
Qed.

Lemma tl_snoc1: forall {A} {n} (l:vector A (S n)) v, tl (snoc l v) = snoc (tl l) v.
Proof.
  intros.
  dep_destruct l.
  reflexivity.
Qed.

Lemma snoc2cons: forall {A} (n:nat) (l:vector A (S n)) v,
    snoc l v = @cons _ (hd l) _ (snoc (tl l) v).
Proof.
  intros.
  dep_destruct l.
  reflexivity.
Qed.

Lemma last_snoc: forall A n (l:vector A n) v, last (snoc l v) = v.
Proof.
  intros.
  induction l.
  auto.
  rewrite snoc2cons.
  simpl.
  assumption.
Qed.

Lemma map_nil: forall A B (f:A->B), map f [] = [].
Proof.
  intros.
  simpl.
  reflexivity.
Qed.

Lemma map2_nil: forall A B C (f:A->B->C), map2 f [] [] = [].
Proof.
  intros.
  simpl.
  reflexivity.
Qed.

Lemma map_hd: forall A B (f:A->B) n (v:vector A (S n)), hd (map f v) = f (hd v).
Proof.
  intros.
  dep_destruct v.
  reflexivity.
Qed.

Lemma Vmap_cons: forall A B (f:A->B) n (x:A) (xs: vector A n),
    Vmap f (Vcons x xs) = Vcons (f x) (Vmap f xs).
Proof.
  intros.
  constructor.
Qed.

Lemma map_cons: forall A B n (f:A->B) (v:vector A (S n)),
    map f v = @cons _ (f (hd v)) _ (map f (tl v)).
Proof.
  intros.
  dep_destruct v.
  reflexivity.
Qed.

Lemma map2_cons: forall A B C (f:A->B->C) n (a:vector A (S n)) (b:vector B (S n)),
    map2 f a b = @cons _ (f (hd a) (hd b)) _ (map2 f (tl a) (tl b)).
Proof.
  intros.
  dep_destruct a.
  dep_destruct b.
  reflexivity.
Qed.

Lemma VMapp2_app:
  forall {A B} {f: A->A->B} (n m : nat)
         {a b: vector A m} {a' b':vector A n},
    Vmap2 f (Vapp a a') (Vapp b b')
    = Vapp (Vmap2 f a b) (Vmap2 f a' b').
Proof.
  intros A B f n m a b a' b'.
  induction m.
  - VOtac.
    reflexivity.
  - VSntac a. VSntac b.
    simpl.
    rewrite IHm.
    reflexivity.
Qed.

Lemma shifout_tl_swap: forall {A} n (l:vector A (S (S n))),
    tl (shiftout l) = shiftout (tl l).
Proof.
  intros.
  dep_destruct l.
  simpl.
  reflexivity.
Qed.

Lemma last_tl: forall {A} n (l:vector A (S (S n))),
    last (tl l) = last l.
Proof.
  intros.
  dep_destruct l.
  simpl.
  reflexivity.
Qed.

Lemma map_snoc: forall A B n (f:A->B) (l:vector A (S n)),
    map f l = snoc (map f (shiftout l)) (f (last l)).
Proof.
  intros.
  induction n.
  Case "n=0".
  dep_destruct l.
  assert (L: last (h::x) = h).
  SCase "L".
  dep_destruct x.
  reflexivity.
  rewrite L.
  assert (S: forall (z:vector A 1), shiftout z = []).
  SCase "S".
  intros.
  dep_destruct z.
  dep_destruct x0.
  reflexivity.
  dep_destruct x.
  rewrite S.
  simpl.
  reflexivity.
  Case "S n".
  rewrite map_cons.
  rewrite IHn.  clear_all.
  symmetry.
  rewrite snoc2cons.
  rewrite map_cons.
  assert (HS: hd (shiftout l) = hd l).
  dep_destruct l.
  reflexivity.
  rewrite HS. clear_all.
  simpl (hd (f (hd l) :: map f (tl (shiftout l)))).
  assert (L:(tl (f (hd l) :: map f (tl (shiftout l)))) = (map f (shiftout (tl l)))).
  simpl. rewrite shifout_tl_swap. reflexivity.
  rewrite L. rewrite last_tl. reflexivity.
Qed.


Lemma map2_snoc: forall A B C (f:A->B->C) n (a:vector A (S n)) (b:vector B (S n)),
    map2 f a b = snoc (map2 f (shiftout a) (shiftout b)) (f (last a) (last b)).
Proof.
  intros.
  induction n.
  Case "n=0".
  dep_destruct a.
  dep_destruct b.
  assert (L: forall T hl (xl:t T 0), last (hl::xl) = hl).
  SCase "L".
  intros.
  dep_destruct xl.
  reflexivity.
  repeat rewrite L.
  assert (S: forall T (z:t T 1), shiftout z = []).
  SCase "S".
  intros.
  dep_destruct z.
  dep_destruct x1.
  reflexivity.
  dep_destruct x.
  dep_destruct x0.
  repeat rewrite S.
  simpl.
  reflexivity.
  Case "S n".
  rewrite map2_cons.
  rewrite IHn.  clear_all.
  symmetry.
  repeat rewrite snoc2cons.
  repeat rewrite map2_cons.
  assert (HS: forall T m (l:t T (S (S m))), hd (shiftout l) = hd l).
  intros. dep_destruct l. reflexivity.
  repeat rewrite HS. clear_all.
  simpl (hd (f (hd a) (hd b) :: map2 f (tl (shiftout a)) (tl (shiftout b)))).

  assert(L:(tl (f (hd a) (hd b) :: map2 f (tl (shiftout a)) (tl (shiftout b)))) = (map2 f (shiftout (tl a)) (shiftout (tl b)))).
  simpl. repeat rewrite shifout_tl_swap. reflexivity.
  rewrite L. repeat rewrite last_tl. reflexivity.
Qed.


Lemma map2_comm: forall A B (f:A->A->B) n (a b:vector A n),
    (forall x y, (f x y) = (f y x)) -> map2 f a b = map2 f b a.
Proof.
  intros.
  induction n.
  dep_destruct a.
  dep_destruct b.
  reflexivity.
  rewrite -> map2_cons.
  rewrite H. (* reorder LHS head *)
  rewrite <- IHn. (* reoder LHS tail *)
  rewrite <- map2_cons.
  reflexivity.
Qed.

(* Shows that two map2 supplied with function which ignores 2nd argument
will be eqivalent for all values of second list *)
Lemma map2_ignore_2: forall A B C (f:A->B->C) n (a:vector A n) (b0 b1:vector B n),
    (forall a' b0' b1', f a' b0' = f a' b1') ->
    map2 f a b0 = map2 f a b1 .
Proof.
  intros.
  induction a.
  dep_destruct (map2 f [] b1).
  dep_destruct (map2 f [] b0).
  reflexivity.
  rewrite 2!map2_cons.
  simpl.
  rewrite -> H with (a':=h) (b0':=(hd b0)) (b1':=(hd b1)).
  assert(map2 f a (tl b0) = map2 f a (tl b1)).
  apply(IHa).
  rewrite <- H0.
  reflexivity.
Qed.


(* Shows that two map2 supplied with function which ignores 1st argument
will be eqivalent for all values of first list *)
Lemma map2_ignore_1: forall A B C (f:A->B->C) n (a0 a1:vector A n) (b:vector B n),
    (forall a0' a1' b', f a0' b' = f a1' b') ->
    map2 f a0 b = map2 f a1 b .
Proof.
  intros.
  induction b.
  dep_destruct (map2 f a0 []).
  dep_destruct (map2 f a1 []).
  reflexivity.
  rewrite 2!map2_cons.
  simpl.
  rewrite -> H with (b':=h) (a0':=(hd a0)) (a1':=(hd a1)).
  assert(map2 f (tl a0) b = map2 f (tl a1) b).
  apply(IHb).
  rewrite <- H0.
  reflexivity.
Qed.

Lemma shiftout_snoc: forall A n (l:vector A n) v, shiftout (snoc l v) = l.
Proof.
  intros.
  induction l.
  auto.
  simpl.
  rewrite IHl.
  reflexivity.
Qed.

Lemma fold_right_reduce: forall A B n (f:A->B->B) (id:B) (v:vector A (S n)),
    fold_right f v id = f (hd v) (fold_right f (tl v) id).
Proof.
  intros.
  dep_destruct v.
  reflexivity.
Qed.

Lemma Vfold_left_1
      {B C : Type} (f: C -> B -> C) {z: C} {v:vector B 1}:
  Vfold_left f z v = f z (Vhead v).
Proof.
  dep_destruct v.
  simpl.
  replace x with (@Vnil B).
  simpl.
  reflexivity.
  symmetry.
  dep_destruct x.
  reflexivity.
Qed.

Lemma Vfold_right_reduce: forall A B n (f:A->B->B) (id:B) (v:vector A (S n)),
    Vfold_right f v id = f (hd v) (Vfold_right f (tl v) id).
Proof.
  intros.
  dep_destruct v.
  reflexivity.
Qed.

Lemma Vfold_right_fold_right: forall {A B:Type} {n} (f:A->B->B) (v: vector A n) (initial:B),
    Vfold_right f v initial = @fold_right A B f n v initial.
Proof.
  intros.
  induction v.
  reflexivity.
  rewrite fold_right_reduce.
  simpl.
  rewrite <- IHv.
  reflexivity.
Qed.

(* It directly follows from definition, but haiving it as sepearate lemma helps to do rewiring *)
Lemma Vfold_left_rev_cons:
  forall A B {n} (f : B->A->B) (b:B) (x: A) (xs : vector A n),
    Vfold_left_rev f b (Vcons x xs) = f (Vfold_left_rev f b xs) x.
Proof.
  intros A B n f b x xs.
  reflexivity.
Qed.

Lemma rev_nil: forall A, rev (@nil A) = [].
Proof.
  intros A.
  unfold rev.
  assert (rev_append (@nil A) (@nil A) = (@nil A)).
  unfold rev_append.
  assert (rev_append_tail (@nil A) (@nil A) = (@nil A)).
  auto.
  rewrite H. clear_all.
  dep_destruct (plus_tail_plus 0 0).
  auto.
  rewrite H. clear_all.
  dep_destruct (plus_n_O 0).
  auto.
Qed.

Lemma hd_eq: forall A n (u v: vector A (S n)), u=v -> (hd u) = (hd v).
Proof.
  intros.
  rewrite H.
  reflexivity.
Qed.

Lemma Vbreak_arg_app:
  forall {B} (m n : nat) (x : vector B (m + n)) (a: vector B m) (b: vector B n),
    Vbreak x = (a, b) -> x = Vapp a b.
Proof.
  intros B m n x a b V.
  rewrite Vbreak_eq_app with (v:=x).
  rewrite V.
  reflexivity.
Qed.

Lemma Vbreak_preserves_values {A} {n1 n2} {x: vector A (n1+n2)} {x0 x1}:
  Vbreak x = (x0, x1) ->
  forall a, Vin a x <-> ((Vin a x0) \/ (Vin a x1)).
Proof.
  intros B a.
  apply Vbreak_arg_app in B.
  subst.
  split.
  apply Vin_app.
  intros.
  destruct H.
  apply Vin_appl; assumption.
  apply Vin_appr; assumption.
Qed.

Lemma Vbreak_preserves_P {A} {n1 n2} {x: vector A (n1+n2)} {x0 x1} {P}:
  Vbreak x = (x0, x1) ->
  (Vforall P x -> ((Vforall P x0) /\ (Vforall P x1))).
Proof.
  intros B D.
  assert(N: forall a, Vin a x -> P a).
  {
    intros a.
    apply Vforall_in with (v:=x); assumption.
  }
  (split;
   apply Vforall_intro; intros x2 H;
   apply N;
   apply Vbreak_preserves_values with (a:=x2) in B;
   destruct B as [B0 B1];
   apply B1) ;
    [left | right]; assumption.
Qed.

Lemma Vforall_hd {A:Type} {P:A->Prop} {n:nat} {v:vector A (S n)}:
  Vforall P v -> P (Vhead v).
Proof.
  dep_destruct v.
  simpl.
  tauto.
Qed.

Lemma Vforall_tl {A:Type} {P:A->Prop} {n:nat} {v:vector A (S n)}:
  Vforall P v -> Vforall P (Vtail v).
Proof.
  dep_destruct v.
  simpl.
  tauto.
Qed.

Lemma Vforall_nil:
  forall B (P:B->Prop), Vforall P (@Vnil B).
Proof.
  crush.
Qed.

Lemma Vforall_cons {B:Type} {P:B->Prop} {n:nat} {x:B} {xs:vector B n}:
  (P x /\ Vforall P xs) = Vforall P (cons x xs).
Proof.
  auto.
Qed.

Lemma Vforall_1 {B: Type} {P} (v: vector B 1):
  Vforall P v <-> P (Vhead v).
Proof.
  split.
  +
    dep_destruct v.
    simpl.
    replace (Vforall P x) with True; simpl.
    tauto.
    replace x with (@Vnil B).
    simpl; reflexivity.
    dep_destruct x; reflexivity.
  + dep_destruct v.
    simpl.
    replace (Vforall P x) with True; simpl.
    tauto.
    replace x with (@Vnil B).
    simpl; reflexivity.
    dep_destruct x; reflexivity.
Qed.

Lemma vec_eq_elementwise n B (v1 v2: vector B n):
  Vforall2 eq v1 v2 -> (v1 = v2).
Proof.
  induction n.
  + dep_destruct v1. dep_destruct v2.
    auto.
  + dep_destruct v1. dep_destruct v2.
    intros H.
    rewrite Vforall2_cons_eq in H.
    destruct H as [Hh Ht].
    apply IHn in Ht.
    rewrite Ht, Hh.
    reflexivity.
Qed.

Lemma Vmap_Vbuild n B C (fm: B->C) (fb : forall i : nat, i < n -> B):
  Vmap fm (Vbuild fb) = Vbuild (fun z zi => fm (fb z zi)).
Proof.
  apply vec_eq_elementwise.
  apply Vforall2_intro_nth.
  intros i ip.
  rewrite Vnth_map.
  rewrite 2!Vbuild_nth.
  reflexivity.
Qed.

Lemma Vexists_Vbuild:
  forall (T:Type) (P: T -> Prop) (n:nat) {f},
    Vexists P (Vbuild (n:=n) f) <-> exists i (ic:i<n), P (f i ic).
Proof.
  intros T P n f.
  split.
  - intros E.
    apply Vexists_eq in E.
    destruct E as[x [V Px]].
    apply Vin_nth in V.
    destruct V as [i [ip V]].
    rewrite Vbuild_nth in V.
    subst x.
    exists i, ip.
    apply Px.
  - intros H.
    apply Vexists_eq.
    destruct H as [i [ic H]].
    exists (f i ic).
    split.
    +
      apply Vin_build.
      exists i, ic.
      reflexivity.
    + assumption.
Qed.

Lemma Vbuild_0:
  forall B gen, @Vbuild B 0 gen = @Vnil B.
Proof.
  intros B gen.
  auto.
Qed.

Lemma Vbuild_1 B gen:
  @Vbuild B 1 gen = [gen 0 (lt_0_Sn 0)].
Proof.
  unfold Vbuild.
  simpl.
  replace (VecUtil.Vbuild_spec_obligation_4 gen eq_refl) with (lt_0_Sn 0) by apply proof_irrelevance.
  reflexivity.
Qed.

Fact lt_0_SSn:  forall n:nat, 0<S (S n). Proof. intros;omega. Qed.

Fact lt_1_SSn:  forall n:nat, 1<S (S n). Proof. intros; omega. Qed.

Lemma Vbuild_2 B gen:
  @Vbuild B 2 gen = [gen 0 (lt_0_SSn 0) ; gen 1 (lt_1_SSn 0)].
Proof.
  unfold Vbuild.
  simpl.
  replace (VecUtil.Vbuild_spec_obligation_4 gen eq_refl) with (lt_0_SSn 0) by apply proof_irrelevance.
  replace (VecUtil.Vbuild_spec_obligation_3 gen eq_refl
                                            (VecUtil.Vbuild_spec_obligation_4
                                               (fun (i : nat) (ip : i < 1) =>
                                                  gen (S i) (VecUtil.Vbuild_spec_obligation_3 gen eq_refl ip)) eq_refl)) with (lt_1_SSn 0) by apply proof_irrelevance.
  reflexivity.
Qed.


Definition Vin_aux {A} {n} (v : vector A n) (x : A) : Prop := Vin x v.

Lemma Vnth_0 {B} {n} (v:vector B (S n)) (ip: 0<(S n)):
  Vnth (i:=0) v ip = Vhead v.
Proof.
  dep_destruct v.
  simpl.
  reflexivity.
Qed.

Lemma Vnth_Sn {B} (n i:nat) (v:B) (vs:vector B n) (ip: S i< S n) (ip': i< n):
  Vnth (Vcons v vs) ip = Vnth vs ip'.
Proof.
  simpl.
  replace (lt_S_n ip) with ip' by apply proof_irrelevance.
  reflexivity.
Qed.

Lemma Vnth_cast_index:
  forall {B} {n : nat} i j (ic: i<n) (jc: j<n) (x : vector B n),
    i = j -> Vnth x ic = Vnth x jc.
Proof.
  intros B n i j ic jc x E.
  crush.
  replace ic with jc by apply proof_irrelevance.
  reflexivity.
Qed.

Lemma Vbuild_cons:
  forall B n (gen : forall i, i < S n -> B),
    Vbuild gen = Vcons (gen 0 (lt_O_Sn n)) (Vbuild (fun i ip => gen (S i) (lt_n_S ip))).
Proof.
  intros B n gen.
  rewrite <- Vbuild_head.
  rewrite <- Vbuild_tail.
  auto.
Qed.

Lemma Vforall_Vbuild (T : Type) (P:T -> Prop) (n : nat) (gen : forall i : nat, i < n -> T):
  Vforall P (Vbuild gen) <-> forall (i : nat) (ip : i < n), P (gen i ip).
Proof.
  split.
  - intros H i ip.
    apply Vforall_nth with (ip:=ip) in H.
    rewrite Vbuild_nth in H.
    apply H.
  - intros H.
    apply Vforall_nth_intro.
    intros i ip.
    rewrite Vbuild_nth.
    apply H.
Qed.

Lemma P_Vnth_Vcons {T:Type} {P:T -> Prop} {n:nat} (h:T) (t:vector T n):
  forall i (ic:i<S n) (ic': (pred i) < n),
    P (Vnth (Vcons h t) ic) -> P h \/ P (Vnth t ic').
Proof.
  intros i ic ic' H.
  destruct i.
  + left.
    auto.
  + right.
    simpl in H.
    replace (lt_S_n ic) with ic' in H by apply proof_irrelevance.
    apply H.
Qed.

Lemma P_Vnth_Vcons_not_head {T:Type} {P:T -> Prop} {n:nat} (h:T) (t:vector T n):
  forall i (ic:i<S n) (ic': (pred i) < n),
    not (P h) -> P (Vnth (Vcons h t) ic) -> P (Vnth t ic').
Proof.
  intros i ic ic' Ph Pt.
  destruct i.
  - simpl in Pt; congruence.
  - simpl in Pt.
    replace (lt_S_n ic) with ic' in Pt by apply proof_irrelevance.
    apply Pt.
Qed.

Section Vunique.
  Local Open Scope nat_scope.

  (* There is only one element in vector satisfying given predicate *)
  Definition Vunique {n} {T:Type}
             (P: T -> Prop)
             (v: vector T n) :=

    (forall (i: nat) (ic: i < n) (j: nat) (jc: j < n),
        (P (Vnth v ic) /\ P (Vnth v jc)) -> i = j).

  Lemma Vunique_Vnil (T : Type) (P : T -> Prop):
    Vunique P (@Vnil T).
  Proof.
    unfold Vunique.
    intros i ic j jc H.
    nat_lt_0_contradiction.
  Qed.

  Lemma Vforall_notP_Vunique:
    forall (n : nat) (T : Type) (P : T -> Prop) (v : vector T n),
      Vforall (not ∘ P) v -> Vunique P v.
  Proof.
    intros n T P v.
    induction v.
    - intros H.
      apply Vunique_Vnil.
    -
      intros H.
      unfold Vunique in *.
      intros i ic j jc V.
      destruct V.
      apply Vforall_nth with (i:=i) (ip:=ic) in H.
      congruence.
  Qed.

  Lemma Vunique_cons_not_head
        {n} {T:Type}
        (P: T -> Prop)
        (h: T) (t: vector T n):
    not (P h) /\ Vunique P t -> Vunique P (Vcons h t).
  Proof.
    intros H.
    destruct H as [Ph Pt].
    unfold Vunique.
    intros i ic j jc H.
    destruct H as [Hi Hj].

    destruct i,j.
    - reflexivity.
    - simpl in Hi. congruence.
    - simpl in Hj. congruence.
    -
      assert(ic': pred (S i) < n) by (apply lt_S_n; apply ic).
      apply P_Vnth_Vcons_not_head with (ic'0:=ic') in Hi; try apply Ph.

      assert(jc': pred (S j) < n) by (apply lt_S_n; apply jc).
      apply P_Vnth_Vcons_not_head with (ic'0:=jc') in Hj; try apply Ph.

      f_equal.
      unfold Vunique in Pt.
      apply Pt with (ic:=ic') (jc:=jc').
      split; [apply Hi| apply Hj].
  Qed.

  Lemma Vunique_cons_head
        {n} {T:Type}
        (P: T -> Prop)
        (h: T) (t: vector T n):
    P h /\ (Vforall (not ∘ P) t) -> Vunique P (Vcons h t).
  Proof.
    intros H.
    destruct H as [Ph Pt].
    unfold Vunique.
    intros i ic j jc H.
    destruct H as [Hi Hj].

    destruct i, j.
    - reflexivity.
    -
      assert(jc':j < n) by omega.
      apply Vforall_nth with (i:=j) (ip:=jc') in Pt.
      unfold compose in Pt.
      rewrite Vnth_Sn with (ip:=jc) (ip':=jc') in Hj.
      congruence.
    -
      assert(ic':i < n) by omega.
      apply Vforall_nth with (i:=i) (ip:=ic') in Pt.
      unfold compose in Pt.
      rewrite Vnth_Sn with (ip:=ic) (ip':=ic') in Hi.
      congruence.
    -
      assert(jc':j < n) by omega.
      apply Vforall_nth with (i:=j) (ip:=jc') in Pt.
      unfold compose in Pt.
      rewrite Vnth_Sn with (ip:=jc) (ip':=jc') in Hj.
      congruence.
  Qed.

  Lemma Vunique_cons {n} {T:Type}
        (P: T -> Prop)
        (h: T) (t: vector T n):
    ((P h /\ (Vforall (not ∘ P) t)) \/
     (not (P h) /\ Vunique P t))
    ->
    Vunique P (Vcons h t).
  Proof.
    intros H.
    destruct H.
    apply Vunique_cons_head; auto.
    apply Vunique_cons_not_head; auto.
  Qed.

  Lemma Vunique_cons_tail {n}
        {T:Type} (P: T -> Prop)
        (h : T) (t : vector T n):
    Vunique P (Vcons h t) -> Vunique P t.
  Proof.
    intros H.
    unfold Vunique in *.
    intros i ic j jc [Vi Vj].
    assert(S i = S j).
    {
      assert(ic': S i < S n) by omega.
      assert(jc': S j < S n) by omega.
      apply H with (ic:=ic') (jc:=jc').
      simpl.
      replace (lt_S_n ic') with ic by apply proof_irrelevance.
      replace (lt_S_n jc') with jc by apply proof_irrelevance.
      auto.
    }
    auto.
  Qed.
End Vunique.

(* Utlity functions for vector products *)

Section VectorPairs.

  Definition Phead {A} {B} {n} (ab:(vector A (S n))*(vector B (S n))): A*B
    := match ab with
       | (va,vb) => ((Vhead va), (Vhead vb))
       end.

  Definition Ptail {A} {B} {n} (ab:(vector A (S n))*(vector B (S n))): (vector A n)*(vector B n)
    := match ab with
       | (va,vb) => ((Vtail va), (Vtail vb))
       end.

End VectorPairs.

Section VMap2_Indexed.

  Definition Vmap2Indexed {A B C : Type} {n}
             (f: nat->A->B->C) (a: vector A n) (b: vector B n)
    := Vbuild (fun i ip => f i (Vnth a ip) (Vnth b ip)).

  Lemma Vnth_Vmap2Indexed:
    forall {A B C : Type} {n:nat} (i : nat) (ip : i < n) (f: nat->A->B->C)
      (a:vector A n) (b:vector B n),
      Vnth (Vmap2Indexed f a b) ip = f i (Vnth a ip) (Vnth b ip).
  Proof.
    intros A B C n i ip f a b.
    unfold Vmap2Indexed.
    rewrite Vbuild_nth.
    reflexivity.
  Qed.

End VMap2_Indexed.


Definition Lst {B:Type} (x:B) := [x].

Lemma Vin_cons:
  forall (T:Type) (h : T) (n : nat) (v : vector T n) (x : T),
    Vin x (Vcons h v) -> x = h \/ Vin x v.
Proof.
  crush.
Qed.
