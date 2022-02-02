Require Import Coq.Strings.String.
Require Import Coq.Lists.List.
Require Import Coq.Arith.Arith.
Require Import Coq.micromega.Lia.
Require Import Psatz.

Require Import CoLoR.Util.Nat.NatUtil.
Require Import CoLoR.Util.Relation.RelUtil.

Require Import Helix.HCOL.CarrierType.

Require Import Helix.MSigmaHCOL.Memory.
Require Import Helix.MSigmaHCOL.MemSetoid.
Require Import Helix.MSigmaHCOL.MSigmaHCOL.
Require Import Helix.MSigmaHCOL.MemoryOfR.
Require Import Helix.MSigmaHCOL.RasCarrierA.

Require Import Helix.DSigmaHCOL.DSigmaHCOL.
Require Import Helix.DSigmaHCOL.DSigmaHCOLEval.
Require Import Helix.RSigmaHCOL.RSigmaHCOL.

(* When proving concrete functions we need to use
   some implementation defs from this packages *)
Require Import Helix.HCOL.HCOL.
Require Import Helix.Util.VecUtil.
Require Import Helix.Util.FinNat.

Require Import Helix.Util.OptionSetoid.
Require Import Helix.Util.ErrorSetoid.
Require Import Helix.MSigmaHCOL.MemSetoid.
Require Import Helix.Tactics.HelixTactics.

Require Import ExtLib.Structures.Monads.
Require Import ExtLib.Data.Monads.OptionMonad.

Require Import MathClasses.misc.util.
Require Import MathClasses.misc.decision.
Require Import MathClasses.interfaces.canonical_names.
Require Import MathClasses.orders.minmax MathClasses.interfaces.orders.
Require Import MathClasses.implementations.peano_naturals.
Require Import MathClasses.orders.orders.

Import MonadNotation.
Import ListNotations.

Open Scope string_scope.
Open Scope list_scope.
Local Open Scope monad_scope.
Local Open Scope nat_scope.

Import RHCOL.

(* TODO: move *)
Section list_aux.

  Lemma nth_error_nil_None {A : Type} (n : nat) :
    List.nth_error [] n ≡ @None A.
  Proof.
    destruct n; reflexivity.
  Qed.
  
  Lemma List_nth_nth_error {A : Type} (l1 l2 : list A) (n : nat) (d : A) :
    List.nth_error l1 n ≡ List.nth_error l2 n ->
    List.nth n l1 d ≡ List.nth n l2 d.
  Proof.
    generalize dependent l2.
    generalize dependent l1.
    induction n.
    -
      intros.
      cbn in *.
      repeat break_match;
        try some_none; repeat some_inv.
      reflexivity.
      reflexivity.
    -
      intros.
      destruct l1, l2; cbn in *.
      +
        reflexivity.
      +
        specialize (IHn [] l2).
        rewrite nth_error_nil_None in IHn.
        specialize (IHn H).
        rewrite <-IHn.
        destruct n; reflexivity.
      +
        specialize (IHn l1 []).
        rewrite nth_error_nil_None in IHn.
        specialize (IHn H).
        rewrite IHn.
        destruct n; reflexivity.
      +
        apply IHn.
        assumption.
  Qed.

End list_aux.

(* TODO: move to Memory.v *)
(* problem: some of these depend on MemSetoid.v, which depends on Memory.v *)
Section mem_aux.

  Lemma mem_add_comm
        (k1 k2: NM.key)
        (v1 v2: CarrierA)
        (N: k1≢k2)
        (m: mem_block):
    mem_add k1 v1 (mem_add k2 v2 m) = mem_add k2 v2 (mem_add k1 v1 m).
  Proof.
    intros y.
    unfold mem_add.
    destruct (Nat.eq_dec y k1) as [K1| NK1].
    -
      subst.
      rewrite NP.F.add_eq_o by reflexivity.
      rewrite NP.F.add_neq_o by auto.
      symmetry.
      apply Option_equiv_eq.
      apply NP.F.add_eq_o.
      reflexivity.
    -
      rewrite NP.F.add_neq_o by auto.
      destruct (Nat.eq_dec y k2) as [K2| NK2].
      subst.
      rewrite NP.F.add_eq_o by reflexivity.
      rewrite NP.F.add_eq_o by reflexivity.
      reflexivity.
      rewrite NP.F.add_neq_o by auto.
      rewrite NP.F.add_neq_o by auto.
      rewrite NP.F.add_neq_o by auto.
      reflexivity.
  Qed.

  Lemma mem_add_overwrite
        (k : NM.key)
        (v1 v2 : CarrierA)
        (m : NM.t CarrierA) :
    mem_add k v2 (mem_add k v1 m) = mem_add k v2 m.
  Proof.
    intros.
    unfold mem_add, equiv, NM_Equiv.
    intros.
    destruct (Nat.eq_dec k k0).
    -
      repeat rewrite NP.F.add_eq_o by assumption.
      reflexivity.
    -
      repeat rewrite NP.F.add_neq_o by assumption.
      reflexivity.
  Qed.

  Lemma mem_block_to_avector_nth
        {n : nat}
        {mx : mem_block}
        {vx : vector CarrierA n}
        (E: mem_block_to_avector mx ≡ Some vx)
        {k: nat}
        {kc: (k < n)%nat}:
    mem_lookup k mx ≡ Some (Vnth vx kc).
  Proof.
    unfold mem_block_to_avector in E.
    apply vsequence_Vbuild_eq_Some in E.
    apply Vnth_arg_eq with (ip:=kc) in E.
    rewrite Vbuild_nth in E.
    rewrite Vnth_map in E.
    apply E.
  Qed.
  
  Lemma mem_op_of_hop_x_density
        {i o: nat}
        {op: vector CarrierA i -> vector CarrierA o}
        {x: mem_block}
    :
      is_Some (mem_op_of_hop op x) -> (forall k (kc:k<i), is_Some (mem_lookup k x)).
  Proof.
    intros H k kc.
    unfold mem_op_of_hop in H.
    break_match_hyp; try some_none.
    apply mem_block_to_avector_nth with (kc0:=kc) in Heqo0.
    apply eq_Some_is_Some in Heqo0.
    apply Heqo0.
  Qed.

  Global Instance mem_union_associative :
    Associative MMemoryOfR.mem_union.
  Proof.
    intros b1 b2 b3.
    unfold equiv, NM_Equiv, MMemoryOfR.mem_union.
    intro k.
    repeat rewrite NP.F.map2_1bis by reflexivity.
    repeat break_match; try some_none.
    reflexivity.
  Qed.

  Lemma mem_in_mem_lookup (k : NM.key) (mb : mem_block) :
    mem_in k mb <-> is_Some (mem_lookup k mb).
  Proof.
    unfold mem_in, mem_lookup.
    rewrite is_Some_ne_None, NP.F.in_find_iff.
    reflexivity.
  Qed.

  Definition mem_firstn (n : nat) (mb : mem_block) :=
    NP.filter_dom (elt:=CarrierA) (fun k => Nat.ltb k n) mb.
  
  Lemma mem_firstn_def (k n : nat) (mb : mem_block) (a : CarrierA) :
    mem_lookup k (mem_firstn n mb) = Some a <-> k < n /\ mem_lookup k mb = Some a.
  Proof.
    split; intros.
    -
      unfold mem_firstn, mem_lookup, NP.filter_dom in *.
      destruct NM.find eqn:F in H; try some_none; some_inv.
      apply NP.F.find_mapsto_iff, NP.filter_iff in F.
      2: intros k1 k2 EK a1 a2 EA; subst; reflexivity.
      destruct F.
      rewrite <-H; clear H.
      apply Nat.ltb_lt in H1.
      intuition.
      apply NM.find_1 in H0.
      rewrite H0; reflexivity.
    -
      unfold mem_firstn, mem_lookup, NP.filter_dom in *.
      destruct H as [H1 H2].
      destruct (NM.find (elt:=CarrierA) k
                        (NP.filter (λ (k0 : NM.key) (_ : CarrierA), k0 <? n) mb)) eqn:F.
      +
        apply NP.F.find_mapsto_iff, NP.filter_iff in F.
        2: intros k1 k2 EK a1 a2 EA; subst; reflexivity.
        destruct F.
        apply NM.find_1 in H.
        rewrite H in H2.
        assumption.
      +
        destruct NM.find eqn:H in H2; try some_none; some_inv.
        contradict F.
        apply is_Some_ne_None, is_Some_def.
        eexists.
        apply NP.F.find_mapsto_iff, NP.filter_iff.
        1: intros k1 k2 EK a1 a2 EA; subst; reflexivity.
        split.
        2: apply Nat.ltb_lt; assumption.
        instantiate (1:=c).
        apply NP.F.find_mapsto_iff.
        assumption.
  Qed.

  Lemma mem_firstn_def_eq (k n : nat) (mb : mem_block) (a : CarrierA) :
    mem_lookup k (mem_firstn n mb) ≡ Some a <-> k < n /\ mem_lookup k mb ≡ Some a.
  Proof.
    split; intros.
    -
      unfold mem_firstn, mem_lookup, NP.filter_dom in *.
      destruct NM.find eqn:F in H; try some_none; some_inv.
      apply NP.F.find_mapsto_iff, NP.filter_iff in F.
      2: intros k1 k2 EK a1 a2 EA; subst; reflexivity.
      destruct F.
      subst.
      apply Nat.ltb_lt in H0.
      intuition.
      apply NM.find_1.
      assumption.
    -
      unfold mem_firstn, mem_lookup, NP.filter_dom in *.
      destruct H as [H1 H2].
      destruct (NM.find (elt:=CarrierA) k
                        (NP.filter (λ (k0 : NM.key) (_ : CarrierA), k0 <? n) mb)) eqn:F.
      +
        apply NP.F.find_mapsto_iff, NP.filter_iff in F.
        2: intros k1 k2 EK a1 a2 EA; subst; reflexivity.
        destruct F.
        apply NM.find_1 in H.
        rewrite H in H2.
        assumption.
      +
        destruct NM.find eqn:H in H2; try some_none; some_inv.
        subst.
        contradict F.
        apply is_Some_ne_None, is_Some_def.
        eexists.
        apply NP.F.find_mapsto_iff, NP.filter_iff.
        1: intros k1 k2 EK a1 a2 EA; subst; reflexivity.
        split.
        2: apply Nat.ltb_lt; assumption.
        eapply NP.F.find_mapsto_iff.
        eassumption.
  Qed.
  
  Lemma mem_firstn_lookup (k n : nat) (mb : mem_block) :
    k < n ->
    mem_lookup k (mem_firstn n mb) ≡ mem_lookup k mb.
  Proof.
    intros.
    destruct (mem_lookup k mb) eqn:L.
    -
      rewrite mem_firstn_def_eq.
      auto.
    -
      apply is_None_def.
      enough (not (is_Some (mem_lookup k (mem_firstn n mb))))
        by (unfold is_None, is_Some in *; break_match; auto).
      intros C.
      apply is_Some_def in C.
      destruct C as [mb' MB].
      apply mem_firstn_def_eq in MB.
      destruct MB; some_none.
  Qed.
  
  Lemma mem_firstn_lookup_oob (k n : nat) (mb : mem_block) :
    n <= k ->
    mem_lookup k (mem_firstn n mb) ≡ None.
  Proof.
    intros.
    apply is_None_def.
    enough (not (is_Some (mem_lookup k (mem_firstn n mb))))
      by (unfold is_None, is_Some in *; break_match; auto).
    intros C.
    apply is_Some_def in C.
    destruct C as [mb' MB]; eq_to_equiv_hyp.
    apply mem_firstn_def in MB.
    lia.
  Qed.
  
  Lemma firstn_mem_const_block_union (o : nat) (init : CarrierA) (mb : mem_block) :
    mem_firstn o (mem_union (mem_const_block o init) mb) = mem_const_block o init.
  Proof.
    intros k.
    destruct (le_lt_dec o k).
    -
      rewrite mem_firstn_lookup_oob, mem_const_block_find_oob by assumption.
      reflexivity.
    -
      rewrite mem_firstn_lookup by assumption.
      unfold mem_union, mem_lookup.
      rewrite NP.F.map2_1bis by reflexivity.
      rewrite mem_const_block_find; auto.
  Qed.

  Lemma mem_not_in_mem_lookup (k : NM.key) (mb : mem_block) :
    not (mem_in k mb) <-> is_None (mem_lookup k mb).
  Proof.
    rewrite is_None_def.
    apply NP.F.not_find_in_iff.
  Qed.

End mem_aux.

Section memory_aux.

  (* [m_sub] ⊆ [m_sup] *)
  Definition memory_subset (m_sub m_sup : memory) :=
    forall k b, memory_mapsto m_sub k b -> memory_mapsto m_sup k b.

  (* Two memory locations equivalent on all addresses except one
     TODO: make `e` 1st parameter to make this relation.
   *)
  Definition memory_equiv_except (m m': memory) (e:nat)
    := forall k, k ≢ e -> memory_lookup m k = memory_lookup m' k.

  (* Relation between memory location defined as:
     1. All addresses except [e] from 1st memory must map to same memory blocks in the 2nd one.
     2. If 1st memory block has [e] initialized it also must be initialized in the 2nd one but not necessary with the same value.
   *)
  Definition memory_subset_except (e : nat) (m_sub m_sup : memory) :=
    forall k v,
      memory_lookup m_sub k = Some v ->
      exists v', (memory_lookup m_sup k = Some v' /\ (k ≢ e -> v = v')).

  Global Instance memory_subset_except_proper:
    Proper ((=) ==> (=) ==> (=) ==> (=)) memory_subset_except.
  Proof.
    intros e e' Ee m_sub m_sub' ESUB m_sup m_sup' ESUP.
    unfold equiv, NatAsNT.MNatAsNT.NTypeEquiv, nat_equiv in Ee.
    subst e'.
    unfold memory_subset_except.
    split; intros.
    -
      rewrite <- ESUB in H0.
      specialize (H k v H0).
      destruct H as [v' H].
      exists v'.
      rewrite <- ESUP.
      apply H.
    -
      rewrite ESUB in H0.
      specialize (H k v H0).
      destruct H as [v' H].
      exists v'.
      rewrite ESUP.
      apply H.
  Qed.

  Lemma memory_equiv_except_memory_set {m m' b k}:
    m' ≡ memory_set m k b -> memory_equiv_except m m' k.
  Proof.
    intros H.
    subst.
    intros k' kc.
    unfold memory_set.
    unfold memory_lookup.
    rewrite NP.F.add_neq_o.
    reflexivity.
    auto.
  Qed.

  Lemma memory_equiv_except_memory_set_inv {m m' b k}:
    memory_equiv_except m m' k ->
    memory_lookup m' k = Some b ->
    m' = memory_set m k b.
  Proof.
    intros EQ L.
    intro k'.
    unfold memory_set.
    destruct (Nat.eq_dec k k').
    -
      rewrite NP.F.add_eq_o by assumption.
      subst.
      apply L.
    -
      rewrite NP.F.add_neq_o by assumption.
      specialize (EQ k').
      autospecialize EQ; [congruence |].
      unfold memory_equiv_except, memory_lookup in EQ.
      now rewrite EQ.
  Qed.
  
  Lemma memory_equiv_except_trans {m m' m'' k}:
    memory_equiv_except m m' k ->
    memory_equiv_except m' m'' k ->
    memory_equiv_except m m'' k.
  Proof.
    intros H H0.
    intros k' kc.
    specialize (H0 k' kc).
    rewrite <- H0. clear H0.
    apply H.
    apply kc.
  Qed.

  Lemma memory_lookup_err_inr_is_Some {s : string} (m : memory) (mbi : nat) :
    forall mb, memory_lookup_err s m mbi ≡ inr mb → is_Some (memory_lookup m mbi).
  Proof.
    intros.
    unfold memory_lookup_err, trywith in H.
    break_match.
    reflexivity.
    inversion H.
  Qed.

  Lemma memory_subset_except_next_keys m_sub m_sup e:
    memory_subset_except e m_sub m_sup ->
    (memory_next_key m_sup) >= (memory_next_key m_sub).
  Proof.
    intros H.
    destruct (memory_next_key m_sub) eqn:E.
    -
      lia.
    -
      rename n into k.
      apply memory_next_key_S in E.
      apply memory_is_set_is_Some in E.
      apply util.is_Some_def in E.
      destruct E as [v E].
      specialize (H k).
      cut (memory_next_key m_sup > k).
      {
        clear.
        intros G.
        lia.
      }
      apply mem_block_exists_next_key_gt.
      destruct (Nat.eq_dec k e) as [EK|NEK].
      +
        (* excluded element *)
        subst.
        specialize (H v).
        eq_to_equiv_hyp.
        apply H in E.
        destruct E as [v' [E _]].
        apply mem_block_exists_exists_equiv.
        exists v'.
        apply E.
      +
        eq_to_equiv_hyp.
        specialize (H v E).
        destruct H as [v' [H  V]].
        apply mem_block_exists_exists_equiv.
        exists v'.
        apply H.
  Qed.

  Lemma memory_set_overwrite (m : memory) (k k' : nat) (mb mb' : mem_block) :
    k = k' ->
    memory_set (memory_set m k mb) k' mb' = memory_set m k' mb'.
  Proof.
    intros E; cbv in E; subst k'.
    unfold memory_set, equiv, NM_Equiv.
    intros j.
    destruct (Nat.eq_dec k j).
    -
      repeat rewrite NP.F.add_eq_o by assumption.
      reflexivity.
    -
      repeat rewrite NP.F.add_neq_o by assumption.
      reflexivity.
  Qed.
  
  Lemma memory_remove_memory_set_eq (m : memory) (k k' : nat) (mb : mem_block) :
    k = k' ->
    memory_remove (memory_set m k mb) k' = memory_remove m k.
  Proof.
    intros; cbv in H; subst k'.
    unfold memory_remove, memory_set, equiv, NM_Equiv.
    intros j.
    destruct (Nat.eq_dec k j).
    -
      repeat rewrite NP.F.remove_eq_o by assumption.
      reflexivity.
    -
      repeat rewrite NP.F.remove_neq_o by assumption.
      rewrite NP.F.add_neq_o by assumption.
      reflexivity.
  Qed.
  
  Lemma memory_remove_nonexistent_key (m : memory) (k : nat) :
    not (mem_block_exists k m) -> memory_remove m k = m.
  Proof.
    intros.
    unfold mem_block_exists, memory_remove in *.
    intros j.
    rewrite NP.F.remove_o.
    break_match; try reflexivity.
    subst.
    apply NP.F.not_find_in_iff in H.
    rewrite H.
    reflexivity.
  Qed.

  Lemma memory_lookup_memory_set_eq (m : memory) (k k' : nat) (mb : mem_block) :
    k = k' ->
    memory_lookup (memory_set m k mb) k' ≡ Some mb.
  Proof.
    intros.
    rewrite H; clear H.
    unfold memory_lookup, memory_set.
    rewrite NP.F.add_eq_o by reflexivity.
    reflexivity.
  Qed.
  
  Lemma memory_lookup_memory_set_neq (m : memory) (k k' : nat) (mb : mem_block) :
    k <> k' ->
    memory_lookup (memory_set m k mb) k' ≡ memory_lookup m k'.
  Proof.
    intros.
    unfold memory_lookup, memory_set.
    rewrite NP.F.add_neq_o by assumption.
    reflexivity.
  Qed.
  
  Lemma memory_lookup_memory_remove_eq (m : memory) (k k' : nat) :
    k = k' ->
    memory_lookup (memory_remove m k) k' = None.
  Proof.
    intros.
    rewrite <-H; clear H.
    unfold memory_lookup, memory_remove.
    rewrite NP.F.remove_eq_o; reflexivity.
  Qed.
  
  Lemma memory_lookup_memory_remove_neq (m : memory) (k k' : nat) :
    k <> k' ->
    memory_lookup (memory_remove m k) k' = memory_lookup m k'.
  Proof.
    intros.
    unfold memory_lookup, memory_remove.
    rewrite NP.F.remove_neq_o.
    reflexivity.
    assumption.
  Qed.

  Lemma memory_lookup_not_next_equiv (m : memory) (k : nat) (mb : mem_block) :
    memory_lookup m k = Some mb -> k <> memory_next_key m.
  Proof.
    intros S C.
    subst.
    pose proof memory_lookup_memory_next_key_is_None m.
    unfold is_None in H.
    break_match.
    trivial.
    some_none.
  Qed.
  
  Lemma memory_next_key_override (k : nat) (m : memory) (mb : mem_block) :
    mem_block_exists k m ->
    memory_next_key (memory_set m k mb) = memory_next_key m.
  Proof.
    intros H.
    apply memory_next_key_struct.
    intros k0.
    split; intros.
    -
      destruct (Nat.eq_dec k k0).
      +
        subst k0.
        assumption.
      +
        apply mem_block_exists_memory_set_neq in H0; auto.
    -
      apply mem_block_exists_memory_set.
      assumption.
  Qed.

  Lemma memory_set_same (m : memory) (k : nat) (mb : mem_block) :
    memory_lookup m k = Some mb ->
    memory_set m k mb = m.
  Proof.
    intros H k'.
    unfold memory_set, memory_lookup in *.
    destruct (Nat.eq_dec k k').
    -
      subst.
      rewrite NP.F.add_eq_o by congruence.
      auto.
    -
      rewrite NP.F.add_neq_o by congruence.
      reflexivity.
  Qed.

  Lemma memory_subset_except_transitive (k : nat) (m1 m2 m3 : memory) :
    memory_subset_except k m1 m2 ->
    memory_subset_except k m2 m3 ->
    memory_subset_except k m1 m3.
  Proof.
    unfold memory_subset_except.
    intros S12 S23 j v1 V1.
    specialize (S12 j v1 V1).
    destruct S12 as [v2 [V2 VE2]].
    specialize (S23 j v2 V2).
    destruct S23 as [v3 [V3 VE3]].
    exists v3.
    split; [assumption |].
    intros.
    rewrite VE2, VE3 by assumption.
    reflexivity.
  Qed.

End memory_aux.

Ltac eq_to_equiv := err_eq_to_equiv_hyp; eq_to_equiv_hyp.

Ltac simplify_memory_hyp :=
  match goal with
  | [ H : memory_lookup (memory_set _ _ _) _ = _ |- _ ] =>
    try rewrite memory_lookup_memory_set_neq in H by congruence;
    try rewrite memory_lookup_memory_set_eq in H by congruence
  | [H : memory_lookup (memory_remove _ _) _ = _ |- _ ] =>
    try rewrite memory_lookup_memory_remove_neq in H by congruence;
    try rewrite memory_lookup_memory_remove_eq in H by congruence
  | [H : memory_set (memory_set _ _ _) _ _ = _ |- _] =>
    try rewrite memory_set_overwrite in H by congruence
  | [H : memory_remove (memory_set _ _ _) _ = _ |- _] =>
    try rewrite memory_remove_memory_set_eq in H by congruence
  end.

(* Shows relations of cells before ([b]) and after ([a]) evaluating
   DSHCOL operator and a result of evaluating [mem_op] as [d] *)
Inductive MemOpDelta (b a d: option CarrierA) : Prop :=
| MemPreserved: is_None d -> b = a -> MemOpDelta b a d (* preserving memory state *)
| MemExpected: is_Some d -> a = d -> MemOpDelta b a d (* expected results *).

Global Instance MemOpDelta_proper:
  Proper ((=) ==> (=) ==> (=) ==> (iff)) MemOpDelta.
Proof.
  intros b b' Eb a a' Ea d d' Ed.
  split; intros H.
  -
    destruct H.
    +
      apply is_None_def in H.
      subst d.
      inversion_clear Ed.
      apply MemPreserved.
      *
        some_none.
      *
        rewrite <- Eb, <- Ea.
        assumption.
    +
      norm_some_none.
      subst d.
      rewrite Ea in H0. clear Ea a.
      dep_destruct d'; try some_none.
      apply MemExpected.
      *
        some_none.
      *
        rewrite H0.
        assumption.
  -
    destruct H.
    +
      apply is_None_def in H.
      subst d'.
      inversion_clear Ed.
      apply MemPreserved.
      *
        some_none.
      *
        rewrite Eb, Ea.
        assumption.
    +
      norm_some_none.
      subst d'.
      rewrite <-Ea in H0. clear Ea a'.
      dep_destruct d; try some_none.
      apply MemExpected.
      *
        some_none.
      *
        rewrite H0.
        symmetry.
        assumption.
Qed.

(* Shows relations of memory blocks before ([mb]) and after ([ma]) evaluating
   DSHCOL operator and a result of evaluating [mem_op] as [md] *)
Definition SHCOL_DSHCOL_mem_block_equiv (mb ma md: mem_block) : Prop :=
  forall i,
    MemOpDelta
      (mem_lookup i mb)
      (mem_lookup i ma)
      (mem_lookup i md).

Definition lookup_PExpr (σ:evalContext) (m:memory) (p:PExpr) :=
  '(a,_) <- evalPExpr σ p ;;
    memory_lookup_err "block_id not found" m a.

(* DSH expression as a "pure" function by enforcing the memory
   invariants guaranteeing that it does not free or allocate any blocks,
   modifies only the output memory block.

   It is assumed that the memory and envirnment are consistent and
   [PExp] successfuly resolve to valid memory locations for [x_p] and
   [y_p] which must be allocated.
 *)
Class DSH_pure
      (d: DSHOperator)
      (y_p: PExpr)
  := {

      (* does not free or allocate any memory *)
      mem_stable: forall σ m m' fuel,
        evalDSHOperator σ d m fuel = Some (inr m') ->
        forall k, mem_block_exists k m <-> mem_block_exists k m';

      (* modifies only [y_p], which must be valid in [σ] *)
      mem_write_safe: forall σ m m' fuel,
          evalDSHOperator σ d m fuel = Some (inr m') ->
          (forall y_i y_size , evalPExpr σ y_p = inr (y_i, y_size) ->
                          memory_equiv_except m m' y_i)
            (* NOTE: memory equaility may need to be constrained
               by [y_size] *)
    }.

(* TODO: move. Rename to [setoid_tuple_inversion]..? *)
Ltac tuple_inversion_equiv :=
  repeat match goal with
         | [ H : (_, _) = (_, _) |- _ ] =>
           let T1 := fresh in
           let T2 := fresh in
           inversion_clear H as [T1 T2];
           cbn [fst snd] in T1, T2
         end.

Ltac subst_nat :=
  repeat match goal with
         | [ H : @equiv nat _ ?n1 ?n2 |- _ ] => cbv in H; try subst n1; try subst n2
         | [ H : @equiv nat _ ?n1 ?n2 |- _ ] => cbv in H; try subst n1; try subst n2
         | [ H : @eq nat ?n1 ?n2 |- _ ] => try subst n1; try subst n2
         | [ H : @eq nat ?n1 ?n2 |- _ ] => try subst n1; try subst n2
         end.

Ltac minimize_eq :=
  repeat match goal with
         | [ H1 : ?A = ?x, H2 : ?A = ?y |- _] => rewrite H1 in H2;
                                               try some_inv; try inl_inr_inv
         end.

Definition lookup_PExpr_wsize (σ : evalContext) (m : memory) (p : PExpr) :=
  '(a, size) <- evalPExpr σ p ;;
  mb <- memory_lookup_err "block_id not found" m a ;;
  ret (mb, size).

Lemma lookup_PExpr_wsize_OK_no_size
      (σ : evalContext)
      (m : memory)
      (p : PExpr)
      (mb : mem_block)
      (sz : nat) :
  lookup_PExpr_wsize σ m p = inr (mb, sz) ->
  lookup_PExpr σ m p = inr mb.
Proof.
  intros.
  unfold lookup_PExpr, lookup_PExpr_wsize in *.
  cbn in *.
  repeat break_match; try inl_inr; inl_inr_inv.
  tuple_inversion_equiv.
  rewrite H0.
  reflexivity.
Qed.

Lemma lookup_PExpr_wsize_Err
      (σ : evalContext)
      (m : memory)
      (p : PExpr)
      (msg : string) :
  lookup_PExpr_wsize σ m p = inl msg ->
  lookup_PExpr σ m p = inl msg.
Proof.
  intros.
  unfold lookup_PExpr, lookup_PExpr_wsize in *.
  cbn in *.
  repeat break_match; try inl_inr; constructor.
Qed.
(* TODO: move stuff above. is DHS_pure right above this comment? *)

(** Given MSHCOL and DSHCOL operators are quivalent wrt [x_p] as
    the input memory block addres and [y_p] as the output.

    It is assumed that we know what memory blocks are used as input
    [x_p] and output [y_p], of the operator. They both must exist
    (be allocated) prior to execution.

    We do not require the input block to be structurally correct, because
    [mem_op] will just return an error in this case. *)
Class MSH_DSH_compat
      {i o: nat}
      (mop: @MSHOperator i o)
      (dop: DSHOperator)
      (σ: evalContext)
      (m: memory)
      (x_p y_p: PExpr)
      `{DSH_pure dop y_p}
  := {
      eval_equiv
      :
        forall (mx mb: mem_block),
          (lookup_PExpr_wsize σ m x_p = inr (mx, i)) (* input exists *) ->
          (lookup_PExpr_wsize σ m y_p = inr (mb, o)) (* output before *) ->

          (* [md] - memory diff *) 
          (* [m'] - memory state after execution *) 
          (h_opt_opterr_c
             (fun md m' => err_p (fun ma => SHCOL_DSHCOL_mem_block_equiv mb ma md)
                              (lookup_PExpr σ m' y_p))
             (mem_op mop mx)
             (evalDSHOperator σ dop m (estimateFuel dop)));
    }.

Section BinCarrierA.

  Class MSH_DSH_BinCarrierA_compat
        (f : CarrierA -> CarrierA -> CarrierA)
        (σ : evalContext)
        (df : AExpr)
        (mem : memory)
    :=
      {
        bin_equiv:
          forall a b, evalBinCType mem σ df a b = inr (f a b)
      }.

  Class MSH_DSH_IUnCarrierA_compat
        {o: nat}
        (f: {n:nat|n<o} -> CarrierA -> CarrierA)
        (σ: evalContext)
        (df : AExpr)
        (mem : memory)
    :=
      {
        iun_equiv:
          forall nc a, evalIUnCType mem σ df (proj1_sig nc) a = inr (f nc a)
      }.

  Class MSH_DSH_IBinCarrierA_compat
        {o: nat}
        (f: {n:nat|n<o} -> CarrierA -> CarrierA -> CarrierA)
        (σ: evalContext)
        (df : AExpr)
        (mem : memory)
    :=
      {
        ibin_equiv:
          forall nc a b, evalIBinCType mem σ df (proj1_sig nc) a b = inr (f nc a b)
      }.
  
  Lemma evalDSHIMap_mem_lookup_mx
        {n: nat}
        {df : AExpr}
        {σ : evalContext}
        {mem : memory}
        {mx mb ma : mem_block}
        (E: evalDSHIMap mem n df σ mx mb = inr ma)
        (k: nat)
        (kc:k<n):
    is_Some (mem_lookup k mx).
  Proof.
    apply inr_is_OK in E.
    revert mb E k kc.
    induction n; intros.
    -
      inversion kc.
    -
      destruct (Nat.eq_dec k n).
      +
        subst.
        cbn in *.
        unfold mem_lookup_err, trywith in *.
        repeat break_match_hyp; try inl_inr.
        split; reflexivity.
      +
        simpl in *.
        repeat break_match_hyp; try inl_inr.
        apply eq_inr_is_OK in Heqs. rename Heqs into H1.
        apply eq_inr_is_OK in Heqs0. rename Heqs0 into H2.
        apply IHn with (mb:=mem_add n c0 mb); clear IHn.
        *
          apply E.
        *
          lia.
  Qed.

  Lemma evalDSHBinOp_mem_lookup_mx
        {n off: nat}
        {df : AExpr}
        {σ : evalContext}
        {mem : memory}
        {mx mb ma : mem_block}
        (E: evalDSHBinOp mem n off df σ mx mb = inr ma)
        (k: nat)
        (kc:k<n):
    is_Some (mem_lookup k mx) /\ is_Some (mem_lookup (k+off) mx).
  Proof.
    apply inr_is_OK in E.
    revert mb E k kc.
    induction n; intros.
    -
      inversion kc.
    -
      destruct (Nat.eq_dec k n).
      +
        subst.
        cbn in *.
        unfold mem_lookup_err, trywith in *.
        repeat break_match_hyp; try inl_inr.
        split; reflexivity.
      +
        simpl in *.
        repeat break_match_hyp; try inl_inr.
        apply eq_inr_is_OK in Heqs. rename Heqs into H1.
        apply eq_inr_is_OK in Heqs0. rename Heqs0 into H2.
        clear Heqs1 c c0.
        apply IHn with (mb:=mem_add n c1 mb); clear IHn.
        *
          apply E.
        *
          lia.
  Qed.

  Fact evalDSHIMap_preservation
       {n k: nat}
       {kc: k>=n}
       {df : AExpr}
       {σ : evalContext}
       {mem : memory}
       {mx ma mb : mem_block}
       {c : CarrierA}:
    evalDSHIMap mem n df σ mx (mem_add k c mb) = inr ma
    → mem_lookup k ma = Some c.
  Proof.
    revert mb k kc.
    induction n; intros mb k kc E.
    -
      simpl in *.
      inl_inr_inv.
      unfold mem_lookup, mem_add in *.
      rewrite <- E.
      apply Option_equiv_eq.
      apply NP.F.add_eq_o.
      reflexivity.
    -
      simpl in E.
      repeat break_match_hyp; try inl_inr.
      apply IHn with (mb:=mem_add n c1 mb).
      lia.
      rewrite mem_add_comm by lia.
      apply E.
  Qed.

  Fact evalDSHBinOp_preservation
       {n off k: nat}
       {kc: k>=n}
       {df : AExpr}
       {σ : evalContext}
       {mem : memory}
       {mx ma mb : mem_block}
       {c : CarrierA}:
    evalDSHBinOp mem n off df σ mx (mem_add k c mb) = inr ma
    → mem_lookup k ma = Some c.
  Proof.
    revert mb k kc.
    induction n; intros mb k kc E.
    -
      simpl in *.
      inl_inr_inv.
      unfold mem_lookup, mem_add in *.
      rewrite <- E.
      apply Option_equiv_eq.
      apply NP.F.add_eq_o.
      reflexivity.
    -
      simpl in E.
      repeat break_match_hyp; try inl_inr.
      apply IHn with (mb:=mem_add n c2 mb).
      lia.
      rewrite mem_add_comm by lia.
      apply E.
  Qed.

  Lemma evalDSHIMap_nth
        {n: nat}
        {df : AExpr}
        {σ : evalContext}
        {mx mb ma : mem_block}
        (mem : memory)
        (k: nat)
        (kc: k<n)
        {a: CarrierA}:
    (mem_lookup k mx = Some a) ->
    (evalDSHIMap mem n df σ mx mb = inr ma) ->
    h_opt_err_c (=) (mem_lookup k ma) (evalIUnCType mem σ df k a).
  Proof.
    intros A E.
    revert mb a A E.
    induction n; intros.
    -
      inversion kc.
    -
      simpl in *.
      repeat break_match_hyp; try some_none; try inl_inr.
      destruct (Nat.eq_dec k n).
      +
        clear IHn.
        subst k.
        unfold mem_lookup_err, trywith in *.
        repeat break_match; try inl_inr.
        repeat some_inv; repeat inl_inr_inv; subst.
        eq_to_equiv_hyp.
        err_eq_to_equiv_hyp.
        rewrite A in *; clear A c.

        assert (mem_lookup n ma = Some c0).
        {
          eapply evalDSHIMap_preservation.
          eassumption.
          Unshelve.
          reflexivity.
        }
        rewrite Heqs0, H.
        constructor.
        reflexivity.
      +
        apply IHn with (mb:=mem_add n c0 mb); auto.
        lia.
  Qed.

  Lemma evalDSHBinOp_nth
        {n off: nat}
        {df : AExpr}
        {σ : evalContext}
        {mx mb ma : mem_block}
        (mem : memory)
        (k: nat)
        (kc: k<n)
        {a b : CarrierA}:
    (mem_lookup k mx = Some a) ->
    (mem_lookup (k + off) mx = Some b) ->
    (evalDSHBinOp mem n off df σ mx mb = inr ma) ->
    h_opt_err_c (=) (mem_lookup k ma) (evalIBinCType mem σ df k a b).
  Proof.
    intros A B E.
    revert mb a b A B E.
    induction n; intros.
    -
      inversion kc.
    -
      simpl in *.
      repeat break_match_hyp; try some_none; try inl_inr.
      destruct (Nat.eq_dec k n).
      +
        clear IHn.
        subst k.
        unfold mem_lookup_err, trywith in *.
        repeat break_match; try inl_inr.
        repeat some_inv; repeat inl_inr_inv; subst.
        eq_to_equiv_hyp.
        err_eq_to_equiv_hyp.
        rewrite A in *; clear A c.
        rewrite B in *; clear B c0.

        assert (mem_lookup n ma = Some c1).
        {
          eapply evalDSHBinOp_preservation.
          eassumption.
          Unshelve.
          reflexivity.
        }

        clear - Heqs1 H.
        rewrite Heqs1, H.
        constructor.
        reflexivity.
      +
        apply IHn with (mb:=mem_add n c1 mb); auto.
        lia.
  Qed.

  Lemma evalDSHIMap_oob_preservation
        {n: nat}
        {df : AExpr}
        {σ : evalContext}
        {mx mb ma : mem_block}
        (mem : memory)
        (ME: evalDSHIMap mem n df σ mx mb = inr ma):
    ∀ (k : NM.key) (kc:k>=n), mem_lookup k mb = mem_lookup k ma.
  Proof.
    intros k kc.
    revert mb ME.
    induction n; intros.
    -
      inversion kc; simpl in ME; inl_inr_inv; rewrite ME; reflexivity.
    -
      simpl in *.
      repeat break_match_hyp; try inl_inr.
      destruct (Nat.eq_dec k n).
      +
        apply IHn; lia.
      +
        replace (mem_lookup k mb) with
            (mem_lookup k (mem_add n c0 mb)).
        apply IHn. clear IHn.
        lia.
        apply ME.
        apply NP.F.add_neq_o.
        auto.
  Qed.

  Lemma evalDSHBinOp_oob_preservation
        {n off: nat}
        {df : AExpr}
        {σ : evalContext}
        {mx mb ma : mem_block}
        (mem : memory)
        (ME: evalDSHBinOp mem n off df σ mx mb = inr ma):
    ∀ (k : NM.key) (kc:k>=n), mem_lookup k mb = mem_lookup k ma.
  Proof.
    intros k kc.
    revert mb ME.
    induction n; intros.
    -
      inversion kc; simpl in ME; inl_inr_inv; rewrite ME; reflexivity.
    -
      simpl in *.
      repeat break_match_hyp; try inl_inr.
      destruct (Nat.eq_dec k n).
      +
        apply IHn; lia.
      +
        replace (mem_lookup k mb) with
            (mem_lookup k (mem_add n c1 mb)).
        apply IHn. clear IHn.
        lia.
        apply ME.
        apply NP.F.add_neq_o.
        auto.
  Qed.
  
  
  (* This is a generalized version of [evalDSHBinOp_nth]
     TODO: see if we can replace [evalDSHBinOp_nth] with it
     or at lease simplify its proof using this lemma.
  *)
  Lemma evalDSHBinOp_equiv_inr_spec
        {off n: nat}
        {df : AExpr}
        {σ : evalContext}
        {mem : memory}
        {mx mb ma : mem_block}:
    (evalDSHBinOp mem n off df σ mx mb = inr ma)
    ->
    (∀ k (kc: k < n),
        ∃ a b,
          (mem_lookup k mx = Some a /\
           mem_lookup (k+off) mx = Some b /\
           (exists c,
               mem_lookup k ma = Some c /\
               evalIBinCType mem σ df k a b = inr c))
    ).
  Proof.
    intros E k kc.
    pose proof (evalDSHBinOp_mem_lookup_mx E) as [A B] ; eauto.
    apply is_Some_equiv_def in A.
    destruct A as [a A].
    apply is_Some_equiv_def in B.
    destruct B as [b B].
    exists a.
    exists b.
    repeat split; auto.
  
    revert mb a b A B E.
    induction n; intros.
    -
      inversion kc.
    -
      simpl in *.
      repeat break_match_hyp; try some_none; try inl_inr.
      destruct (Nat.eq_dec k n).
      +
        clear IHn.
        subst k.
        unfold mem_lookup_err, trywith in *.
        repeat break_match; try inl_inr.
        repeat some_inv; repeat inl_inr_inv; subst.
        eq_to_equiv_hyp.
        err_eq_to_equiv_hyp.
        rewrite A in *; clear A c.
        rewrite B in *; clear B c0.
        exists c1.

        assert (mem_lookup n ma = Some c1).
        {
          eapply evalDSHBinOp_preservation.
          eassumption.
          Unshelve.
          reflexivity.
        }

        rewrite Heqs1, H.
        split; reflexivity.
      +
        apply IHn with (mb:=mem_add n c1 mb); auto.
        lia.
  Qed.

  (* TODO: generalize this (looks like Proper) *)
  Lemma is_OK_evalDSHIMap_mem_equiv
        (n: nat)
        (df : AExpr)
        (σ : evalContext)
        (mem : memory)
        (mx ma mb : mem_block) :
    ma = mb ->
    is_OK (evalDSHIMap mem n df σ mx ma) <->
    is_OK (evalDSHIMap mem n df σ mx mb).
  Proof.
    intros.
    pose proof evalDSHIMap_proper mem n df σ mx mx.
    unfold Proper, respectful in H0.
    assert (T : mx = mx) by reflexivity;
      specialize (H0 T ma mb H); clear T.
    unfold is_Some.
    repeat break_match; try reflexivity; inversion H0.
    split; constructor.
    split; intros C; inversion C.
  Qed.
  
  (* TODO: generalize this (looks like Proper) *)
  Lemma is_OK_evalDSHBinOp_mem_equiv
        (n off : nat)
        (df : AExpr)
        (σ : evalContext)
        (mem : memory)
        (mx ma mb : mem_block) :
    ma = mb ->
    is_OK (evalDSHBinOp mem n off df σ mx ma) <->
    is_OK (evalDSHBinOp mem n off df σ mx mb).
  Proof.
    intros.
    pose proof evalDSHBinOp_proper mem n off df σ mx mx.
    unfold Proper, respectful in H0.
    assert (T : mx = mx) by reflexivity;
      specialize (H0 T ma mb H); clear T.
    unfold is_Some.
    repeat break_match; try reflexivity; inversion H0.
    split; constructor.
    split; intros C; inversion C.
  Qed.

  Lemma is_OK_evalDSHIMap_mem_add
        (n : nat)
        (df : AExpr)
        (mem : memory)
        (σ : evalContext)
        (mx mb : mem_block)
        (k : NM.key)
        (v : CarrierA) :
    is_OK (evalDSHIMap mem n df σ mx (mem_add k v mb)) <->
    is_OK (evalDSHIMap mem n df σ mx mb).
  Proof.
    dependent induction n; [split; constructor |].
    cbn.
    repeat break_match; try reflexivity.
    destruct (Nat.eq_dec n k).
    -
      subst.
      apply is_OK_evalDSHIMap_mem_equiv.
      apply mem_add_overwrite.
    -
      rewrite is_OK_evalDSHIMap_mem_equiv
        with (ma := mem_add n c0 (mem_add k v mb)).
      apply IHn.
      apply mem_add_comm.
      assumption.
  Qed.

  Lemma is_OK_evalDSHBinOp_mem_add
        (n off : nat)
        (df : AExpr)
        (mem : memory)
        (σ : evalContext)
        (mx mb : mem_block)
        (k : NM.key)
        (v : CarrierA) :
    is_OK (evalDSHBinOp mem n off df σ mx (mem_add k v mb)) <->
    is_OK (evalDSHBinOp mem n off df σ mx mb).
  Proof.
    dependent induction n; [split; constructor |].
    cbn.
    repeat break_match; try reflexivity.
    destruct (Nat.eq_dec n k).
    -
      subst.
      apply is_OK_evalDSHBinOp_mem_equiv.
      apply mem_add_overwrite.
    -
      rewrite is_OK_evalDSHBinOp_mem_equiv
        with (ma := mem_add n c1 (mem_add k v mb))
             (mb := mem_add k v (mem_add n c1 mb)).
      apply IHn.
      apply mem_add_comm.
      assumption.
  Qed.

  Lemma evalNExpr_cons_CTypeVal
        (a b : CarrierA)
        (σ1 σ2 : evalContext)
        (n : NExpr)
        {f}
    :
    (forall n', evalNExpr σ1 n' = evalNExpr σ2 n') ->
    evalNExpr ((DSHCTypeVal a,f) :: σ1) n = evalNExpr ((DSHCTypeVal b,f) :: σ2) n.
  Proof.
    intros.
    induction n.

    (* base case 1 *)
    destruct v; [constructor |].
    specialize (H (NVar v)).
    cbn in *.
    unfold context_lookup in *.
    repeat rewrite ListUtil.nth_error_Sn.
    assumption.

    (* base case 2 *)
    reflexivity.

    (* inductive cases *)
    all: cbn.
    all: destruct (evalNExpr ((DSHCTypeVal a,f) :: σ1) n1),
                  (evalNExpr ((DSHCTypeVal a,f) :: σ1) n2),
                  (evalNExpr ((DSHCTypeVal b,f) :: σ2) n1),
                  (evalNExpr ((DSHCTypeVal b,f) :: σ2) n2); try inl_inr; try constructor.
    all: repeat inl_inr_inv; cbv in IHn1, IHn2; subst.
    all: try reflexivity.
    all: break_match; constructor.
  Qed.

  (* TODO: move somewhere *)
  Global Instance prod_Equivalence
         `{Ae:Equiv A}
         `{Aeq:Equivalence A Ae}
         `{Be: Equiv B}
         `{Beq:Equivalence B Be}:
    Equivalence (@products.prod_equiv _ Ae _ Be).
  Proof.
    split.
    -
      intros (a,b); constructor; auto.
    -
      intros (a0,b0) (a1,b1) E.
      inv E.
      constructor; auto.
    -
      intros (a0,b0) (a1,b1) (a2,b2) E0 E1.
      inv E0.
      inv E1.
      constructor; auto.
  Qed.

  Lemma evalMExpr_cons_CTypeVal
        (a b : CarrierA)
        (σ1 σ2 : evalContext)
        (mem: memory)
        (m : MExpr)
        {f}
    :
    (forall m', evalMExpr mem σ1 m' = evalMExpr mem σ2 m') ->
    evalMExpr mem ((DSHCTypeVal a,f) :: σ1) m = evalMExpr mem ((DSHCTypeVal b,f) :: σ2) m.
  Proof.
    intros.
    destruct m as [[v] | t] ; [| reflexivity].
    destruct v; [reflexivity |].
    cbn.
    specialize (H (MPtrDeref (PVar v))).
    apply H.
  Qed.
      
  Lemma evalIUnCarrierA_value_independent
        (mem : memory)
        (σ : evalContext)
        (df : AExpr)
        (n : nat) :
    (exists a, is_OK (evalIUnCType mem σ df n a)) ->
    forall b, is_OK (evalIUnCType mem σ df n b).
  Proof.
    intros.
    destruct H as [a H].
    induction df; cbn in *.

    (* base case 1 *)
    {
      destruct v.
      constructor.
      apply H.
    }

    (* base case 2 *)
    trivial.

    (* base case 3 *)
    {
      repeat break_match; try some_none; try inl_inr.
      -
        enough (inl s = inr n1) by inl_inr.
        rewrite <-Heqs0, <-Heqs; clear.
        apply evalNExpr_cons_CTypeVal.
        reflexivity.
      -
        enough (inl s = inr (m0, n3)) by inl_inr.
        rewrite <-Heqs0, <-Heqs2; clear.
        apply evalMExpr_cons_CTypeVal.
        reflexivity.
      -
        unfold NatAsNT.MNatAsNT.to_nat in *.
        eq_to_equiv.
        erewrite evalNExpr_cons_CTypeVal in Heqs by reflexivity.
        rewrite Heqs in Heqs2.
        erewrite evalMExpr_cons_CTypeVal in Heqs3 by reflexivity.
        rewrite Heqs0 in Heqs3.
        repeat inl_inr_inv.
        inversion Heqs3; cbv in H1; subst.
        cbv in Heqs2; subst.
        inl_inr.
      -
        subst.
        unfold NatAsNT.MNatAsNT.to_nat in *.
        eq_to_equiv.
        erewrite evalNExpr_cons_CTypeVal in Heqs by reflexivity.
        rewrite Heqs in Heqs2.
        erewrite evalMExpr_cons_CTypeVal in Heqs3 by reflexivity.
        rewrite Heqs0 in Heqs3.
        repeat inl_inr_inv.
        cbv in Heqs2; subst.
        inversion Heqs3.
        cbv in H1; subst.
        cbn in H0.
        clear - H H0.
        inversion H; clear H.
        err_eq_to_equiv_hyp.
        rewrite <-H0 in H2.
        destruct mem_lookup_err; try inl_inr; try constructor.
    }


    (* inductive cases *)
    all: unfold evalIUnCType in *.
    all: repeat break_match; try reflexivity; try some_none; try inl_inr.
    all: try apply IHdf; try apply IHdf1; try apply IHdf2.
    all: constructor.
  Qed.

  Lemma evalIBinCarrierA_value_independent
        (mem : memory)
        (σ : evalContext)
        (df : AExpr)
        (n : nat) :
    (exists a b, is_OK (evalIBinCType mem σ df n a b)) ->
    forall c d, is_OK (evalIBinCType mem σ df n c d).
  Proof.
    intros.
    destruct H as [a [b H]].
    induction df; cbn in *.
    
    (* base case 1 *)
    {
      destruct v.
      constructor.
      destruct v.
      constructor.
      apply H.
    }
    
    (* base case 2 *)
    trivial.
    
    (* base case 3 *)
    {
      repeat break_match; try some_none; try inl_inr.
      -
        enough (inl s = inr n1) by inl_inr.
        rewrite <-Heqs0, <-Heqs; clear.
        apply evalNExpr_cons_CTypeVal; intro.
        apply evalNExpr_cons_CTypeVal.
        reflexivity.
      - 
        enough (inl s = inr (m0, n3)) by inl_inr.
        rewrite <-Heqs0, <-Heqs2; clear.
        apply evalMExpr_cons_CTypeVal; intro.
        apply evalMExpr_cons_CTypeVal.
        reflexivity.
      - 
        unfold NatAsNT.MNatAsNT.to_nat in *.
        eq_to_equiv.

        assert (n1 = n3).
        {
          enough (inr n1 = inr n3) by (inl_inr_inv; assumption).
          rewrite <-Heqs, <-Heqs2; clear.
          apply evalNExpr_cons_CTypeVal; intro.
          apply evalNExpr_cons_CTypeVal.
          reflexivity.
        }

        assert (n2 = n4).
        {
          enough (E : inr (m0, n2) = inr (m1, n4)) by (inl_inr_inv; inversion E; assumption).
          rewrite <-Heqs0, <-Heqs3; clear.
          apply evalMExpr_cons_CTypeVal; intro.
          apply evalMExpr_cons_CTypeVal.
          reflexivity.
        }
        cbv in H0, H1; subst.
        inl_inr.
      - 
        unfold NatAsNT.MNatAsNT.to_nat in *.
        eq_to_equiv.

        assert (n1 = n3).
        {
          enough (inr n1 = inr n3) by (inl_inr_inv; assumption).
          rewrite <-Heqs, <-Heqs2; clear.
          apply evalNExpr_cons_CTypeVal; intro.
          apply evalNExpr_cons_CTypeVal.
          reflexivity.
        }

        assert (m0 = m1).
        {
          enough (E : inr (m0, n2) = inr (m1, n4)) by (inl_inr_inv; inversion E; assumption).
          rewrite <-Heqs0, <-Heqs3; clear.
          apply evalMExpr_cons_CTypeVal; intro.
          apply evalMExpr_cons_CTypeVal.
          reflexivity.
        }
        cbv in H0; subst.
        clear - H H1.
        inversion H; clear H.
        err_eq_to_equiv_hyp.
        rewrite <-H1 in H2.
        destruct mem_lookup_err; try inl_inr; try constructor.
    }
    
    (* inductive cases *)
    all: unfold evalIBinCType in *.
    all: repeat break_match; try reflexivity; try some_none; try inl_inr.
    all: try apply IHdf; try apply IHdf1; try apply IHdf2.
    all: constructor.
  Qed.

  Lemma evalDSHIMap_is_OK_inv
        {mem : memory}
        {n: nat}
        {df : AExpr}
        {σ : evalContext}
        {mx mb: mem_block}:
    (∀ k (kc: k < n),
        ∃ a, (mem_lookup k mx = Some a /\
              is_OK (evalIUnCType mem σ df k a)))
    -> (is_OK (evalDSHIMap mem n df σ mx mb)).
  Proof.
    intros H.
    induction n; [constructor |].
    simpl.
    repeat break_match.
    1-2: exfalso.
    -
      assert (T : n < S n) by lia.
      specialize (H n T).
      destruct H as [a [L1 S]].
      unfold mem_lookup_err, trywith in Heqs.
      break_match; try inversion Heqs; try some_none.
    -
      err_eq_to_equiv_hyp.
      contradict Heqs0.
      assert (T : n < S n) by lia.
      specialize (H n T).
      apply is_OK_neq_inl.
      apply evalIUnCarrierA_value_independent.
      destruct H as [a H].
      exists a.
      apply H.
    -
      rewrite is_OK_evalDSHIMap_mem_add.
      apply IHn.
      intros.
      apply H.
      lia.
  Qed.

  Lemma evalDSHBinOp_is_OK_inv
        {mem : memory}
        {off n: nat}
        {df : AExpr}
        {σ : evalContext}
        {mx mb: mem_block}:
    (∀ k (kc: k < n),
        ∃ a b,
          (mem_lookup k mx = Some a /\
           mem_lookup (k+off) mx = Some b /\
           is_OK (evalIBinCType mem σ df k a b)
          )
    ) -> (is_OK (evalDSHBinOp mem n off df σ mx mb)).
  Proof.
    intros H.
    induction n; [constructor |].
    simpl.
    repeat break_match.
    1-3: exfalso.
    -
      assert (T : n < S n) by lia.
      specialize (H n T).
      destruct H as [a [b [L1 [L2 S]]]].
      unfold mem_lookup_err, trywith in Heqs.
      break_match; try inversion Heqs; try some_none.
    -
      assert (T : n < S n) by lia.
      specialize (H n T).
      destruct H as [a [b [L1 [L2 S]]]].
      unfold mem_lookup_err, trywith in Heqs0.
      break_match; try inversion Heqs0; try some_none.
    -
      err_eq_to_equiv_hyp.
      contradict Heqs1.
      assert (T : n < S n) by lia.
      specialize (H n T).
      apply is_OK_neq_inl.
      apply evalIBinCarrierA_value_independent.
      destruct H as [a [b H]].
      exists a, b.
      apply H.
    -
      rewrite is_OK_evalDSHBinOp_mem_add.
      apply IHn.
      intros.
      apply H.
      lia.
  Qed.

  Lemma evalDSHIMap_is_Err
        (mem : memory)
        (n: nat)
        (nz: n≢0)
        (df : AExpr)
        (σ : evalContext)
        (mx mb : mem_block):
    (exists k (kc:k<n), is_None (mem_lookup k mx))
    ->
    is_Err (evalDSHIMap mem n df σ mx mb).
  Proof.
    revert mb.
    induction n; intros mb DX.
    +
      lia.
    +
      destruct DX as [k [kc DX]].
      destruct (Nat.eq_dec k n).
      *
        clear IHn.
        subst k.
        simpl.
        repeat break_match; try constructor.
        unfold is_None in DX.
        break_match; inversion DX.
        unfold mem_lookup_err in Heqs, Heqs0.
        try rewrite Heqo in Heqs; try rewrite Heqo in Heqs0.
        cbn in *; inl_inr.
      *
        simpl.
        repeat break_match; try constructor.
        apply IHn.
        lia.
        exists k.
        assert(k < n) as kc1 by lia.
        exists kc1.
        apply DX.
  Qed.

  Lemma evalDSHBinOp_is_Err
        (mem : memory)
        (off n: nat)
        (nz: n≢0)
        (df : AExpr)
        (σ : evalContext)
        (mx mb : mem_block):
    (exists k (kc:k<n),
        is_None (mem_lookup k mx) \/ is_None (mem_lookup (k+off) mx))
    ->
    is_Err (evalDSHBinOp mem n off df σ mx mb).
  Proof.
    revert mb.
    induction n; intros mb DX.
    +
      lia.
    +
      destruct DX as [k [kc DX]].
      destruct (Nat.eq_dec k n).
      *
        clear IHn.
        subst k.
        simpl.
        repeat break_match; try constructor.
        destruct DX.
        all: unfold is_None in H.
        all: break_match; inversion H.
        all: unfold mem_lookup_err in Heqs, Heqs0.
        all: try rewrite Heqo in Heqs; try rewrite Heqo in Heqs0.
        all: cbn in *; inl_inr.
      *
        simpl.
        repeat break_match; try constructor.
        apply IHn.
        lia.
        exists k.
        assert(k < n) as kc1 by lia.
        exists kc1.
        apply DX.
  Qed.
  
End BinCarrierA.

Lemma SHCOL_DSHCOL_mem_block_equiv_comp (m0 m1 m2 d01 d12 : mem_block) :
  SHCOL_DSHCOL_mem_block_equiv m0 m1 d01 →
  SHCOL_DSHCOL_mem_block_equiv m1 m2 d12 →
  SHCOL_DSHCOL_mem_block_equiv m0 m2 (MMemoryOfR.mem_union d12 d01).
Proof.
  intros D01' D12'.
  unfold SHCOL_DSHCOL_mem_block_equiv in *.
  intro k.
  specialize (D01' k); specialize (D12' k).
  unfold mem_lookup, MMemoryOfR.mem_union in *.
  rewrite NP.F.map2_1bis by reflexivity.
  inversion_clear D01' as [D01 E01| D01 E01];
  inversion_clear D12' as [D12 E12| D12 E12].
  all: try apply is_None_def in D01.
  all: try apply is_None_def in D12.
  all: try apply is_Some_def in D01.
  all: try apply is_Some_def in D12.
  -
    constructor 1.
    rewrite D01, D12; reflexivity.
    rewrite E01, E12; reflexivity.
  -
    destruct D12 as [x D12].
    constructor 2.
    rewrite D01, D12; reflexivity.
    rewrite E12, D12; reflexivity.
  -
    destruct D01 as [x D01].
    constructor 2.
    rewrite D12, D01; reflexivity.
    rewrite D12, <-E01, E12; reflexivity.
  -
    destruct D01 as [x1 D01].
    destruct D12 as [x2 D12].
    constructor 2.
    rewrite D12; reflexivity.
    rewrite D12, E12, D12; reflexivity.
Qed.

Instance lookup_PExpr_proper :
  Proper ((=) ==> (=) ==> (=) ==> (=)) lookup_PExpr.
Proof.
  intros σ σ' Σ m m' M p p' P.
  unfold lookup_PExpr, memory_lookup_err, trywith.
  cbn.
  repeat break_match.
  all: eq_to_equiv_hyp; err_eq_to_equiv_hyp.
  all: try rewrite Σ in *.
  all: try rewrite M in *.
  all: try rewrite P in *.
  all: try constructor.
  all: rewrite Heqs in *.
  all: try inl_inr; inl_inr_inv.
  all: rewrite Heqs0 in *.
  all: try rewrite Heqo in *.
  all: inversion Heqo0.

  -
    apply Some_inj_equiv.
    inversion_clear Heqs0.
    cbn in *.
    rewrite <- Heqo0, <- Heqo.
    rewrite H2.
    reflexivity.
  -
    exfalso.
    inversion_clear Heqs0.
    cbn in *.
    rewrite H in Heqo.
    some_none.
  -
    exfalso.
    inversion_clear Heqs0.
    cbn in *.
    rewrite <- H2 in Heqo0.
    some_none.
Qed.

Lemma lookup_PExpr_wsize_incrPVar (foo : DSHVal) (σ : evalContext) (m : memory) (p : PExpr) {f} :
  lookup_PExpr_wsize ((foo,f) :: σ) m (incrPVar 0 p) ≡
  lookup_PExpr_wsize σ m p.
Proof.
  unfold lookup_PExpr_wsize.
  rewrite evalPExpr_incrPVar.
  reflexivity.
Qed.

Lemma lookup_PExpr_incrPVar (foo : DSHVal) (σ : evalContext) (m : memory) (p : PExpr) {f}:
  lookup_PExpr ((foo,f) :: σ) m (incrPVar 0 p) ≡
  lookup_PExpr σ m p.
Proof.
  unfold lookup_PExpr.
  rewrite evalPExpr_incrPVar.
  reflexivity.
Qed.

Lemma lookup_PExpr_eval_lookup (σ : evalContext) (m : memory) (x : PExpr) (mb : mem_block) :
  lookup_PExpr σ m x = inr mb ->
  exists x_id x_size, evalPExpr σ x = inr (x_id,x_size) /\ memory_lookup m x_id = Some mb.
Proof.
  intros.
  unfold lookup_PExpr, memory_lookup_err, trywith in H.
  cbn in *.
  repeat break_match; try inl_inr; inl_inr_inv.
  exists n.
  exists n0.
  intuition.
  rewrite Heqo, H.
  reflexivity.
Qed.

Instance SHCOL_DSHCOL_mem_block_equiv_proper :
  Proper ((=) ==> (=) ==> (=) ==> iff) SHCOL_DSHCOL_mem_block_equiv.
Proof.
  intros mb mb' MBE ma ma' MAE md md' MDE.
  unfold SHCOL_DSHCOL_mem_block_equiv.
  split; intros.
  all: specialize (H i).
  -
    rewrite MBE, MAE, MDE in H.
    assumption.
  -
    rewrite <-MBE, <-MAE, <-MDE in H.
    assumption.
Qed.

Instance SHCOL_DSHCOL_mem_block_equiv_err_p_proper {mb md} :
  Proper ((=) ==> iff) (err_p (λ ma : mem_block, SHCOL_DSHCOL_mem_block_equiv mb ma md)).
Proof.
  intros.
  intros m1 m2 ME.
  destruct m1, m2; try inl_inr; repeat inl_inr_inv.
  all: split; intros C; inversion C; subst.
  all: constructor.
  rewrite <-ME; assumption.
  rewrite ME; assumption.
Qed.

Instance MSH_DSH_compat_R_proper {σ : evalContext} {mb : mem_block} {y_p : PExpr} :
  Proper ((=) ==> (=) ==> iff)
             (fun md m' => err_p (fun ma => SHCOL_DSHCOL_mem_block_equiv mb ma md)
                              (lookup_PExpr σ m' y_p)).
Proof.
  intros md1 md2 MDE m1' m2' ME.
  split; intros.
  -
    inversion H; clear H.
    eq_to_equiv.
    rewrite ME in H0.
    rewrite <-H0.
    constructor.
    rewrite <-MDE.
    assumption.
  -
    inversion H; clear H.
    eq_to_equiv.
    rewrite <-ME in H0.
    rewrite <-H0.
    constructor.
    rewrite MDE.
    assumption.
Qed.

Lemma SHCOL_DSHCOL_mem_block_equiv_mem_empty {a b: mem_block}:
  SHCOL_DSHCOL_mem_block_equiv mem_empty a b <-> a = b.
Proof.
  split.
  -
    intros H.
    unfold SHCOL_DSHCOL_mem_block_equiv in H.
    intros k.
    specialize (H k).
    unfold mem_lookup, mem_empty in H.
    rewrite NP.F.empty_o in H.
    inversion H.
    +
      rewrite <- H1.
      apply is_None_def in H0.
      rewrite H0.
      reflexivity.
    +
      assumption.
  -
    intros.
    rewrite H.
    intros k.
    destruct (mem_lookup k b).
    constructor 2; reflexivity.
    constructor 1; reflexivity.
Qed.

Lemma estimateFuel_positive (dop : DSHOperator) :
  1 <= estimateFuel dop.
Proof.
  induction dop.
  all: try (cbn; constructor; fail).
  all: cbn; lia.
Qed.

(* TODO: move *)
Definition evalPExpr_id (σ : evalContext) (exp : PExpr) :=
  '(id, size) <- evalPExpr σ exp ;;
  ret id.

(** * MSHEmbed, MSHPick **)

Global Instance Assign_DSH_pure
       {x_n y_n : NExpr}
       {x_p y_p : PExpr}
  :
    DSH_pure (DSHAssign (x_p, x_n) (y_p, y_n)) y_p.
Proof.
  split.
  -
    intros.
    destruct fuel; [inversion H |].
    cbn in H.
    repeat break_match; repeat some_inv; try inl_inr.
    inl_inr_inv; rewrite <-H.
    split; intros.
    +
      apply mem_block_exists_memory_set; assumption.
    +
      apply mem_block_exists_memory_set_inv in H0.
      destruct H0; [assumption |].
      subst.
      apply memory_is_set_is_Some.
      apply memory_lookup_err_inr_is_Some in Heqs2.
      assumption.
  -
    intros.
    unfold memory_equiv_except, memory_lookup; intros.
    destruct fuel; [inversion H |].
    cbn in H.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    unfold equiv, NM_Equiv, memory_set, mem_add in H.
    specialize (H k).
    rewrite <-H.
    destruct (Nat.eq_dec n1 k), (Nat.eq_dec n4 k);
        try (rewrite NP.F.add_eq_o with (x := n1) by assumption);
        try (rewrite NP.F.add_eq_o with (x := n4) by assumption);
        try (rewrite NP.F.add_neq_o with (x := n1) by assumption);
        try (rewrite NP.F.add_neq_o with (x := n4) by assumption).
    all: subst.
    all: try congruence.
    all: try reflexivity.

    +
      inversion_clear H0.
      cbn in H2, H3.
      congruence.
    +
      inversion_clear H0.
      cbn in H2, H3.
      congruence.
Qed.

Global Instance Embed_MSH_DSH_compat
       {o b: nat}
       {bc: b < o}
       {σ: evalContext}
       {y_n : NExpr}
       {x_p y_p : PExpr}
       {m : memory}
       (Y: evalNExpr σ y_n = inr b)
       (BP : DSH_pure (DSHAssign (x_p, NConst 0) (y_p, y_n)) y_p)
  :
    @MSH_DSH_compat _ _ (MSHEmbed bc) (DSHAssign (x_p, NConst 0) (y_p, y_n)) σ m x_p y_p BP.
Proof.
  constructor; intros mx mb MX MB.
  destruct mem_op as [md |] eqn:MD, evalDSHOperator as [fma |] eqn:FMA; try constructor.
  2: exfalso.
  all: unfold lookup_PExpr in MX, MB.
  all: cbn in *.
  all: destruct evalPExpr eqn:XP in MX; try some_none; try inl_inr; rewrite XP in *.
  all: destruct evalPExpr eqn:YP in MB; try some_none; try inl_inr; rewrite YP in *.
  all: unfold Embed_mem,
              map_mem_block_elt,
              MMemoryOfR.mem_lookup,
              MMemoryOfR.mem_add,
              MMemoryOfR.mem_empty
         in MD.
  all: unfold memory_lookup_err, trywith in *.
  all: repeat break_match;
    try some_none; repeat some_inv;
    try inl_inr; repeat inl_inr_inv.
  all: inversion_clear MX; inversion_clear MB; cbn in *.
  all: cbn in *; subst.
  -
    cbv in H6, H8, Y; subst.
    exfalso; clear - bc Heqs2.
    unfold assert_NT_lt, NatAsNT.MNatAsNT.to_nat in Heqs2.
    apply Nat.ltb_lt in bc.
    rewrite bc in Heqs2.
    inversion Heqs2.
  -
    cbv in H6, H8; subst n2 o.
    exfalso.
    unfold mem_lookup_err, trywith in *.
    break_match; try inl_inr.
    enough (None = Some c) by some_none.
    unfold CarrierA, CarrierDefs_R in *.
    rewrite <-Heqo2, <-Heqo.
    unfold mem_lookup.
    rewrite H.
    reflexivity.
  -
    repeat constructor.
    inversion Y; subst; clear Y.
    unfold SHCOL_DSHCOL_mem_block_equiv,
      memory_lookup, memory_set, mem_add, mem_lookup.
    rewrite NP.F.add_eq_o by reflexivity.
    constructor.
    intros.
    destruct (Nat.eq_dec b i);
      [ repeat rewrite NP.F.add_eq_o by assumption
      | repeat rewrite NP.F.add_neq_o by assumption ].
    +
      constructor 2; [reflexivity |].
      eq_to_equiv.
      mem_lookup_err_to_option.
      rewrite <-Heqo2, <-Heqs3.
      rewrite H.
      reflexivity.
    +
      constructor 1; [reflexivity |].
      rewrite H7.
      reflexivity.
  -
    constructor.
  -
    constructor.
  -
    exfalso.
    mem_lookup_err_to_option.
    enough (Some c = None) by some_none.
    unfold CarrierA, CarrierDefs_R in *.
    rewrite <-Heqo2, <-Heqs3.
    rewrite H.
    reflexivity.
Qed.

Global Instance Pick_MSH_DSH_compat
       {i b: nat}
       {bc: b < i}
       {σ: evalContext}
       {x_n : NExpr}
       {x_p y_p : PExpr}
       {m : memory}
       (X: evalNExpr σ x_n = inr b)
       (BP : DSH_pure (DSHAssign (x_p, x_n) (y_p, NConst 0)) y_p)
  :
    @MSH_DSH_compat _ _ (MSHPick bc) (DSHAssign (x_p, x_n) (y_p, NConst 0)) σ m x_p y_p BP.
Proof.
  constructor; intros mx mb MX MB.
  destruct mem_op as [md |] eqn:MD, evalDSHOperator as [fma |] eqn:FMA; try constructor.
  2: exfalso.
  all: unfold lookup_PExpr in MX, MB.
  all: cbn in *.
  all: destruct evalPExpr eqn:XP in MX; try some_none; try inl_inr; rewrite XP in *.
  all: destruct evalPExpr eqn:YP in MB; try some_none; try inl_inr; rewrite YP in *.
  all: unfold Pick_mem,
              map_mem_block_elt,
              MMemoryOfR.mem_lookup,
              MMemoryOfR.mem_add,
              MMemoryOfR.mem_empty
         in MD.
  all: unfold memory_lookup_err, trywith in *.
  all: repeat break_match;
    try some_none; repeat some_inv;
    try inl_inr; repeat inl_inr_inv.
  all: try (inversion MX; fail).
  all: try (inversion MB; fail).
  all: subst.
  all: repeat constructor.
  1,2,4: exfalso.
  all: cbv in X; subst.
  -
    inversion MB.
    cbv in H0; subst.
    cbv in Heqs2.
    inl_inr.
  -
    mem_lookup_err_to_option.
    enough (None = Some c) by some_none.
    rewrite <-Heqo1, <-Heqs3.
    inversion MX.
    rewrite H.
    reflexivity.
  -
    mem_lookup_err_to_option.
    enough (None = Some c) by some_none.
    rewrite <-Heqo1, <-Heqs3.
    inversion MX.
    rewrite H.
    reflexivity.
  -
    unfold SHCOL_DSHCOL_mem_block_equiv,
      memory_lookup, memory_set, mem_add, mem_lookup.
    rewrite NP.F.add_eq_o by reflexivity.
    constructor.
    intros.
    destruct (Nat.eq_dec 0 i0);
      [ repeat rewrite NP.F.add_eq_o by assumption
      | repeat rewrite NP.F.add_neq_o by assumption ].
    +
      constructor 2; [reflexivity |].
      mem_lookup_err_to_option.
      unfold CarrierA, CarrierDefs_R in *.
      rewrite <-Heqs3, <-Heqo1.
      inversion MX.
      rewrite H.
      reflexivity.
    +
      constructor 1; [reflexivity |].
      inversion MB.
      rewrite H.
      reflexivity.
Qed.



(** * MSHPointwise  *)

Global Instance IMap_DSH_pure
       {nn : nat}
       {x_p y_p : PExpr}
       {a : AExpr}
  :
    DSH_pure (DSHIMap nn x_p y_p a) y_p.
Proof.
  constructor.
  -
    intros.
    destruct fuel; [inversion H |].
    cbn in H.
    repeat break_match; repeat some_inv; try inl_inr.
    inl_inr_inv; rewrite <-H.
    split; intros.
    +
      apply mem_block_exists_memory_set; assumption.
    +
      apply mem_block_exists_memory_set_inv in H0.
      destruct H0; [assumption |].
      subst.
      apply memory_is_set_is_Some.
      apply memory_lookup_err_inr_is_Some in Heqs4.
      assumption.
  -
    intros.
    unfold memory_equiv_except, memory_lookup; intros.
    destruct fuel; [inversion H |].
    cbn in H.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    unfold equiv, NM_Equiv, memory_set, mem_add in H.
    specialize (H k).
    rewrite <-H.
    cbv in H0; destruct H0; subst.
    rewrite NP.F.add_neq_o by congruence.
    reflexivity.
Qed.

Opaque CarrierA.

Global Instance Pointwise_MSH_DSH_compat
       {n: nat}
       {f: FinNat n -> CarrierA -> CarrierA}
       {pF: Proper ((=) ==> (=) ==> (=)) f}
       {df : AExpr}
       {x_p y_p : PExpr}
       {σ : evalContext}
       {m : memory}
       (FDF : MSH_DSH_IUnCarrierA_compat f (protect_p σ y_p) df m)
       (P : DSH_pure (DSHIMap n x_p y_p df) y_p)
       {XY : evalPExpr_id σ x_p <> evalPExpr_id σ y_p}
  :
    @MSH_DSH_compat _ _ (@MSHPointwise n f pF) (DSHIMap n x_p y_p df) σ m x_p y_p P.
Proof.
  split.
  intros mx mb MX MB.
  simpl.
  destruct (mem_op_of_hop (HPointwise f) mx) as [md|] eqn:MD.
  -
    unfold lookup_PExpr_wsize, lookup_PExpr in *.
    simpl in *.
    repeat break_match;
      memory_lookup_err_to_option;
      try some_none; repeat some_inv;
        try inl_inr; repeat inl_inr_inv;
          subst.
    +
      exfalso.
      cbn in XY.
      rewrite Heqs, Heqs0 in XY.
      rename Heqs1 into NE.
      clear - XY NE.
      rewrite inr_neq in XY.
      unfold assert_nat_neq, assert_false_to_err in NE.
      destruct (Nat.eqb n2 n0) eqn:E.
      * apply beq_nat_true in E.
        congruence.
      *
        inl_inr.
    +
      (* mem_op succeeded with [Some md] while evaluation of DHS failed *)
      eq_to_equiv; tuple_inversion_equiv; subst_nat; minimize_eq.

      rename Heqs2 into E.

      apply equiv_Some_is_Some in MD.
      pose proof (mem_op_of_hop_x_density MD) as DX.
      clear MD pF.

      inversion_clear FDF as [FV].

      contradict E.
      apply is_OK_neq_inl.

      unfold assert_NT_le.
      rewrite Nat.leb_refl.
      cbn.
      constructor.
    +
      (* mem_op succeeded with [Some md] while evaluation of DHS failed *)
      eq_to_equiv; tuple_inversion_equiv; subst_nat; minimize_eq.

      rename Heqs5 into E.

      apply equiv_Some_is_Some in MD.
      pose proof (mem_op_of_hop_x_density MD) as DX.
      clear MD pF.

      inversion_clear FDF as [FV].

      contradict E.
      apply is_OK_neq_inl.
      eapply evalDSHIMap_is_OK_inv.

      intros k kc.

      specialize (DX k kc).
      apply is_Some_equiv_def in DX.
      destruct DX as [a DX].
      exists a.
      split.
      rewrite H1; assumption.
      specialize (FV (mkFinNat kc) a).
      destruct evalIUnCType; try inl_inr; try constructor.
    +
      constructor.
      eq_to_equiv; tuple_inversion_equiv; subst_nat; minimize_eq.
      unfold memory_lookup_err, memory_lookup, memory_set in *.
      rewrite NP.F.add_eq_o by reflexivity.
      constructor.
      repeat some_inv.

      eq_to_equiv_hyp; err_eq_to_equiv_hyp.

      rename Heqs5 into ME.
      intros k.

      unfold mem_op_of_hop in MD.
      break_match_hyp; try some_none.
      some_inv.
      rewrite <- MD.
      clear MD md.
      rename t into vx.

      unfold avector_to_mem_block.
      avector_to_mem_block_to_spec md HD OD.
      destruct (NatUtil.lt_ge_dec k n) as [kc | kc].
      *
        (* k<n, which is normal *)
        clear OD.
        simpl in *.
        unfold MMemoryOfR.mem_lookup in HD.
        unfold mem_lookup.
        rewrite HD with (ip:=kc).
        clear HD md.
        apply MemExpected.
        --
          unfold is_Some.
          tauto.
        --
          inversion_clear FDF as [FV].

          rewrite HPointwise_nth with (jc:=kc).

          pose proof (evalDSHIMap_mem_lookup_mx ME k kc) as A.

          apply is_Some_equiv_def in A. destruct A as [a A].

          specialize FV with (nc:=mkFinNat kc) (a:=a).
          cbn in FV.

          pose proof (evalDSHIMap_nth m k kc A ME) as T.
          inversion T; [rewrite <-H3 in FV; inl_inr | clear T].
          unfold mem_lookup in H0.
          rewrite <-H0.
          rewrite <-H2 in FV.
          inversion FV.
          subst.

          pose proof (mem_block_to_avector_nth Heqo (kc:=kc)) as MVA.
          eq_to_equiv.
          rewrite <-H1, A in MVA; some_inv.
          rewrite H3, H6, MVA.
          reflexivity.
      *
        (* k >= 0 *)
        simpl in *.
        clear HD.
        rewrite OD by assumption.
        apply MemPreserved.
        --
          unfold is_None.
          tauto.
        --
          specialize (OD k kc).
          rewrite H, H1 in ME.
          apply (evalDSHIMap_oob_preservation m ME), kc.
  -
    unfold lookup_PExpr, lookup_PExpr_wsize in *.
    simpl in *.
    repeat break_match;
      try some_none; repeat some_inv;
        try inl_inr; repeat inl_inr_inv.
    all: try constructor.
    exfalso.
    memory_lookup_err_to_option;
      eq_to_equiv; tuple_inversion_equiv;
        subst_nat; minimize_eq.
    subst p p0.

    unfold mem_op_of_hop in MD.
    break_match_hyp; try some_none.
    clear MD.
    rename Heqo into MX.
    unfold mem_block_to_avector in MX.
    apply vsequence_Vbuild_eq_None in MX.
    destruct n.
    *
      destruct MX as [k [kc MX]].
      inversion kc.
    *
      rewrite H, H1 in *.
      contradict Heqs3.
      enough (T : is_Err (evalDSHIMap m (S n) df (protect_p σ y_p) mx mb))
        by (destruct (evalDSHIMap m (S n) df (protect_p σ y_p) mx mb);
            [intros C; inl_inr | inversion T ]).
      apply evalDSHIMap_is_Err; try typeclasses eauto.
      lia.
      destruct MX as [k MX].
      destruct (NatUtil.lt_ge_dec k (S n)) as [kc1 | kc2].
      --
        exists k.
        exists kc1.
        destruct MX as [kc MX].
        apply is_None_def in MX.
        eapply MX.
      --
        destruct MX as [kc MX].
        lia.
Qed.



(** * MSHBinOp  *)

Global Instance BinOp_DSH_pure
       {o : nat}
       {x_p y_p : PExpr}
       {a: AExpr}
  :
    DSH_pure (DSHBinOp o x_p y_p a) y_p.
Proof.
  split.
  -
    intros.
    destruct fuel; [inversion H |].
    cbn in H.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    rewrite <-H.
    split; intros.
    +
      apply mem_block_exists_memory_set; assumption.
    +
      apply mem_block_exists_memory_set_inv in H0.
      destruct H0; [assumption |].
      subst.
      apply memory_is_set_is_Some.
      apply memory_lookup_err_inr_is_Some in Heqs4.
      assumption.
  -
    intros σ m m' fuel E y_i size P.
    destruct fuel; cbn in E; [some_none |].

    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    memory_lookup_err_to_option;
      eq_to_equiv; tuple_inversion_equiv;
        subst_nat; minimize_eq.
    subst.
    intros k NKY.
    rewrite <-E.
    clear E m'.
    unfold memory_lookup, memory_set in *.
    rewrite NP.F.add_neq_o by auto.
    reflexivity.    
Qed.

Global Instance BinOp_MSH_DSH_compat
       {o: nat}
       {f: {n:nat|n<o} -> CarrierA -> CarrierA -> CarrierA}
       {pF: Proper ((=) ==> (=) ==> (=) ==> (=)) f}
       {x_p y_p : PExpr}
       {df : AExpr}
       {σ: evalContext}
       (m: memory)
       (FDF : MSH_DSH_IBinCarrierA_compat f (protect_p σ y_p) df m)
       (BP: DSH_pure (DSHBinOp o x_p y_p df) y_p)
       {XY : evalPExpr_id σ x_p <> evalPExpr_id σ y_p}
  :
    @MSH_DSH_compat _ _ (MSHBinOp f) (DSHBinOp o x_p y_p df) σ m x_p y_p BP.
Proof.
  split.
  intros mx mb MX MB.
  simpl.
  destruct (mem_op_of_hop (HCOL.HBinOp f) mx) as [md|] eqn:MD.
  -
    unfold lookup_PExpr, lookup_PExpr_wsize in *.
    simpl in *.
    repeat break_match;
      memory_lookup_err_to_option;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv;
      subst.
    2,3,4: eq_to_equiv; tuple_inversion_equiv; subst_nat; minimize_eq.
    +
      exfalso.
      cbn in XY.
      rewrite Heqs, Heqs0 in XY.
      rename Heqs1 into NE.
      clear - XY NE.
      rewrite inr_neq in XY.
      unfold assert_nat_neq, assert_false_to_err in NE.
      destruct (Nat.eqb n1 n) eqn:E.
      * apply beq_nat_true in E.
        congruence.
      *
        inl_inr.
    + (* mem_op succeeded with [Some md] while evaluation of DHS failed *)
      exfalso.
      rename Heqs2 into E.

      apply equiv_Some_is_Some in MD.
      pose proof (mem_op_of_hop_x_density MD) as DX.
      clear MD pF.

      inversion_clear FDF as [FV].

      contradict E.
      apply is_OK_neq_inl.

      unfold assert_NT_le.
      rewrite Nat.leb_refl.
      cbn.
      constructor.
    + (* mem_op succeeded with [Some md] while evaluation of DHS failed *)
      exfalso.
      rename Heqs5 into E.

      apply equiv_Some_is_Some in MD.
      pose proof (mem_op_of_hop_x_density MD) as DX.
      clear MD pF.

      inversion_clear FDF as [FV].

      contradict E.
      apply is_OK_neq_inl.

      eapply evalDSHBinOp_is_OK_inv.

      intros k kc.

      assert(DX1:=DX).
      assert(kc1: k < o + o) by lia.
      specialize (DX k kc1).
      apply is_Some_equiv_def in DX.
      destruct DX as [a DX].

      assert(kc2: k + o < o + o) by lia.
      specialize (DX1 (k+o) kc2).
      apply is_Some_equiv_def in DX1.
      destruct DX1 as [b DX1].
      exists a.
      exists b.
      repeat split.
      rewrite H1; assumption.
      rewrite H1; assumption.
      specialize (FV (FinNat.mkFinNat kc) a b).
      cbn in FV.
      eapply inr_is_OK.
      eassumption.
    +
      constructor.
      unfold memory_lookup_err, trywith, memory_lookup, memory_set.
      rewrite NP.F.add_eq_o by reflexivity.
      constructor.
      repeat some_inv.
      rename Heqs5 into ME.
      intros k.
      unfold mem_op_of_hop in MD.
      break_match_hyp; try some_none.
      some_inv.
      rewrite <- MD.
      clear MD md.
      rename t into vx.
      unfold avector_to_mem_block.

      avector_to_mem_block_to_spec md HD OD.
      destruct (NatUtil.lt_ge_dec k o) as [kc | kc].
      *
        (* k<o, which is normal *)
        clear OD.
        simpl in *.
        unfold MMemoryOfR.mem_lookup in HD.
        unfold mem_lookup.
        rewrite HD with (ip:=kc).
        clear HD md.
        apply MemExpected.
        --
          unfold is_Some.
          tauto.
        --
          inversion_clear FDF as [FV].

          assert (k < o + o)%nat as kc1 by lia.
          assert (k + o < o + o)%nat as kc2 by lia.
          rewrite HBinOp_nth with (jc1:=kc1) (jc2:=kc2).

          pose proof (evalDSHBinOp_mem_lookup_mx ME k kc) as [A B].

          apply is_Some_equiv_def in A. destruct A as [a A].
          apply is_Some_equiv_def in B. destruct B as [b B].


          specialize FV with (nc:=mkFinNat kc) (a:=a) (b:=b).
          cbn in FV.

          pose proof (evalDSHBinOp_nth m k kc A B ME) as T.
          inversion T; [rewrite <-H3 in FV; inl_inr | clear T].
          unfold mem_lookup in H0.
          rewrite <-H0.
          rewrite <-H2 in FV.
          inversion FV.
          subst.
          
          pose proof (mem_block_to_avector_nth Heqo0 (kc:=kc1)) as MVA.
          pose proof (mem_block_to_avector_nth Heqo0 (kc:=kc2)) as MVB.
          rewrite H, H1 in *.
          rewrite MVA, MVB in *.
          repeat some_inv.
          rewrite A, B.
          rewrite <-H6.
          rewrite H3.
          reflexivity.
      *
        (* k >= 0 *)
        simpl in *.
        clear HD.
        rewrite OD by assumption.
        apply MemPreserved.
        --
          unfold is_None.
          tauto.
        --
          specialize (OD k kc).
          rewrite H, H1 in *.
          apply (evalDSHBinOp_oob_preservation m ME), kc.
  -
    unfold lookup_PExpr, lookup_PExpr_wsize in *.
    simpl in *.
    repeat break_match;
      memory_lookup_err_to_option;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    all: try constructor.
    eq_to_equiv; tuple_inversion_equiv; subst_nat; minimize_eq.
    exfalso.
    subst.

    unfold mem_op_of_hop in MD.
    break_match_hyp; try some_none.
    clear MD.
    rename Heqo0 into MX.
    unfold mem_block_to_avector in MX.
    apply vsequence_Vbuild_eq_None in MX.
    destruct o.
    *
      destruct MX as [k [kc MX]].
      inversion kc.
    *
      contradict Heqs4.
      rewrite H, H1 in *.
      enough (T : is_Err (evalDSHBinOp m (S o) (S o) df (protect_p σ y_p) mx mb))
        by (destruct (evalDSHBinOp m (S o) (S o) df (protect_p σ y_p) mx mb);
            [intros C; inl_inr | inversion T ]).
      apply evalDSHBinOp_is_Err; try typeclasses eauto.
      lia.
      destruct MX as [k MX].
      destruct (NatUtil.lt_ge_dec k (S o)) as [kc1 | kc2].
      --
        exists k.
        exists kc1.
        left.
        destruct MX as [kc MX].
        apply is_None_def in MX.
        eapply MX.
      --
        exists (k-(S o)).
        destruct MX as [kc MX].
        assert(kc3: k - S o < S o) by lia.
        exists kc3.
        right.
        apply is_None_def in MX.
        replace (k - S o + S o) with k.
        apply MX.
        lia.
Qed.



(** * MSHInductor *)

Global Instance Power_DSH_pure
       {n : NExpr}
       {x_n y_n : NExpr}
       {x_p y_p : PExpr}
       {a : AExpr}
       {initial : CarrierA}
  :
    DSH_pure (DSHPower n (x_p, x_n) (y_p, y_n) a initial) y_p.
Proof.
  split.
  -
    intros.
    destruct fuel; [inversion H |].
    cbn in H.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    rewrite <-H.
    split; intros.
    +
      apply mem_block_exists_memory_set; assumption.
    +
      apply mem_block_exists_memory_set_inv in H0.
      destruct H0; [assumption |].
      subst.
      apply memory_is_set_is_Some.
      apply memory_lookup_err_inr_is_Some in Heqs3.
      assumption.
  -
    intros.
    unfold memory_equiv_except, memory_lookup; intros.
    destruct fuel; [inversion H |].
    cbn in H.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    subst.
    unfold equiv, NM_Equiv, memory_set, mem_add in H.
    specialize (H k).
    rewrite <-H.
    destruct (Nat.eq_dec n2 k), (Nat.eq_dec n0 k);
        try (rewrite NP.F.add_eq_o with (x := n2) by assumption);
        try (rewrite NP.F.add_eq_o with (x := n0) by assumption);
        try (rewrite NP.F.add_neq_o with (x := n2) by assumption);
        try (rewrite NP.F.add_neq_o with (x := n0) by assumption).
    all: tuple_inversion_equiv; subst_nat.
    all: subst.
    all: try congruence.
    all: reflexivity.
Qed.

Global Instance Inductor_MSH_DSH_compat
       {σ : evalContext}
       {n : nat}
       {nx : NExpr}
       {N : evalNExpr σ nx = inr n}
       {m : memory}
       {f : CarrierA -> CarrierA -> CarrierA}
       {PF : Proper ((=) ==> (=) ==> (=)) f}
       {init : CarrierA}
       {a : AExpr}
       {x_p y_p : PExpr}
       (FA : MSH_DSH_BinCarrierA_compat f (protect_p σ y_p) a m)
       (PD : DSH_pure (DSHPower nx (x_p, NConst 0) (y_p, NConst 0) a init) y_p)
       {XY : evalPExpr_id σ x_p <> evalPExpr_id σ y_p}
  :
    @MSH_DSH_compat _ _
                    (MSHInductor n f init)
                    (DSHPower nx (x_p, NConst 0) (y_p, NConst 0) a init)
                    σ m x_p y_p PD.
Proof.
  constructor; intros x_m y_m X_M Y_M.
  assert (T : evalNExpr σ nx ≡ inr n)
    by (inversion N; inversion H1; reflexivity);
    clear N; rename T into N.
  destruct mem_op as [mma |] eqn:MOP.
  all: destruct evalDSHOperator as [r |] eqn:DOP; [destruct r as [msg | dma] |].
  all: repeat constructor.
  1,3,4: exfalso.
  - (* [mem_op] suceeds, [evalDSHOperator] fails *)
    destruct (evalPExpr σ x_p) as [| x_id] eqn:X;
      [unfold lookup_PExpr_wsize in X_M; rewrite X in X_M; inversion X_M |].
    destruct (evalPExpr σ y_p) as [| y_id] eqn:Y;
      [unfold lookup_PExpr_wsize in Y_M; rewrite Y in Y_M; inversion Y_M |].

    cbn in X_M; rewrite X in X_M.
    cbn in Y_M; rewrite Y in Y_M.

    unfold memory_lookup_err, trywith in *.
    destruct x_id as (x_id, x_sz), y_id as (y_id, y_sz).

    destruct (memory_lookup m x_id) eqn:X_M'; inversion X_M; subst;
      clear X_M; rename m0 into x_m', H1 into XME.
    destruct (memory_lookup m y_id) eqn:Y_M'; inversion Y_M; subst;
      clear Y_M; rename m0 into y_m', H1 into YME.

    destruct n.
    +
      cbn in DOP.
      unfold NatAsNT.MNatAsNT.to_nat in *.
      repeat break_match_hyp; try inl_inr;
        repeat inl_inr_inv; repeat some_inv; try some_none; subst.
      *
        exfalso.
        cbn in XY.
        rewrite Heqs, Heqs0 in XY.
        rename Heqs1 into NE.
        clear - XY NE.
        rewrite inr_neq in XY.
        unfold assert_nat_neq, assert_false_to_err in NE.
        destruct (Nat.eqb x_id y_id) eqn:E.
        -- apply beq_nat_true in E.
           congruence.
        --
          inl_inr.
      *
        repeat err_eq_to_equiv_hyp.
        apply memory_lookup_err_inl_None in Heqs2.
        repeat eq_to_equiv_hyp.
        some_none.
      *
        repeat err_eq_to_equiv_hyp.
        apply memory_lookup_err_inl_None in Heqs3.
        repeat eq_to_equiv_hyp.
        some_none.
      *
        (* assert_NT_lt fails *)
        unfold assert_NT_lt, assert_true_to_err in Heqs5.
        cbn in Heqs5.
        break_if; try inl_inr.
        break_match_hyp; [| inversion Heqb].
        unfold NatAsNT.MNatAsNT.to_nat in Heqn.
        subst.
        inv YME.
        cbn in H0.
        inv H0.
      *
        unfold memory_lookup_err, trywith in *.
        rewrite X_M' in Heqs2.
        rewrite Y_M' in Heqs3.
        repeat inl_inr_inv.
        subst.
        cbn in Heqs6.
        inl_inr.
    +
      cbn in MOP.
      unfold mem_op_of_hop in MOP.
      repeat break_match_hyp; try inl_inr;
        repeat inl_inr_inv; repeat some_inv; try some_none; subst.

      (* [x_m] is dense *)
      rename Heqo into XD.
      assert(0<1) as jc by lia.
      apply mem_block_to_avector_nth with (kc:=jc) in XD.

      cbn in DOP.
      unfold NatAsNT.MNatAsNT.to_nat in *.
      rewrite N in DOP.
      repeat break_match_hyp;
        try some_none; repeat some_inv; 
          try inl_inr; repeat inl_inr_inv;
            subst.
      1: {
        cbn in XY.
        rewrite Heqs, Heqs0 in XY.
        rename Heqs1 into NE.
        clear - XY NE.
        rewrite inr_neq in XY.
        unfold assert_nat_neq, assert_false_to_err in NE.
        destruct (Nat.eqb x_id y_id) eqn:E.
        -- apply beq_nat_true in E.
           congruence.
        --
          inl_inr.
      }
      all: memory_lookup_err_to_option; tuple_inversion_equiv;
        minimize_eq; eq_to_equiv; subst_nat; subst.
      all: try some_none.
      1: inv Heqs4.
      unfold memory_lookup_err, trywith in *.
      rewrite X_M' in Heqs2.
      rewrite Y_M' in Heqs3.
      repeat some_inv.

      rewrite <-Heqs2, <-Heqs3, H, H1 in *;
        clear Heqs2 Heqs3 H H1 y_m' x_m'.

      rename Heqs5 into EV.
      clear - EV XD FA.
      apply equiv_Some_is_Some in XD.
      revert x_m XD EV.
      remember (mem_add 0 init y_m) as iy_m.
      assert(is_Some (mem_lookup 0 iy_m)) as YD.
      {
        subst iy_m.
        unfold mem_lookup, mem_add.
        rewrite NP.F.add_eq_o.
        some_none.
        reflexivity.
      }
      clear Heqiy_m y_m.
      rename iy_m into y_m.
      revert y_m YD.

      induction n; intros.
      *
        cbn in *.
        repeat break_match_hyp; try inl_inr;
          repeat inl_inr_inv; repeat some_inv; try some_none; subst.
        --
          unfold mem_lookup_err,trywith in Heqs.
          break_match_hyp; try inl_inr.
          some_none.
        --
          unfold mem_lookup_err,trywith in Heqs0.
          break_match_hyp; try inl_inr.
          some_none.
        --
          destruct FA.
          specialize (bin_equiv0 c0 c).
          rewrite Heqs1 in bin_equiv0.
          inl_inr.
      *
        revert IHn EV.
        generalize (S n) as z.
        intros z IHn EV.
        cbn in EV.
        repeat break_match_hyp; try inl_inr;
          repeat inl_inr_inv; repeat some_inv; try some_none; subst.
        --
          unfold mem_lookup_err,trywith in Heqs.
          break_match_hyp; try inl_inr.
          some_none.
        --
          unfold mem_lookup_err,trywith in Heqs0.
          break_match_hyp; try inl_inr.
          some_none.
        --
          destruct FA.
          specialize (bin_equiv0 c0 c).
          rewrite Heqs1 in bin_equiv0.
          inl_inr.
        --
          eapply IHn in EV; eauto.
          unfold mem_lookup, mem_add.
          rewrite NP.F.add_eq_o.
          some_none.
          reflexivity.
  - (* [mem_op] suceeds, [evalDSHOperator] out of fuel *)
    exfalso.
    contradict DOP.
    apply is_Some_ne_None.
    apply evalDSHOperator_estimateFuel.
  - (* [mem_op] fails, [evalDSHOperator] suceeds *)
    exfalso.
    destruct (evalPExpr σ x_p) as [| x_id] eqn:X;
      [unfold lookup_PExpr_wsize in X_M; rewrite X in X_M; inversion X_M |].
    destruct (evalPExpr σ y_p) as [| y_id] eqn:Y;
      [unfold lookup_PExpr_wsize in Y_M; rewrite Y in Y_M; inversion Y_M |].

    cbn in X_M; rewrite X in X_M.
    cbn in Y_M; rewrite Y in Y_M.

    unfold memory_lookup_err, trywith in *.
    destruct x_id as (x_id, x_sz), y_id as (y_id, y_sz).

    destruct (memory_lookup m x_id) eqn:X_M'; inversion X_M; subst;
      clear X_M; rename m0 into x_m', H1 into XME.
    destruct (memory_lookup m y_id) eqn:Y_M'; inversion Y_M; subst;
      clear Y_M; rename m0 into y_m', H1 into YME.

    (* simplify DOP down to evalDSHPower *)
    cbn in DOP; unfold NatAsNT.MNatAsNT.to_nat in *; some_inv; rename H0 into DOP.
    rewrite N in DOP.
    repeat break_match; try inl_inr.

    destruct n;[cbn in MOP;some_none|].
    cbn in MOP.
    unfold mem_op_of_hop in MOP.
    repeat break_match_hyp;
      try some_none; repeat some_inv; 
      try inl_inr; repeat inl_inr_inv;
      subst.
    memory_lookup_err_to_option; tuple_inversion_equiv;
      minimize_eq; subst_nat; subst.
    rename H into YME, H1 into XME.

    rename Heqs5 into EV.

    (* [x_m] is not dense *)
    rename Heqo into XD.
    apply mem_block_to_avector_eq_None in XD.

    unfold memory_lookup_err, trywith in *.
    rewrite X_M' in Heqs2.
    rewrite Y_M' in Heqs3.
    repeat some_inv.
    eq_to_equiv; subst y_m' x_m'.
    rewrite XME, YME in *; clear XME YME m0.

    destruct XD as (j & jc & XD).
    destruct j; [clear jc|lia].

    eq_to_equiv_hyp.
    err_eq_to_equiv_hyp.
    clear X_M'.
    revert x_m XD EV.
    generalize (mem_add 0 init y_m) as m0.
    clear_all.

    induction n; intros.
    *
      cbn in *.
      repeat break_match_hyp; try inl_inr;
        repeat inl_inr_inv; repeat some_inv; try some_none; subst.
      unfold mem_lookup_err,trywith in Heqs.
      break_match_hyp; try inl_inr.
      eq_to_equiv_hyp.
      some_none.
    *
      revert IHn EV.
      generalize (S n) as z.
      intros z IHn EV.
      cbn in EV.
      repeat break_match_hyp; try inl_inr;
        repeat inl_inr_inv; repeat some_inv; try some_none; subst.
      eapply IHn; eauto.
  -
    unfold lookup_PExpr; cbn.
    cbn in DOP.
    unfold NatAsNT.MNatAsNT.to_nat in *.
    destruct (evalPExpr σ x_p) as [| x_id] eqn:X;
      [unfold lookup_PExpr_wsize in X_M; rewrite X in X_M; inversion X_M |].
    destruct (evalPExpr σ y_p) as [| y_id] eqn:Y;
      [unfold lookup_PExpr_wsize in Y_M; rewrite Y in Y_M; inversion Y_M |].
    destruct x_id as (x_id, x_sz), y_id as (y_id, y_sz).
    destruct (memory_lookup dma y_id) as [y_dma |] eqn:Y_DMA.
    unfold memory_lookup_err.
    +
      rewrite Y_DMA.
      constructor.
      unfold SHCOL_DSHCOL_mem_block_equiv.
      intro k.

      cbn in X_M; rewrite X in X_M.
      cbn in Y_M; rewrite Y in Y_M.

      unfold memory_lookup_err, trywith in *.

      destruct (memory_lookup m x_id) eqn:X_M'; inversion X_M; subst;
        clear X_M; rename m0 into x_m', H1 into XME.
      destruct (memory_lookup m y_id) eqn:Y_M'; inversion Y_M; subst;
        clear Y_M; rename m0 into y_m', H1 into YME.

      (* simplify DOP down to evalDSHPower *)
      cbn in DOP; some_inv; rename H0 into DOP.
      rewrite N in DOP.
      repeat break_match; try inl_inr.
      inl_inr_inv.
      rename m0 into pm, Heqs1 into PM,
      H0 into DMA.
      rewrite <-DMA in *.
      unfold memory_lookup, memory_set in Y_DMA.
      rewrite NP.F.add_eq_o in Y_DMA by reflexivity.
      replace pm with y_dma in * by congruence; clear Y_DMA; rename PM into Y_DMA.

      tuple_inversion_equiv; subst_nat.
      rename H1 into XME, H into YME.

      (* make use of MOP *)
      destruct n as [|n'].
      {
        cbn in *.
        some_inv; inl_inr_inv.
        destruct (Nat.eq_dec 0 k).
        -
          subst.
          unfold mem_lookup, mem_add, MMemoryOfR.mem_add.
          repeat rewrite NP.F.add_eq_o by reflexivity.
          constructor 2; reflexivity.
        -
          unfold mem_lookup, mem_add, MMemoryOfR.mem_add.
          repeat rewrite NP.F.add_neq_o by assumption.
          constructor 1; [reflexivity |].
          rewrite YME.
          reflexivity.
      }
      cbn in MOP.
      remember (S n') as n; clear Heqn.
      unfold mem_op_of_hop in MOP.
      break_match; try some_none.
      some_inv.
      rename t into x_v, Heqo into X_V.

      destruct (Nat.eq_dec k 0) as [KO | KO].
      * (* the changed part of the block*)
        subst.
        cbn.
        constructor 2; [reflexivity |].
        destruct (mem_lookup 0 y_dma) as [ydma0 |] eqn:YDMA0.
        --
          clear N PD.
          err_eq_to_equiv_hyp.
          generalize dependent y_dma.
          generalize dependent init.
          induction n; intros.
          ++ (* induction base *)
            cbn in Y_DMA.
            inl_inr_inv.
            rewrite <-YDMA0.
            clear ydma0 YDMA0.
            rewrite <-Y_DMA; clear Y_DMA.
            unfold mem_lookup, mem_add.
            rewrite NP.F.add_eq_o by reflexivity.
            reflexivity.
          ++ (* inductive step *)

            (* simplify Y_DMA *)
            cbn in Y_DMA.
            unfold mem_lookup_err in Y_DMA.
            replace (mem_lookup 0 (mem_add 0 init y_m'))
              with (Some init)
              in Y_DMA
              by (unfold mem_lookup, mem_add;
                  rewrite NP.F.add_eq_o by reflexivity;
                  reflexivity).
            cbn in Y_DMA.
            destruct (mem_lookup 0 x_m') as [xm'0|] eqn:XM'0;
              cbn in Y_DMA; try inl_inr.
            inversion FA; clear FA;
              rename bin_equiv0 into FA; specialize (FA init xm'0 ).
            destruct (evalBinCType m (protect_p σ y_p) a init xm'0 ) as [|df] eqn:DF;
              try inl_inr; inl_inr_inv.
            (* abstract: this gets Y_DMA to "the previous step" for induction *)
            rewrite mem_add_overwrite in Y_DMA.

            apply mem_block_to_avector_nth with (kc:=le_n 1) (k := 0) in X_V.
            rewrite Vnth_1_Vhead in X_V.
            assert (T : xm'0 = Vhead x_v).
            {
              enough (Some xm'0 = Some (Vhead x_v)) by (some_inv; assumption).
              rewrite <-X_V, <-XM'0, XME; reflexivity.
            }
            rewrite T in FA; clear T.

            (* applying induction hypothesis *)
            apply IHn in Y_DMA; [| assumption].

            rewrite Y_DMA, FA.

            unfold HCOLImpl.Inductor.
            rewrite nat_rect_succ_r.
            reflexivity.
        --
          clear - Y_DMA YDMA0.
          eq_to_equiv_hyp.
          err_eq_to_equiv_hyp.
          contradict YDMA0.
          generalize dependent init.
          induction n; cbn in *.
          ++
            intros.
            inversion Y_DMA; subst.
            rewrite <-H1.
            unfold mem_lookup, mem_add.
            rewrite NP.F.add_eq_o by reflexivity.
            intros C; inversion C.
          ++
            intros.
            repeat break_match; try inl_inr.
            eapply IHn.
            rewrite <-Y_DMA.
            f_equiv.
            rewrite mem_add_overwrite.
            reflexivity.
      * (* the preserved part of the block *)
        constructor 1;
          [cbn; break_match; try reflexivity;
           contradict KO; rewrite e; reflexivity |].
        inversion PD; clear PD mem_stable0; rename mem_write_safe0 into MWS.
        specialize (MWS σ m dma).

        clear - Y_DMA KO YME.
        err_eq_to_equiv_hyp.
        rewrite YME in Y_DMA.
        clear YME y_m'.

        assert(mem_lookup k y_m = mem_lookup k (mem_add 0 init y_m)) as P.
        {
          unfold mem_lookup, mem_add.
          rewrite NP.F.add_neq_o by auto.
          reflexivity.
        }
        revert Y_DMA P.
        generalize (mem_add 0 init y_m) as m0.
        induction n; intros.
        --
          cbn in *.
          inl_inr_inv.
          rewrite <- Y_DMA.
          apply P.
        --
          cbn in Y_DMA.
          repeat break_match_hyp; try inl_inr.
          eapply IHn.
          eauto.
          unfold mem_lookup, mem_add.
          rewrite NP.F.add_neq_o by auto.
          apply P.
    +
      exfalso.
      repeat break_match_hyp; try inl_inr; try some_inv; try some_none.
      repeat inl_inr_inv; subst.
      unfold memory_lookup, memory_set in Y_DMA.
      rewrite NP.F.add_eq_o in Y_DMA by reflexivity.
      some_none.
Qed.



(** * MSHIUnion *)

Global Instance Loop_DSH_pure
       {n : nat}
       {dop : DSHOperator}
       {y_p : PExpr}
       (P : DSH_pure dop (incrPVar 0 y_p))

  :
    DSH_pure (DSHLoop n dop) y_p.
Proof.
  split.
  -
    intros.
    destruct fuel; [inversion H |].
    generalize dependent fuel.
    generalize dependent m'.
    induction n.
    +
      intros.
      cbn in *.
      some_inv; inl_inr_inv.
      rewrite H; reflexivity.
    +
      intros.
      cbn in H.
      repeat break_match;
        try some_none; repeat some_inv;
        try inl_inr; repeat inl_inr_inv.
      subst.
      destruct fuel; [inversion Heqo |].
      eq_to_equiv_hyp.
      apply IHn in Heqo.
      rewrite Heqo.
      clear - P H.
      inversion P.
      eapply mem_stable0.
      eassumption.
  -
    intros.
    destruct fuel; [inversion H |].
    generalize dependent fuel.
    generalize dependent m'.
    induction n.
    +
      intros.
      cbn in *.
      some_inv; inl_inr_inv.
      unfold memory_equiv_except.
      intros.
      rewrite H.
      reflexivity.
    +
      intros.
      cbn in H.
      repeat break_match;
        try some_none; repeat some_inv;
        try inl_inr; repeat inl_inr_inv.
      subst.
      destruct fuel; [inversion Heqo |].
      eq_to_equiv_hyp.
      apply IHn in Heqo.
      unfold memory_equiv_except in *.
      intros.
      rewrite Heqo by assumption.
      inversion P.
      unfold memory_equiv_except in *.
      eapply mem_write_safe0.
      eassumption.
      rewrite evalPExpr_incrPVar.
      eassumption.
      assumption.
Qed.

Theorem IUnion_MSH_step {i o n : nat} (mb : mem_block) (S_opf : @MSHOperatorFamily i o (S n)) :
  let opf := shrink_m_op_family S_opf in
  let fn := mkFinNat (Nat.lt_succ_diag_r n) in
  mem_op (MSHIUnion S_opf) mb = mb' <- mem_op (MSHIUnion opf) mb ;;
                                mbn <- mem_op (S_opf fn) mb ;;
                                Some (MMemoryOfR.mem_union mbn mb').
Proof.
  simpl.
  unfold IUnion_mem.
  simpl.
  unfold Apply_mem_Family in *.
  repeat break_match;
    try discriminate; try reflexivity.
  all: repeat some_inv; subst.
  -
    rename l into S_lb, l0 into lb.

    (* poor man's apply to copy and avoid evars *)
    assert (S_LB : ∀ (j : nat) (jc : (j < S n)%mc),
               List.nth_error S_lb j ≡ get_family_mem_op S_opf j jc mb)
      by (apply ListSetoid.monadic_Lbuild_op_eq_Some; assumption).
    assert (LB : ∀ (j : nat) (jc : (j < n)%mc),
               List.nth_error lb j ≡ get_family_mem_op (shrink_m_op_family S_opf) j jc mb)
      by (apply ListSetoid.monadic_Lbuild_op_eq_Some; assumption).

    apply ListSetoid.monadic_Lbuild_opt_length in Heqo0; rename Heqo0 into S_L.
    apply ListSetoid.monadic_Lbuild_opt_length in Heqo3; rename Heqo3 into L.
    rename m0 into mbn, Heqo2 into MBN.

    unfold get_family_mem_op in *.
    assert (H : forall j, j < n -> List.nth_error lb j ≡ List.nth_error S_lb j)
      by (intros; erewrite S_LB, LB; reflexivity).
    Unshelve. 2: assumption.

    assert (N_MB : is_Some (mem_op (S_opf (mkFinNat (Nat.lt_succ_diag_r n))) mb)).
    {
      apply is_Some_ne_None.
      intro C.
      rewrite <-S_LB in C.
      apply List.nth_error_None in C.
      lia.
    }
    apply is_Some_def in N_MB.
    destruct N_MB as [n_mb N_MB].

    assert (H1 : S_lb ≡ lb ++ [n_mb]).
    {
      apply list_eq_nth;
        [rewrite List.app_length; cbn; lia |].
      intros k KC.
      (* extensionality *)
      enough (forall d, List.nth k S_lb d ≡ List.nth k (lb ++ [n_mb]) d)
        by (apply Logic.FunctionalExtensionality.functional_extensionality; assumption).
      rewrite S_L in KC.
      destruct (Nat.eq_dec k n).
      -
        subst k.
        intros.
        apply List_nth_nth_error.
        replace n with (0 + Datatypes.length lb).
        rewrite ListNth.nth_error_length.
        cbn.
        rewrite L.
        rewrite S_LB with (jc := (Nat.lt_succ_diag_r n)).
        rewrite <-N_MB.
        reflexivity.
      -
        assert (k < n) by lia; clear KC n0.
        intros.
        apply List_nth_nth_error.
        rewrite <-H by lia.
        rewrite List.nth_error_app1 by lia.
        reflexivity.
    }

    rewrite H1.
    rewrite ListSetoid.fold_left_rev_append.

    2: {
      clear.
      intros m1 m2 m3 k.
      unfold MMemoryOfR.mem_union.
      repeat rewrite NP.F.map2_1bis by reflexivity.
      repeat break_match; reflexivity.
    }
    2: {
      clear.
      intros.
      split.
      all: unfold MMemoryOfR.mem_union, MMemoryOfR.mem_empty.
      all: intros k.
      all: rewrite NP.F.map2_1bis by reflexivity.
      all: break_match; try reflexivity.
      cbn in Heqo; some_none.
    }

    rewrite MBN in N_MB; some_inv.
    reflexivity.
  -
    rename l into S_lb, l0 into lb.

    (* poor man's apply to copy and avoid evars *)
    assert (S_LB : ∀ (j : nat) (jc : (j < S n)%mc),
               List.nth_error S_lb j ≡ get_family_mem_op S_opf j jc mb)
      by (apply ListSetoid.monadic_Lbuild_op_eq_Some; assumption).
    apply ListSetoid.monadic_Lbuild_opt_length in Heqo0; rename Heqo0 into S_L.

    assert (N_MB : is_Some (mem_op (S_opf (mkFinNat (Nat.lt_succ_diag_r n))) mb)).
    {
      apply is_Some_ne_None.
      intro C.
      unfold get_family_mem_op in *.
      rewrite <-S_LB in C.
      apply List.nth_error_None in C.
      lia.
    }

    rewrite Heqo2 in N_MB.
    some_none.
  -
    exfalso; clear Heqo1.

    pose proof Heqo0 as L; apply ListSetoid.monadic_Lbuild_opt_length in L.

    apply ListSetoid.monadic_Lbuild_op_eq_None in Heqo2.
    destruct Heqo2 as [k [KC N]].
    apply ListSetoid.monadic_Lbuild_op_eq_Some
      with (i0:=k) (ic:=le_S KC)
      in Heqo0.
    unfold get_family_mem_op, shrink_m_op_family in *.
    cbn in *.
    rewrite N in Heqo0.
    apply ListNth.nth_error_length_ge in Heqo0.
    assert (k < n) by assumption.
    lia.
  -
    exfalso.

    pose proof Heqo3 as S_L; apply ListSetoid.monadic_Lbuild_opt_length in S_L.

    apply ListSetoid.monadic_Lbuild_op_eq_None in Heqo0.
    destruct Heqo0 as [k [KC N]].
    destruct (Nat.eq_dec k n).
    +
      subst k.
      unfold get_family_mem_op in *.
      assert (KC ≡ (Nat.lt_succ_diag_r n)) by (apply lt_unique).
      rewrite <-H, N in Heqo2.
      some_none.
    +
      assert (k < n) by (assert (k < S n) by assumption; lia); clear n0.
      apply ListSetoid.monadic_Lbuild_op_eq_Some
        with (i0:=k) (ic:=H)
        in Heqo3.
      unfold get_family_mem_op, shrink_m_op_family in *.
      cbn in Heqo3.
      assert (le_S H ≡ KC) by (apply lt_unique).
      rewrite H0, N in Heqo3.
      apply ListNth.nth_error_length_ge in Heqo3.
      rewrite S_L in Heqo3.
      lia.
Qed.

Global Instance IUnion_MSH_DSH_compat
       {i o n : nat}
       {dop : DSHOperator}
       {x_p y_p : PExpr}
       {σ : evalContext}
       {m : memory}
       {XY : evalPExpr_id σ x_p <> evalPExpr_id σ y_p}
       {opf : MSHOperatorFamily}
       {DP : DSH_pure dop (incrPVar 0 y_p)}
       {LP : DSH_pure (DSHLoop n dop) y_p}
       (FC : forall t m' y_i y_size,
           evalPExpr σ y_p ≡ inr (y_i, y_size) ->
           memory_equiv_except m m' y_i ->
           @MSH_DSH_compat _ _ (opf t) dop
                           (((DSHnatVal (proj1_sig t)),false) :: σ)
                           m' (incrPVar 0 x_p) (incrPVar 0 y_p) DP)
  
:
    @MSH_DSH_compat _ _ (@MSHIUnion i o n opf) (DSHLoop n dop) σ m x_p y_p LP.
Proof.
  constructor.
  intros x_m y_m X_M Y_M.

  generalize dependent m.
  induction n.
  -
    intros.
    cbn in *.
    constructor.
    break_match; try inl_inr.
    destruct p as (y_id, y_sz).
    destruct memory_lookup_err; try inl_inr; inl_inr_inv.
    constructor.
    unfold SHCOL_DSHCOL_mem_block_equiv.
    intros k.
    constructor 1.
    reflexivity.
    tuple_inversion_equiv.
    rewrite H.
    reflexivity.
  -
    intros.
    simpl evalDSHOperator.
    repeat break_match; subst.
    +
      (* evalDSHOperator errors *)
      pose (opf' := shrink_m_op_family opf).
      assert (T1 : DSH_pure (DSHLoop n dop) y_p) by (apply Loop_DSH_pure; assumption).
      assert (T2: (∀ t m' y_i y_sz,
                      evalPExpr σ y_p ≡ inr (y_i, y_sz) ->
                      memory_equiv_except m m' y_i ->
                      MSH_DSH_compat (opf' t) dop ((DSHnatVal (proj1_sig t),false) :: σ) m'
                                     (incrPVar 0 x_p) (incrPVar 0 y_p))).
      {
        clear - FC.
        subst opf'.
        intros.
        unfold shrink_m_op_family.
        specialize (FC (mkFinNat (le_S (proj2_sig t))) m' y_i y_sz H H0).
        enough (T : (proj1_sig (mkFinNat (le_S (proj2_sig t)))) ≡ (proj1_sig t))
          by (rewrite T in FC; assumption).
        cbv.
        repeat break_match; congruence.
      }
      specialize (IHn opf' T1 m T2 X_M Y_M); clear T1 T2.
      rewrite evalDSHOperator_estimateFuel_ge in Heqo0
        by (pose proof estimateFuel_positive dop; cbn; lia).
      rewrite Heqo0 in IHn; clear Heqo0.
      rename opf into S_opf, opf' into opf.

      subst opf.
      rewrite IUnion_MSH_step.
      remember (λ (md : mem_block) (m' : memory),
             err_p (λ ma : mem_block, SHCOL_DSHCOL_mem_block_equiv y_m ma md)
               (lookup_PExpr σ m' y_p))
        as R.

      inversion IHn; clear IHn; subst.
      simpl.
      rewrite <-H0.
      constructor.
    +
      rename m0 into loop_m.
      
      pose (opf' := shrink_m_op_family opf).
      assert (T1 : DSH_pure (DSHLoop n dop) y_p) by (apply Loop_DSH_pure; assumption).
      assert (T2: (∀ t m' y_i y_sz,
                      evalPExpr σ y_p ≡ inr (y_i, y_sz) ->
                      memory_equiv_except m m' y_i ->
                      MSH_DSH_compat (opf' t) dop ((DSHnatVal (proj1_sig t),false) :: σ) m'
                                     (incrPVar 0 x_p) (incrPVar 0 y_p))).
      {
        clear - FC.
        subst opf'.
        intros.
        unfold shrink_m_op_family.
        specialize (FC (mkFinNat (le_S (proj2_sig t))) m' y_i y_sz H H0).
        enough (T : (proj1_sig (mkFinNat (le_S (proj2_sig t)))) ≡ (proj1_sig t))
          by (rewrite T in FC; assumption).
        cbv.
        repeat break_match; congruence.
      }
      specialize (IHn opf' T1 m T2 X_M Y_M); clear T1 T2.
      rewrite evalDSHOperator_estimateFuel_ge in Heqo0
        by (pose proof estimateFuel_positive dop; cbn; lia).
      rewrite Heqo0 in IHn.
      rename opf into S_opf, opf' into opf.

      subst opf.
      rewrite IUnion_MSH_step.

      inversion IHn; clear IHn; subst.
      inversion H1; clear H1; subst.
      cbn [mem_op MSHIUnion].
      rewrite <-H.
      simpl.
      rename a into mm, H into MM, x into y_lm, H0 into Y_LM, H2 into LE.
      symmetry in MM, Y_LM.

      destruct (evalPExpr σ y_p) as [|(y_i, y_sz)] eqn:YI;
        [unfold lookup_PExpr_wsize in Y_M; rewrite YI in Y_M; cbn in Y_M; inl_inr |].
      assert (T : memory_equiv_except m loop_m y_i).
      {
        clear - Heqo0 DP YI.

        assert (LP : DSH_pure (DSHLoop n dop) y_p)
         by (apply Loop_DSH_pure; assumption).
        inversion_clear LP as [T S]; clear T.
        err_eq_to_equiv_hyp; eq_to_equiv_hyp.
        apply S with (y_i:=y_i) (y_size:=y_sz) in Heqo0.
        assumption.
        assumption.
      }
      specialize (FC (mkFinNat (Nat.lt_succ_diag_r n)) loop_m y_i y_sz eq_refl T); clear T.
      cbn in FC.
      inversion_clear FC as [F].

      assert (T1 : lookup_PExpr_wsize ((DSHnatVal n,false) :: σ) loop_m (incrPVar 0 x_p) = inr (x_m, i)).
      {
        rewrite lookup_PExpr_wsize_incrPVar.
        clear - Heqo0 DP Y_M X_M XY YI.
        pose proof @Loop_DSH_pure n dop y_p DP.
        inversion_clear H as [T C]; clear T.
        err_eq_to_equiv_hyp; eq_to_equiv_hyp.
        specialize (C σ m loop_m (estimateFuel (DSHLoop n dop)) Heqo0 y_i y_sz YI).
        unfold memory_equiv_except in *.
        clear - X_M C XY YI.
        unfold lookup_PExpr, memory_lookup_err in *; cbn in *.
        destruct (evalPExpr σ x_p) as [|(x_i, x_sz)]; try inl_inr.
        repeat break_match; try inl_inr; repeat inl_inr_inv; subst.
        -
          tuple_inversion_equiv; subst_nat.
          memory_lookup_err_to_option.
          eq_to_equiv.
          rewrite C in Heqs0 by congruence.
          some_none.
        -
          tuple_inversion_equiv; subst_nat.
          memory_lookup_err_to_option.
          eq_to_equiv.
          rewrite C in Heqs0 by congruence.
          rewrite Heqs0 in Heqs.
          some_inv.
          constructor.
          constructor.
          cbn.
          rewrite <-H, Heqs; reflexivity.
          reflexivity.
      }

      assert (T2 : lookup_PExpr_wsize ((DSHnatVal n,false) :: σ) loop_m (incrPVar 0 y_p)
                   = inr (y_lm, o)).
      {
        unfold lookup_PExpr_wsize in *.
        rewrite evalPExpr_incrPVar, YI.
        cbn.
        unfold lookup_PExpr in Y_LM, Y_M.
        rewrite YI in Y_LM, Y_M.
        cbn in Y_LM, Y_M.
        rewrite Y_LM.
        constructor.
        constructor.
        reflexivity.
        cbn.
        clear - Y_M.
        break_match; try inl_inr.
        inversion Y_M.
        tuple_inversion_equiv.
        assumption.
      }
      specialize (F x_m y_lm T1 T2); clear T1 T2.

      rewrite evalDSHOperator_estimateFuel_ge by nia.
      remember (evalDSHOperator ((DSHnatVal n,false) :: σ) dop loop_m (estimateFuel dop)) as dm;
        clear Heqdm.
      remember (mem_op (S_opf (mkFinNat (Nat.lt_succ_diag_r n))) x_m) as mmb;
        clear Heqmmb.

      inversion F; clear F; try constructor.
      subst.
      inversion H; clear H.
      rewrite lookup_PExpr_incrPVar in H0.
      rewrite <-H0.
      constructor.
      clear - H1 LE.

      eapply SHCOL_DSHCOL_mem_block_equiv_comp; eassumption.
    +
      exfalso; clear - Heqo0.
      contradict Heqo0.
      apply is_Some_ne_None.
      rewrite evalDSHOperator_estimateFuel_ge
        by (pose proof estimateFuel_positive dop; cbn; lia).
      apply evalDSHOperator_estimateFuel.
Qed.



(** * MSHCompose *)

Global Instance Compose_DSH_pure
         {n: nat}
         {y_p: PExpr}
         {dop1 dop2: DSHOperator}
         (P2: DSH_pure dop2 (PVar 0))
         (P1: DSH_pure dop1 (incrPVar 0 y_p))
  : DSH_pure (DSHAlloc n (DSHSeq dop2 dop1)) y_p.
Proof.
  split.
  - (* mem_stable *)
    intros σ m m' fuel H k.
    destruct P1 as [MS1 _].
    destruct P2 as [MS2 _].
    destruct fuel; simpl in *; try some_none.
    repeat break_match_hyp; try some_none.
    inversion H; inversion H2.
    destruct fuel; simpl in *; try some_none.
    break_match_hyp; try some_none; repeat some_inv; try inl_inr.
    rename Heqo into D1, Heqs0 into D2.
    inl_inr_inv. rewrite <- H. clear m' H.
    remember (memory_next_key m) as k'.

    destruct(Nat.eq_dec k k') as [E|NE].
    +
      break_match; [inversion D1 |].
      subst.
      split; intros H.
      *
        contradict H.
        apply mem_block_exists_memory_next_key.
      *
        contradict H.
        apply mem_block_exists_memory_remove.
    +
      break_match; [inversion D1 |].
      subst.
      rename Heqo0 into D2.
      apply Option_equiv_eq in D1.
      apply Option_equiv_eq in D2.
      apply MS2 with (k:=k) in D2.
      apply MS1 with (k:=k) in D1.
      clear MS1 MS2.
      split; intros H.
      *
        eapply mem_block_exists_memory_set in H.
        apply D2 in H.
        apply D1 in H.
        erewrite <- mem_block_exists_memory_remove_neq; eauto.
      *
        eapply mem_block_exists_memory_set_neq.
        eauto.
        eapply D2.
        eapply D1.
        eapply mem_block_exists_memory_remove_neq; eauto.
  -
    (* mem_write_safe *)
    intros σ m0 m4 fuel H y_i y_sz H0.
    destruct fuel; simpl in *; try some_none.
    repeat break_match_hyp;
      try some_none; repeat some_inv; try inl_inr; repeat inl_inr_inv.
    destruct fuel; simpl in *; try some_none.
    repeat break_match_hyp;
      try some_none; repeat some_inv; try inl_inr; repeat inl_inr_inv.
    subst.
    rename m1 into m2, m into m3.
    rename Heqo into E1, Heqo0 into E2.
    remember (memory_next_key m0) as t_i.
    remember (memory_set m0 t_i mem_empty) as m1.
    remember ((DSHPtrVal t_i n,false) :: σ) as σ'.
    intros k ky.


    destruct (Nat.eq_dec k t_i) as [kt|kt].
    1:{

      subst k.
      pose proof (mem_block_exists_memory_next_key m0) as H1.
      rewrite <- Heqt_i in H1.

      unfold mem_block_exists in H1.
      apply NP.F.not_find_in_iff in H1.
      unfold memory_lookup.
      rewrite_clear H1.
      symmetry.

      pose proof (mem_block_exists_memory_remove t_i m3) as H4.
      unfold mem_block_exists in H4.
      apply NP.F.not_find_in_iff in H4.
      unfold equiv, NM_Equiv in H.
      rewrite <- H.
      rewrite H4.
      reflexivity.
    }

    destruct P1 as [P1p P1w].
    destruct P2 as [P2p P2w].
    apply Option_equiv_eq in E1.
    apply Option_equiv_eq in E2.
    specialize (P1p _ _ _ _ E1).
    specialize (P1w _ _ _ _ E1).
    specialize (P2p _ _ _ _ E2).
    specialize (P2w _ _ _ _ E2).

    destruct(decidable_mem_block_exists k m0) as [F0|NF0]; symmetry.
    2:{

      assert(¬ mem_block_exists k m1) as NF1.
      {
        revert NF0.
        apply not_iff_compat.
        subst m1.
        symmetry.
        apply mem_block_exists_memory_set_neq.
        apply kt.
      }

      specialize (P2p k).
      apply not_iff_compat in P2p.
      apply P2p in NF1.

      specialize (P1p k).
      apply not_iff_compat in P1p.
      apply P1p in NF1.

      assert(¬ mem_block_exists k m4) as NF4.
      {
        rewrite <- H.
        erewrite <- mem_block_exists_memory_remove_neq; eauto.
      }

      unfold mem_block_exists in NF4.
      apply NP.F.not_find_in_iff in NF4.
      unfold memory_lookup.
      rewrite NF4.

      unfold mem_block_exists in NF0.
      apply NP.F.not_find_in_iff in NF0.
      rewrite NF0.
      reflexivity.
    }

    pose proof F0 as V.
    apply NP.F.in_find_iff, is_Some_ne_None, is_Some_def in V.
    destruct V as [v V].
    unfold memory_lookup.
    rewrite V.

    cut(NM.find (elt:=mem_block) k m3 = Some v).
    intros F3.
    unfold equiv, NM_Equiv in H.
    rewrite <- H.
    unfold memory_remove.
    rewrite NP.F.remove_neq_o; auto.

    cut(NM.find (elt:=mem_block) k m2 = Some v).
    intros F2.
    unfold memory_equiv_except, memory_lookup in P1w.
    specialize (P1w y_i y_sz).
    erewrite <- P1w; auto.
    subst σ'.
    rewrite evalPExpr_incrPVar.
    assumption.

    cut(NM.find (elt:=mem_block) k m1 = Some v).
    intros F1.
    unfold memory_equiv_except, memory_lookup in P2w.
    specialize (P2w t_i n).
    erewrite <- P2w; auto.
    subst σ'.
    repeat constructor.
    rewrite Heqm1.
    unfold memory_set.
    rewrite NP.F.add_neq_o by congruence.
    rewrite V; reflexivity.
Qed.

Lemma lookup_PExpr_size
      (σ : evalContext)
      (p : PExpr)
      (m : memory)
      (id : nat)
      (sz : nat)
      (mb : mem_block) :
  evalPExpr σ p = inr (id, sz) ->
  lookup_PExpr σ m p = inr mb ->
  lookup_PExpr_wsize σ m p = inr (mb, sz).
Proof.
  intros.
  unfold lookup_PExpr, lookup_PExpr_wsize in *.
  cbn in *.
  repeat break_match; try inl_inr; repeat inl_inr_inv.
  tuple_inversion_equiv.
  subst; subst_nat.
  repeat constructor.
  rewrite H0.
  reflexivity.
Qed.

Lemma lookup_PExpr_size'
      (σ : evalContext)
      (p : PExpr)
      (m m' : memory)
      (sz : nat)
      (mb mb' : mem_block) :
  lookup_PExpr_wsize σ m' p = inr (mb', sz) ->
  lookup_PExpr σ m p = inr mb ->
  lookup_PExpr_wsize σ m p = inr (mb, sz).
Proof.
  intros.
  unfold lookup_PExpr, lookup_PExpr_wsize in *.
  cbn in *.
  repeat break_match; try inl_inr; repeat inl_inr_inv.
  tuple_inversion_equiv.
  subst; subst_nat.
  repeat constructor.
  rewrite H0.
  reflexivity.
Qed.

Lemma lookup_PExpr_size_invariant
      (σ : evalContext)
      (p : PExpr)
      (m : memory)
      (sz sz' : nat)
      (mb mb' : mem_block) :
  lookup_PExpr_wsize σ m p = inr (mb, sz) ->
  forall m', lookup_PExpr_wsize σ m' p = inr (mb', sz') ->
        sz ≡ sz'.
Proof.
  intros.
  unfold lookup_PExpr_wsize in *.
  cbn in *.
  repeat break_match; try inl_inr.
  repeat inl_inr_inv; tuple_inversion_equiv.
  subst_nat; subst.
  reflexivity.
Qed.

Lemma lookup_PExpr_size_invariant'
      (σ : evalContext)
      (p : PExpr)
      (sz sz' : nat)
      (id : nat)
      (mb : mem_block) :
  evalPExpr σ p = inr (id, sz) ->
  forall m, lookup_PExpr_wsize σ m p = inr (mb, sz') ->
        sz ≡ sz'.
Proof.
  intros.
  unfold lookup_PExpr_wsize in *.
  cbn in *.
  repeat break_match; try inl_inr.
  repeat inl_inr_inv; tuple_inversion_equiv.
  subst_nat; subst.
  reflexivity.
Qed.

Global Instance Compose_MSH_DSH_compat
         {i1 o2 o3: nat}
         {mop1: @MSHOperator o2 o3}
         {mop2: @MSHOperator i1 o2}
         {σ: evalContext}
         {m: memory}
         {dop1 dop2: DSHOperator}
         {x_p y_p: PExpr}
         (P: DSH_pure (DSHAlloc o2 (DSHSeq dop2 dop1)) y_p)
         (P2: DSH_pure dop2 (PVar 0))
         (P1: DSH_pure dop1 (incrPVar 0 y_p))
         (C2: @MSH_DSH_compat _ _ mop2 dop2
                              ((DSHPtrVal (memory_next_key m) o2,false) :: σ)
                              (memory_set m (memory_next_key m) mem_empty)
                              (incrPVar 0 x_p) (PVar 0)
                              P2
         )
         (C1: forall m'' mbt, m'' = memory_set m (memory_next_key m) mbt ->
                      @MSH_DSH_compat _ _ mop1 dop1
                                     ((DSHPtrVal (memory_next_key m) o2,false) :: σ)
                                     m''
                                     (PVar 0) (incrPVar 0 y_p) P1)
  :
    @MSH_DSH_compat _ _
      (MSHCompose mop1 mop2)
      (DSHAlloc o2 (DSHSeq dop2 dop1))
      σ m x_p y_p P.
Proof.
  (* TODO: (refactoring proof)
     [full_autospecialize] and [assert (_ <> _)] blocks are C-c C-v *)
  split.
  intros mx mb MX MB.
  simpl.

  remember (memory_next_key m) as t_i.
  remember ((DSHPtrVal t_i o2,false) :: σ) as σ'.
  remember (memory_set m t_i mem_empty) as m'.

  destruct (option_compose (mem_op mop1) (mem_op mop2) mx) as [md|] eqn:MD;
    repeat break_match;
    try some_none; repeat some_inv;
    try inl_inr; repeat inl_inr_inv;
    repeat constructor.
  all: copy_apply lookup_PExpr_wsize_OK_no_size MX; rename MX into MX_SZ, H into MX.
  all: copy_apply lookup_PExpr_wsize_OK_no_size MB; rename MB into MB_SZ, H into MB.
  -
    exfalso.
    unfold lookup_PExpr in *.
    simpl in MX, MB.
    repeat break_match_hyp; try some_none; repeat some_inv; try inl_inr.
    rename n1 into x_i, n into y_i.
    rename Heqo0 into E2.
    rewrite evalDSHOperator_estimateFuel_ge in E2 by lia.

    assert(t_i ≢ y_i).
    {
      destruct (Nat.eq_dec t_i y_i); auto.
      subst.
      exfalso.
      contradict MB.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      intro C.
      inversion C.
    }

    assert(t_i ≢ x_i).
    {
      destruct (Nat.eq_dec t_i x_i); auto.
      subst.
      exfalso.
      contradict MX.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      intro C.
      inversion C.
    }

    unfold memory_lookup, memory_remove.

    assert(mem_block_exists y_i m) as EY.
    {
      clear - MB.
      apply mem_block_exists_exists_equiv.
      unfold memory_lookup_err, trywith in MB.
      break_match; try inl_inr.
      exists m0; reflexivity.
      inversion MB.
    }

    assert(mem_block_exists y_i m') as EY'.
    {
      subst m'.
      apply mem_block_exists_memory_set.
      eauto.
    }

    unfold option_compose in MD.
    destruct (mem_op mop2 mx) as [mt|] eqn:MT; try some_none.

    destruct C2 as [C2].
    specialize (C2 mx (mem_empty)).

    assert(MX': lookup_PExpr_wsize σ' m' (incrPVar 0 x_p) = inr (mx, i1)).
    {
      rewrite Heqσ'.
      rewrite lookup_PExpr_wsize_incrPVar.
      unfold lookup_PExpr_wsize.
      simpl.
      rewrite Heqs1.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_neq_o.
      unfold memory_lookup_err, memory_lookup in MX.
      break_match; try inl_inr.
      inversion MX.
      constructor.
      constructor.
      assumption.
      cbn.
      subst_nat; subst.
      unfold lookup_PExpr_wsize in MX_SZ.
      rewrite Heqs1 in MX_SZ.
      cbn in MX_SZ.
      break_match; try inl_inr; repeat inl_inr_inv.
      tuple_inversion_equiv; subst_nat.
      reflexivity.
      assumption.
    }
    specialize (C2 MX').

    assert(MT': lookup_PExpr_wsize σ' m' (PVar 0) = inr (mem_empty, o2)).
    {
      rewrite Heqσ'.
      unfold lookup_PExpr_wsize.
      cbn.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_eq_o; reflexivity.
    }
    specialize (C2 MT').

    rewrite E2 in C2.
    rewrite MT in C2.
    inversion C2.
  -
    exfalso.
    rename m0 into m''.
    unfold lookup_PExpr in *.
    simpl in MX, MB.
    repeat break_match_hyp; try some_none; repeat some_inv; try inl_inr.
    rename n1 into x_i, n into y_i.
    rename Heqo0 into E2, Heqo into E1.
    rewrite evalDSHOperator_estimateFuel_ge in E1 by lia.
    rewrite evalDSHOperator_estimateFuel_ge in E2 by lia.

    assert(t_i ≢ y_i).
    {
      destruct (Nat.eq_dec t_i y_i); auto.
      subst.
      exfalso.
      contradict MB.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      intro C.
      inversion C.
    }

    assert(t_i ≢ x_i).
    {
      destruct (Nat.eq_dec t_i x_i); auto.
      subst.
      exfalso.
      contradict MX.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      intro C.
      inversion C.
    }

    assert(mem_block_exists y_i m) as EY.
    {
      clear - MB.
      apply mem_block_exists_exists_equiv.
      unfold memory_lookup_err, trywith in MB.
      break_match; try inl_inr.
      exists m0; reflexivity.
      inversion MB.
    }

    assert(mem_block_exists y_i m') as EY'.
    {
      subst m'.
      apply mem_block_exists_memory_set.
      eauto.
    }

    assert(mem_block_exists y_i m'') as EY''.
    {
      destruct P2.
      eapply (mem_stable0  _ m' m'').
      apply Option_equiv_eq in E2.
      eapply E2.
      assumption.
    }

    unfold option_compose in MD.
    destruct (mem_op mop2 mx) as [mt|] eqn:MT; try some_none.

    destruct C2 as [C2].
    specialize (C2 mx (mem_empty)).

    assert(MX': lookup_PExpr_wsize σ' m' (incrPVar 0 x_p) = inr (mx, i1)).
    {
      rewrite Heqσ'.
      rewrite lookup_PExpr_wsize_incrPVar.
      unfold lookup_PExpr_wsize.
      simpl.
      rewrite Heqs3.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_neq_o.
      unfold memory_lookup_err, memory_lookup in MX.
      break_match; try inl_inr.
      inversion MX.
      constructor.
      constructor.
      assumption.
      cbn.
      subst_nat; subst.
      unfold lookup_PExpr_wsize in MX_SZ.
      rewrite Heqs3 in MX_SZ.
      cbn in MX_SZ.
      break_match; try inl_inr; repeat inl_inr_inv.
      tuple_inversion_equiv; subst_nat.
      reflexivity.
      assumption.
    }
    specialize (C2 MX').

    assert(MT': lookup_PExpr_wsize σ' m' (PVar 0) = inr (mem_empty, o2)).
    {
      rewrite Heqσ'.
      unfold lookup_PExpr_wsize.
      cbn.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_eq_o; reflexivity.
    }
    specialize (C2 MT').

    rewrite E2 in C2.
    rewrite MT in C2.
    inversion C2; subst a b; clear C2; rename H3 into C2.

    assert(mem_block_exists t_i m') as ET'.
    {
      subst m'.
      apply mem_block_exists_memory_set_eq.
      reflexivity.
    }

    assert(mem_block_exists t_i m'') as ET''.
    {
      destruct P2.
      eapply (mem_stable0  _ m' m'').
      apply Option_equiv_eq in E2.
      eapply E2.
      assumption.
    }

    inversion C2 as [mt' HC2 MT'']; clear C2; rename HC2 into C2.
    symmetry in MT''.

    apply SHCOL_DSHCOL_mem_block_equiv_mem_empty in C2.
    apply err_equiv_eq in MT''.
    rewrite C2 in MT''.
    clear C2 mt'.

    specialize (C1 m'').
    copy_apply mem_block_exists_exists ET''.
    destruct H1 as [m''_t M''T].
    specialize (C1 m''_t).
    destruct C1 as [C1].
    1:{
      rewrite <-memory_set_overwrite with (k:=t_i) (mb:=mem_empty)
        by reflexivity.
      rewrite <-Heqm'.
      intros k.
      destruct (Nat.eq_dec t_i k).
      -
        subst.
        unfold memory_set.
        erewrite NP.F.add_eq_o by reflexivity.
        now rewrite <-M''T.
      -
        unfold memory_set.
        erewrite NP.F.add_neq_o by assumption.
        inversion P2 as [_ S].
        apply Option_equiv_eq in E2.
        subst σ'.
        eapply S in E2; [| cbn; reflexivity].
        unfold memory_equiv_except, memory_lookup in E2.
        rewrite E2; auto.
    }

    specialize (C1 mt mb).
    full_autospecialize C1.
    {
      eapply lookup_PExpr_size.
      subst σ'.
      cbn.
      reflexivity.
      assumption.
    }
    {
      subst σ'.
      rewrite lookup_PExpr_wsize_incrPVar.
      eapply lookup_PExpr_size.
      replace o3 with n0 in * by
          (eapply lookup_PExpr_size_invariant';
           [rewrite Heqs1; reflexivity | eassumption]).
      rewrite Heqs1; reflexivity.
      unfold lookup_PExpr.
      simpl.
      rewrite Heqs1.

      destruct P2 as [_ mem_write_safe2].
      apply Option_equiv_eq in E2.
      specialize (mem_write_safe2 _ _ _ _ E2).

      assert(TS: evalPExpr ((DSHPtrVal t_i o2,false) :: σ) (PVar 0) = inr (t_i, o2))
        by reflexivity.
      specialize (mem_write_safe2 _ _ TS).

      assert(MB': memory_lookup m' y_i = Some mb).
      {
        assert (memory_lookup m y_i = Some mb).
        {
         clear - MB.
         unfold memory_lookup_err, trywith in MB.
         break_match; inversion MB.
         rewrite H1; reflexivity.
        }

        rewrite <-H1.
        subst m'.
        unfold memory_lookup, memory_set.
        rewrite NP.F.add_neq_o.
        reflexivity.
        assumption.
      }

      enough (T : memory_lookup m'' y_i = Some mb)
        by (unfold memory_lookup_err; rewrite T; reflexivity).
      rewrite <- MB'.
      symmetry.
      apply mem_write_safe2.
      auto.
    }

    rewrite MD, E1 in C1.

    inversion C1.
  -
    rename m1 into m''.
    rename m0 into m'''.
    unfold lookup_PExpr in *.
    simpl in MX, MB.
    repeat break_match_hyp; try some_none; repeat some_inv; try inl_inr.
    simpl.
    rename n1 into x_i, n into y_i.
    rename Heqo0 into E2, Heqo into E1.
    rewrite evalDSHOperator_estimateFuel_ge in E1 by lia.
    rewrite evalDSHOperator_estimateFuel_ge in E2 by lia.

    assert(t_i ≢ y_i).
    {
      destruct (Nat.eq_dec t_i y_i); auto.
      subst.
      exfalso.
      contradict MB.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      cbn.
      intros C; inl_inr.
    }

    assert(t_i ≢ x_i).
    {
      destruct (Nat.eq_dec t_i x_i); auto.
      subst.
      exfalso.
      contradict MX.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      cbn.
      intros C; inl_inr.
    }

    unfold memory_lookup_err, memory_lookup, memory_remove.
    rewrite NP.F.remove_neq_o by assumption.

    assert(mem_block_exists y_i m) as EY.
    {
      apply mem_block_exists_exists_equiv.
      eexists.
      unfold memory_lookup_err, trywith in MB.
      break_match_hyp; inversion MB.
      constructor.
      apply H3.
    }

    assert(mem_block_exists y_i m') as EY'.
    {
      subst m'.
      apply mem_block_exists_memory_set.
      eauto.
    }

    assert(mem_block_exists y_i m'') as EY''.
    {
      destruct P2.
      eapply (mem_stable0  _ m' m'').
      apply Option_equiv_eq in E2.
      eapply E2.
      assumption.
    }

    assert(mem_block_exists y_i m''') as EY'''.
    {
      destruct P1.
      eapply (mem_stable0  _ m'' m''').
      apply Option_equiv_eq in E1.
      eapply E1.
      assumption.
    }

    destruct (NM.find (elt:=mem_block) y_i m''') as [ma|] eqn:MA .
    2:{
      apply memory_is_set_is_Some, is_Some_ne_None in EY'''.
      unfold memory_lookup in EY'''.
      congruence.
    }
    constructor.
    unfold SHCOL_DSHCOL_mem_block_equiv.
    intros k.

    unfold option_compose in MD.
    destruct (mem_op mop2 mx) as [mt|] eqn:MT; try some_none.

    destruct C2 as [C2].
    specialize (C2 mx (mem_empty)).

    full_autospecialize C2.
    {
      subst σ'.
      rewrite lookup_PExpr_wsize_incrPVar.
      rewrite <-MX_SZ.
      unfold lookup_PExpr_wsize.
      simpl.
      rewrite Heqs3.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_neq_o by assumption.
      reflexivity.
    }
    {
      subst σ'.
      cbn.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_eq_o by reflexivity.
      reflexivity.
    }

    rewrite E2 in C2.
    rewrite MT in C2.
    inversion C2; subst a b; clear C2 ; rename H3 into C2.

    assert(mem_block_exists t_i m') as ET'.
    {
      subst m'.
      apply mem_block_exists_memory_set_eq.
      reflexivity.
    }

    assert(mem_block_exists t_i m'') as ET''.
    {
      destruct P2.
      eapply (mem_stable0  _ m' m'').
      apply Option_equiv_eq in E2.
      eapply E2.
      assumption.
    }

    inversion C2 as [mt' HC2 MT'']; clear C2; rename HC2 into C2.
    symmetry in MT''.

    apply SHCOL_DSHCOL_mem_block_equiv_mem_empty in C2.
    apply err_equiv_eq in MT''.
    rewrite C2 in MT''.
    clear C2 mt'.

    specialize (C1 m'').
    copy_apply mem_block_exists_exists ET''.
    destruct H1 as [m''_t M''T].
    specialize (C1 m''_t).
    destruct C1 as [C1].
    1:{
      rewrite <-memory_set_overwrite with (k:=t_i) (mb:=mem_empty)
        by reflexivity.
      rewrite <-Heqm'.
      intros i.
      destruct (Nat.eq_dec t_i i).
      -
        subst.
        unfold memory_set.
        erewrite NP.F.add_eq_o by reflexivity.
        now rewrite <-M''T.
      -
        unfold memory_set.
        erewrite NP.F.add_neq_o by assumption.
        inversion P2 as [_ S].
        apply Option_equiv_eq in E2.
        subst σ'.
        eapply S in E2; [| cbn; reflexivity].
        unfold memory_equiv_except, memory_lookup in E2.
        rewrite E2; auto.
    }

    specialize (C1 mt mb).
    full_autospecialize C1.
    {
      eapply lookup_PExpr_size.
      subst σ'.
      cbn.
      reflexivity.
      assumption.
    }
    {
      subst σ'.
      rewrite lookup_PExpr_wsize_incrPVar.
      unfold lookup_PExpr_wsize.
      rewrite Heqs2.
      cbn.

      destruct P2 as [_ mem_write_safe2].
      apply Option_equiv_eq in E2.
      specialize (mem_write_safe2 _ _ _ _ E2).

      assert(TS: evalPExpr ((DSHPtrVal t_i o2,false) :: σ) (PVar 0) = inr (t_i, o2))
        by reflexivity.
      specialize (mem_write_safe2 _ _ TS).

      assert(MB': memory_lookup m' y_i = Some mb).
      {
        unfold memory_lookup_err, trywith in MB.
        break_match_hyp; inversion MB; subst.
        rewrite <-H3.
        rewrite <-Heqo.
        unfold memory_lookup, memory_set.
        rewrite NP.F.add_neq_o.
        reflexivity.
        assumption.
      }

      unfold memory_lookup_err, trywith.
      assert (T : memory_lookup m'' y_i = Some mb).
      {
        rewrite <- MB'.
        symmetry.
        apply mem_write_safe2.
        auto.
      }
      repeat break_match; try some_none; try inl_inr.
      some_inv; inl_inr_inv.
      repeat constructor.
      rewrite <-H2; assumption.
      cbn.
      eapply lookup_PExpr_size_invariant'.
      rewrite Heqs2; reflexivity.
      eassumption.
    }

    rewrite MD, E1 in C1.

    inversion C1 as [ | | ab bm HC1 HA HB];
      clear C1; rename HC1 into C1;
        subst ab; subst bm.

    assert(MA''': lookup_PExpr σ' m''' (incrPVar 0 y_p) = inr ma).
    {
      subst σ'.
      unfold lookup_PExpr.
      rewrite evalPExpr_incrPVar.
      simpl.
      rewrite Heqs2.
      unfold memory_lookup_err.
      enough (T : memory_lookup m''' y_i = Some ma) by (rewrite T; reflexivity).
      unfold memory_lookup.
      rewrite MA.
      reflexivity.
    }

    rewrite MA''' in C1.
    inversion C1.
    auto.
  -
    exfalso.
    rename m0 into m''.
    unfold lookup_PExpr in *.
    simpl in MX, MB.
    repeat break_match_hyp; try some_none; repeat some_inv; try inl_inr.
    rename n1 into x_i, n into y_i.
    rename Heqo0 into E2, Heqo into E1.
    rewrite evalDSHOperator_estimateFuel_ge in E1 by lia.
    rewrite evalDSHOperator_estimateFuel_ge in E2 by lia.

    assert(t_i ≢ y_i).
    {
      destruct (Nat.eq_dec t_i y_i); auto.
      subst.
      exfalso.
      contradict MB.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      intro C.
      inversion C.
    }

    assert(t_i ≢ x_i).
    {
      destruct (Nat.eq_dec t_i x_i); auto.
      subst.
      exfalso.
      contradict MX.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      intro C.
      inversion C.
    }

    assert(mem_block_exists y_i m) as EY.
    {
      clear - MB.
      apply mem_block_exists_exists_equiv.
      unfold memory_lookup_err, trywith in MB.
      break_match; try inl_inr.
      exists m0; reflexivity.
      inversion MB.
    }

    assert(mem_block_exists y_i m') as EY'.
    {
      subst m'.
      apply mem_block_exists_memory_set.
      eauto.
    }

    assert(mem_block_exists y_i m'') as EY''.
    {
      destruct P2.
      eapply (mem_stable0  _ m' m'').
      apply Option_equiv_eq in E2.
      eapply E2.
      assumption.
    }

    unfold option_compose in MD.
    destruct (mem_op mop2 mx) as [mt|] eqn:MT; try some_none.

    destruct C2 as [C2].
    specialize (C2 mx (mem_empty)).

    full_autospecialize C2.
    {
      subst σ'.
      rewrite lookup_PExpr_wsize_incrPVar.
      rewrite <-MX_SZ.
      unfold lookup_PExpr_wsize.
      simpl.
      rewrite Heqs2.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_neq_o by assumption.
      reflexivity.
    }
    {
      subst σ'.
      cbn.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_eq_o by reflexivity.
      reflexivity.
    }

    rewrite E2 in C2.
    rewrite MT in C2.
    inversion C2; subst a b; clear C2; rename H3 into C2.

    assert(mem_block_exists t_i m') as ET'.
    {
      subst m'.
      apply mem_block_exists_memory_set_eq.
      reflexivity.
    }

    assert(mem_block_exists t_i m'') as ET''.
    {
      destruct P2.
      eapply (mem_stable0  _ m' m'').
      apply Option_equiv_eq in E2.
      eapply E2.
      assumption.
    }

    inversion C2 as [mt' HC2 MT'']; clear C2; rename HC2 into C2.
    symmetry in MT''.

    apply SHCOL_DSHCOL_mem_block_equiv_mem_empty in C2.
    apply err_equiv_eq in MT''.
    rewrite C2 in MT''.
    clear C2 mt'.

    specialize (C1 m'').
    copy_apply mem_block_exists_exists ET''.
    destruct H1 as [m''_t M''T].
    specialize (C1 m''_t).
    destruct C1 as [C1].
    1:{
      rewrite <-memory_set_overwrite with (k:=t_i) (mb:=mem_empty)
        by reflexivity.
      rewrite <-Heqm'.
      intros i.
      destruct (Nat.eq_dec t_i i).
      -
        subst.
        unfold memory_set.
        erewrite NP.F.add_eq_o by reflexivity.
        now rewrite <-M''T.
      -
        unfold memory_set.
        erewrite NP.F.add_neq_o by assumption.
        inversion P2 as [_ S].
        apply Option_equiv_eq in E2.
        subst σ'.
        eapply S in E2; [| cbn; reflexivity].
        unfold memory_equiv_except, memory_lookup in E2.
        rewrite E2; auto.
    }

    specialize (C1 mt mb).
    full_autospecialize C1.
    {
      eapply lookup_PExpr_size.
      subst σ'.
      cbn.
      reflexivity.
      assumption.
    }
    {
      subst σ'.
      rewrite lookup_PExpr_wsize_incrPVar.
      eapply lookup_PExpr_size.
      replace o3 with n0 in * by
          (eapply lookup_PExpr_size_invariant';
           [rewrite Heqs1; reflexivity | eassumption]).
      rewrite Heqs1; reflexivity.
      unfold lookup_PExpr.
      simpl.
      rewrite Heqs1.

      destruct P2 as [_ mem_write_safe2].
      apply Option_equiv_eq in E2.
      specialize (mem_write_safe2 _ _ _ _ E2).

      assert(TS: evalPExpr ((DSHPtrVal t_i o2,false) :: σ) (PVar 0) = inr (t_i, o2))
        by reflexivity.
      specialize (mem_write_safe2 _ _ TS).

      assert(MB': memory_lookup m' y_i = Some mb).
      {
        assert (memory_lookup m y_i = Some mb).
        {
         clear - MB.
         unfold memory_lookup_err, trywith in MB.
         break_match; inversion MB.
         rewrite H1; reflexivity.
        }

        rewrite <-H1.
        subst m'.
        unfold memory_lookup, memory_set.
        rewrite NP.F.add_neq_o.
        reflexivity.
        assumption.
      }

      enough (T : memory_lookup m'' y_i = Some mb)
        by (unfold memory_lookup_err; rewrite T; reflexivity).
      rewrite <- MB'.
      symmetry.
      apply mem_write_safe2.
      auto.
    }

    rewrite MD, E1 in C1.
    inversion C1.
  -
    exfalso.
    unfold lookup_PExpr in *.
    simpl in MX, MB.
    repeat break_match_hyp; try some_none; repeat some_inv; try inl_inr.
    rename n1 into x_i, n into y_i.
    clear Heqo.
    rename Heqo0 into E2.
    rewrite evalDSHOperator_estimateFuel_ge in E2 by lia.

    assert(t_i ≢ y_i).
    {
      destruct (Nat.eq_dec t_i y_i); auto.
      subst.
      exfalso.
      contradict MB.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      intro C.
      inversion C.
    }

    assert(t_i ≢ x_i).
    {
      destruct (Nat.eq_dec t_i x_i); auto.
      subst.
      exfalso.
      contradict MX.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      intro C.
      inversion C.
    }

    unfold memory_lookup, memory_remove.

    assert(mem_block_exists y_i m) as EY.
    {
      clear - MB.
      apply mem_block_exists_exists_equiv.
      unfold memory_lookup_err, trywith in MB.
      break_match; try inl_inr.
      exists m0; reflexivity.
      inversion MB.
    }

    assert(mem_block_exists y_i m') as EY'.
    {
      subst m'.
      apply mem_block_exists_memory_set.
      eauto.
    }

    unfold option_compose in MD.
    destruct (mem_op mop2 mx) as [mt|] eqn:MT; try some_none.

    destruct C2 as [C2].
    specialize (C2 mx (mem_empty)).

    full_autospecialize C2.
    {
      subst σ'.
      rewrite lookup_PExpr_wsize_incrPVar.
      rewrite <-MX_SZ.
      unfold lookup_PExpr_wsize.
      simpl.
      rewrite Heqs0.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_neq_o by assumption.
      reflexivity.
    }
    {
      subst σ'.
      cbn.
      subst m'.
      unfold memory_lookup_err, memory_lookup, memory_set.
      rewrite NP.F.add_eq_o by reflexivity.
      reflexivity.
    }

    rewrite E2 in C2.
    rewrite MT in C2.
    inversion C2.
  -
    exfalso.
    rename m1 into m''.
    rename m0 into m'''.
    unfold lookup_PExpr in *.
    simpl in MX, MB.
    repeat break_match_hyp; try some_none; repeat some_inv; try inl_inr.
    rename n1 into x_i, n into y_i.
    rename Heqo0 into E2, Heqo into E1.
    rewrite evalDSHOperator_estimateFuel_ge in E1 by lia.
    rewrite evalDSHOperator_estimateFuel_ge in E2 by lia.

    assert(t_i ≢ y_i).
    {
      destruct (Nat.eq_dec t_i y_i); auto.
      subst.
      exfalso.
      contradict MB.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      cbn.
      intros C; inl_inr.
    }

    assert(t_i ≢ x_i).
    {
      destruct (Nat.eq_dec t_i x_i); auto.
      subst.
      exfalso.
      contradict MX.
      pose proof (memory_lookup_memory_next_key_is_None m) as F.
      apply is_None_def in F.
      unfold memory_lookup_err.
      rewrite F.
      cbn.
      intros C; inl_inr.
    }

    assert(mem_block_exists y_i m) as EY.
    {
      clear - MB.
      apply mem_block_exists_exists_equiv.
      unfold memory_lookup_err, trywith in MB.
      break_match; try inl_inr.
      exists m0; reflexivity.
      inversion MB.
    }

    assert(mem_block_exists y_i m') as EY'.
    {
      subst m'.
      apply mem_block_exists_memory_set.
      eauto.
    }

    assert(mem_block_exists y_i m'') as EY''.
    {
      destruct P2.
      eapply (mem_stable0  _ m' m'').
      apply Option_equiv_eq in E2.
      eapply E2.
      assumption.
    }

    assert(mem_block_exists y_i m''') as EY'''.
    {
      destruct P1.
      eapply (mem_stable0  _ m'' m''').
      apply Option_equiv_eq in E1.
      eapply E1.
      assumption.
    }

    destruct (NM.find (elt:=mem_block) y_i m''') as [ma|] eqn:MA .
    2:{
      apply memory_is_set_is_Some, is_Some_ne_None in EY'''.
      unfold memory_lookup in EY'''.
      congruence.
    }

    destruct C2 as [C2].
    specialize (C2 mx (mem_empty)).

    unfold option_compose in MD.

    destruct (mem_op mop2 mx) as [mt|] eqn:MT; try some_none.
    +
      (* mop2 = Some, mop1 = None *)
      full_autospecialize C2.
      {
        subst σ'.
        rewrite lookup_PExpr_wsize_incrPVar.
        rewrite <-MX_SZ.
        unfold lookup_PExpr_wsize.
        simpl.
        rewrite Heqs3.
        subst m'.
        unfold memory_lookup_err, memory_lookup, memory_set.
        rewrite NP.F.add_neq_o by assumption.
        reflexivity.
      }
      {
        subst σ'.
        cbn.
        subst m'.
        unfold memory_lookup_err, memory_lookup, memory_set.
        rewrite NP.F.add_eq_o by reflexivity.
        reflexivity.
      }

      rewrite E2 in C2.
      inversion C2; subst a b; clear C2; rename H3 into C2.

      assert(mem_block_exists t_i m') as ET'.
      {
        subst m'.
        apply mem_block_exists_memory_set_eq.
        reflexivity.
      }

      assert(mem_block_exists t_i m'') as ET''.
      {
        destruct P2.
        eapply (mem_stable0  _ m' m'').
        apply Option_equiv_eq in E2.
        eapply E2.
        assumption.
      }

      inversion C2 as [mt' HC2 MT'']; clear C2; rename HC2 into C2.
      symmetry in MT''.

      apply SHCOL_DSHCOL_mem_block_equiv_mem_empty in C2.
      apply err_equiv_eq in MT''.
      rewrite C2 in MT''.
      clear C2 mt'.

      specialize (C1 m'').
      copy_apply mem_block_exists_exists ET''.
      destruct H1 as [m''_t M''T].
      specialize (C1 m''_t).
      destruct C1 as [C1].
      1:{
        rewrite <-memory_set_overwrite with (k:=t_i) (mb:=mem_empty)
          by reflexivity.
        rewrite <-Heqm'.
        intros i.
        destruct (Nat.eq_dec t_i i).
        -
          subst.
          unfold memory_set.
          erewrite NP.F.add_eq_o by reflexivity.
          now rewrite <-M''T.
        -
          unfold memory_set.
          erewrite NP.F.add_neq_o by assumption.
          inversion P2 as [_ S].
          apply Option_equiv_eq in E2.
          subst σ'.
          eapply S in E2; [| cbn; reflexivity].
          unfold memory_equiv_except, memory_lookup in E2.
          rewrite E2; auto.
      }

      specialize (C1 mt mb).
      full_autospecialize C1.
      {
        eapply lookup_PExpr_size.
        subst σ'.
        cbn.
        reflexivity.
        assumption.
      }
      {
        subst σ'.
        rewrite lookup_PExpr_wsize_incrPVar.
        eapply lookup_PExpr_size.
        replace o3 with n0 in * by
            (eapply lookup_PExpr_size_invariant';
             [rewrite Heqs2; reflexivity | eassumption]).
        rewrite Heqs2; reflexivity.
        unfold lookup_PExpr.
        simpl.
        rewrite Heqs2.
        
        destruct P2 as [_ mem_write_safe2].
        apply Option_equiv_eq in E2.
        specialize (mem_write_safe2 _ _ _ _ E2).
        
        assert(TS: evalPExpr ((DSHPtrVal t_i o2,false) :: σ) (PVar 0) = inr (t_i, o2))
          by reflexivity.
        specialize (mem_write_safe2 _ _ TS).
        
        assert(MB': memory_lookup m' y_i = Some mb).
        {
          assert (memory_lookup m y_i = Some mb).
          {
            clear - MB.
            unfold memory_lookup_err, trywith in MB.
            break_match; inversion MB.
            rewrite H1; reflexivity.
          }
          
          rewrite <-H1.
          subst m'.
          unfold memory_lookup, memory_set.
          rewrite NP.F.add_neq_o.
          reflexivity.
          assumption.
        }
        
        enough (T : memory_lookup m'' y_i = Some mb)
          by (unfold memory_lookup_err; rewrite T; reflexivity).
        rewrite <- MB'.
        symmetry.
        apply mem_write_safe2.
        auto.
      }
      rewrite MD, E1 in C1.

      inversion C1.
    +
      (* mop2 = None, no mop1 *)
      full_autospecialize C2.
      {
        subst σ'.
        rewrite lookup_PExpr_wsize_incrPVar.
        rewrite <-MX_SZ.
        unfold lookup_PExpr_wsize.
        simpl.
        rewrite Heqs3.
        subst m'.
        unfold memory_lookup_err, memory_lookup, memory_set.
        rewrite NP.F.add_neq_o by assumption.
        reflexivity.
      }
      {
        subst σ'.
        cbn.
        subst m'.
        unfold memory_lookup_err, memory_lookup, memory_set.
        rewrite NP.F.add_eq_o by reflexivity.
        reflexivity.
      }

      rewrite E2 in C2.
      inversion C2; subst a b; clear C2; rename H4 into C2.
Qed.



(** * MApply2Union *)

Lemma herr_f_whatev  :
  forall R a b,
    @herr_f nat nat R a b <->
    (forall ax bx, a = inr ax -> b = inr bx -> R ax bx).
Proof.
  split; intros.
  -
    destruct a, b; try inl_inr; repeat inl_inr_inv.
    cbv in H0, H1; subst.
    inversion H.
    assumption.
  -
    destruct a, b; constructor.
    apply H; reflexivity.
Qed.

Global Instance Apply2Union_MSH_DSH_compat
         {i o : nat}
         {mop1: @MSHOperator i o}
         {mop2: @MSHOperator i o}
         {m: memory}
         {σ: evalContext}
         {dop1 dop2: DSHOperator}
         {x_p y_p : PExpr}
         {dot}
         (P: DSH_pure (DSHSeq dop1 dop2) y_p)
         (D : forall x_id y_id x_sz y_sz,
             evalPExpr σ x_p = inr (x_id, x_sz) ->
             evalPExpr σ y_p = inr (y_id, y_sz) ->
             x_id <> y_id)
         (P1: DSH_pure dop1 y_p)
         (P2: DSH_pure dop2 y_p)
         (C1: @MSH_DSH_compat _ _ mop1 dop1 σ m x_p y_p P1)
         (C2: forall m', lookup_PExpr σ m x_p = lookup_PExpr σ m' x_p ->
                      @MSH_DSH_compat _ _ mop2 dop2 σ m' x_p y_p P2)
  :
    @MSH_DSH_compat _ _
      (MApply2Union dot mop1 mop2)
      (DSHSeq dop1 dop2)
      σ m x_p y_p P.
Proof.
  constructor; intros x_m y_m X_M Y_M.

  destruct (evalPExpr σ x_p) as [| (x_id, x_sz)] eqn:X;
    [unfold lookup_PExpr_wsize in X_M; rewrite X in X_M; inversion X_M |].
  destruct (evalPExpr σ y_p) as [| (y_id, y_sz)] eqn:Y;
    [unfold lookup_PExpr_wsize in Y_M; rewrite Y in Y_M; inversion Y_M |].
  assert (XY : x_id <> y_id) by (eapply D; reflexivity).

  destruct mem_op as [mma |] eqn:MOP.
  all: destruct evalDSHOperator as [r |] eqn:DOP; [destruct r as [msg | dma] |].
  all: repeat constructor.

  1,3,4: exfalso.
  -
    cbn in MOP.
    destruct (mem_op mop2 x_m) as [mma2 |] eqn:MOP2; [| some_none].
    destruct (mem_op mop1 x_m) as [mma1 |] eqn:MOP1; [| some_none].
    some_inv; subst.

    cbn in DOP.
    destruct evalDSHOperator as [r |] eqn:DOP1 in DOP; [| some_none];
      destruct r as [msg1 | dma1]; inversion DOP; subst; clear DOP.
    +
      (* make use of C1 *)
      inversion C1; clear C1; rename eval_equiv0 into C1.
      specialize (C1 x_m y_m).
      full_autospecialize C1; try assumption.

      cbn in X_M; rewrite X in X_M.
      cbn in Y_M; rewrite Y in Y_M.

      rewrite evalDSHOperator_estimateFuel_ge in DOP1 by lia.
      rewrite DOP1, MOP1 in C1.
      inversion C1.
    +
      rename H0 into DOP2.

      inversion C1; clear C1; rename eval_equiv0 into C1.
      specialize (C1 x_m y_m).
      full_autospecialize C1; try assumption.

      rewrite evalDSHOperator_estimateFuel_ge in DOP1 by lia.
      rewrite DOP1, MOP1 in C1.
      inversion C1; subst.
      inversion H1; clear C1 H1.
      rename x into y_dma1, H into Y_DMA1, H0 into C1; symmetry in Y_DMA1.

      (*
      cbn in X_M; rewrite X in X_M.
      cbn in Y_M; rewrite Y in Y_M.
      *)

      (* make use of C2 *)
      specialize (C2 dma1).
      autospecialize C2.
      {
        clear - X X_M P1 DOP1 Y XY.
        inversion P1; clear P1 mem_stable0; rename mem_write_safe0 into P1.
        eq_to_equiv_hyp.
        apply P1 with (y_i := y_id) (y_size:=y_sz) in DOP1;
          [| err_eq_to_equiv_hyp; assumption]; clear P1.
        unfold lookup_PExpr, memory_lookup_err.
        rewrite X.
        cbn.
        unfold memory_equiv_except in DOP1.
        specialize (DOP1 x_id XY).
        rewrite DOP1.
        reflexivity.
      }
      inversion C2; clear C2; rename eval_equiv0 into C2.
      specialize (C2 x_m y_dma1).
      full_autospecialize C2.
      {
        eapply lookup_PExpr_size'.
        eassumption.
        eapply lookup_PExpr_wsize_OK_no_size.
        erewrite <-X_M.
        clear - X X_M P1 DOP1 Y XY.
        inversion P1; clear P1 mem_stable0; rename mem_write_safe0 into P1.
        eq_to_equiv_hyp.
        apply P1 with (y_i := y_id) (y_size:=y_sz) in DOP1;
          [| err_eq_to_equiv_hyp; assumption]; clear P1.
        unfold lookup_PExpr_wsize, memory_lookup_err, trywith.
        rewrite X.
        cbn.
        unfold memory_equiv_except in DOP1.
        specialize (DOP1 x_id XY).
        repeat break_match; try some_none; try inl_inr.
        constructor.
        repeat constructor.
        repeat inl_inr_inv.
        rewrite <-H0, <-H1.
        some_inv.
        rewrite DOP1.
        reflexivity.
      }
      {
        eapply lookup_PExpr_size'.
        eassumption.
        rewrite Y_DMA1.
        reflexivity.
      }
      rewrite evalDSHOperator_estimateFuel_ge in DOP2 by lia.
      rewrite DOP2, MOP2 in C2.
      inversion C2.
  -
    cbn in MOP.
    destruct (mem_op mop2 x_m) as [mma2 |] eqn:MOP2; [| some_none].
    destruct (mem_op mop1 x_m) as [mma1 |] eqn:MOP1; [| some_none].
    some_inv; subst.

    cbn in DOP.
    destruct evalDSHOperator as [r |] eqn:DOP1 in DOP.
    +
      destruct r as [| dma1]; inversion DOP; subst; clear DOP.
      rename H0 into DOP2.

      (* make use of C1 *)
      inversion C1; clear C1; rename eval_equiv0 into C1.
      specialize (C1 x_m y_m).
      full_autospecialize C1; try assumption.

      rewrite evalDSHOperator_estimateFuel_ge in DOP1 by lia.
      rewrite DOP1, MOP1 in C1.
      inversion C1; subst.
      inversion H1; clear C1 H1.
      rename x into y_dma1, H into Y_DMA1, H0 into C1; symmetry in Y_DMA1.

      (* make use of C2 *)
      specialize (C2 dma1).
      autospecialize C2.
      {
        clear - X X_M P1 DOP1 Y XY.
        inversion P1; clear P1 mem_stable0; rename mem_write_safe0 into P1.
        eq_to_equiv_hyp.
        apply P1 with (y_i := y_id) (y_size:=y_sz) in DOP1;
          [| err_eq_to_equiv_hyp; assumption]; clear P1.
        unfold lookup_PExpr, memory_lookup_err.
        rewrite X.
        cbn.
        unfold memory_equiv_except in DOP1.
        specialize (DOP1 x_id XY).
        rewrite DOP1.
        reflexivity.
      }
      inversion C2; clear C2; rename eval_equiv0 into C2.
      specialize (C2 x_m y_dma1).
      full_autospecialize C2.
      {
        eapply lookup_PExpr_size'.
        eassumption.
        eapply lookup_PExpr_wsize_OK_no_size.
        erewrite <-X_M.
        clear - X X_M P1 DOP1 Y XY.
        inversion P1; clear P1 mem_stable0; rename mem_write_safe0 into P1.
        eq_to_equiv_hyp.
        apply P1 with (y_i := y_id) (y_size:=y_sz) in DOP1;
          [| err_eq_to_equiv_hyp; assumption]; clear P1.
        unfold lookup_PExpr_wsize, memory_lookup_err, trywith.
        rewrite X.
        cbn.
        unfold memory_equiv_except in DOP1.
        specialize (DOP1 x_id XY).
        repeat break_match; try some_none; try inl_inr.
        constructor.
        repeat constructor.
        repeat inl_inr_inv.
        rewrite <-H0, <-H1.
        some_inv.
        rewrite DOP1.
        reflexivity.
      }
      {
        eapply lookup_PExpr_size'.
        eassumption.
        rewrite Y_DMA1.
        reflexivity.
      }
      rewrite evalDSHOperator_estimateFuel_ge in DOP2 by lia.
      rewrite DOP2, MOP2 in C2.
      inversion C2.
    +
      clear DOP.

      (* make use of C1 *)
      inversion C1; clear C1; rename eval_equiv0 into C1.
      specialize (C1 x_m y_m).
      full_autospecialize C1; try assumption.

      rewrite evalDSHOperator_estimateFuel_ge in DOP1 by lia.
      rewrite DOP1, MOP1 in C1.
      inversion C1.
  -
    cbn in DOP.
    destruct evalDSHOperator as [r |] eqn:DOP1 in DOP; [| some_none].
    destruct r as [| dma1]; [some_inv; inl_inr |].
    rename DOP into DOP2.
    
    cbn in MOP.
    destruct (mem_op mop1 x_m) as [mma1 |] eqn:MOP1.
    +
      destruct (mem_op mop2 x_m) eqn:MOP2; [some_none |].
      clear MOP.

      (* make use of C1 *)
      inversion C1; clear C1; rename eval_equiv0 into C1.
      specialize (C1 x_m y_m).
      full_autospecialize C1; try assumption.

      rewrite evalDSHOperator_estimateFuel_ge in DOP1 by lia.
      rewrite DOP1, MOP1 in C1.
      inversion C1; subst.
      inversion H1; clear C1 H1.
      rename x into y_dma1, H into Y_DMA1, H0 into C1; symmetry in Y_DMA1.

      (* make use of C2 *)
      specialize (C2 dma1).
      autospecialize C2.
      {
        clear - X X_M P1 DOP1 Y XY.
        inversion P1; clear P1 mem_stable0; rename mem_write_safe0 into P1.
        eq_to_equiv_hyp.
        apply P1 with (y_i := y_id) (y_size:=y_sz) in DOP1;
          [| err_eq_to_equiv_hyp; assumption]; clear P1.
        unfold lookup_PExpr, memory_lookup_err.
        rewrite X.
        cbn.
        unfold memory_equiv_except in DOP1.
        specialize (DOP1 x_id XY).
        rewrite DOP1.
        reflexivity.
      }
      inversion C2; clear C2; rename eval_equiv0 into C2.
      specialize (C2 x_m y_dma1).
      full_autospecialize C2.
      {
        eapply lookup_PExpr_size'.
        eassumption.
        eapply lookup_PExpr_wsize_OK_no_size.
        erewrite <-X_M.
        clear - X X_M P1 DOP1 Y XY.
        inversion P1; clear P1 mem_stable0; rename mem_write_safe0 into P1.
        eq_to_equiv_hyp.
        apply P1 with (y_i := y_id) (y_size:=y_sz) in DOP1;
          [| err_eq_to_equiv_hyp; assumption]; clear P1.
        unfold lookup_PExpr_wsize, memory_lookup_err, trywith.
        rewrite X.
        cbn.
        unfold memory_equiv_except in DOP1.
        specialize (DOP1 x_id XY).
        repeat break_match; try some_none; try inl_inr.
        constructor.
        repeat constructor.
        repeat inl_inr_inv.
        rewrite <-H0, <-H1.
        some_inv.
        rewrite DOP1.
        reflexivity.
      }
      {
        eapply lookup_PExpr_size'.
        eassumption.
        rewrite Y_DMA1.
        reflexivity.
      }

      rewrite evalDSHOperator_estimateFuel_ge in DOP2 by lia.
      rewrite DOP2, MOP2 in C2.
      inversion C2.
    +
      clear MOP.
      
      (* make use of C1 *)
      inversion C1; clear C1; rename eval_equiv0 into C1.
      specialize (C1 x_m y_m).
      full_autospecialize C1; try assumption.
       
      rewrite evalDSHOperator_estimateFuel_ge in DOP1 by lia.
      rewrite DOP1, MOP1 in C1.
      inversion C1.
  -
    unfold lookup_PExpr; cbn.
    rewrite Y.
    unfold memory_lookup_err.
    destruct (memory_lookup dma y_id) as [y_dma |] eqn:Y_DMA.
    +
      constructor.
      unfold SHCOL_DSHCOL_mem_block_equiv.
      intro k.

      cbn in MOP.
      destruct (mem_op mop2 x_m) as [mma2 |] eqn:MOP2; [| some_none].
      destruct (mem_op mop1 x_m) as [mma1 |] eqn:MOP1; [| some_none].
      some_inv; subst.

      cbn in DOP.
      destruct evalDSHOperator as [r |] eqn:DOP1 in DOP; [| some_none].
      destruct r as [| dma1]; [some_inv; inl_inr |].
      rename DOP into DOP2.

      (* make use of C1 *)
      inversion C1; clear C1; rename eval_equiv0 into C1.
      specialize (C1 x_m y_m).
      full_autospecialize C1; try assumption.

      rewrite evalDSHOperator_estimateFuel_ge in DOP1 by lia.
      rewrite DOP1, MOP1 in C1.
      inversion C1; subst.
      inversion H1; clear C1 H1.
      rename x into y_dma1, H into Y_DMA1, H0 into C1; symmetry in Y_DMA1.

      (* make use of C2 *)
      specialize (C2 dma1).
      autospecialize C2.
      {
        clear - X X_M P1 DOP1 Y XY.
        inversion P1; clear P1 mem_stable0; rename mem_write_safe0 into P1.
        eq_to_equiv_hyp.
        apply P1 with (y_i := y_id) (y_size:=y_sz) in DOP1;
          [| err_eq_to_equiv_hyp; assumption]; clear P1.
        unfold lookup_PExpr, memory_lookup_err.
        rewrite X.
        cbn.
        unfold memory_equiv_except in DOP1.
        specialize (DOP1 x_id XY).
        rewrite DOP1.
        reflexivity.
      }
      inversion C2; clear C2; rename eval_equiv0 into C2.
      specialize (C2 x_m y_dma1).
      full_autospecialize C2.
      {
        eapply lookup_PExpr_size'.
        eassumption.
        eapply lookup_PExpr_wsize_OK_no_size.
        erewrite <-X_M.
        clear - X X_M P1 DOP1 Y XY.
        inversion P1; clear P1 mem_stable0; rename mem_write_safe0 into P1.
        eq_to_equiv_hyp.
        apply P1 with (y_i := y_id) (y_size:=y_sz) in DOP1;
          [| err_eq_to_equiv_hyp; assumption]; clear P1.
        unfold lookup_PExpr_wsize, memory_lookup_err, trywith.
        rewrite X.
        cbn.
        unfold memory_equiv_except in DOP1.
        specialize (DOP1 x_id XY).
        repeat break_match; try some_none; try inl_inr.
        constructor.
        repeat constructor.
        repeat inl_inr_inv.
        rewrite <-H0, <-H1.
        some_inv.
        rewrite DOP1.
        reflexivity.
      }
      {
        eapply lookup_PExpr_size'.
        eassumption.
        rewrite Y_DMA1.
        reflexivity.
      }

      rewrite evalDSHOperator_estimateFuel_ge in DOP2 by lia.
      rewrite DOP2, MOP2 in C2.
      inversion C2; subst.
      inversion H1; clear C2 H1.
      rename x into y_dma2, H into Y_DMA2, H0 into C2; symmetry in Y_DMA2.
      replace y_dma2 with y_dma in *.
      2: {
        clear - Y Y_DMA Y_DMA2.
        unfold lookup_PExpr, memory_lookup_err in Y_DMA2.
        rewrite Y in Y_DMA2.
        cbn in Y_DMA2.
        rewrite Y_DMA in Y_DMA2.
        inversion Y_DMA2.
        reflexivity.
      }
      clear y_dma2 Y_DMA2.

      eapply SHCOL_DSHCOL_mem_block_equiv_comp; eassumption.
    +
      exfalso.
      clear - P DOP Y Y_M Y_DMA.

      rewrite <-mem_block_not_exists_exists in Y_DMA.
      contradict Y_DMA.

      inversion P; clear mem_write_safe0; rename mem_stable0 into MS.
      apply Option_equiv_eq in DOP.
      apply MS with (k := y_id) in DOP; clear MS.

      apply DOP, mem_block_exists_exists_equiv.
      exists y_m.
      unfold lookup_PExpr_wsize in Y_M.
      rewrite Y in Y_M.
      cbn in Y_M.
      unfold memory_lookup_err, trywith in Y_M.
      repeat break_match; try inl_inr.
      repeat inl_inr_inv.
      tuple_inversion_equiv; subst_nat; subst.
      constructor.
      apply H.
Qed.



(** * MSHIReduction *)

Global Instance Seq_DSH_pure
       {dop1 dop2 : DSHOperator}
       {y_p : PExpr}
       (P1: DSH_pure dop1 y_p)
       (P2: DSH_pure dop2 y_p)
  :
    DSH_pure (DSHSeq dop1 dop2) y_p.
Proof.
  split.
  -
    intros σ m0 m2 fuel M2 k.

    destruct fuel; [inversion M2 |].
    cbn in *.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    subst.
    rename m into m1, Heqo into M1.
    eq_to_equiv_hyp.

    inversion P1; clear P1 mem_write_safe0;
      rename mem_stable0 into P1.
    apply P1 with (k:=k) in M1; clear P1.
    inversion P2; clear P2 mem_write_safe0;
      rename mem_stable0 into P2.
    apply P2 with (k:=k) in M2; clear P2.
    rewrite M1, M2.
    reflexivity.
  -
    intros σ m0 m2 fuel M2 y_i y_sz Y.

    destruct fuel; [inversion M2 |].
    cbn in *.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    subst.
    rename m into m1, Heqo into M1.
    eq_to_equiv_hyp.

    inversion P1; clear P1 mem_stable0;
      rename mem_write_safe0 into P1.
    eapply P1 with (y_i:=y_i) (y_size:=y_sz) in M1; [| assumption].
    inversion P2; clear P2 mem_stable0;
      rename mem_write_safe0 into P2.
    eapply P2 with (y_i:=y_i) (y_size:=y_sz) in M2; [| assumption].
    clear - M1 M2.
    eapply memory_equiv_except_trans; eassumption.
Qed.

Global Instance MemMap2_DSH_pure
       {x0_p x1_p y_p : PExpr}
       {n : nat}
       {a : AExpr}
  :
    DSH_pure (DSHMemMap2 n x0_p x1_p y_p a) y_p.
Proof.
  constructor.
  -
    intros.
    destruct fuel; cbn in *; try some_none.
    unfold memory_lookup_err, trywith in *.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    subst.

    rewrite <-H; clear H m'.

    split; [apply mem_block_exists_memory_set | intros].
    apply mem_block_exists_memory_set_inv in H.
    destruct H; [assumption | subst].
    apply memory_is_set_is_Some.
    rewrite Heqo.
    reflexivity.
  -
    intros.
    destruct fuel; cbn in *; try some_none.
    unfold memory_lookup_err, trywith in *.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    cbv in H0.
    subst.

    unfold memory_equiv_except; intros.
    rewrite <-H; clear H m'.
    unfold memory_lookup, memory_set.
    destruct H0.
    rewrite NP.F.add_neq_o by congruence.
    reflexivity.
Qed.

Global Instance MemInit_DSH_pure
       {y_p : PExpr}
       {init : CarrierA}
  :
    DSH_pure (DSHMemInit y_p init) y_p.
Proof.
  constructor.
  -
    intros.
    destruct fuel; cbn in *; try some_none.
    unfold memory_lookup_err, trywith in *.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    subst.

    rewrite <-H; clear H m'.

    split; [apply mem_block_exists_memory_set | intros].
    apply mem_block_exists_memory_set_inv in H.
    destruct H; [assumption | subst].
    apply memory_is_set_is_Some.
    rewrite Heqo.
    reflexivity.
  -
    intros.
    destruct fuel; cbn in *; try some_none.
    unfold memory_lookup_err, trywith in *.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    cbv in H0.
    subst.

    unfold memory_equiv_except; intros.
    rewrite <-H; clear H m'.
    unfold memory_lookup, memory_set.
    destruct H0.
    rewrite NP.F.add_neq_o by congruence.
    reflexivity.
Qed.

Global Instance IReduction_DSH_pure
       {no nn : nat}
       {y_p y_p'': PExpr}
       {init : CarrierA}
       {rr : DSHOperator}
       {df : AExpr}
       (Y: y_p'' ≡ incrPVar 0 (incrPVar 0 y_p))
       (P: DSH_pure rr (PVar 1))
  :
    DSH_pure
      (DSHSeq
         (DSHMemInit y_p init)
         (DSHAlloc no
                   (DSHLoop nn
                            (DSHSeq
                               rr
                               (DSHMemMap2 no y_p''
                                           (PVar 1)
                                           y_p''
                                           df)))))
      y_p.
Proof.
  subst.
  apply Seq_DSH_pure.
  apply MemInit_DSH_pure.

  (* we don't care what operator it is so long as it's pure *)
  remember (DSHMemMap2 no (incrPVar 0 (incrPVar 0 y_p)) (PVar 1)
                (incrPVar 0 (incrPVar 0 y_p)) df)
    as dop.
  assert (DSH_pure dop (incrPVar 0 (incrPVar 0 y_p)))
    by (subst; apply MemMap2_DSH_pure).
  clear Heqdop.

  constructor; intros.
  -
    generalize dependent m'.
    induction nn.
    +
      intros.
      do 2 (destruct fuel; [cbn in *; some_none |]).
      cbn in *.
      some_inv; inl_inr_inv.
      eq_to_equiv; simplify_memory_hyp.
      rewrite memory_remove_nonexistent_key in H0
        by (apply mem_block_exists_memory_next_key).
      rewrite H0.
      reflexivity.
    +
      intros.
      do 2 (destruct fuel; [cbn in *; some_none |]).
      cbn in H0.
      repeat break_match;
        try some_none; repeat some_inv;
        try inl_inr; repeat inl_inr_inv.
      subst.
      rename m1 into loop_m, m0 into step_m.
      specialize (IHnn (memory_remove loop_m (memory_next_key m))).
      full_autospecialize IHnn.
      *
        remember (S fuel) as t; cbn; subst t. (* poor man's partial unfold *)
        apply evalDSHOperator_fuel_ge with (f' := S fuel) in Heqo0;
          [| constructor; reflexivity].
        rewrite Heqo0.
        reflexivity.
      *
        rewrite <-H0.
        clear Heqo0 H0 m'.
        destruct fuel; cbn in *; try some_none.
        repeat break_match;
          try some_none; repeat some_inv;
          try inl_inr; repeat inl_inr_inv.
        subst.
        rename m0 into rr_m.
        eq_to_equiv.
        inversion_clear P as [S T]; clear T.
        apply S with (k:=k) in Heqo0; clear S.
        inversion_clear H as [S T]; clear T.
        apply S with (k:=k) in Heqo; clear S.
        rewrite IHnn.
        destruct (Nat.eq_dec k (memory_next_key m)).
        --
          rewrite <-e in *.
          pose proof mem_block_exists_memory_remove k loop_m.
          pose proof mem_block_exists_memory_remove k step_m.
          intuition.
        --
          repeat rewrite <-mem_block_exists_memory_remove_neq by congruence.
          rewrite Heqo0, Heqo.
          reflexivity.
  -
    generalize dependent m'.
    induction nn.
    +
      intros.
      do 2 (destruct fuel; [cbn in *; some_none |]).
      cbn in *.
      some_inv; inl_inr_inv.
      eq_to_equiv; simplify_memory_hyp.
      rewrite memory_remove_nonexistent_key in H0
        by (apply mem_block_exists_memory_next_key).
      unfold memory_equiv_except.
      intros.
      rewrite H0.
      reflexivity.
    +
      intros.
      do 2 (destruct fuel; [cbn in *; some_none |]).
      cbn in H0.
      repeat break_match;
        try some_none; repeat some_inv;
        try inl_inr; repeat inl_inr_inv.
      subst.
      rename m1 into loop_m, m0 into step_m.
      specialize (IHnn (memory_remove loop_m (memory_next_key m))).
      full_autospecialize IHnn.
      *
        remember (S fuel) as t; cbn; subst t. (* poor man's partial unfold *)
        apply evalDSHOperator_fuel_ge with (f' := S fuel) in Heqo0;
          [| constructor; reflexivity].
        rewrite Heqo0.
        reflexivity.
      *
        unfold memory_equiv_except.
        intros.
        rewrite <-H0.
        clear Heqo0 H0 m'.
        destruct fuel; cbn in Heqo; try some_none.
        repeat break_match;
          try some_none; repeat some_inv;
          try inl_inr; repeat inl_inr_inv.
        subst.
        rename m0 into rr_m.
        eq_to_equiv.
        inversion_clear P as [T S]; clear T.
        apply S with (y_i:=memory_next_key m) (y_size:=no) in Heqo0;
          clear S; [| reflexivity].
        inversion_clear H as [T S]; clear T.
        apply S with (y_i:=y_i) (y_size:=y_size) in Heqo; clear S;
          [| repeat rewrite evalPExpr_incrPVar; assumption].
        rewrite IHnn by assumption.
        destruct (Nat.eq_dec k (memory_next_key m)).
        --
          rewrite <-e in *.
          repeat rewrite memory_lookup_memory_remove_eq by reflexivity.
          reflexivity.
        --
          repeat rewrite memory_lookup_memory_remove_neq by congruence.
          rewrite Heqo0 by congruence.
          rewrite Heqo by congruence.
          reflexivity.
Qed.

Lemma evalDSHMap2_rest_preserved
      (x1 x2 y y' : mem_block)
      (m : memory)
      (df : AExpr)
      (σ : evalContext)
      (n : nat)
  :
    evalDSHMap2 m n df σ x1 x2 y = inr y' ->
    forall k, n <= k -> mem_lookup k y' = mem_lookup k y.
Proof.
  intros.

  generalize dependent k.
  generalize dependent y.
  induction n.
  -
    intros.
    cbn in *.
    inl_inr_inv.
    rewrite H.
    reflexivity.
  -
    intros.
    cbn [evalDSHMap2] in H.
    remember ("Error reading 1st arg memory in evalDSHMap2 @" ++
      Misc.string_of_nat n ++ " in " ++ string_of_mem_block_keys x1)%string as t1;
      clear Heqt1.
    remember ("Error reading 2nd arg memory in evalDSHMap2 @" ++
      Misc.string_of_nat n ++ " in " ++ string_of_mem_block_keys x2)%string as t2;
      clear Heqt2.
    cbn in *.
    repeat break_match; try inl_inr.
    rewrite IHn with (y := mem_add n c1 y); [| assumption | lia].
    unfold mem_lookup, mem_add.
    rewrite NP.F.add_neq_o by lia.
    reflexivity.
Qed.

Lemma evalDSHMap2_result
      (x1 x2 y y' : mem_block)
      (m : memory)
      (df : AExpr)
      (σ : evalContext)
      (n : nat)
      (dot : CarrierA -> CarrierA -> CarrierA)
      (DF : MSH_DSH_BinCarrierA_compat dot σ df m)
  :
    evalDSHMap2 m n df σ x1 x2 y = inr y' ->
    forall k, k < n -> exists a1 a2,
        mem_lookup k x1 = Some a1 /\
        mem_lookup k x2 = Some a2 /\
        mem_lookup k y' = Some (dot a1 a2).
Proof.
  intros.

  generalize dependent k.
  generalize dependent y.
  induction n.
  -
    lia.
  -
    intros.
    cbn [evalDSHMap2] in H.
    remember ("Error reading 1st arg memory in evalDSHMap2 @" ++
      Misc.string_of_nat n ++ " in " ++ string_of_mem_block_keys x1)%string as t1;
      clear Heqt1.
    remember ("Error reading 2nd arg memory in evalDSHMap2 @" ++
      Misc.string_of_nat n ++ " in " ++ string_of_mem_block_keys x2)%string as t2;
      clear Heqt2.
    cbn in *.
    repeat break_match; try inl_inr.
    destruct (Nat.eq_dec k n).
    +
      subst; clear H0.
      exists c, c0.
      split; [| split].
      1,2: unfold mem_lookup_err, trywith in *.
      1,2: repeat break_match; try inl_inr; repeat inl_inr_inv.
      1,2: reflexivity.
      apply evalDSHMap2_rest_preserved with (k:=n) in H; [| reflexivity].
      rewrite H.
      unfold mem_lookup, mem_add.
      rewrite NP.F.add_eq_o by reflexivity.
      inversion_clear DF as [D].
      eq_to_equiv.
      rewrite D in Heqs1.
      inl_inr_inv.
      rewrite Heqs1.
      reflexivity.
    +
      eapply IHn.
      eassumption.
      lia.
Qed.

Lemma MemMap2_rest_preserved
      (o : nat)
      (σ : evalContext)
      (m rm : memory)
      (x1_p x2_p y_p : PExpr)
      (df : AExpr)
      (y_m y_rm : mem_block)
      (Y_M : lookup_PExpr σ m y_p = inr y_m)
      (Y_RM : lookup_PExpr σ rm y_p = inr y_rm)
  :
    evalDSHOperator σ (DSHMemMap2 o x1_p x2_p y_p df) m
                    (estimateFuel (DSHMemMap2 o x1_p x2_p y_p df)) = Some (inr rm) ->
    ∀ k : nat, o <= k → mem_lookup k y_rm = mem_lookup k y_m.
Proof.
  intros.
  cbn in H.
  repeat break_match;
    try some_none; repeat some_inv;
    try inl_inr; repeat inl_inr_inv.
  memory_lookup_err_to_option.
  unfold lookup_PExpr, memory_lookup_err in *.
  rewrite Heqs1 in *.
  cbn in *.
  rewrite Heqs5 in Y_M.
  rewrite <-H in *.
  rewrite memory_lookup_memory_set_eq in * by reflexivity.
  cbn in *.
  repeat inl_inr_inv.
  eq_to_equiv.
  rewrite Y_M, Y_RM in *; clear Y_M Y_RM.
  eapply evalDSHMap2_rest_preserved in Heqs6; [| eassumption].
  assumption.
Qed.

Lemma MemMap2_result_fill
      (o : nat)
      (σ : evalContext)
      (m rm : memory)
      (x1_p x2_p y_p : PExpr)
      (df : AExpr)
      (y_rm : mem_block)
      (Y_RM : lookup_PExpr σ rm y_p = inr y_rm)
  :
    evalDSHOperator σ (DSHMemMap2 o x1_p x2_p y_p df) m
                    (estimateFuel (DSHMemMap2 o x1_p x2_p y_p df)) = Some (inr rm) ->
    ∀ k, k < o → mem_in k y_rm.
Proof.
  intros.
  cbn in H.
  repeat break_match;
    try some_none; repeat some_inv;
    try inl_inr; repeat inl_inr_inv.
  memory_lookup_err_to_option.
  unfold lookup_PExpr, memory_lookup_err in Y_RM.
  rewrite Heqs1 in Y_RM.
  cbn in Y_RM.
  rewrite <-H in Y_RM.
  rewrite memory_lookup_memory_set_eq in Y_RM by reflexivity.
  cbn in Y_RM.
  inl_inr_inv.
  eq_to_equiv.
  rewrite Y_RM in *; clear Y_RM.
  clear - Heqs6 H0.
  rename Heqs6 into M, H0 into KO.

  generalize dependent k.
  generalize dependent m2.
  generalize dependent y_rm.
  induction o; [lia |].
  intros.
  cbn [evalDSHMap2] in M.
  rename m0 into x1_m, m1 into x2_m.
  remember ("Error reading 1st arg memory in evalDSHMap2 @" ++
    Misc.string_of_nat o ++ " in " ++ string_of_mem_block_keys x1_m)%string as t1;
    clear Heqt1.
  remember ("Error reading 2nd arg memory in evalDSHMap2 @" ++
    Misc.string_of_nat o ++ " in " ++ string_of_mem_block_keys x2_m)%string as t2;
    clear Heqt2.
  cbn in *.
  repeat break_match; try inl_inr.
  destruct (Nat.eq_dec k o).
  +
    subst; clear KO.
    apply evalDSHMap2_rest_preserved with (k:=o) in M; [| reflexivity].
    unfold mem_in, mem_lookup, mem_add in *.
    rewrite NP.F.add_eq_o in M by reflexivity.
    apply NP.F.in_find_iff.
    intros C.
    rewrite C in M.
    some_none.
  +
    eapply IHo.
    eassumption.
    lia.
Qed.

Lemma DSHMap2_succeeds 
      (x1_p x2_p y_p : PExpr)
      (x1_m x2_m y_m : mem_block)
      (σ : evalContext)
      (m : memory)
      (df : AExpr)
      (o y_sz : nat)
      (SZ : o <= y_sz)
      (LX1 : lookup_PExpr σ m x1_p = inr x1_m)
      (LX2 : lookup_PExpr σ m x2_p = inr x2_m)
      (LY : lookup_PExpr_wsize σ m y_p = inr (y_m, y_sz))
      (D1 : forall k, k < o -> mem_in k x1_m)
      (D2 : forall k, k < o -> mem_in k x2_m)

      (dot : CarrierA -> CarrierA -> CarrierA)
      (DC : MSH_DSH_BinCarrierA_compat dot (protect_p σ y_p) df m)
  :
    exists m', evalDSHOperator σ (DSHMemMap2 o x1_p x2_p y_p df) m
                    (estimateFuel (DSHMemMap2 o x1_p x2_p y_p df)) = Some (inr m').
Proof.
  apply lookup_PExpr_eval_lookup in LX1.
  destruct LX1 as [x1_id [x1_sz [X1_ID X1_M]]].
  apply lookup_PExpr_eval_lookup in LX2.
  destruct LX2 as [x2_id [x2_sz [X2_ID X2_M]]].
  copy_apply lookup_PExpr_wsize_OK_no_size LY;
    rename LY into LY_SZ, H into LY.
  apply lookup_PExpr_eval_lookup in LY.
  destruct LY as [y_id [y_sz' [Y_ID Y_M]]].
  replace y_sz' with y_sz in *
    by (symmetry; eapply lookup_PExpr_size_invariant'; eassumption);
    clear y_sz'.
  cbn.
  unfold memory_lookup_err, trywith.
  repeat break_match;
    try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
  all: tuple_inversion_equiv; subst_nat; subst.
  all: eq_to_equiv.
  all: rename Heqs into X1_ID, Heqs0 into X2_ID, Heqs1 into Y_ID.
  all: try some_none.
  all: subst.
  1: {
    exfalso.
    unfold assert_NT_le, assert_true_to_err in Heqs2.
    break_if; try inl_inr.
    apply leb_complete_conv in Heqb.
    unfold NatAsNT.MNatAsNT.to_nat in Heqb.
    lia.
  }
  all: rewrite Heqo2, Heqo1, Heqo0 in *; repeat some_inv.
  all: rewrite X1_M, X2_M, Y_M in *; clear X1_M X2_M Y_M.
  all: rename Heqo2 into X1_M, Heqo1 into X2_M, Heqo0 into Y_M.
  all: rename Heqs6 into M.
  - (* evalDSHMap2 fails *)
    exfalso.
    contradict M; generalize s; apply is_OK_neq_inl.

    clear Y_M LY_SZ.
    generalize dependent y_m.
    induction o.
    +
      cbn [evalDSHMap2].
      generalize ("Error reading 2nd arg memory in evalDSHMap2 @" ++
       Misc.string_of_nat 0 ++ " in " ++ string_of_mem_block_keys x2_m)%string.
      generalize ("Error reading 1st arg memory in evalDSHMap2 @" ++
       Misc.string_of_nat 0 ++ " in " ++ string_of_mem_block_keys x1_m)%string.
      intros.
      cbn.
      constructor.
    +
      autospecialize IHo; [lia |].
      autospecialize IHo; [intros; apply D1; lia |].
      autospecialize IHo; [intros; apply D2; lia |].
      autospecialize IHo.
      {
        clear - Heqs2.
        unfold assert_NT_le, assert_true_to_err in *.
        break_if; try inl_inr.
        destruct u.
        reflexivity.
        exfalso.
        break_if; try inl_inr.
        apply leb_complete_conv in Heqb.
        apply leb_complete in Heqb0.
        clear Heqs2 u.
        unfold NatAsNT.MNatAsNT.to_nat in *.
        lia.
      }
      
      cbn [evalDSHMap2].
      generalize ("Error reading 1st arg memory in evalDSHMap2 @" ++
       Misc.string_of_nat o ++ " in " ++ string_of_mem_block_keys x1_m)%string.
      generalize ("Error reading 2nd arg memory in evalDSHMap2 @" ++
       Misc.string_of_nat o ++ " in " ++ string_of_mem_block_keys x2_m)%string.
      specialize (D1 o); autospecialize D1; [lia |].
      specialize (D2 o); autospecialize D2; [lia |].
      rewrite mem_in_mem_lookup in *.
      rewrite is_Some_def in D1, D2.
      destruct D1 as [x1_mb D1], D2 as [x2_mb D2].
      unfold mem_lookup_err.
      rewrite D1, D2.
      intros.
      cbn.

      inversion_clear DC as [D].
      pose proof D x1_mb x2_mb as D'.
      break_match; try inl_inr.
      apply IHo.
  -
    eexists.
    reflexivity.
Qed.

Lemma MemMap2_merge_with_def
      (x1_p x2_p y_p : PExpr)
      (x1_m x2_m y_m y_m': mem_block)
      (σ : evalContext)
      (m m' : memory)
      (dot : CarrierA -> CarrierA -> CarrierA)
      (PF : Proper ((=) ==> (=) ==> (=)) dot)
      (df : AExpr)
      (init : CarrierA)
      (o : nat)
      (LX1 : lookup_PExpr σ m x1_p = inr x1_m)
      (LX2 : lookup_PExpr σ m x2_p = inr x2_m)
      (LY : lookup_PExpr σ m y_p = inr y_m)

      (DC : MSH_DSH_BinCarrierA_compat dot (protect_p σ y_p) df m)
  :
    evalDSHOperator σ (DSHMemMap2 o x1_p x2_p y_p df) m
                    (estimateFuel (DSHMemMap2 o x1_p x2_p y_p df)) = Some (inr m') ->
    lookup_PExpr σ m' y_p = inr y_m' ->
    forall k, k < o -> mem_lookup k y_m' =
                 mem_lookup k (mem_merge_with_def dot init x1_m x2_m).
Proof.
  apply lookup_PExpr_eval_lookup in LX1.
  destruct LX1 as [x1_id [x1_sz [X1_ID X1_M]]].
  apply lookup_PExpr_eval_lookup in LX2.
  destruct LX2 as [x2_id [x2_sz [X2_ID X2_M]]].
  apply lookup_PExpr_eval_lookup in LY.
  destruct LY as [y_id [y_sz [Y_ID Y_M]]].
  cbn [evalDSHOperator estimateFuel].
  remember evalDSHMap2 as t1; remember mem_lookup as t2;
    cbn; subst t1 t2.

  unfold memory_lookup_err, trywith.
  repeat break_match;
    try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
  all: tuple_inversion_equiv; subst_nat; subst.
  all: eq_to_equiv.
  all: rename Heqs into X1_ID, Heqs0 into X2_ID, Heqs1 into Y_ID.
  all: try some_none.
  all: intros; try some_none; repeat some_inv; try inl_inr; inl_inr_inv.
  all: invc H0; rewrite H4 in *; clear H4.
  subst.
  rewrite Heqo3, Heqo2, Heqo1 in *; repeat some_inv.
  rewrite X1_M, X2_M, Y_M in *; clear X1_M X2_M Y_M.
  rename Heqo3 into X1_M, Heqo2 into X2_M, Heqo1 into Y_M.
  rename Heqs6 into M.
  rewrite <-H in Heqo0.
  rewrite memory_lookup_memory_set_eq in Heqo0 by reflexivity.
  some_inv.
  rewrite Heqo0 in *; clear Heqo0.
  
  apply evalDSHMap2_result with (k:=k) (dot:=dot) in M; try assumption.
  destruct M as [a1 [a2 [X1 [X2 Y]]]].
  unfold mem_lookup in Y.
  rewrite Y.
  unfold mem_lookup, mem_merge_with_def.
  repeat rewrite NP.F.map2_1bis by reflexivity.
  unfold mem_lookup in X1, X2.
  repeat break_match; try some_none; repeat some_inv.
  rewrite X1, X2.
  reflexivity.
Qed.

Lemma MemMap2_merge_with_def_firstn
      (x1_p x2_p y_p : PExpr)
      (x1_m x2_m y_m : mem_block)
      (σ : evalContext)
      (m : memory)
      (dot : CarrierA -> CarrierA -> CarrierA)
      (PF : Proper ((=) ==> (=) ==> (=)) dot)
      (df : AExpr)
      (init : CarrierA)
      (o y_sz : nat)
      (SZ : o <= y_sz)
      (y_id : nat)
      (LX1 : lookup_PExpr σ m x1_p = inr x1_m)
      (LX2 : lookup_PExpr σ m x2_p = inr x2_m)
      (Y_ID : evalPExpr_id σ y_p = inr y_id)
      (Y_M : lookup_PExpr_wsize σ m y_p = inr (y_m, y_sz))
      (D1 : forall k, k < o -> mem_in k x1_m)
      (D2 : forall k, k < o -> mem_in k x2_m)

      (DC : MSH_DSH_BinCarrierA_compat dot (protect_p σ y_p) df m)
  :
    evalDSHOperator σ (DSHMemMap2 o x1_p x2_p y_p df) m
                    (estimateFuel (DSHMemMap2 o x1_p x2_p y_p df))
    = Some (inr
              (memory_set m y_id (mem_union (mem_merge_with_def dot init
                                                                (mem_firstn o x1_m)
                                                                (mem_firstn o x2_m))
                                            y_m))).
Proof.
  assert (YID_M : memory_lookup m y_id = Some y_m).
  {
    clear - Y_ID Y_M.
    unfold lookup_PExpr_wsize in Y_M.
    cbn in *.
    repeat break_match; try inl_inr.
    repeat inl_inr_inv.
    tuple_inversion_equiv; memory_lookup_err_to_option; subst_nat; subst.
    rewrite Heqs0, H.
    reflexivity.
  }
  unfold evalPExpr_id in Y_ID; cbn in Y_ID.
  assert (exists m', evalDSHOperator σ (DSHMemMap2 o x1_p x2_p y_p df) m
                  (estimateFuel (DSHMemMap2 o x1_p x2_p y_p df)) = Some (inr m'))
    by (eapply DSHMap2_succeeds; eassumption).
  destruct H as [ma MA].
  rewrite MA.
  do 2 f_equiv.
  intros b_id.
  destruct (Nat.eq_dec b_id y_id).
  -
    subst b_id.
    unfold memory_set.
    rewrite NP.F.add_eq_o by reflexivity.
    assert (exists y_ma, lookup_PExpr σ ma y_p = inr y_ma).
    {
      apply equiv_Some_is_Some, memory_is_set_is_Some,
      (mem_stable _ _ _ _ MA), mem_block_exists_exists in YID_M.
      destruct YID_M as [y_ma H].
      exists y_ma.
      cbn.
      break_match; try inl_inr.
      destruct p.
      apply memory_lookup_err_inr_Some.
      inv Y_ID.
      rewrite H2, H.
      reflexivity.
    }
    destruct H as [y_ma Y_MA].
    assert (T : NM.find (elt:=mem_block) y_id ma = Some y_ma).
    {
      unfold lookup_PExpr, memory_lookup_err, trywith, memory_lookup in Y_MA.
      cbn in Y_MA.
      repeat break_match; try inl_inr; repeat inl_inr_inv.
      rewrite <-Y_ID, <-Y_MA, Heqo0.
      reflexivity.
    }
    rewrite T; clear T.
    f_equiv.
    intros k.
    destruct (le_lt_dec o k).
    +
      unfold mem_union.
      rewrite NP.F.map2_1bis by reflexivity.
      assert (NM.find (elt:=CarrierA) k
                      (mem_merge_with_def dot init (mem_firstn o x1_m)
                                          (mem_firstn o x2_m)) = None).
      {
        unfold mem_merge_with_def.
        rewrite NP.F.map2_1bis by reflexivity.
        repeat rewrite mem_firstn_lookup_oob by assumption; reflexivity.
      }
      break_match; try some_none.
      clear Heqo0 H.
      eapply MemMap2_rest_preserved in MA; eauto.
      unfold lookup_PExpr, memory_lookup_err, trywith.
      cbn.
      repeat break_match; try inl_inr; repeat inl_inr_inv.
      all: eq_to_equiv.
      all: rewrite Y_ID in Heqo0.
      all: rewrite Heqo0 in YID_M.
      all: try some_none; some_inv.
      rewrite YID_M.
      reflexivity.
    +
      erewrite MemMap2_merge_with_def.
      7: eapply MA.
      all: try eassumption.
      2: {
        unfold lookup_PExpr, memory_lookup_err, trywith.
        cbn.
        repeat break_match; try some_none; try inl_inr.
        all: inl_inr_inv.
        all: eq_to_equiv.
        all: rewrite Y_ID in Heqo0.
        all: rewrite Heqo0 in YID_M.
        all: try some_none; some_inv.
        rewrite YID_M.
        reflexivity.
      }
      instantiate (1:=init).
      unfold mem_lookup, mem_union, mem_merge_with_def.
      repeat rewrite NP.F.map2_1bis by reflexivity.

      assert (exists k_x1m, mem_lookup k x1_m = Some k_x1m).
      {
        specialize (D1 k l).
        apply mem_in_mem_lookup in D1.
        apply is_Some_def in D1.
        destruct D1.
        exists x; rewrite H; reflexivity.
      }
      destruct H as [k_x1m K_X1M].
      assert (exists k_x2m, mem_lookup k x2_m = Some k_x2m).
      {
        specialize (D2 k l).
        apply mem_in_mem_lookup in D2.
        apply is_Some_def in D2.
        destruct D2.
        exists x; rewrite H; reflexivity.
      }
      destruct H as [k_x2m K_X2M].
      repeat rewrite mem_firstn_lookup by assumption.
      unfold mem_lookup in *.
      repeat break_match; try some_none.
  -
    unfold memory_set.
    rewrite NP.F.add_neq_o by congruence.
    break_match; try inl_inr.
    destruct p; inl_inr_inv.
    eapply mem_write_safe in MA.
    specialize (MA b_id n).
    rewrite MA.
    reflexivity.
    rewrite Heqs.
    repeat constructor.
    rewrite Y_ID.
    reflexivity.
Qed.

Lemma SHCOL_DSHCOL_mem_block_equiv_keys_union (ma mb md : mem_block) :
  SHCOL_DSHCOL_mem_block_equiv mb ma md ->
  forall k, mem_in k mb \/ mem_in k md <-> mem_in k ma.
Proof.
  intros.
  specialize (H k).
  inversion H.
  all: repeat rewrite mem_in_mem_lookup in *.
  all: repeat rewrite mem_not_in_mem_lookup in *.
  all: repeat break_match; try some_none.
  all: intuition.
  all: unfold is_Some in *; repeat break_match; try some_none.
  all: auto.
Qed.

Theorem IReduction_MSH_step
      {i o n : nat}
      (mb : mem_block)
      (dot : CarrierA -> CarrierA -> CarrierA)
      (pdot : Proper ((=) ==> (=) ==> (=)) dot)
      (init : CarrierA)
      (S_opf : @MSHOperatorFamily i o (S n))
  :
    let opf := shrink_m_op_family S_opf in
    let fn := mkFinNat (Nat.lt_succ_diag_r n) in
    mem_op (MSHIReduction init dot S_opf) mb =
    mb' <- mem_op (MSHIReduction init dot opf) mb ;;
    mbn <- mem_op (S_opf fn) mb ;;
    Some (mem_merge_with_def dot init mb' mbn).
Proof.
  simpl.
  unfold IReduction_mem.
  simpl.
  unfold Apply_mem_Family in *.
  repeat break_match;
    try discriminate; try reflexivity.
  all: repeat some_inv; subst.
  -
    rename l into S_lb, l0 into lb.

    (* poor man's apply to copy and avoid evars *)
    assert (S_LB : ∀ (j : nat) (jc : (j < S n)%mc),
               List.nth_error S_lb j ≡ get_family_mem_op S_opf j jc mb)
      by (apply ListSetoid.monadic_Lbuild_op_eq_Some; assumption).
    assert (LB : ∀ (j : nat) (jc : (j < n)%mc),
               List.nth_error lb j ≡ get_family_mem_op (shrink_m_op_family S_opf) j jc mb)
      by (apply ListSetoid.monadic_Lbuild_op_eq_Some; assumption).

    apply ListSetoid.monadic_Lbuild_opt_length in Heqo0; rename Heqo0 into S_L.
    apply ListSetoid.monadic_Lbuild_opt_length in Heqo3; rename Heqo3 into L.
    rename m0 into mbn, Heqo2 into MBN.

    unfold get_family_mem_op in *.
    assert (H : forall j, j < n -> List.nth_error lb j ≡ List.nth_error S_lb j)
      by (intros; erewrite S_LB, LB; reflexivity).
    Unshelve. 2: assumption.

    assert (N_MB : is_Some (mem_op (S_opf (mkFinNat (Nat.lt_succ_diag_r n))) mb)).
    {
      apply is_Some_ne_None.
      intro C.
      rewrite <-S_LB in C.
      apply List.nth_error_None in C.
      lia.
    }
    apply is_Some_def in N_MB.
    destruct N_MB as [n_mb N_MB].

    assert (H1 : S_lb ≡ lb ++ [n_mb]).
    {
      apply list_eq_nth;
        [rewrite List.app_length; cbn; lia |].
      intros k KC.
      (* extensionality *)
      enough (forall d, List.nth k S_lb d ≡ List.nth k (lb ++ [n_mb]) d)
        by (apply Logic.FunctionalExtensionality.functional_extensionality; assumption).
      rewrite S_L in KC.
      destruct (Nat.eq_dec k n).
      -
        subst k.
        intros.
        apply List_nth_nth_error.
        replace n with (0 + Datatypes.length lb).
        rewrite ListNth.nth_error_length.
        cbn.
        rewrite L.
        rewrite S_LB with (jc := (Nat.lt_succ_diag_r n)).
        rewrite <-N_MB.
        reflexivity.
      -
        assert (k < n) by lia; clear KC n0.
        intros.
        apply List_nth_nth_error.
        rewrite <-H by lia.
        rewrite List.nth_error_app1 by lia.
        reflexivity.
    }

    rewrite H1.
    rewrite List.fold_left_app.
    cbn.

    rewrite MBN in N_MB; some_inv.
    reflexivity.
  -
    rename l into S_lb, l0 into lb.

    (* poor man's apply to copy and avoid evars *)
    assert (S_LB : ∀ (j : nat) (jc : (j < S n)%mc),
               List.nth_error S_lb j ≡ get_family_mem_op S_opf j jc mb)
      by (apply ListSetoid.monadic_Lbuild_op_eq_Some; assumption).
    apply ListSetoid.monadic_Lbuild_opt_length in Heqo0; rename Heqo0 into S_L.

    assert (N_MB : is_Some (mem_op (S_opf (mkFinNat (Nat.lt_succ_diag_r n))) mb)).
    {
      apply is_Some_ne_None.
      intro C.
      unfold get_family_mem_op in *.
      rewrite <-S_LB in C.
      apply List.nth_error_None in C.
      lia.
    }

    rewrite Heqo2 in N_MB.
    some_none.
  -
    exfalso; clear Heqo1.

    pose proof Heqo0 as L; apply ListSetoid.monadic_Lbuild_opt_length in L.

    apply ListSetoid.monadic_Lbuild_op_eq_None in Heqo2.
    destruct Heqo2 as [k [KC N]].
    apply ListSetoid.monadic_Lbuild_op_eq_Some
      with (i0:=k) (ic:=le_S KC)
      in Heqo0.
    unfold get_family_mem_op, shrink_m_op_family in *.
    cbn in *.
    rewrite N in Heqo0.
    apply ListNth.nth_error_length_ge in Heqo0.
    assert (k < n) by assumption.
    lia.
  -
    exfalso.

    pose proof Heqo3 as S_L; apply ListSetoid.monadic_Lbuild_opt_length in S_L.

    apply ListSetoid.monadic_Lbuild_op_eq_None in Heqo0.
    destruct Heqo0 as [k [KC N]].
    destruct (Nat.eq_dec k n).
    +
      subst k.
      unfold get_family_mem_op in *.
      assert (KC ≡ (Nat.lt_succ_diag_r n)) by (apply lt_unique).
      rewrite <-H, N in Heqo2.
      some_none.
    +
      assert (k < n) by (assert (k < S n) by assumption; lia); clear n0.
      apply ListSetoid.monadic_Lbuild_op_eq_Some
        with (i0:=k) (ic:=H)
        in Heqo3.
      unfold get_family_mem_op, shrink_m_op_family in *.
      cbn in Heqo3.
      assert (le_S H ≡ KC) by (apply lt_unique).
      rewrite H0, N in Heqo3.
      apply ListNth.nth_error_length_ge in Heqo3.
      rewrite S_L in Heqo3.
      lia.
Qed.

Lemma MemInit_simpl
      (y_sz: nat)
      (σ : evalContext)
      (m : memory)
      (dop : DSHOperator)
      (init : CarrierA)
      (y_p : PExpr)
      (y_id : nat)
      (y_m : mem_block)
      (Y_ID : evalPExpr_id σ y_p = inr y_id)
      (Y_M : lookup_PExpr_wsize σ m y_p = inr (y_m, y_sz))
  :
  evalDSHOperator σ (DSHSeq (DSHMemInit y_p init) dop) m
                  (estimateFuel (DSHSeq (DSHMemInit y_p init) dop)) =
  evalDSHOperator σ dop (memory_set m y_id (mem_union (mem_const_block y_sz init) y_m))
                  (estimateFuel dop).
Proof.
  assert (YID_M : memory_lookup m y_id = Some y_m).
  {
    clear - Y_ID Y_M.
    cbn in *.
    repeat break_match; try inl_inr; repeat inl_inr_inv.
    memory_lookup_err_to_option.
    tuple_inversion_equiv; subst_nat; subst.
    rewrite Heqs0, H.
    reflexivity.
  }
  unfold evalPExpr_id in Y_ID; cbn in Y_ID.
  pose proof estimateFuel_positive dop.
  cbn.
  repeat break_match;
    try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
  all: cbn in Heqo.
  all: repeat break_match;
    try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv;
        subst; try lia.
  -
    memory_lookup_err_to_option.
    eq_to_equiv.
    rewrite Y_ID in Heqs3.
    some_none.
  -
    memory_lookup_err_to_option.
    eq_to_equiv.
    rewrite Y_ID in *.
    rewrite Heqs3 in YID_M.
    some_inv.
    rewrite YID_M.
    unfold NatAsNT.MNatAsNT.to_nat.
    unfold lookup_PExpr_wsize in Y_M.
    cbn in Y_M.
    break_match.
    inversion Y_M.
    break_let.
    break_match.
    inversion Y_M.
    repeat inl_inr_inv.
    invc Heqs2.
    invc Y_M.
    cbn in H0, H1, H2, H3.
    rewrite <- H1, H3.
    reflexivity.
Qed.

Lemma Alloc_Loop_step
      (o n : nat)
      (body : DSHOperator)
      (m loopN_m iterSN_m : memory)
      (σ : evalContext)
      (t_id : nat)
      (T_ID : t_id ≡ memory_next_key m)
      (LoopN : evalDSHOperator ((DSHPtrVal t_id o,false) :: σ) (DSHLoop n body)
                               (memory_set m t_id mem_empty)
                               (estimateFuel (DSHLoop n body))
               = Some (inr loopN_m))
      (IterSN : evalDSHOperator ((DSHnatVal n,false) :: (DSHPtrVal t_id o,false) :: σ)
                                body
                                loopN_m
                                (estimateFuel body) = Some (inr iterSN_m))
  :
    evalDSHOperator σ (DSHAlloc o (DSHLoop (S n) body)) m
                  (estimateFuel (DSHAlloc o (DSHLoop (S n) body))) = 
    Some (inr (memory_remove iterSN_m t_id)).
Proof.
  cbn.
  rewrite <-T_ID.
  rewrite evalDSHOperator_estimateFuel_ge
    by (pose proof estimateFuel_positive body; cbn; nia).
  destruct (evalDSHOperator ((DSHPtrVal t_id o,false) :: σ) (DSHLoop n body)
                            (memory_set m t_id mem_empty) (estimateFuel (DSHLoop n body)))
           as [t|] eqn:LoopN'; [destruct t as [|loopN_m'] |];
    try some_none; some_inv; try inl_inr; inl_inr_inv.
  rewrite evalDSHOperator_estimateFuel_ge
    by (pose proof estimateFuel_positive body; cbn; nia).
  rewrite <-LoopN in *; clear LoopN loopN_m.
  repeat break_match; try some_none; some_inv; try inl_inr; inl_inr_inv.
  rewrite IterSN.
  reflexivity.
Qed.

Lemma Alloc_Loop_error1
      (o n : nat)
      (body : DSHOperator)
      (m : memory)
      (σ : evalContext)
      (t_id : nat)
      (T_ID : t_id ≡ memory_next_key m)
      (msg : string)
      (LoopN : evalDSHOperator ((DSHPtrVal t_id o,false) :: σ) (DSHLoop n body)
                               (memory_set m t_id mem_empty)
                               (estimateFuel (DSHLoop n body))
               = Some (inl msg))
  :
    evalDSHOperator σ (DSHAlloc o (DSHLoop (S n) body)) m
                  (estimateFuel (DSHAlloc o (DSHLoop (S n) body))) = 
    Some (inl msg).
Proof.
  cbn.
  rewrite <-T_ID.
  rewrite evalDSHOperator_estimateFuel_ge
    by (pose proof estimateFuel_positive body; cbn; lia).
  destruct (evalDSHOperator ((DSHPtrVal t_id o,false) :: σ) (DSHLoop n body)
                            (memory_set m t_id mem_empty) (estimateFuel (DSHLoop n body)))
           as [t|] eqn:LoopN'; [destruct t as [|loopN_m'] |].
  - repeat constructor.
  - some_inv; inl_inr.
  - some_none.
Qed.

Lemma Alloc_Loop_error2
      (o n : nat)
      (body : DSHOperator)
      (m loopN_m : memory)
      (σ : evalContext)
      (t_id : nat)
      (T_ID : t_id ≡ memory_next_key m)
      (msg : string)
      (LoopN : evalDSHOperator ((DSHPtrVal t_id o,false) :: σ) (DSHLoop n body)
                               (memory_set m t_id mem_empty)
                               (estimateFuel (DSHLoop n body))
               = Some (inr loopN_m))
      (IterSN : evalDSHOperator ((DSHnatVal n,false) :: (DSHPtrVal t_id o,false) :: σ)
                                body
                                loopN_m
                                (estimateFuel body) = Some (inl msg))
  :
    evalDSHOperator σ (DSHAlloc o (DSHLoop (S n) body)) m
                  (estimateFuel (DSHAlloc o (DSHLoop (S n) body))) = 
    Some (inl msg).
Proof.
  cbn.
  rewrite <-T_ID.
  rewrite evalDSHOperator_estimateFuel_ge
    by (pose proof estimateFuel_positive body; cbn; nia).
  destruct (evalDSHOperator ((DSHPtrVal t_id o,false) :: σ) (DSHLoop n body)
                            (memory_set m t_id mem_empty) (estimateFuel (DSHLoop n body)))
           as [t|] eqn:LoopN'; [destruct t as [|loopN_m'] |];
    try some_none; some_inv; try inl_inr; inl_inr_inv.
  rewrite evalDSHOperator_estimateFuel_ge by nia.
  rewrite <-LoopN in *; clear LoopN loopN_m.
  repeat break_match; try some_none; repeat some_inv; try inl_inr.
  repeat constructor.
Qed.

Lemma DSHAlloc_inv
      (σ : evalContext)
      (m rm : memory)
      (o : nat)
      (dop : DSHOperator)
      (t_id : NM.key)
      (T_ID : t_id ≡ memory_next_key m)
  :
    evalDSHOperator σ (DSHAlloc o dop) m (estimateFuel (DSHAlloc o dop)) = Some (inr rm) ->
    exists m', evalDSHOperator ((DSHPtrVal t_id o,false) :: σ) dop (memory_set m t_id mem_empty)
                          (estimateFuel dop) = Some (inr m') /\
          rm = memory_remove m' t_id.
Proof.
  intros.
  cbn in H.
  repeat break_match; try some_none; repeat some_inv; try inl_inr; repeat inl_inr_inv.
  subst.
  exists m0.
  eq_to_equiv.
  intuition.
Qed.

(* Exactly the same as [mem_stable] in [DSH_pure],
   except not part of the typeclass.
   Useful when an operator is not strictly [DSH_pure], but still
   does not free or allocate blocks. *)
Definition mem_stable' (dop : DSHOperator) := 
  ∀ (σ : evalContext) (m m' : memory) (fuel : nat),
    evalDSHOperator σ dop m fuel = Some (inr m') →
    ∀ k : nat, mem_block_exists k m ↔ mem_block_exists k m'.

Lemma DSH_pure_mem_stable (dop : DSHOperator) (y_p : PExpr) :
  DSH_pure dop y_p -> mem_stable' dop.
Proof.
  intros.
  unfold mem_stable'.
  apply mem_stable.
Qed.

Lemma DSHSeq_mem_stable (dop1 dop2 : DSHOperator) :
  mem_stable' dop1 ->
  mem_stable' dop2 ->
  mem_stable' (DSHSeq dop1 dop2).
Proof.
  intros.
  unfold mem_stable' in *.
  cbn in *.
  intros.
  destruct fuel; [inversion H1|].
  cbn in H1.
  repeat break_match;
    try some_none; repeat some_inv;
    try inl_inr; repeat inl_inr_inv.
  subst.
  rename m0 into m1, m' into m2, m into m0.
  eq_to_equiv.
  apply H with (k:=k) in Heqo.
  apply H0 with (k:=k) in H1.
  rewrite Heqo, H1.
  reflexivity.
Qed.

Lemma DSHLoop_mem_stable (dop : DSHOperator) :
  mem_stable' dop ->
  forall n, mem_stable' (DSHLoop n dop).
Proof.
  unfold mem_stable'.
  intros.
  generalize dependent m'.
  generalize dependent fuel.
  induction n.
  -
    intros.
    destruct fuel; [inversion H0 |].
    cbn in H0.
    some_inv; inl_inr_inv.
    rewrite H0; reflexivity.
  -
    intros.
    destruct fuel; [inversion H0 |].
    cbn in H0.
    repeat break_match;
      try some_none; repeat some_inv;
      try inl_inr; repeat inl_inr_inv.
    eq_to_equiv.
    apply IHn in Heqo.
    apply H with (k:=k) in H0.
    rewrite Heqo, H0.
    reflexivity.
Qed.

Lemma DSHLoop_invariant
      (σ : evalContext)
      (body : DSHOperator)
      (n : nat)
      (m rm: memory)
      (P : memory -> Prop)
      (PP : Proper ((=) ==> iff) P)
      (body_inv : forall n m m', P m ->
                            evalDSHOperator ((DSHnatVal n,false) :: σ) body m
                                            (estimateFuel body) = Some (inr m') ->
                            P m')
  :
    P m ->
    evalDSHOperator σ (DSHLoop n body) m (estimateFuel (DSHLoop n body)) = Some (inr rm) ->
    P rm.
Proof.
  intros.
  pose proof (estimateFuel_positive body) as FB.
  generalize dependent rm.
  induction n.
  -
    intros.
    cbn in H0.
    some_inv; inl_inr_inv.
    rewrite <-H0.
    assumption.
  -
    intros.
    cbn in H0.
    rewrite evalDSHOperator_estimateFuel_ge in H0 by (cbn; lia).
    repeat break_match; try some_none; repeat some_inv; try inl_inr.
    subst.
    specialize (IHn m0).
    autospecialize IHn; [reflexivity |].
    eapply body_inv.
    apply IHn.
    rewrite evalDSHOperator_estimateFuel_ge in H0 by (cbn; nia).
    eapply H0.
Qed.

(* TODO: move *)
Lemma lookup_PExpr_memory_lookup
      (σ : evalContext)
      (x_p : PExpr)
      (x_id : nat)
      (x_sz : nat)
      (m : memory)
      (x_m : mem_block)
  :
      evalPExpr σ x_p ≡ inr (x_id, x_sz) ->
      lookup_PExpr_wsize σ m x_p = inr (x_m, x_sz) →
      memory_lookup m x_id = Some x_m.
Proof.
  intros.
  unfold lookup_PExpr_wsize in H0.
  rewrite H in H0; clear H.
  cbn in H0.
  break_match; try inl_inr; inl_inr_inv.
  memory_lookup_err_to_option.
  rewrite Heqs.
  tuple_inversion_equiv.
  rewrite H.
  reflexivity.
Qed.

Global Instance IReduction_MSH_DSH_compat_S
       {i o n: nat}
       {init : CarrierA}
       {dot: CarrierA -> CarrierA -> CarrierA}
       {pdot: Proper ((=) ==> (=) ==> (=)) dot}
       {op_family: @MSHOperatorFamily i o (S n)}
       {df : AExpr}
       {σ : evalContext}
       {x_p y_p y_p'': PExpr}
       {XY : evalPExpr_id σ x_p <> evalPExpr_id σ y_p}
       {Y : y_p'' ≡ incrPVar 0 (incrPVar 0 y_p)}
       {rr : DSHOperator}
       {m : memory}
       {DP}
       (P: DSH_pure rr (PVar 1))
       (DC : forall m' y_id d1 d2,
           evalPExpr_id σ y_p ≡ inr y_id ->
           memory_subset_except y_id m m'  ->
           MSH_DSH_BinCarrierA_compat dot (protect_p (d1 :: d2 :: σ) (incrPVar 0 (incrPVar 0 y_p))) df m')
       (FC : forall m' tmpk t y_id mb,
           evalPExpr_id σ y_p ≡ inr y_id ->
           memory_subset_except y_id m m'  ->
           tmpk ≡ memory_next_key m ->
           @MSH_DSH_compat _ _ (op_family t) rr
                           ((DSHnatVal (proj1_sig t),false) :: (DSHPtrVal tmpk o,false) :: σ)
                           (memory_set m' tmpk mb)
                           (incrPVar 0 (incrPVar 0 x_p)) (PVar 1) P)

       (MF : MSHOperator_Facts (@MSHIReduction i o (S n) init dot _ op_family))
       (FMF : ∀ (j : nat) (jc : j < (S n)), MSHOperator_Facts (op_family (mkFinNat jc)))
       (FD : ∀ (j : nat) (jc : j < (S n)),
           Same_set (FinNat o) (m_out_index_set (op_family (mkFinNat jc)))
                    (Full_set (FinNat o)))
  :
    @MSH_DSH_compat
      _ _
      (@MSHIReduction i o (S n) init dot pdot op_family)
      (DSHSeq
         (DSHMemInit y_p init)
         (DSHAlloc o
                   (DSHLoop (S n)
                            (DSHSeq
                               rr
                               (DSHMemMap2 o y_p''
                                           (PVar 1)
                                           y_p''
                                           df)))))
      σ m x_p y_p DP.
Proof.
  subst.
  constructor.
  intros x_m y_m X_M Y_M.
  unfold evalPExpr_id in *.

  (* prepare context and memory lookups *)
  destruct (evalPExpr σ x_p) as [| (x_id, x_sz)] eqn:X_ID;
    [unfold lookup_PExpr_wsize in X_M; rewrite X_ID in X_M; inversion X_M |].
  destruct (evalPExpr σ y_p) as [| (y_id, y_sz)] eqn:Y_ID;
    [unfold lookup_PExpr_wsize in Y_M; rewrite Y_ID in Y_M; inversion Y_M |].

  assert (X_IDID : evalPExpr_id σ x_p = inr x_id)
    by (cbn; rewrite X_ID; reflexivity).
  assert (Y_IDID : evalPExpr_id σ y_p = inr y_id)
    by (cbn; rewrite Y_ID; reflexivity).
    
  replace x_sz with i in *
    by (symmetry; eapply lookup_PExpr_size_invariant';
        [rewrite X_ID; reflexivity | eassumption]).
  replace y_sz with o in *
    by (symmetry; eapply lookup_PExpr_size_invariant';
        [rewrite Y_ID; reflexivity | eassumption]).
  clear x_sz y_sz.
  
  assert (XID_M : memory_lookup m x_id = Some x_m)
    by (eapply lookup_PExpr_memory_lookup; eassumption).
  assert (YID_M : memory_lookup m y_id = Some y_m)
    by (eapply lookup_PExpr_memory_lookup; eassumption).
  assert (T : x_id ≢ y_id) by (intros C; contradict XY; rewrite C; reflexivity);
    clear XY; rename T into XY.

  copy_apply lookup_PExpr_wsize_OK_no_size X_M.
  rename X_M into X_M_SZ, H into X_M.
  copy_apply lookup_PExpr_wsize_OK_no_size Y_M.
  rename Y_M into Y_M_SZ, H into Y_M.

  induction n.
  -
    (* go through init *)
    remember (DSHLoop (S 0)
                  (DSHSeq rr
                     (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) (PVar 1) 
                                 (incrPVar 0 (incrPVar 0 y_p)) df)))
      as loop eqn:LOOP.
    remember (DSHAlloc o loop) as dop.
    cbn [evalDSHOperator estimateFuel].
    rewrite evalDSHOperator_estimateFuel_ge by (subst; cbn; lia).
    cbn [evalDSHOperator estimateFuel].
    simpl bind.
    rewrite Y_ID.
    unfold memory_lookup_err.
    destruct (memory_lookup m y_id) eqn:YID_M'; try some_none.
    replace (trywith "Error looking up 'y' in DSHMemInit" (Some m0))
      with (@inr string mem_block m0)
      by reflexivity.
    replace (assert_NT_le "DSHMemInit 'size' larger than 'y_size'" o o)
      with (@inr string unit tt)
      by (unfold assert_NT_le, NatAsNT.MNatAsNT.to_nat; rewrite Nat.leb_refl; reflexivity).
    rewrite evalDSHOperator_estimateFuel_ge by (subst; cbn; lia).
    some_inv.
    rename m0 into y_m'.
    remember (memory_set m y_id
                         (mem_union (mem_const_block (NatAsNT.MNatAsNT.to_nat o) init)
                                    y_m'))
      as init_m eqn:INIT_M; symmetry in INIT_M.
    remember (memory_next_key init_m) as t_id eqn:T_ID; symmetry in T_ID.
    subst dop.
  
    (* deal with y_m and y_m' (get rid of one) *)
    remember (λ (md : mem_block) (m' : memory),
              err_p (λ ma : mem_block, SHCOL_DSHCOL_mem_block_equiv y_m ma md)
                    (lookup_PExpr σ m' y_p))
      as Rel'.
    rename y_m' into t, y_m into y_m';
      rename t into y_m, YID_M into YM_YM', YID_M' into YID_M.
    rewrite <-YM_YM' in Y_M.
    remember (λ (md : mem_block) (m' : memory),
               err_p (λ ma : mem_block, SHCOL_DSHCOL_mem_block_equiv y_m ma md)
                     (lookup_PExpr σ m' y_p)) as Rel.
    assert (T : forall omb oem, h_opt_opterr_c Rel omb oem <-> h_opt_opterr_c Rel' omb oem);
      [| apply T; clear T HeqRel' Rel' YM_YM' Y_M_SZ y_m']. (* HERE *)
    {
      assert (forall mb m, Rel' mb m <-> Rel mb m).
      {
        subst; clear - YM_YM'.
        split; intros.
        all: inversion H; constructor.
        all: rewrite YM_YM' in *; assumption.
      }
      clear - H.
      split; intros.
      all: inversion H0; try constructor.
      all: apply H.
      all: assumption.
    }
  
    
    (* useful facts about init *)
    assert (T_next_M : memory_next_key m ≡ t_id).
    {
      subst.
      rewrite memory_next_key_override.
      reflexivity.
      apply mem_block_exists_exists_equiv.
      eexists.
      eq_to_equiv.
      eassumption.
    }
    assert (TX_neq : t_id <> x_id)
      by (apply memory_lookup_not_next_equiv in XID_M; congruence).
    assert (TY_neq : t_id <> y_id)
      by (eq_to_equiv; apply memory_lookup_not_next_equiv in YID_M; congruence).
    rename XY into T; assert (XY_neq : x_id <> y_id) by congruence; clear T.
    assert (INIT_equiv_M : memory_equiv_except init_m m y_id)
      by (intros k H; subst init_m;
          rewrite memory_lookup_memory_set_neq by congruence; reflexivity).

    simpl bind in *.

    (* specialize FC *)
    remember (Nat.lt_0_succ 0) as o1 eqn:O1.
    specialize (FC init_m t_id (mkFinNat o1) y_id mem_empty).
    full_autospecialize FC; try congruence.
    {
      intros k v L.
      subst init_m.
      destruct (Nat.eq_dec k y_id).
      -
        rewrite memory_lookup_memory_set_eq by congruence.
        eexists.
        split.
        reflexivity.
        congruence.
      -
        exists v.
        rewrite memory_lookup_memory_set_neq by congruence.
        intuition.
    }
    cbn in FC.
    inversion_clear FC as [T]; rename T into FC.
    specialize (FC x_m mem_empty).
    full_autospecialize FC.
    {
      repeat rewrite lookup_PExpr_wsize_incrPVar.
      unfold lookup_PExpr_wsize.
      rewrite X_ID.
      cbn.
      unfold memory_lookup_err.
      subst init_m.
      repeat rewrite memory_lookup_memory_set_neq by congruence.
      unfold trywith.
      repeat break_match; try some_none; try inl_inr.
      repeat constructor.
      inversion Heqs.
      inversion XID_M.
      subst.
      rewrite H2.
      reflexivity.
    }
    {
      cbn.
      unfold memory_lookup_err.

      rewrite memory_lookup_memory_set_eq by congruence.
      reflexivity.
    }

    
    cbn in FC.
    inversion FC as [M D | msg M D | mm dm R M D ]; clear FC.
    + (* DSH runs out of fuel *)
      exfalso; clear - D.
      symmetry in D.
      contradict D.
      apply is_Some_ne_None.
      apply evalDSHOperator_estimateFuel.
    + (* both MSH and DSH fail *)
      cbn.

      (* simplify mem_op to None *)
      unfold get_family_mem_op.
      rewrite <-O1.
      destruct mem_op; try some_none.

      (* simplify dop *)
      subst loop.
      cbn.
      rewrite T_ID.
      rewrite evalDSHOperator_estimateFuel_ge by lia.
      rewrite <-D.
      constructor.
    +
      (* both MSH and DSH succeed *)
      cbn.

      (* simplify mem_op down to fold *)
      unfold get_family_mem_op.
      rewrite <-O1.
      destruct mem_op as [m'|] eqn:MM; 
        [some_inv; subst m' | some_none].
      cbn.

      (* simplify dop down to MemMap2*)
      subst loop.
      cbn.
      rewrite T_ID.
      rewrite evalDSHOperator_estimateFuel_ge by lia.
      rewrite <-D.
      rewrite evalDSHOperator_estimateFuel_ge
        by (cbn; pose proof estimateFuel_positive rr; lia).

      (* asserts to be used by MemMap2_merge_with_def *)
      assert (M_subs_DM : memory_subset_except y_id m dm).
      {
        clear - o P D T_next_M INIT_M TY_neq.
        subst init_m.
        unfold memory_subset_except; intros.
        assert (KT_neq : k <> t_id)
          by (apply memory_lookup_not_next_equiv in H; congruence).
        clear T_next_M.
        inversion_clear P as [T S]; clear T.
        symmetry in D; eq_to_equiv.
        apply S with (y_i:=t_id) (y_size:=o) in D; [| reflexivity]; clear S.
        specialize (D k KT_neq).
        destruct (Nat.eq_dec k y_id).
        -
          eexists.
          rewrite <-D; clear D.
          rewrite memory_lookup_memory_set_neq by congruence.
          rewrite memory_lookup_memory_set_eq by congruence.
          split.
          reflexivity.
          congruence.
        -
          eexists.
          rewrite <-D; clear D.
          repeat rewrite memory_lookup_memory_set_neq by congruence.
          split.
          eassumption.
          reflexivity.
      }
      assert (T : exists t_dm,
                   lookup_PExpr ((DSHnatVal 0,false) :: (DSHPtrVal t_id o,false) :: σ) dm (PVar 1) = inr t_dm);
        [| destruct T as [t_dm T_DM]].
      {
        cbn.
        intros.
        clear - D P.
        inversion_clear P as [S T]; clear T.
        symmetry in D; eq_to_equiv.
        apply S with (k:=t_id) in D; clear S.
        assert (mem_block_exists t_id (memory_set init_m t_id mem_empty))
          by (apply mem_block_exists_memory_set_eq; reflexivity).
        apply D in H; clear D.
        apply memory_is_set_is_Some in H.
        apply is_Some_def in H.
        destruct H.
        exists x.
        unfold memory_lookup_err.
        rewrite H.
        constructor.
        reflexivity.
      }
      assert (YID_DM : memory_lookup dm y_id =
                      Some (mem_union (mem_const_block o init) y_m)).
      {
        clear - o D P INIT_M TY_neq.
        subst init_m.
        inversion_clear P as [T S]; clear T.
        symmetry in D; eq_to_equiv.
        apply S with (y_i:=t_id) (y_size:=o) in D; [| reflexivity]; clear S.
        unfold memory_equiv_except in D.
        rewrite <-D by congruence; clear D.
        rewrite memory_lookup_memory_set_neq by congruence.
        rewrite memory_lookup_memory_set_eq by congruence.
        reflexivity.
      }
      assert (Y_ID_in_dm : evalPExpr ((DSHnatVal 0,false) :: (DSHPtrVal t_id 0,false) :: σ)
                                    (incrPVar 0 (incrPVar 0 y_p)) = inr (y_id, o))
        by (repeat rewrite evalPExpr_incrPVar; rewrite Y_ID; reflexivity).
      assert (Y_DM : lookup_PExpr ((DSHnatVal 0,false) :: (DSHPtrVal t_id o,false) :: σ)
                               dm (incrPVar 0 (incrPVar 0 y_p)) =
                     inr (mem_union (mem_const_block o init) y_m)).
      {
        clear - YID_DM Y_ID.
        repeat rewrite lookup_PExpr_incrPVar.
        unfold lookup_PExpr, memory_lookup_err.
        rewrite Y_ID.
        cbn.
        rewrite YID_DM.
        reflexivity.
      }
      assert (Dot_compat_dm : MSH_DSH_BinCarrierA_compat dot
                                               (protect_p ((DSHnatVal 0,false) :: (DSHPtrVal t_id o,false) :: σ) (incrPVar 0 (incrPVar 0 y_p)) )
                                               df dm);
        [| clear DC].
      {
        eapply DC.
        reflexivity.
        assumption.
      }
      assert (T_DM_dense : ∀ k : nat, k < o → mem_in k t_dm).
      {
        intros.
        inversion R.
        assert (x = t_dm)
          by (eq_to_equiv; rewrite T_DM in H0; inl_inr_inv; assumption).
        rewrite H2 in H1.
        eapply SHCOL_DSHCOL_mem_block_equiv_keys_union.
        eassumption.
        right.
        clear - MM FMF FD H.
        specialize (FMF 0 o1); specialize (FD 0 o1).
        inversion_clear FMF as [T1 FILL T2]; clear T1 T2.
        apply FILL with (jc:=H) (m0:=x_m).
        assumption.
        unfold Same_set, Included in FD.
        destruct FD as [T FD]; clear T.
        apply FD.
        constructor.
      }
      assert (IY_dense : ∀ k : nat, k < o → mem_in k (mem_union (mem_const_block o init) y_m)).
      {
        intros.
        eapply mem_union_as_Union.
        reflexivity.
        left.
        apply mem_in_mem_lookup.
        erewrite mem_const_block_find.
        constructor.
        assumption.
      }
      
      repeat break_match.
      * (* Map2 fails *)
        exfalso.
        eq_to_equiv.
        enough (exists m', evalDSHOperator ((DSHnatVal 0,false) :: (DSHPtrVal t_id o,false) :: σ)
            (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) (PVar 1)
               (incrPVar 0 (incrPVar 0 y_p)) df) dm
            (estimateFuel
               (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) (PVar 1) 
                  (incrPVar 0 (incrPVar 0 y_p)) df)) = Some (inr m'))
          by (destruct H; rewrite H in Heqo0; some_inv; inl_inr).
        eapply DSHMap2_succeeds; try eassumption.
        { reflexivity. }
        {
          eapply lookup_PExpr_size.
          repeat rewrite evalPExpr_incrPVar; eassumption.
          eassumption.
        }
      * (* Map2 succeeds *)
        rename m0 into ma, Heqo0 into MA; clear Heqs0 s.
        constructor.
        subst Rel.

        destruct (lookup_PExpr σ (memory_remove ma t_id) y_p) eqn:Y_MA.
        {
          (* [y_p] disappeared in [ma] - not pure behavior *)
          exfalso.
          pose proof @MemMap2_DSH_pure
               (incrPVar 0 (incrPVar 0 y_p)) (PVar 1) (incrPVar 0 (incrPVar 0 y_p)) o df.
          eq_to_equiv.
          cbn in Y_MA.
          unfold memory_lookup_err, trywith in Y_MA.
          repeat break_match; try inl_inr; repeat inl_inr_inv.
          1: inversion Y_MA.
          eq_to_equiv.
          tuple_inversion_equiv.
          rewrite H0 in Heqo0.
          rewrite memory_lookup_memory_remove_neq in Heqo0 by congruence.
          clear - Heqo0 MA H YID_DM.
          inversion_clear H as [S T]; clear T.
          apply S with (k:=y_id) in MA; clear S.
          contradict Heqo0.
          apply is_Some_nequiv_None.
          repeat rewrite memory_is_set_is_Some in *.
          apply MA.
          unfold is_Some; break_match; try some_none.
          trivial.
        }
        constructor.

        apply Option_equiv_eq in MA.
        apply err_equiv_eq in Y_MA.
        rewrite MemMap2_merge_with_def_firstn with (init:=init) in MA; try eassumption.
        2: reflexivity.
        2: {
          cbn.
          repeat rewrite evalPExpr_incrPVar.
          rewrite Y_ID.
          reflexivity.
        }
        2: {
          eapply lookup_PExpr_size.
          repeat rewrite evalPExpr_incrPVar; rewrite Y_ID; reflexivity.
          eassumption.
        }
        
        some_inv; inl_inr_inv.
        rewrite <-MA in Y_MA; clear MA ma.
        assert (m0 = mem_union (mem_merge_with_def dot init
                                 (mem_firstn o (mem_union (mem_const_block o init) y_m))
                                 (mem_firstn o t_dm))
                               (mem_union (mem_const_block o init) y_m)).
        {
          eq_to_equiv.
          unfold lookup_PExpr, memory_lookup_err in Y_MA.
          assert (evalPExpr σ y_p ≡ inr (y_id, o))
            by (clear - Y_ID; destruct evalPExpr as [| (i',o')]; try inl_inr;
                inl_inr_inv; tuple_inversion_equiv; subst_nat; reflexivity).
          rewrite H in Y_MA.
          simpl in Y_MA.
          rewrite memory_lookup_memory_remove_neq in Y_MA by congruence.
          rewrite memory_lookup_memory_set_eq in Y_MA by congruence.
          unfold trywith in Y_MA.
          inversion Y_MA; subst.
          rewrite H2.
          reflexivity.
        }
        rewrite H.
        clear Y_MA H m0.
        intros k.
        destruct (le_lt_dec o k).
        --
          constructor 1.
          ++
            apply mem_not_in_mem_lookup.
            rewrite <-mem_merge_with_def_as_Union.
            unfold MMemoryOfR.mem_empty, mem_in.
            rewrite NP.F.empty_in_iff.
            enough (not (mem_in k mm)) by intuition.
            eapply out_mem_oob; eassumption.
          ++
            unfold mem_lookup, mem_union, mem_merge_with_def.
            repeat rewrite NP.F.map2_1bis by reflexivity.
            repeat rewrite mem_firstn_lookup_oob by assumption.
            rewrite mem_const_block_find_oob by assumption.
            reflexivity.
        --
          constructor 2.
          ++
            apply mem_in_mem_lookup.
            rewrite <-mem_merge_with_def_as_Union.
            right.
            eapply out_mem_fill_pattern.
            eassumption.
            instantiate (1:=l).
            apply FD.
            constructor.
          ++
            rewrite firstn_mem_const_block_union.
            unfold mem_lookup, mem_union, mem_merge_with_def.
            unfold MMemoryOfR.mem_merge_with_def.
            repeat rewrite NP.F.map2_1bis by reflexivity.
            rewrite mem_const_block_find by assumption.
            rewrite mem_firstn_lookup by assumption.
            specialize (T_DM_dense k l).
            apply mem_in_mem_lookup, is_Some_def in T_DM_dense.
            destruct T_DM_dense as [k_tdm K_TDM].
            rewrite K_TDM.
            cbn.

            inversion R.
            assert (exists k_mm, mem_lookup k mm = Some k_mm).
            {
              apply is_Some_equiv_def.
              apply mem_in_mem_lookup.
              eapply out_mem_fill_pattern.
              eassumption.
              instantiate (1:=l).
              apply FD.
              constructor.
            }
            eq_to_equiv; symmetry in H; memory_lookup_err_to_option.
            assert (T : x = t_dm); [| rewrite T in *; clear T x].
            {
              clear - H T_DM.
              cbn in T_DM.
              memory_lookup_err_to_option.
              rewrite H in T_DM; some_inv.
              assumption.
            }
            destruct H1 as [k_mm K_MM].
            break_match.
            all: eq_to_equiv; rewrite K_MM in Heqo0.
            all: try some_none; some_inv.
            rewrite <-Heqo0 in *; clear c Heqo0.
            
            specialize (H0 k).
            rewrite K_MM, K_TDM in H0.
            inversion H0; try some_none.
            some_inv.
            rewrite H2.
            reflexivity.
      * (* Map2 runs out of fuel *)
        clear - Heqo0.
        assert (is_Some (evalDSHOperator ((DSHnatVal 0,false) :: (DSHPtrVal t_id o,false) :: σ)
            (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) (PVar 1)
               (incrPVar 0 (incrPVar 0 y_p)) df) dm
            (estimateFuel
               (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) (PVar 1)
                           (incrPVar 0 (incrPVar 0 y_p)) df))))
          by apply evalDSHOperator_estimateFuel.
        unfold is_Some in H.
        break_match; try some_none.
        contradiction.
  -
    (* MSH step *)
    (* done immediately to get [opf] *)
    rewrite IReduction_MSH_step.

    (* renaming *)
    rename n into n'; remember (S n') as n.
    remember (Nat.lt_succ_diag_r n) as nSn.
    rename op_family into S_opf; remember (shrink_m_op_family S_opf) as opf.

    (* specialize IHn *)
    specialize (IHn opf).
    full_autospecialize IHn.
    {
      apply IReduction_DSH_pure; auto.
    }
    {
      intros.
      subst opf.
      unfold shrink_m_op_family.
      eapply FC.
      all: eassumption.
    }
    {
      subst.
      unfold shrink_m_op_family.
      apply IReduction_MFacts.
      -
        intros.
        apply FMF.
      -
        intros.
        apply FD.
    }
    {
      subst opf.
      unfold shrink_m_op_family.
      intros.
      apply FMF.
    }
    {
      subst opf.
      unfold shrink_m_op_family.
      intros.
      apply FD.
    }

    (* cases by [opf] and [loopN] *)
    remember (evalDSHOperator σ
               (DSHSeq (DSHMemInit y_p init)
                  (DSHAlloc o
                     (DSHLoop n
                        (DSHSeq rr
                           (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) 
                              (PVar 1) (incrPVar 0 (incrPVar 0 y_p)) df))))) m
               (estimateFuel
                  (DSHSeq (DSHMemInit y_p init)
                     (DSHAlloc o
                        (DSHLoop n
                           (DSHSeq rr
                              (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) 
                                 (PVar 1) (incrPVar 0 (incrPVar 0 y_p)) df)))))))
      as d.
    inversion IHn; subst d; clear IHn.
    +
      (* [loopN] ran out of fuel *)
      exfalso; clear - H1; symmetry in H1; contradict H1.
      apply is_Some_ne_None.
      apply evalDSHOperator_estimateFuel.
    +
      (* both [MSHIReduction opf] and [loopN] failed *)
      replace (mem_op (MSHIReduction init dot opf) x_m) with (@None mem_block).
      simpl bind.

      eq_to_equiv.
      rewrite MemInit_simpl in *; try eassumption.
      symmetry in H1.
      remember (DSHLoop n
                        (DSHSeq rr
                                (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) (PVar 1)
                                            (incrPVar 0 (incrPVar 0 y_p)) df))) as t.
      cbn in H1.
      repeat break_match;
        try some_none; repeat some_inv;
        try inl_inr; repeat inl_inr_inv.
      rewrite Alloc_Loop_error1.
      constructor.
      reflexivity.
      eq_to_equiv.
      rewrite <-Heqt.
      apply Heqo0.
      all: reflexivity.
    +
      (* both [MSHIReduction opf] and [loopN] succeeded *)
      symmetry in H, H1.
      rename a into opf_mm, H into OPF_MM, b into loopN_m, H1 into LoopN_M.
      rename H0 into OPF_LoopN.

      apply Option_equiv_eq in LoopN_M.

      (* lookups in [loopN_m] *)
      assert (M_LoopNM_E : memory_equiv_except m loopN_m y_id).
      {
        eapply mem_write_safe with (y_i:=y_id) in LoopN_M.
        assumption.
        erewrite Y_ID.
        reflexivity.
        Unshelve.
        apply IReduction_DSH_pure; auto.
      }
      assert (M_LoopNM_K : forall k, mem_block_exists k m ↔ mem_block_exists k loopN_m).
      {
        intros.
        unshelve eapply mem_stable with (k:=k) in LoopN_M.
        exact y_p.
        apply IReduction_DSH_pure; auto.
        eassumption.
      }
      assert (X_LoopNM : lookup_PExpr σ loopN_m x_p = inr x_m).
      {
        unfold lookup_PExpr, memory_lookup_err, trywith.
        rewrite X_ID.
        cbn.
        specialize (M_LoopNM_E x_id XY).
        rewrite XID_M in M_LoopNM_E.
        break_match; try some_none.
        some_inv; rewrite M_LoopNM_E; reflexivity.
      }
      assert (T : exists y_loopNm, lookup_PExpr σ loopN_m y_p = inr y_loopNm);
        [| destruct T as [y_loopNm Y_LoopNM]].
      {
        unfold lookup_PExpr, memory_lookup_err, trywith.
        rewrite Y_ID.
        cbn.
        break_match; [eexists; reflexivity |].
        enough (T : is_Some (memory_lookup loopN_m y_id)) by (rewrite Heqo0 in T; some_none).
        apply memory_is_set_is_Some.
        apply M_LoopNM_K.
        apply memory_is_set_is_Some.
        apply is_Some_equiv_def; eexists; eassumption.
      }

      (* lookups in [init_m] *)
      rewrite MemInit_simpl in *; try (eq_to_equiv; eassumption); try reflexivity.
      remember (memory_set m y_id (mem_union (mem_const_block o init) y_m)) as init_m.
      assert (M_InitM_E : memory_equiv_except m init_m y_id).
      {
        intros k YK.
        subst init_m.
        rewrite memory_lookup_memory_set_neq by congruence.
        reflexivity.
      }
      assert (M_InitM_K : forall k, mem_block_exists k m <-> mem_block_exists k init_m).
      {
        intros.
        subst init_m.
        repeat rewrite memory_is_set_is_Some.
        destruct (Nat.eq_dec k y_id).
        -
          subst.
          rewrite memory_lookup_memory_set_eq by congruence.
          cbn.
          unfold is_Some.
          break_match; try some_none.
          reflexivity.
        -
          rewrite memory_lookup_memory_set_neq by congruence.
          reflexivity.
      }
      assert (X_InitM : lookup_PExpr σ init_m x_p = inr x_m).
      {
        subst init_m.
        unfold lookup_PExpr, memory_lookup_err, trywith.
        rewrite X_ID.
        simpl.
        rewrite memory_lookup_memory_set_neq by congruence.
        break_match; try some_none; some_inv; f_equiv; assumption.
      }
      remember (mem_union (mem_const_block o init) y_m) as y_initm.
      assert (Y_InitM : lookup_PExpr σ init_m y_p = inr y_initm).
      {
        subst init_m.
        unfold lookup_PExpr, memory_lookup_err, trywith.
        rewrite Y_ID.
        simpl.
        rewrite memory_lookup_memory_set_eq by congruence.
        reflexivity.
      }
      assert (INIT_equiv_M : memory_equiv_except init_m m y_id)
        by (intros k H; subst init_m;
            rewrite memory_lookup_memory_set_neq by congruence; reflexivity).

      (* facts about t_id *)
      remember (memory_next_key init_m) as t_id eqn:T_ID.
      assert (T_next_M : t_id ≡ memory_next_key m).
      {
        subst.
        rewrite memory_next_key_override.
        reflexivity.
        apply mem_block_exists_exists_equiv.
        eexists.
        eq_to_equiv.
        eassumption.
      }
      assert (TX_neq : t_id <> x_id)
        by (apply memory_lookup_not_next_equiv in XID_M; congruence).
      assert (TY_neq : t_id <> y_id)
        by (eq_to_equiv; apply memory_lookup_not_next_equiv in YID_M; congruence).
      rename XY into T; assert (XY_neq : x_id <> y_id) by congruence; clear T.

      (* lookups in [loopN_tm] *)
      apply DSHAlloc_inv with (t_id:=t_id) in LoopN_M; [| subst; reflexivity].
      destruct LoopN_M as [loopN_tm [LoopN_TM LoopN_M]].
      assert (X_LoopNTM : lookup_PExpr σ loopN_tm x_p = inr x_m).
      {
        rewrite <-X_LoopNM.
        unfold lookup_PExpr, memory_lookup_err.
        rewrite X_ID.
        cbn.
        rewrite LoopN_M.
        rewrite memory_lookup_memory_remove_neq by congruence.
        reflexivity.
      }
      assert (Y_LoopNTM : lookup_PExpr σ loopN_tm y_p = inr y_loopNm).
      {
        rewrite <-Y_LoopNM.
        unfold lookup_PExpr, memory_lookup_err.
        rewrite Y_ID.
        cbn.
        rewrite LoopN_M.
        rewrite memory_lookup_memory_remove_neq by congruence.
        reflexivity.
      }
      assert (T : exists t_loopNtm, memory_lookup loopN_tm t_id = Some t_loopNtm);
        [| destruct T as [t_loopNtm T_LoopNTM]].
      {
        clear - P LoopN_TM.
        assert (mem_stable'
                  (DSHLoop n (DSHSeq rr
                     (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) 
                        (PVar 1) (incrPVar 0 (incrPVar 0 y_p)) df)))).
        {
          apply DSHLoop_mem_stable.
          apply DSHSeq_mem_stable.
          eapply DSH_pure_mem_stable; eassumption.
          eapply DSH_pure_mem_stable; eapply MemMap2_DSH_pure.
        }
        apply H in LoopN_TM; clear H.
        specialize (LoopN_TM t_id).
        repeat rewrite memory_is_set_is_Some in LoopN_TM.
        rewrite memory_lookup_memory_set_eq in LoopN_TM by reflexivity.
        assert (T : is_Some (Some mem_empty)) by reflexivity;
          apply LoopN_TM in T; clear LoopN_TM.
        apply is_Some_def in T.
        destruct T.
        exists x.
        rewrite H; reflexivity.
      }
      assert (M_sub_LoopNTM : memory_subset_except y_id m loopN_tm).
      {
        clear - M_LoopNM_E M_LoopNM_K YID_M LoopN_M TY_neq T_next_M.
        intros k v V.
        destruct (Nat.eq_dec k y_id).
        -
          subst.
          specialize (M_LoopNM_K y_id).
          repeat rewrite memory_is_set_is_Some in M_LoopNM_K.
          assert (is_Some (memory_lookup m y_id))
            by (apply is_Some_equiv_def; eexists; eassumption).
          apply M_LoopNM_K in H.
          eapply is_Some_equiv_def in H; destruct H.
          exists x.
          intuition.
          rewrite <-H.
          rewrite LoopN_M.
          rewrite memory_lookup_memory_remove_neq by congruence.
          reflexivity.
        -
          exists v.
          intuition.
          rewrite <-V.
          rewrite M_LoopNM_E by congruence.
          rewrite LoopN_M.
          rewrite memory_lookup_memory_remove_neq; [reflexivity |].
          clear - T_next_M V.
          apply memory_lookup_not_next_equiv in V.
          congruence.
      }
      (* specialize FC *)
      specialize (FC loopN_tm t_id (mkFinNat nSn) y_id t_loopNtm).
      full_autospecialize FC; try reflexivity; try congruence; try assumption.
      cbn in FC.
      inversion_clear FC as [T]; rename T into FC.
      specialize (FC x_m t_loopNtm).
      full_autospecialize FC.
      {
        repeat rewrite lookup_PExpr_wsize_incrPVar.
        unfold lookup_PExpr_wsize, memory_lookup_err, trywith.
        rewrite X_ID.
        simpl.
        rewrite memory_lookup_memory_set_neq by congruence.
        unfold lookup_PExpr, memory_lookup_err in X_LoopNTM.
        rewrite X_ID in X_LoopNTM.
        cbn in X_LoopNTM.
        repeat break_match; try inl_inr.
        inversion X_LoopNTM.
        repeat constructor.
        inversion Heqs.
        rewrite <-H0.
        inversion X_LoopNTM.
        rewrite H2.
        reflexivity.
      }
      {
        cbn.
        unfold memory_lookup_err.
        rewrite memory_lookup_memory_set_eq by congruence.
        reflexivity.
      }
      rewrite memory_set_same in FC by assumption.


      
      inversion FC as [M D | msg M D | opf_n_m rr_m R OPF_M RR_M]; clear FC.
      *
        (* rr[n] runs out of fuel *)
        exfalso; symmetry in D; contradict D; clear.
        apply is_Some_ne_None.
        apply evalDSHOperator_estimateFuel.
      *
        (* last family member fails in both MSH and DSH *)
        rewrite Alloc_Loop_error2.
        cbn.
        repeat break_match; constructor.
        reflexivity.
        rewrite <-T_ID.
        apply LoopN_TM.
        cbn.
        rewrite evalDSHOperator_estimateFuel_ge
          by (pose proof estimateFuel_positive rr; cbn; nia).
        rewrite <-T_ID.
        rewrite <-D.
        reflexivity.
      *
        (* last family member succeeds in both MSH and DSH *)
        symmetry in OPF_M, RR_M.

        assert (X_RRM : lookup_PExpr σ rr_m x_p = inr x_m).
        {
          clear - P RR_M X_LoopNTM X_ID TX_neq.
          eq_to_equiv_hyp.
          eapply mem_write_safe in RR_M; [| cbn; reflexivity].
          unfold lookup_PExpr, memory_lookup_err in *.
          rewrite X_ID in *.
          cbn in *.
          rewrite RR_M in X_LoopNTM by congruence.
          assumption.
        }
        assert (Y_RRM : lookup_PExpr σ rr_m y_p = inr y_loopNm).
        {
          clear - P RR_M Y_LoopNTM Y_ID TY_neq.
          eq_to_equiv_hyp.
          eapply mem_write_safe in RR_M; [| cbn; reflexivity].
          unfold lookup_PExpr, memory_lookup_err in *.
          rewrite Y_ID in *.
          cbn in *.
          rewrite RR_M in Y_LoopNTM by congruence.
          assumption.
        }
        assert (T : exists t_rrm, memory_lookup rr_m t_id = Some t_rrm);
          [| destruct T as [t_rrm T_RRM]].
        {
          apply is_Some_equiv_def.
          apply memory_is_set_is_Some.
          eq_to_equiv.
          apply mem_stable with (k:=t_id) in RR_M.
          apply RR_M.
          apply memory_is_set_is_Some.
          apply is_Some_equiv_def.
          eexists; eassumption.
        }

        assert (opf_mm_fill : forall k, k < o -> mem_in k opf_mm).
        {
          intros.
          replace (IReduction_mem dot init (get_family_mem_op opf) x_m)
            with (mem_op (MSHIReduction init dot opf) x_m)
            in OPF_MM
            by reflexivity.
          unshelve eapply out_mem_fill_pattern with (j:=k) in OPF_MM; try eassumption.
          subst opf.
          unfold shrink_m_op_family.
          apply IReduction_MFacts.
          intros.
          apply FMF.
          intros.
          apply FD.
          apply OPF_MM.
          cbn.
          apply m_family_out_set_implies_members.
          subst opf.
          unfold shrink_m_op_family.
          eexists.
          eexists.
          eapply FD.
          constructor.

          Unshelve.
          exact O. (* TODO: this is rather strange - just returning a random nat *)
          lia.
        }

        assert (opf_n_m_fill : forall k, k < o -> mem_in k opf_n_m).
        {
          intros.
          eapply out_mem_fill_pattern; try eassumption.
          apply FD.
          constructor.
          Unshelve.
          assumption.
        }

        assert (y_loopNm_fill : forall k, k < o -> mem_in k y_loopNm).
        {
          clear Y_RRM Y_LoopNM.
          generalize dependent y_loopNm.
          eapply DSHLoop_invariant with (m:=memory_set init_m t_id mem_empty)
                                        (rm:=loopN_tm).
          4: eassumption.
          -
            intros m1 m2 ME.
            split; intros.
            all: specialize (H y_loopNm).
            1: autospecialize H; [rewrite ME; assumption |].
            2: autospecialize H; [rewrite <-ME; assumption |].
            all: apply H; assumption.
          -
            intros.
            rename m into mb, m' into ma, y_loopNm into b.
            cbn in H0.
            repeat break_match; try some_none; try (some_inv; inl_inr).
            rewrite evalDSHOperator_estimateFuel_ge in H0 by (cbn; nia).
            eapply MemMap2_result_fill in H0.
            eapply H0.
            repeat rewrite lookup_PExpr_incrPVar.
            assumption.
            assumption.
          -
            intros.
            unfold lookup_PExpr, memory_lookup_err in Y_LoopNTM.
            rewrite Y_ID in Y_LoopNTM.
            simpl bind in Y_LoopNTM.
            subst init_m.
            rewrite memory_lookup_memory_set_neq in Y_LoopNTM by congruence.
            rewrite memory_lookup_memory_set_eq in Y_LoopNTM by congruence.
            cbn in Y_LoopNTM.
            inl_inr_inv.
            rewrite <-Y_LoopNTM.
            subst y_initm.
            apply mem_in_mem_lookup.
            unfold mem_lookup, mem_union.
            rewrite NP.F.map2_1bis by reflexivity.
            rewrite mem_const_block_find by assumption.
            reflexivity.
        }

        assert (t_rrm_fill : forall k, k < o -> mem_in k t_rrm).
        {
          intros.
          cbn in R.
          unfold memory_lookup_err in R.
          rewrite T_RRM in R.
          cbn in R.
          inversion R.
          subst x.
          specialize (H1 k).
          specialize (opf_n_m_fill k H).
          apply mem_in_mem_lookup in opf_n_m_fill.
          apply is_Some_equiv_def in opf_n_m_fill.
          destruct opf_n_m_fill.
          rewrite H0 in H1.
          inversion H1; try some_none.
          apply mem_in_mem_lookup.
          apply is_Some_equiv_def.
          eexists; eassumption.
        }

        assert (
            evalDSHOperator ((DSHnatVal n,false) :: (DSHPtrVal t_id o,false) :: σ)
                            (DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p)) (PVar 1)
                                        (incrPVar 0 (incrPVar 0 y_p)) df)
                            rr_m
                            (estimateFuel ((DSHMemMap2 o (incrPVar 0 (incrPVar 0 y_p))
                                                       (PVar 1)
                                                       (incrPVar 0 (incrPVar 0 y_p))
                                                       df))) =
            Some (inr
                    (memory_set rr_m y_id (mem_union
                                          (mem_merge_with_def dot init
                                                              (mem_firstn o y_loopNm)
                                                              (mem_firstn o t_rrm))
                                          y_loopNm)))).
        {
          apply MemMap2_merge_with_def_firstn with (y_sz:=o).
          -
            assumption.
          -
            reflexivity.
          -
            repeat rewrite lookup_PExpr_incrPVar.
            assumption.
          -
            cbn.
            unfold memory_lookup_err.
            rewrite T_RRM.
            reflexivity.
          -
            unfold evalPExpr_id.
            repeat rewrite evalPExpr_incrPVar.
            rewrite Y_ID; reflexivity.
          -
            eapply lookup_PExpr_size.
            repeat rewrite evalPExpr_incrPVar.
            rewrite Y_ID.
            reflexivity.
            repeat rewrite lookup_PExpr_incrPVar.
            eassumption.
          -
            cbn in Y_RRM.
            rewrite Y_ID in Y_RRM.
            memory_lookup_err_to_option.
            assumption.
          -
            assumption.
          -
            eapply DC.
            reflexivity.
            unfold memory_subset_except.
            intros.
            destruct (Nat.eq_dec k y_id).
            +
              subst k.
              exists y_loopNm.
              split; [| congruence].
              apply Option_equiv_eq in RR_M.
              apply mem_write_safe with (y_i:=t_id) (y_size:=o) in RR_M; [| reflexivity].
              rewrite <-RR_M by congruence.
              unfold lookup_PExpr in Y_LoopNTM.
              rewrite Y_ID in Y_LoopNTM.
              cbn in Y_LoopNTM.
              memory_lookup_err_to_option.
              assumption.
            +
              destruct (Nat.eq_dec k t_id).
              *
                subst k.
                rewrite T_next_M in H.
                apply memory_lookup_not_next_equiv in H.
                congruence.
              *
                apply Option_equiv_eq in RR_M.
                apply mem_write_safe with (y_i:=t_id) (y_size:=o) in RR_M; [| reflexivity].
                specialize (M_sub_LoopNTM k v H).
                destruct M_sub_LoopNTM as [v' G].
                exists v'.
                rewrite <-RR_M by congruence.
                apply G.
        }

        (* DSH step *)
        erewrite Alloc_Loop_step; try (eq_to_equiv; eauto; fail).
        2: {
          intros.
          cbn.
          replace (Init.Nat.max (estimateFuel rr) 1)
            with (estimateFuel rr)
            by (pose proof estimateFuel_positive rr; lia).
          rewrite RR_M.
          rewrite evalDSHOperator_estimateFuel_ge
            by (pose proof estimateFuel_positive rr; cbn; lia).
          eapply H.
        }

        (* simplify MSH part *)
        replace (mem_op (MSHIReduction init dot opf) x_m)
          with (Some opf_mm)
          by (rewrite <-OPF_MM; reflexivity).
        remember (λ (md : mem_block) (m' : memory),
                  err_p (λ ma : mem_block, SHCOL_DSHCOL_mem_block_equiv y_m ma md)
                        (lookup_PExpr σ m' y_p))
          as Rel.
        cbn.
        constructor.

        (* coerse MSH and DSH steps to common form *)
        subst Rel.
        assert (T : lookup_PExpr σ
                  (memory_remove
                     (memory_set rr_m y_id
                        (mem_union
                           (mem_merge_with_def dot init
                                               (mem_firstn o y_loopNm)
                                               (mem_firstn o t_rrm))
                           y_loopNm))
                     t_id)
                  y_p = inr (mem_union (mem_merge_with_def dot init
                                                           (mem_firstn o y_loopNm)
                                                           (mem_firstn o t_rrm))
                                       y_loopNm)).
        {
          unfold lookup_PExpr, memory_lookup_err.
          rewrite Y_ID.
          simpl.
          rewrite memory_lookup_memory_remove_neq by congruence.
          rewrite memory_lookup_memory_set_eq by reflexivity.
          reflexivity.
        }

        rewrite T; clear T.
        constructor.
        intros k.
        destruct (le_lt_dec o k).
        --
          (* k is OOB *)
          constructor 1.
          ++
            apply mem_not_in_mem_lookup.
            rewrite <-mem_merge_with_def_as_Union.
            intros C; destruct C as [C | C]; contradict C.
            **
              move OPF_MM after l.
              replace (IReduction_mem dot init (get_family_mem_op opf) x_m)
                with (mem_op (MSHIReduction init dot opf) x_m)
                in OPF_MM
                by reflexivity.
              unshelve eapply out_mem_oob with (j:=k) in OPF_MM; try eassumption.
              subst opf.
              unfold shrink_m_op_family.
              apply IReduction_MFacts.
              intros.
              apply FMF.
              intros.
              apply FD.
            **
              eapply out_mem_oob; eassumption.
          ++
            assert (T : mem_lookup k (mem_union
                                        (mem_merge_with_def dot init
                                                            (mem_firstn o y_loopNm)
                                                            (mem_firstn o t_rrm))
                                        y_loopNm) = mem_lookup k y_loopNm).
            {
              unfold mem_lookup, mem_union.
              rewrite NP.F.map2_1bis by reflexivity.
              break_match; try reflexivity.
              enough (is_None (Some c)) by some_none.
              rewrite <-Heqo0; clear Heqo0 c.
              apply mem_not_in_mem_lookup.
              rewrite <-mem_merge_with_def_as_Union.
              intros C; destruct C as [C | C].
              all: contradict C.
              all: apply mem_not_in_mem_lookup.
              all: rewrite mem_firstn_lookup_oob; [reflexivity | assumption].
            }
            rewrite T.
            eapply MemMap2_rest_preserved with (k:=k) in H.
            2: repeat rewrite lookup_PExpr_incrPVar; eassumption.
            2: {
              repeat rewrite lookup_PExpr_incrPVar.
              unfold lookup_PExpr, memory_lookup_err.
              rewrite Y_ID.
              simpl bind.
              rewrite memory_lookup_memory_set_eq by reflexivity.
              cbn.
              reflexivity.
            }
            2: assumption.
            rewrite <-H.
            rewrite T.
            clear H T.


            clear Y_LoopNM y_loopNm_fill Y_RRM.
            generalize dependent y_loopNm.
            eapply DSHLoop_invariant with (m:=memory_set init_m t_id mem_empty)
                                          (rm:=loopN_tm).
            4: eassumption.
            **
              intros m1 m2 ME.
              split; intros.
              all: specialize (H y_loopNm).
              1: autospecialize H; [rewrite ME; assumption |].
              2: autospecialize H; [rewrite <-ME; assumption |].
              all: apply H; assumption.
            **
              intros.
              cbn in H0.
              repeat break_match;
                try some_none; repeat some_inv;
                try inl_inr; repeat inl_inr_inv.
              subst s.
              rewrite evalDSHOperator_estimateFuel_ge in H0
                by (pose proof estimateFuel_positive rr; cbn; lia).


              pose proof H0 as T.
              cbn in T.
                  
              repeat break_match; try some_none; repeat some_inv; try inl_inr.
              memory_lookup_err_to_option.

              clear Heqs0.
              rename Heqs1 into Heqs0,
                     Heqs2 into Heqs1,
                     Heqs3 into Heqs2,
                     Heqs4 into Heqs3.
              
              repeat rewrite evalPExpr_incrPVar in Heqs.
              rewrite Y_ID in Heqs; inl_inr_inv; subst y_id.
              clear Heqs1 Heqs2 Heqs3 T m4 m5.
              
              eapply MemMap2_rest_preserved in H0.
              4: eassumption.
              3: repeat rewrite lookup_PExpr_incrPVar; eassumption.
              2: {
                repeat rewrite lookup_PExpr_incrPVar.
                unfold lookup_PExpr, memory_lookup_err.
                rewrite Y_ID.
                cbn.
                rewrite Heqs0.
                cbn.
                reflexivity.
              }
              rewrite H0.
              apply H.

              unfold lookup_PExpr, memory_lookup_err.
              rewrite Y_ID.
              cbn.

              apply Option_equiv_eq in Heqo0.
              eapply mem_write_safe with (y_i:=t_id) (y_size:=o) in Heqo0; [| reflexivity].
              rewrite Heqo0 by congruence.
              rewrite Heqs0.
              reflexivity.
            **
              intros.
              unfold lookup_PExpr, memory_lookup_err in Y_LoopNTM.
              rewrite Y_ID in Y_LoopNTM.
              simpl bind in Y_LoopNTM.
              subst init_m.
              rewrite memory_lookup_memory_set_neq in Y_LoopNTM by congruence.
              rewrite memory_lookup_memory_set_eq in Y_LoopNTM by congruence.
              cbn in Y_LoopNTM.
              inl_inr_inv.
              rewrite <-Y_LoopNTM.
              subst y_initm.
              unfold mem_lookup, mem_union.
              rewrite NP.F.map2_1bis by reflexivity.
              rewrite mem_const_block_find_oob by assumption.
              reflexivity.
        --
          (* k is within bounds *)
          constructor 2.
          ++
            apply mem_in_mem_lookup.
            rewrite <-mem_merge_with_def_as_Union.
            right.
            eapply out_mem_fill_pattern; try eassumption.
            apply FD.
            constructor.
            Unshelve.
            assumption.
          ++
            assert (T : mem_lookup k (mem_union
                                        (mem_merge_with_def dot init
                                                            (mem_firstn o y_loopNm)
                                                            (mem_firstn o t_rrm))
                                        y_loopNm) =
                        mem_lookup k (mem_merge_with_def dot init
                                                         (mem_firstn o y_loopNm)
                                                         (mem_firstn o t_rrm)));
              [| rewrite T; clear T].
            {
              unfold mem_lookup, mem_union.
              rewrite NP.F.map2_1bis by reflexivity.
              break_match; try reflexivity.
              enough (is_Some (@None CarrierA)) by some_none.
              rewrite <-Heqo0; clear Heqo0.
              apply mem_in_mem_lookup.
              rewrite <-mem_merge_with_def_as_Union.
              left.
              apply mem_in_mem_lookup.
              rewrite mem_firstn_lookup by assumption.
              apply mem_in_mem_lookup.
              apply y_loopNm_fill.
              assumption.
            }
            
            rewrite Y_LoopNM in OPF_LoopN.
            inversion OPF_LoopN; subst x.
            
            assert (T : lookup_PExpr ((DSHnatVal n,false) :: (DSHPtrVal t_id o,false) :: σ) rr_m (PVar 1)
                        = inr t_rrm)
              by (cbn; unfold memory_lookup_err; rewrite T_RRM; reflexivity).
            rewrite T in R; clear T.
            inversion R; subst.
            f_equiv.
            f_equiv.
            **
              intros j.
              specialize (H1 j).
              destruct (le_lt_dec o j).
              ---
                rewrite mem_firstn_lookup_oob by assumption.
                apply Option_equiv_eq.
                symmetry.
                apply NP.F.not_find_in_iff.

                move OPF_MM after l0.
                replace (IReduction_mem dot init
                                        (get_family_mem_op (shrink_m_op_family S_opf)) x_m)
                  with (mem_op (MSHIReduction init dot (shrink_m_op_family S_opf)) x_m)
                  in OPF_MM
                  by reflexivity.
                eapply out_mem_oob with (j0:=j) in OPF_MM.
                assumption.
                assumption.
                Unshelve.
                eapply IReduction_MFacts.
                intros.
                unfold shrink_m_op_family.
                apply FMF.
                intros.
                apply FD.
              ---
                rewrite mem_firstn_lookup by assumption.
                inversion H1.
                {
                  exfalso.
                  apply mem_not_in_mem_lookup in H0.
                  contradict H0.
                  replace (IReduction_mem dot init
                                          (get_family_mem_op (shrink_m_op_family S_opf)) x_m)
                    with (mem_op (MSHIReduction init dot (shrink_m_op_family S_opf)) x_m)
                    in OPF_MM
                    by reflexivity.
                  eapply out_mem_fill_pattern with (j0:=j) in OPF_MM.
                  apply OPF_MM.
                  cbn.
                  left.
                  unfold shrink_m_op_family.
                  cbn.
                  eapply FD.
                  constructor.
                }
                assumption.
                Unshelve.
                eapply IReduction_MFacts.
                intros.
                unfold shrink_m_op_family.
                apply FMF.
                intros.
                apply FD.
                assumption.
            **
              intros j.
              specialize (H2 j).
              destruct (le_lt_dec o j).
              ---
                rewrite mem_firstn_lookup_oob by assumption.
                apply Option_equiv_eq.
                symmetry.
                apply NP.F.not_find_in_iff.

                eapply out_mem_oob in OPF_M.
                eassumption.
                assumption.
              ---
                rewrite mem_firstn_lookup by assumption.
                inversion H2.
                {
                  exfalso.
                  exfalso.
                  apply mem_not_in_mem_lookup in H0.
                  contradict H0.
                  unshelve eapply out_mem_fill_pattern with (j0:=j) in OPF_M.
                  assumption.
                  apply OPF_M.
                  apply FD.
                  constructor.
                }
                assumption.
Qed.
