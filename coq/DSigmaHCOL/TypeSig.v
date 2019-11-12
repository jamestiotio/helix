Require Import Coq.Arith.Arith.
Require Import Coq.Structures.OrderedTypeEx.
Require Import Coq.Arith.PeanoNat.
Require Import Coq.Arith.Peano_dec.
Require Import Coq.Logic.Decidable.
Require Import Omega.
Require Import Psatz.

Require Import CoLoR.Util.Nat.NatUtil.

From Coq.FSets Require Import
     FSetAVL
     FSetInterface
     FSetFacts
     FSetProperties
     FSetToFiniteSet
     FMapAVL
     FMapInterface
     FMapFacts.

Require Import Helix.HCOL.CarrierType.

Require Import Helix.DSigmaHCOL.DSigmaHCOL.
Require Import Helix.DSigmaHCOL.DSigmaHCOLEval.

Require Import MathClasses.misc.util.
Require Import MathClasses.interfaces.canonical_names.
Require Import MathClasses.orders.minmax MathClasses.interfaces.orders.
Require Import MathClasses.implementations.peano_naturals.
Require Import MathClasses.implementations.bool.
Require Import MathClasses.orders.orders.
Require Import MathClasses.misc.decision.

Require Import Helix.Util.OptionSetoid.
Require Import Helix.Tactics.HelixTactics.

Open Scope list_scope.

Require Import ExtLib.Structures.Monads.
Require Import ExtLib.Data.Monads.OptionMonad.

Import MonadNotation.
Local Open Scope monad_scope.
Local Open Scope nat_scope.

Module TM := FMapAVL.Make(Nat_as_OT).
Module Import TP := FMapFacts.WProperties_fun(Nat_as_OT)(TM).
(* [TypeSig] is a signature of an evaluation context, which maps
   De-Brujn indices to expected types *)
Definition TypeSig := TM.t DSHType.

Section TypeSig_Setoid.

  Global Instance TypeSig_Equiv: Equiv (TypeSig) :=
    fun m m' => forall k : TM.key, TM.find k m = TM.find k m'.

  Global Instance TypeSig_Equiv_Reflexive:
    Reflexive (TypeSig_Equiv).
  Proof.
    unfold TypeSig_Equiv.
    unfold Reflexive.
    reflexivity.
  Qed.

  Global Instance TypeSig_Equiv_Symmetric:
    Symmetric (TypeSig_Equiv).
  Proof.
    unfold TypeSig_Equiv.
    unfold Symmetric.
    intros x y H k.
    specialize (H k).
    auto.
  Qed.

  Global Instance TypeSig_Equiv_Transitive:
    Transitive (TypeSig_Equiv).
  Proof.
    unfold TypeSig_Equiv.
    unfold Transitive.
    intros x y z H0 H1 k.
    specialize (H0 k).
    specialize (H1 k).
    auto.
  Qed.

  Global Instance TypeSig_Equiv_Equivalence:
    Equivalence (TypeSig_Equiv).
  Proof.
    split; typeclasses eauto.
  Qed.

End TypeSig_Setoid.

(* True if nth context element has expected type. decidable. *)
Definition contextEnsureType (σ: evalContext) (k:nat) (t:DSHType) : Prop :=
  match nth_error σ k with
  | Some v => DSHValType v t
  | _ => False
  end.

Global Instance contextEnsureType_Decision {σ k t}:
  Decision (contextEnsureType σ k t).
Proof.
  unfold Decision, contextEnsureType.
  break_match; auto.
  apply DSHValType_Decision.
Qed.

(* typecheck env. starting from [off] index (inclusuve).  *)
Definition typecheck_env_bool (off:nat) (tm:TypeSig) (σ: evalContext) : bool :=
  TP.for_all (fun k t =>
                (k<?off) || (bool_decide (contextEnsureType σ (k-off) t))
             ) tm.

(* Propositional version *)
Definition typecheck_env (off:nat) (tm:TypeSig) (σ: evalContext) :  Prop :=
  typecheck_env_bool off tm σ ≡ true.

(* not needed for now. maybe need later.
Global Instance typecheck_env_proper:
  Proper ((=) ==> (=) ==> (=) ==> iff) typecheck_env.
Proof.
Admitted.
*)

(* Compare two type signatures for conflicts and returns map of
   conflicting entries, for each conflicting key, the value us a tuple
   of 2 incompatible values.

   A conflict occurs when different values occur at different
   signatures at the same index. If for given index the value is
   present only in one signature that does not constiture a
   conflct.  *)
Definition findTypeSigConflicts (s1 s2:TypeSig)
  := TM.map2 (fun a b => match a, b with
                      | Some x, Some y =>
                        if bool_decide (x = y)
                        then None
                        else Some (a,b)
                      | _, _ => None
                      end) s1 s2.

(* Returns [True], if given type signatures do not have conflicts.

   A conflict occurs when different values occur at different
   signatures at the same index. If for given index the value is
   present only in one signature that does not constiture a
   conflct.  *)
Definition TypeSigCompat (s1 s2:TypeSig) : Prop
  := TM.Empty (findTypeSigConflicts s1 s2).

Global Instance TypeSigCompat_Decision {s1 s2}:
  Decision (TypeSigCompat s1 s2).
Proof.
  unfold Decision, TypeSigCompat.
  destruct (TM.is_empty (elt:=option DSHType * option DSHType)
                        (findTypeSigConflicts s1 s2)) eqn:H.
  - left; apply TM.is_empty_2; assumption.
  - right; intro C; apply TM.is_empty_1 in C; congruence.
Qed.

(* This is "unsafe" version which will override conflicting keys *)
Definition TypeSigUnion := TP.update (elt:=DSHType).

(* This is "safe" version which returns error in case of conflct *)
Definition TypeSigUnion_error (s1 s2: TypeSig)
  := if TypeSigCompat_Decision (s1:=s1) (s2:=s2)
     then Some (TypeSigUnion s1 s2)
     else None.

Lemma TypeSigCompat_TypeSigUnion_error {dsig1 dsig2}:
  TypeSigCompat dsig1 dsig2 ->
  TypeSigUnion_error dsig1 dsig2 = Some (TypeSigUnion dsig1 dsig2).
Proof.
  intros H.
  unfold TypeSigUnion_error.
  break_if; [ reflexivity | congruence ].
Qed.

(* Helper wrapper for double bind of [TypeSigUnion_error] *)
Definition TypeSigUnion_error' (os1 os2: option TypeSig): option TypeSig
  := s1 <- os1 ;; s2 <- os2 ;; TypeSigUnion_error s1 s2.

Definition TypeSig_safe_add (k:var_id) (v:DSHType) (ts: TypeSig): option TypeSig
  := match TM.find k ts with
     | Some v' =>
       if bool_decide (v = v')
       then Some ts (* already exists with same value *)
       else None (* already exists, but with different value *)
     | None => Some (TM.add k v ts)
     end.

Definition TypeSigMExpr (me:MExpr) : option TypeSig :=
  match me with
  | MVar v => Some (TM.add v DSHMemBlock (TM.empty _))
  | MConst _ => Some (TM.empty _)
  end.

Fixpoint TypeSigNExpr (ne:NExpr) : option TypeSig :=
  match ne with
  | NVar v => TypeSig_safe_add v DSHnat (TM.empty _)
  | NConst x => Some (TM.empty _)
  | NDiv a b => TypeSigUnion_error' (TypeSigNExpr a) (TypeSigNExpr b)
  | NMod a b => TypeSigUnion_error' (TypeSigNExpr a) (TypeSigNExpr b)
  | NPlus a b => TypeSigUnion_error' (TypeSigNExpr a) (TypeSigNExpr b)
  | NMinus a b => TypeSigUnion_error' (TypeSigNExpr a) (TypeSigNExpr b)
  | NMult a b => TypeSigUnion_error' (TypeSigNExpr a) (TypeSigNExpr b)
  | NMin a b => TypeSigUnion_error' (TypeSigNExpr a) (TypeSigNExpr b)
  | NMax a b => TypeSigUnion_error' (TypeSigNExpr a) (TypeSigNExpr b)
  end.

Fixpoint TypeSigAExpr (ae:AExpr) : option TypeSig :=
  match ae with
  | AVar v => TypeSig_safe_add v DSHCarrierA (TM.empty _)
  | AConst _ => Some (TM.empty _)
  | ANth m n => TypeSigUnion_error' (TypeSigMExpr m) (TypeSigNExpr n)
  | AAbs a => TypeSigAExpr a
  | APlus a b => TypeSigUnion_error' (TypeSigAExpr a) (TypeSigAExpr b)
  | AMinus a b => TypeSigUnion_error' (TypeSigAExpr a) (TypeSigAExpr b)
  | AMult a b => TypeSigUnion_error' (TypeSigAExpr a) (TypeSigAExpr b)
  | AMin a b => TypeSigUnion_error' (TypeSigAExpr a) (TypeSigAExpr b)
  | AMax a b => TypeSigUnion_error' (TypeSigAExpr a) (TypeSigAExpr b)
  | AZless a b => TypeSigUnion_error' (TypeSigAExpr a) (TypeSigAExpr b)
  end.

(* make sure 2 contexts are quivalent at locations from given [TypeSig].
   additionally makes typechecks both contexts wrt [TypeSig] *)
Definition context_equiv_at_TypeSig (tm:TypeSig) : relation evalContext
  := fun σ0 σ1 =>
       forall k t, TM.MapsTo k t tm ->
                   contextEnsureType σ0 k t /\
                   contextEnsureType σ1 k t /\ (* this is redundant *)
                   context_lookup σ0 k = context_lookup σ1 k.

(* Similar to [context_equiv_at_TypeSig] but assumes first [off] values
   are not included in eval contexts but still could be referenced in
   type signature. These first [off] keys will not be type checked.
 *)
Definition context_equiv_at_TypeSig_off (tm:TypeSig) (off:nat): relation evalContext
  := fun σ0 σ1 =>
       forall k t, k>=off ->
              TM.MapsTo k t tm ->
              contextEnsureType σ0 (k-off) t /\
              contextEnsureType σ1 (k-off) t /\ (* this is redundant *)
              context_lookup σ0 (k-off) = context_lookup σ1 (k-off).

Definition context_equiv_at_TypeSig_head (tm:TypeSig) (max:nat): relation evalContext
  := fun σ0 σ1 =>
       forall k t, k<max ->
              TM.MapsTo k t tm ->
              contextEnsureType σ0 k t /\
              contextEnsureType σ1 k t /\ (* this is redundant *)
              context_lookup σ0 k = context_lookup σ1 k.

Lemma context_equiv_at_TypeSig_0 {tm σ0 σ1}:
  context_equiv_at_TypeSig_off tm 0 σ0 σ1 <-> context_equiv_at_TypeSig tm σ0 σ1.
Proof.
  split; intros H.
  -
    unfold context_equiv_at_TypeSig_off in H.
    unfold context_equiv_at_TypeSig.
    intros k t H0.
    specialize (H k t).
    rewrite Nat.sub_0_r in H.
    destruct (lt_ge_dec k 0) as [kc|kc].
    inversion kc.
    auto.
  -
    unfold context_equiv_at_TypeSig_off.
    unfold context_equiv_at_TypeSig in H.
    intros k t kc H1.
    rewrite Nat.sub_0_r.
    apply H.
    auto.
Qed.

Definition TypeSig_incr_n (t:TypeSig) (off:nat): TypeSig :=
  TP.of_list (List.map (fun '(k,v) => (k+off, v)) (TP.to_list t)).

(* increases keys in type signature by 1.

TODO: Should be defined as := TypeSig_incr_n t 1.

 *)
Definition TypeSig_incr (t:TypeSig) : TypeSig :=
  TP.of_list (List.map (fun '(k,v) => (S k, v)) (TP.to_list t)).

Lemma InA_map_1 {A : Type}
                (eqA : A -> A -> Prop)
                (x : A)
                (m : list A)
                (f : A -> A) :
  (forall a b, eqA a b -> eqA (f a) (f b)) ->
  InA eqA x m -> InA eqA (f x) (map f m).
Proof.
  intros P H.
  apply InA_alt.
  apply InA_alt in H.
  destruct H as [y [H1 H2]].
  exists (f y).
  split; [apply P; congruence |].
  apply in_map_iff.
  exists y; auto.
Qed.

Lemma InA_map_2 {A : Type}
                (eqA : A -> A -> Prop)
                (x : A)
                (m : list A)
                (f : A -> A) :
  (forall a b, eqA (f a) (f b) -> eqA a b) ->
  InA eqA (f x) (map f m) -> InA eqA x m.
Proof.
  intros P H.
  apply InA_alt.
  apply InA_alt in H.
  destruct H as [fy [H1 H2]].
  apply in_map_iff in H2.
  destruct H2 as [y [H2 H3]].
  exists y; split;
    [apply P; congruence | assumption].
Qed.

Lemma InA_map_prototype {A : Type}
                        (eqA : A -> A -> Prop)
                        (fx : A)
                        (m : list A)
                        (f : A -> A) :
  Reflexive eqA ->
  InA eqA fx (map f m) -> (exists x, InA eqA x m /\ eqA fx (f x)).
Proof.
  intros R H.
  apply InA_alt in H.
  destruct H as [fy [H1 H2]].
  apply in_map_iff in H2.
  destruct H2 as [y [H2 H3]].
  exists y.
  split; [| congruence].
  induction m;
    [inversion H3 |].
  simpl in H3; destruct H3 as [EQ | NEQ].
  -
    apply InA_cons_hd.
    rewrite EQ.
    apply R.
  -
    apply InA_cons_tl.
    intuition.
Qed.

Lemma TypeSig_incr_NoDupA (tm : TypeSig) :
  NoDupA (TM.eq_key (elt:=DSHType)) (map (λ '(k, v), (S k, v)) (to_list tm)).
Proof.
    unfold to_list.
    pose proof TM.elements_3w (elt:=DSHType) tm.
    induction H; [constructor |].
    simpl.
    break_match.
    constructor; [| assumption].
    intros C; contradict H.
    apply InA_alt.
    apply InA_alt in C.
    destruct C as [y [H1 H2]].
    apply in_map_iff in H2.
    destruct H2 as [x' [H2 H3]].
    break_match; subst.
    inversion H1; subst.
    exists (n, d0); split; [reflexivity | assumption].
Qed.

Lemma MapsTo_TypeSig_incr {tm : TypeSig}
                          {k : nat}
                          {t : DSHType} :
  TM.MapsTo (S k) t (TypeSig_incr tm) → TM.MapsTo k t tm.
Proof.
  intros H.
  unfold TypeSig_incr in H.
  apply of_list_1 in H;
    [| apply TypeSig_incr_NoDupA].
  remember (λ '(k, v), (S k, v)) as f.
  remember (TM.eq_key_elt (elt:=DSHType)) as K.
  assert (KP : ∀ a b, K (f a) (f b) → K a b).
  {
    subst; clear.
    intros.
    repeat break_match.
    cbv in *.
    intuition.
  }
  pose proof InA_map_2 K (k, t) (to_list tm) f KP.
  subst; apply H0 in H; clear - H.
  apply TM.elements_2.
  assumption.
Qed.

Lemma context_equiv_at_TypeSig_widening {σ0 σ1 tm foo0 foo1}:
  context_equiv_at_TypeSig tm σ0 σ1 ->
  context_equiv_at_TypeSig (TypeSig_incr tm) (foo0 :: σ0) (foo1 :: σ1).
Proof.
  intros H k t M.
  destruct k.
  -
    exfalso.
    apply of_list_1 in M;
      [| apply TypeSig_incr_NoDupA].
    apply InA_alt in M.
    destruct M as [x [H1 H2]].
    apply in_map_iff in H2.
    destruct H2 as [y [H2 H3]].
    break_match; subst.
    inversion H1; discriminate.
  -
    specialize (H k t (MapsTo_TypeSig_incr M)).
    destruct H as [ET0 [ET1 L]].
    repeat split.
    +
      unfold contextEnsureType in *.
      crush.
    +
      unfold contextEnsureType in *.
      crush.
    +
      simpl.
      assumption.
Qed.

Require Import CoLoR.Util.List.ListUtil.

Lemma find_Empty (elt : Type) (m : TM.t elt) :
  TM.Empty (elt:=elt) m ->
  forall k, TM.find k m ≡ None.
Proof.
  intros.
  apply elements_Empty in H.
  rewrite F.elements_o, H.
  reflexivity.
Qed.

Lemma context_equiv_at_TypeSigUnion_left {σ0 σ1 dsig1 dsig2}:
  TypeSigCompat dsig1 dsig2 ->
  context_equiv_at_TypeSig (TypeSigUnion dsig1 dsig2) σ0 σ1 ->
  context_equiv_at_TypeSig dsig1 σ0 σ1.
Proof.
  unfold context_equiv_at_TypeSig.
  intros; apply H0; clear - H H1.
  apply update_mapsto_iff.
  destruct (F.In_dec (elt:=DSHType) dsig2 k) as [I|];
    [left | auto].
  apply TM.find_2.
  unfold TypeSigCompat, TypeSigUnion in H.
  apply find_Empty with (k := k) in H.
  unfold findTypeSigConflicts, TypeSig in H.
  rewrite TM.map2_1 in H by auto.
  rewrite TM.find_1 with (e := t) in H by assumption.
  unfold bool_decide in H.
  repeat break_match_hyp; try congruence.
  apply F.in_find_iff in I; congruence.
Qed.

Lemma context_equiv_at_TypeSigUnion_right {σ0 σ1 dsig1 dsig2}:
  TypeSigCompat dsig1 dsig2 ->
  context_equiv_at_TypeSig (TypeSigUnion dsig1 dsig2) σ0 σ1 ->
  context_equiv_at_TypeSig dsig2 σ0 σ1.
Proof.
  unfold context_equiv_at_TypeSig.
  intros; apply H0; clear - H H1.
  apply update_mapsto_iff.
  destruct (F.In_dec (elt:=DSHType) dsig1 k) as [I|];
    [left | auto].
  apply TM.find_2.
  unfold TypeSigCompat, TypeSigUnion in H.
  apply find_Empty with (k := k) in H.
  unfold findTypeSigConflicts, TypeSig in H.
  rewrite TM.map2_1 in H by auto.
  rewrite TM.find_1 with (e := t) (m := dsig2) in H by assumption.
  unfold bool_decide in H.
  repeat break_match_hyp; try congruence.
  apply TM.find_1; assumption.
  apply F.in_find_iff in I; congruence.
Qed.

Lemma context_equiv_at_TypeSig_off_both_typcheck
      (off: nat)
      (dfs : TypeSig)
      (σ0 σ1 : evalContext):
  context_equiv_at_TypeSig_off dfs off σ0 σ1 →
  (typecheck_env off dfs σ0 /\ typecheck_env off dfs σ1).
Proof.
Admitted.

(* Special case of previous lemma *)
Lemma context_equiv_at_TypeSig_both_typcheck
      (off: nat)
      (dfs : TypeSig)
      (σ0 σ1 : evalContext):
  context_equiv_at_TypeSig dfs σ0 σ1 →
  (typecheck_env 0 dfs σ0 /\ typecheck_env 0 dfs σ1).
Proof.
  intros H.
  split.
  -
    unfold typecheck_env, typecheck_env_bool.
    apply for_all_iff; [typeclasses eauto |].
    intros k t M.
    destruct (k <? 0); [constructor |].
    simpl; apply bool_decide_true.
    specialize (H k t M).
    rewrite Nat.sub_0_r.
    intuition.
  -
    apply for_all_iff.
    typeclasses eauto.
    intros k t M.
    destruct (k <? 0); [constructor |].
    simpl; apply bool_decide_true.
    specialize (H k t M).
    rewrite Nat.sub_0_r.
    intuition.
Qed.

(* True if all of [needle]'s keys belong to [haystack] with
   the same values. This is boolean predicate. *)
Definition TypeSigIncluded_bool (needle haystack: TypeSig) : bool
  := TP.for_all (fun k v => bool_decide (TM.find k haystack = Some v)) needle.

(* True if all of [needle]'s keys belong to [haystack] with
   the same values. This is propositional predicate *)
Definition TypeSigIncluded (needle haystack: TypeSig) : Prop
  := TypeSigIncluded_bool needle haystack ≡ true.

(* TODO: move somewhere? *)
Lemma eq_equiv_bool:
  forall (a b:bool), a ≡ b <-> a = b.
Proof.
  split; intros; destr_bool.
Qed.

Global Instance TypeSig_find_proper:
  Proper ((eq) ==> (=) ==> (=)) (TM.find (elt:=DSHType)).
Proof.
  simpl_relation.
  apply H0.
Qed.

(* not sure this is provable *)
Global Instance TypeSig_fold_proper :
  Proper (((=) ==> (=) ==> (=)) ==> (=) ==> (=) ==> (=))
         (TM.fold (elt:=DSHType) (A:=bool)).
Proof.
  simpl_relation.
  rewrite TM.fold_1 at 1.
  apply eq_equiv_bool.
  pose proof ListUtil.fold_left_m_ext.
  unfold Proper, respectful in *.
  unfold ListUtil.feq in H2.
Admitted.

(* not sure it is provable *)
Global Instance TypeSig_for_all_proper:
  Proper (((=) ==> (=) ==> (=)) ==> (=) ==> (=)) (for_all (elt:=DSHType)).
Proof.
  simpl_relation.
  unfold for_all.
  apply TypeSig_fold_proper; auto.
  unfold respectful in *; intros.
  specialize (H x1 y1 H1 x2 y2 H2).
  repeat break_if; congruence.
Qed.

Global Instance TypeSigIncluded_proper:
  Proper ((=) ==> (=) ==> iff) TypeSigIncluded.
Proof.
  intros n0 n1 En s0 s1 Es.
  split; intros H.
  -
    unfold TypeSigIncluded, TypeSigIncluded_bool in *.
    rewrite <- H.
    apply eq_equiv_bool.
    f_equiv; auto.

    simpl_relation.
    apply eq_equiv_bool.
    unfold bool_decide.
    repeat break_if; auto.
    +
      exfalso.
      clear Heqd Heqd0.
      rewrite H1, H0 in e.
      rewrite <- e in n.
      crush.
    +
      exfalso.
      clear Heqd Heqd0.
      rewrite <- H1, Es, <- H0 in e.
      rewrite <- e in n.
      crush.
  -
    unfold TypeSigIncluded, TypeSigIncluded_bool in *.
    rewrite <- H.
    apply eq_equiv_bool.
    f_equiv; auto.
    simpl_relation.
    apply eq_equiv_bool.
    unfold bool_decide.
    repeat break_if; auto.
    +
      exfalso.
      clear Heqd Heqd0.
      rewrite H0, H1, Es in e.
      rewrite <- e in n.
      crush.
    +
      exfalso.
      clear Heqd Heqd0.
      rewrite <- H1, <- Es, <- H0 in e.
      rewrite <- e in n.
      crush.
Qed.

(* If given key if in type signature it must have certain type.
   OK if it is not present *)
Definition TypeSig_MaybeMapsTo (k:nat) (t:DSHType) (tm:TypeSig): Prop :=
  match TM.find k tm with
  | Some t' => t = t'
  | None => True
  end.

Lemma typecheck_env_S (off:nat) (tm:TypeSig) (σ: evalContext)
  :
    forall v,
      TypeSig_MaybeMapsTo off (DSHValToType v) tm ->
      typecheck_env (S off) tm (σ) ->
      typecheck_env off tm (List.cons v σ).
Proof.
  intros v M T.

  unfold typecheck_env, typecheck_env_bool, for_all in *.

  setoid_rewrite <- T at 2. clear T.
  f_equal.
  extensionality k.
  extensionality e.
  extensionality b.

Admitted.


Lemma TypeSigIncluded_at (needle haystack:TypeSig):
  TypeSigIncluded needle haystack ->
  forall k v, TM.MapsTo k v needle -> TM.MapsTo k v haystack.
Proof.
  intros I k v M.
  unfold TypeSigIncluded, TypeSigIncluded_bool, TP.for_all in I.
Admitted.

Lemma MaybeMapsTo_Included (needle haystack:TypeSig):
  forall k t,
    TM.MapsTo k t haystack ->
    TypeSigIncluded needle haystack ->
    TypeSig_MaybeMapsTo k t needle.
Proof.
  intros k t M I.
  unfold TypeSig_MaybeMapsTo in *.
  break_match; try trivial.
  apply TM.find_2 in Heqo.
  apply TypeSigIncluded_at with (haystack:=haystack) in Heqo; [|auto].
  eapply TP.F.MapsTo_fun in Heqo; eauto.
Qed.

Lemma context_equiv_at_TypeSig_off_incr {dfs σ0 σ1 n}:
  context_equiv_at_TypeSig (TypeSig_incr_n dfs n) σ0 σ1 <->
  context_equiv_at_TypeSig_off dfs n σ0 σ1.
Proof.
Admitted.

Lemma context_equiv_at_TypeSig_split {σ0 σ1 σ0' σ1' tm}:
  context_equiv_at_TypeSig_off tm (length σ0') σ0 σ1 ->

  (length σ0' = length σ1') ->
  context_equiv_at_TypeSig_head tm (length σ0') σ0' σ1' ->

  context_equiv_at_TypeSig_off tm 0 (σ0' ++ σ0) (σ1' ++ σ1).
Proof.
  intros T L H.
  intros k t _ M.
  rewrite Nat.sub_0_r.
  unfold equiv, nat_equiv in L.
  destruct (lt_ge_dec k (length σ0')) as [kc|kc].
  -
    (* head *)
    clear T.
    specialize (H k t kc M).

    unfold contextEnsureType in *.
    unfold context_lookup in *.
    rewrite nth_app_left by assumption.
    rewrite nth_app_left by lia.
    auto.
  -
    (* tail *)
    clear H.
    specialize (T k t kc M).
    unfold contextEnsureType in *.
    unfold context_lookup in *.
    rewrite nth_app_right by assumption.
    rewrite nth_app_right by lia.
    rewrite L in T.
    rewrite L.
    auto.
Qed.
