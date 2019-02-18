Require Import Helix.Util.VecUtil.
Require Import Helix.Util.Matrix.
Require Import Helix.Util.VecSetoid.
Require Import Helix.Util.OptionSetoid.
Require Import Helix.Util.Misc.
Require Import Helix.Util.FinNat.
Require Import Helix.Util.FMapSetoid.
Require Import Helix.SigmaHCOL.Rtheta.
Require Import Helix.SigmaHCOL.SVector.
Require Import Helix.SigmaHCOL.IndexFunctions.
Require Import Helix.SigmaHCOL.Memory.
Require Import Helix.SigmaHCOL.SigmaHCOLImpl.
Require Import Helix.SigmaHCOL.SigmaHCOL.
Require Import Helix.SigmaHCOL.SigmaHCOLMem.
Require Import Helix.HCOL.HCOL. (* Presently for HOperator only. Consider moving it elsewhere *)
Require Import Helix.Util.FinNatSet.
Require Import Helix.Util.WriterMonadNoT.

Require Import Coq.Logic.FunctionalExtensionality.
Require Import Coq.Arith.Arith.
Require Import Coq.Bool.Bool.
Require Import Coq.Bool.BoolEq.
Require Import Coq.Strings.String.
Require Import Coq.Arith.Peano_dec.
Require Import Coq.Logic.Decidable.

Require Import Helix.Tactics.HelixTactics.
Require Import Psatz.
Require Import Omega.

Require Import MathClasses.interfaces.abstract_algebra.
Require Import MathClasses.orders.minmax MathClasses.interfaces.orders.
Require Import MathClasses.theory.rings.
Require Import MathClasses.implementations.peano_naturals.
Require Import MathClasses.orders.orders.
Require Import MathClasses.orders.semirings.
Require Import MathClasses.theory.setoids.

Require Import ExtLib.Structures.Monad.
Require Import ExtLib.Structures.Monoid.

Import Monoid.

Import VectorNotations.
Open Scope vector_scope.

Program Definition svector_to_mem_block_spec
        {fm}
        {n : nat}
        (v : svector fm n):
  { m : mem_block | forall i (ip : i < n),
      Is_Val (Vnth v ip) ->
      mem_lookup i m ≡ Some (evalWriter (Vnth v ip))
  }
  := Vfold_right_indexed' 0
                          (fun k r m =>
                             if Is_Val_dec r then mem_add k (evalWriter r) m
                             else m
                          )
                          v mem_empty.
Next Obligation.
  unfold mem_lookup.
  revert H. revert ip. revert i.
  induction n; intros.
  -
    nat_lt_0_contradiction.
  -
    dep_destruct v;clear v.
    simpl.
    destruct i.
    +
      unfold Vfold_right_indexed, mem_add.
      destruct (Is_Val_dec h).
      *
        apply NM_find_add_1.
        reflexivity.
      *
        simpl in H.
        crush.
    +
      destruct (Is_Val_dec h).
      *
        rewrite NM_find_add_3; auto.
        assert (N: i<n) by apply Lt.lt_S_n, ip.
        specialize (IHn x i N).
        simpl in H.
        replace (Lt.lt_S_n ip) with N by apply le_unique.
        rewrite <- IHn; clear IHn.
        --
          unfold mem_add.
          unfold mem_empty.
          rewrite find_vold_right_indexed'_S_P.
          reflexivity.
        --
          replace N with (lt_S_n ip) by apply le_unique.
          apply H.
      *
        simpl in H.
        rewrite find_vold_right_indexed'_S_P.
        apply IHn.
        apply H.
Qed.

Definition svector_to_mem_block {fm} {n} (v: svector fm n) := proj1_sig (svector_to_mem_block_spec v).

Lemma svector_to_mem_block_key_oob {n:nat} {fm} {v: svector fm n}:
  forall (k:nat) (kc:ge k n), mem_lookup k (svector_to_mem_block v) ≡ None.
Proof.
  intros k kc.
  unfold svector_to_mem_block.
  simpl.
  revert k kc; induction v; intros.
  -
    reflexivity.
  -
    unfold mem_lookup.
    simpl.
    destruct k.
    +
      omega.
    +
      break_if.
      *
        rewrite NM_find_add_3 by omega.
        rewrite find_vold_right_indexed'_S_P.
        rewrite IHv.
        reflexivity.
        omega.
      *
        rewrite find_vold_right_indexed'_S_P.
        rewrite IHv.
        reflexivity.
        omega.
Qed.

Ltac svector_to_mem_block_to_spec m H0 H1 :=
  match goal with
    [ |- context[svector_to_mem_block_spec ?v]] =>
    pose proof (svector_to_mem_block_key_oob (v:=v)) as H1;
    unfold svector_to_mem_block in H1 ;
    destruct (svector_to_mem_block_spec v) as [m H0]
  end.

Global Instance mem_block_Equiv:
  Equiv (mem_block) := mem_block_equiv.

Module NMS := FMapSetoid.Make Coq.Structures.OrderedTypeEx.Nat_as_OT NM
                              CarrierA_as_BooleanDecidableType.

Global Instance mem_block_Equiv_Reflexive:
  Reflexive (mem_block_Equiv).
Proof.
  apply NMS.EquivSetoid_Reflexive.
  typeclasses eauto.
Qed.

Global Instance mem_block_Equiv_Symmetric:
  Symmetric (mem_block_Equiv).
Proof.
  apply NMS.EquivSetoid_Symmetric.
  typeclasses eauto.
Qed.

Global Instance mem_block_Equiv_Transitive:
  Transitive (mem_block_Equiv).
Proof.
  apply NMS.EquivSetoid_Transitive.
  typeclasses eauto.
Qed.

Global Instance mem_block_Equiv_Equivalence:
  Equivalence (mem_block_Equiv).
Proof.
  apply NMS.EquivSetoid_Equivalence.
  typeclasses eauto.
Qed.

Class SHOperator_MemVecEq
      {fm}
      {i o: nat}
      (f: @SHOperator fm i o)
      `{facts: SHOperator_Facts _ _ _ f}
  :=
    {
      mem_vec_preservation:
        forall x,

          (* Only for inputs which comply to `facts` *)
          (∀ (j : nat) (jc : (j < i)%nat),
              in_index_set fm f (mkFinNat jc) → Is_Val (Vnth x jc))
          ->
          Some (svector_to_mem_block (op fm f x)) =
          mem_op fm f (svector_to_mem_block x)
      ;
    }.

Section MemVecEq.
  Variable fm:Monoid RthetaFlags.
  Variable fml:@MonoidLaws RthetaFlags RthetaFlags_type fm.

  Global Instance liftM_MemVecEq
         {i o}
         (hop: avector i -> avector o)
         `{HOP: HOperator i o hop}
    : SHOperator_MemVecEq (liftM_HOperator fm hop).
  Proof.
    assert (facts: SHOperator_Facts fm (liftM_HOperator fm hop)) by
        typeclasses eauto.
    destruct facts.
    split.
    intros x G.
    simpl.
    unfold mem_op_of_hop.
    unfold liftM_HOperator', avector_to_mem_block, svector_to_mem_block, compose in *.

    svector_to_mem_block_to_spec m0 H0 O0.
    svector_to_mem_block_to_spec m1 H1 O1.
    break_match.
    -
      f_equiv.
      avector_to_mem_block_to_spec m2 H2 O2.
      simpl in *.
      unfold equiv, mem_block_Equiv, mem_block_equiv, NM.Equiv.
      split.
      *
        intros.
        destruct (NatUtil.lt_ge_dec k o) as [H | H].
        --
          clear O0 O1 O2.
          split.
          ++
            intros H3.
            specialize (H2 k H).
            unfold mem_lookup in *.
            apply NMS.F.in_find_iff.
            crush.
          ++
            intros H3.
            specialize (H0 k H).
            unfold mem_lookup in *.
            apply NMS.F.in_find_iff.
            assert(V: Is_Val (Vnth (sparsify fm (hop (densify fm x))) H)).
            {
              apply out_as_range.
              intros j jc H4.
              apply G.
              apply Full_intro.
              apply Full_intro.
            }
            crush.
        --
          clear H0 H1 H2.
          split.
          ++
            intros H3; apply NMS.In_MapsTo in H3; destruct H3 as [e H3]; apply NM.find_1 in H3.
            specialize (O0 k H); unfold mem_lookup in O0.
            congruence.
          ++
            intros H3; apply NMS.In_MapsTo in H3; destruct H3 as [e H3]; apply NM.find_1 in H3.
            specialize (O2 k H); unfold mem_lookup in O2.
            congruence.
      *
        admit.
    -
      simpl in *.
      (* Heqo0 never happens because of H1 *)
      admit.
  Qed.

  Global Instance eUnion_MemVecEq
         {o b:nat}
         (bc: b < o)
         (z: CarrierA)
    : SHOperator_MemVecEq (eUnion fm bc z).
  Proof.
    (* assert (facts: SHOperator_Facts fm (eUnion fm bc z)) by
        typeclasses eauto. *)
    split.
    intros x G.
    simpl.
    unfold eUnion_mem, map_mem_block_elt.
    unfold svector_to_mem_block, compose.
    break_match.
    -
      f_equiv.
      unfold eUnion'.
      unfold densify in *.
      unfold avector_to_mem_block in *.

      avector_to_mem_block_to_spec m M B.
      avector_to_mem_block_to_spec m0 M0 B0.
      simpl in *.
      rewrite Vmap_Vbuild in *.
      setoid_rewrite Vbuild_nth in M.
      setoid_rewrite Vnth_map in M0.
      specialize (M0 0 (lt_0_Sn 0)).
      rewrite Vnth_0 in M0.
      unfold zero in *.
      rewrite Heqo0 in M0; clear Heqo0 m0.
      some_inv.
      rewrite <- H0.
      admit.
    -
      unfold avector_to_mem_block in *.
      destruct (avector_to_mem_block_spec (densify fm x)) as [m E].
      simpl in Heqo0.
      specialize (E 0 (lt_0_Sn 0)).
      unfold zero in E.
      rewrite E in Heqo0.
      some_none_contradiction.
  Qed.

End MemVecEq.