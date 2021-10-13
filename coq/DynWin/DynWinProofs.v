Require Import Helix.Util.VecUtil.
Require Import Helix.Util.Matrix.
Require Import Helix.Util.FinNat.
Require Import Helix.Util.VecSetoid.
Require Import Helix.Util.ErrorSetoid.
Require Import Helix.Util.OptionSetoid.
Require Import Helix.SigmaHCOL.SVector.
Require Import Helix.Util.Misc.
Require Import Helix.Util.FinNatSet.

Require Import Helix.HCOL.CarrierType.
Require Import Helix.HCOL.HCOL.
Require Import Helix.HCOL.THCOL.

Require Import Helix.SigmaHCOL.Rtheta.
Require Import Helix.SigmaHCOL.SigmaHCOL.
Require Import Helix.SigmaHCOL.TSigmaHCOL.
Require Import Helix.SigmaHCOL.IndexFunctions.

Require Import Coq.Arith.Arith.
Require Import Coq.Arith.Compare_dec.
Require Import Coq.Arith.Peano_dec.
Require Import Coq.Strings.String.
Require Import Coq.micromega.Lia.

Require Import Helix.Tactics.HelixTactics.
Require Import Helix.HCOL.HCOLBreakdown.
Require Import Helix.SigmaHCOL.SigmaHCOLRewriting.


Require Import MathClasses.interfaces.canonical_names.

Require Import Helix.DynWin.DynWin.

Require Import Helix.Util.FinNatSet.

Require Import Helix.MSigmaHCOL.ReifySHCOL.
Require Import Helix.MSigmaHCOL.MSigmaHCOL.
Require Import Helix.MSigmaHCOL.ReifyProofs.
Require Import Helix.Util.MonoidalRestriction.

Require Import Helix.ASigmaHCOL.ASigmaHCOL.
Require Import Helix.ASigmaHCOL.ReifyMSHCOL.
Require Import Helix.ASigmaHCOL.ReifyProofs.

Require Import Helix.RSigmaHCOL.RSigmaHCOL.
Require Import Helix.RSigmaHCOL.ReifyAHCOL.

Require Import Helix.FSigmaHCOL.FSigmaHCOL.
Require Import Helix.FSigmaHCOL.ReifyRHCOL.
Require Import Helix.FSigmaHCOL.Int64asNT.
Require Import Coq.Bool.Sumbool.
Require Import MathClasses.misc.decision.

Require Import ExtLib.Structures.Monad.
Import MonadNotation.

Section HCOL_Breakdown.

  (* Initial HCOL breakdown proof *)
  Theorem DynWinHCOL:  forall (a: avector 3),
      dynwin_orig a = dynwin_HCOL a.
  Proof.
    intros a.
    unfold dynwin_orig, dynwin_HCOL.
    rewrite breakdown_OTLess_Base.
    rewrite breakdown_OEvalPolynomial.
    rewrite breakdown_OScalarProd.
    rewrite breakdown_OMonomialEnumerator.
    rewrite breakdown_OChebyshevDistance.
    rewrite breakdown_OVMinus.
    rewrite breakdown_OTInfinityNorm.
    HOperator_reflexivity.
  Qed.
  

End HCOL_Breakdown.

Local Notation "g ⊚ f" := (@SHCompose _ _ Monoid_RthetaFlags _ _ _ _ g f) (at level 40, left associativity) : type_scope.

(* This tactics solves both [SHOperator_Facts] and [MSHOperator_Facts]
   as well [SH_MSH_Operator_compat].

   Maybe it is better split into 2.
*)
Ltac solve_facts :=
  repeat match goal with
         | [ |- SHOperator_Facts _ (SumSparseEmbedding _ _ _) ] => unfold SumSparseEmbedding
         | [ |- SHOperator_Facts _ (ISumUnion _) ] => unfold ISumUnion
         | [ |- SHOperator_Facts _ (IUnion _ _) ] => apply IUnion_Facts; intros
         | [ |- SHOperator_Facts _ (SHBinOp _ _) ] => apply SHBinOp_RthetaSafe_Facts
         | [ |- @SHOperator_Facts ?m ?i ?o _ (@SHBinOp _ _ ?o _ _) ] =>
           replace (@SHOperator_Facts m i) with (@SHOperator_Facts m (o+o)) by apply eq_refl
         | [ |- SHOperator_Facts _ (SafeCast _)          ] => apply SafeCast_Facts
         | [ |- SHOperator_Facts _ (UnSafeCast _)        ] => apply UnSafeCast_Facts
         | [ |- SHOperator_Facts _ (Apply2Union _ _ _ _) ] => apply Apply2Union_Facts
         | [ |- SHOperator_Facts _ (Scatter _ _)         ] => apply Scatter_Rtheta_Facts
         | [ |- SHOperator_Facts _ (ScatH _ _)           ] => apply Scatter_Rtheta_Facts
         | [ |- SHOperator_Facts _ (ScatH _ _ _)         ] => apply Scatter_Rtheta_Facts
         | [ |- SHOperator_Facts _ (liftM_HOperator _ _) ] => apply liftM_HOperator_Facts
         | [ |- SHOperator_Facts _ (Gather _ _)          ] => apply Gather_Facts
         | [ |- SHOperator_Facts _ (GathH _ _)           ] => apply Gather_Facts
         | [ |- SHOperator_Facts _ (GathH _ _ _)         ] => apply Gather_Facts
         | [ |- SHOperator_Facts _ (SHPointwise _ _)     ] => apply SHPointwise_Facts
         | [ |- SHInductor_Facts _ (SHInductor _ _ _ _)  ] => apply SHInductor_Facts
         | [ |- SHOperator_Facts _ (IReduction _ _)      ] => apply IReduction_Facts; intros
         | [ |- SHOperator_Facts _ _                     ] => apply SHCompose_Facts
         | [ |- SH_MSH_Operator_compat (SafeCast _) _          ] => apply SafeCast_SH_MSH_Operator_compat
         | [ |- SH_MSH_Operator_compat (UnSafeCast _) _        ] => apply UnSafeCast_SH_MSH_Operator_compat
         | [ |- SH_MSH_Operator_compat (Apply2Union _ _ _ _) _ ] => apply Apply2Union_SH_MSH_Operator_compat
         | [ |- SH_MSH_Operator_compat (SHPointwise _ _) _     ] => apply SHPointwise_SH_MSH_Operator_compat
         | [ |- SH_MSH_Operator_compat (SHInductor _ _ _ _) _  ] => apply SHInductor_SH_MSH_Operator_compat
         | [ |- SH_MSH_Operator_compat (IReduction minmax.max _) _  ] =>
           apply IReduction_SH_MSH_Operator_compat with (SGP:=NN);
           [typeclasses eauto | apply CommutativeRMonoid_max_NN;typeclasses eauto | intros | | ]
         | [ |- SH_MSH_Operator_compat (IReduction plus _) _  ] =>
           apply IReduction_SH_MSH_Operator_compat with (SGP:=ATT CarrierA);
           [typeclasses eauto | apply Monoid2CommutativeRMonoid;typeclasses eauto | intros | | ]
         | [ |- SH_MSH_Operator_compat (IReduction _ _) _     ] => apply IReduction_SH_MSH_Operator_compat; intros
         | [ |- SH_MSH_Operator_compat (Embed _ _) _           ] => apply Embed_SH_MSH_Operator_compat
         | [ |- SH_MSH_Operator_compat (SHBinOp _ _) _        ] => apply SHBinOp_RthetaSafe_SH_MSH_Operator_compat
         | [ |- SH_MSH_Operator_compat (IUnion _ _) _         ] => apply (@IUnion_SH_MSH_Operator_compat _ _); intros
         | [ |- SH_MSH_Operator_compat (Pick _ _) _          ] => apply Pick_SH_MSH_Operator_compat
         | [ |- SH_MSH_Operator_compat _ _                    ] => apply SHCompose_SH_MSH_Operator_compat
         | [ |- Monoid.MonoidLaws Monoid_RthetaFlags] => apply MonoidLaws_RthetaFlags
         | [ |- Monoid.MonoidLaws Monoid_RthetaSafeFlags] => apply MonoidLaws_SafeRthetaFlags
         | [ |- MSHOperator_Facts _ ] => apply Apply2Union_MFacts
         | [ |- MSHOperator_Facts _ ] => apply Pick_MFacts
         | [ |- MSHOperator_Facts _ ] => apply SHPointwise_MFacts
         | [ |- MSHOperator_Facts _ ] => apply Embed_MFacts
         | [ |- MSHOperator_Facts _ ] => apply IUnion_MFacts; intros
         | [ |- MSHOperator_Facts _ ] => apply SHInductor_MFacts
         | [ |- MSHOperator_Facts _ ] => apply SHCompose_MFacts
         | [ |- MSHOperator_Facts _ ] => apply IReduction_MFacts; intros
         | [ |- MSHOperator_Facts _ ] => apply SHBinOp_MFacts
         | [ |- Disjoint _ (singleton _) (singleton _)] => apply Disjoined_singletons; auto
         | _ => crush
  end.

Section HCOL_to_SigmaHCOL.

  (* --- HCOL -> Sigma->HCOL --- *)

  (* HCOL -> SigmaHCOL Value correctness. *)
  Theorem DynWinSigmaHCOL_Value_Correctness
        (a: avector 3)
  :
    liftM_HOperator Monoid_RthetaFlags (dynwin_HCOL a)
    =
    dynwin_SHCOL a.
  Proof.
    unfold dynwin_HCOL, dynwin_SHCOL.
    rewrite LiftM_Hoperator_compose.
    rewrite expand_HTDirectSum. (* this one does not work with Diamond_arg_proper *)
    Opaque SHCompose.
    repeat rewrite LiftM_Hoperator_compose.
    repeat rewrite <- SHBinOp_equiv_lifted_HBinOp at 1.
    repeat rewrite <- SHPointwise_equiv_lifted_HPointwise at 1.
    setoid_rewrite expand_BinOp at 3.

    (* normalize associativity of composition *)
    repeat rewrite <- SHCompose_assoc.
    reflexivity.
    Transparent SHCompose.
  Qed.

  Lemma DynWinSigmaHCOL_dense_input
        (a: avector 3)
    : Same_set _ (in_index_set _ (dynwin_SHCOL a)) (Full_set (FinNat _)).
  Proof.
    split.
    -
      unfold Included.
      intros [x xc].
      intros H.
      apply Full_intro.
    -
      unfold Included.
      intros x.
      intros _.
      unfold In in *.
      simpl.
      destruct x as [x xc].
      destruct x.
      +
        apply Union_introl.
        compute; tauto.
      +
        apply Union_intror.
        compute in xc.
        unfold In.
        unfold index_map_range_set.
        repeat (destruct x; crush).
  Qed.

  Lemma DynWinSigmaHCOL_dense_output
        (a: avector 3)
    : Same_set _ (out_index_set _ (dynwin_SHCOL a)) (Full_set (FinNat _)).
  Proof.
    split.
    -
      unfold Included.
      intros [x xc].
      intros H.
      apply Full_intro.
    -
      unfold Included.
      intros x.
      intros H. clear H.
      unfold In in *.
      simpl.
      apply Full_intro.
  Qed.

  Fact two_index_maps_span_I_2
       (x : FinNat 2)
       (b2 : forall (x : nat) (_ : x < 1), 0 + (x * 1) < 2)
       (b1 : forall (x : nat) (_ : x < 1), 1 + (x * 1) < 2)
    :
      Union (@sig nat (fun x0 : nat => x0 < 2))
            (@index_map_range_set 1 2 (@h_index_map 1 2 1 1 b1))
            (@index_map_range_set 1 2 (@h_index_map 1 2 O 1 b2)) x.
  Proof.
    let lu := fresh "LU" in
    let ru := fresh "RU" in
    match goal with
    | [ |- Union ?t ?a ?b ?x] => remember a as lu; remember b as ru
    end.

    destruct x as [x xc].
    dep_destruct x.
    -
      assert(H: RU (@mkFinNat 2 0 xc)).
      {
        subst RU.
        compute.
        tauto.
      }
      apply Union_introl with (C:=LU) in H.
      apply Union_comm.
      apply H.
    -
      destruct x0.
      +
        assert(H: LU (@mkFinNat 2 1 xc)).
        {
          subst LU.
          compute.
          tauto.
        }
        apply Union_intror with (B:=RU) in H.
        apply Union_comm.
        apply H.
      +
        crush.
  Qed.

  Fact two_h_index_maps_disjoint
       (m n: nat)
       (mnen : m ≢ n)
       (b2 : forall (x : nat) (_ : x < 1), n + (x*1) < 2)
       (b1 : forall (x : nat) (_ : x < 1), m + (x*1) < 2)
    :
      Disjoint (FinNat 2)
               (@index_map_range_set 1 2 (@h_index_map 1 2 m 1 b1))
               (@index_map_range_set 1 2 (@h_index_map 1 2 n 1 b2)).
  Proof.
    apply Disjoint_intro.
    intros x.
    unfold not, In.
    intros H.
    inversion H. clear H.
    subst.
    unfold In in *.
    unfold index_map_range_set in *.
    apply in_range_exists in H0.
    apply in_range_exists in H1.

    destruct H0 as [x0 [x0c H0]].
    destruct H1 as [x1 [x1c H1]].
    destruct x as [x xc].
    simpl in *.
    subst.
    crush.
    crush.
    crush.
  Qed.


  Instance DynWinSigmaHCOL_Facts
           (a: avector 3):
    SHOperator_Facts _ (dynwin_SHCOL a).
  Proof.
    unfold dynwin_SHCOL.

    (* First resolve all SHOperator_Facts typeclass instances *)
    solve_facts.

    (* Now let's take care of remaining proof obligations *)
    -
      apply two_h_index_maps_disjoint.
      assumption.
    -
      unfold Included, In.
      intros x H.

      replace (Union _ _ (Empty_set _)) with (@index_map_range_set 1 2 (@h_index_map 1 2 0 1 (ScatH_1_to_n_range_bound 0 2 1 (@le_S 1 1 (le_n 1))))).
      +
        apply two_index_maps_span_I_2.
      +
        apply Extensionality_Ensembles.
        apply Union_Empty_set_lunit.
        apply h_index_map_range_set_dec.

    -
      unfold Included.
      intros x H.
      apply Full_intro.
    -
      apply two_h_index_maps_disjoint.
      unfold peano_naturals.nat_lt, peano_naturals.nat_plus,
      peano_naturals.nat_1, one, plus, lt.
      crush.
    -
      unfold Included, In.
      intros x H.
      apply Union_comm.
      apply two_index_maps_span_I_2.
  Qed.

End HCOL_to_SigmaHCOL.

(* --- SigmaHCOL -> final SigmaHCOL --- *)
Section SigmaHCOL_rewriting.

  (*
           This assumptions is required for reasoning about non-negativity and [abs].
           It is specific to [abs] and this we do not make it a global assumption
           on [CarrierA] but rather assume for this particular SHCOL expression.
   *)
  Context `{CarrierASRO: @orders.SemiRingOrder CarrierA CarrierAe CarrierAplus CarrierAmult CarrierAz CarrierA1 CarrierAle}.

   Instance DynWinSigmaHCOL1_Facts
           (a: avector 3):
    SHOperator_Facts _ (dynwin_SHCOL1 a).
  Proof.
    unfold dynwin_SHCOL1.
    solve_facts.
    (* Now let's take care of remaining proof obligations *)
    -
      unfold Included, In.
      intros x H.

      replace (Union (FinNat 2) (singleton 0) (Empty_set (FinNat 2))) with
          (singleton (n:=2) 0).
      {
        destruct x.
        destruct x.
        -
          apply Union_intror.
          unfold singleton, In.
          reflexivity.
        -
          destruct x.
          *
            apply Union_introl.
            unfold singleton, In.
            reflexivity.
          *
            crush.
      }
      apply Extensionality_Ensembles.
      apply Union_Empty_set_lunit.
      apply Singleton_FinNatSet_dec.
    -
      unfold Included, In.
      intros x H.

      destruct x.
      destruct x.
      apply Union_introl.
      unfold singleton, In.
      reflexivity.

      destruct x.
      apply Union_intror.
      unfold singleton, In.
      reflexivity.

      crush.
  Qed.

  Lemma op_Vforall_P_SHPointwise
        {m n: nat}
        {svalue: CarrierA}
        {fm: Monoid.Monoid RthetaFlags}
        {f: CarrierA -> CarrierA}
        `{f_mor: !Proper ((=) ==> (=)) f}
        {P: CarrierA -> Prop}
        (F: @SHOperator _ fm m n svalue)
    :
      (forall x, P (f x)) ->
      op_Vforall_P fm (liftRthetaP P)
                   (SHCompose fm
                              (SHPointwise (n:=n) fm (IgnoreIndex f))
                              F).
  Proof.
    intros H.
    unfold op_Vforall_P.
    intros x.
    apply Vforall_nth_intro.
    intros i ip.

    unfold SHCompose.
    simpl.
    unfold compose.
    generalize (op fm F x).
    intros v.
    unfold SigmaHCOLImpl.SHPointwise_impl.
    rewrite Vbuild_nth.
    unfold liftRthetaP.
    rewrite evalWriter_Rtheta_liftM.
    unfold IgnoreIndex, const.
    apply H.
  Qed.

  (* Sigma-HCOL rewriting correctenss *)
  Lemma DynWinSigmaHCOL1_Value_Correctness
        (a: avector 3)
    : dynwin_SHCOL a = dynwin_SHCOL1 a.
  Proof.
    unfold dynwin_SHCOL.
    unfold SumSparseEmbedding.

    (* normalize to left-associativity of compose *)
    repeat rewrite <- SHCompose_assoc.
    rewrite SHCompose_mid_assoc with (g:=SHPointwise _ _).

    (* ### RULE: Reduction_ISumReduction *)
    rewrite rewrite_PointWise_ISumUnion.
    all:revgoals.
    (* solve 2 sub-dependent goals *)
    { apply SparseEmbedding_Apply_Family_Single_NonUnit_Per_Row. }
    { intros j jc; apply abs_0_s. }

    (* Re-associate compositions before applying next rule *)
    rewrite SHCompose_mid_assoc with (f:=ISumUnion _).

    (* ### RULE: Reduction_ISumReduction *)
    rewrite rewrite_Reduction_IReduction_max_plus.
    all:revgoals.
    {
      remember (SparseEmbedding _ _ _ _) as t.
      generalize dependent t.
      intros fam _.

      apply Apply_Family_Vforall_SHOperatorFamilyCompose_move_P.
      intros x.

      apply Vforall_nth_intro.
      intros t tc.
      rewrite SHPointwise_nth_eq.
      unfold Is_NonNegative, liftRthetaP.
      rewrite evalWriter_Rtheta_liftM.
      unfold IgnoreIndex, const.
      apply abs_always_nonneg.
    }

    {
      remember (SparseEmbedding _ _ _ _) as fam.

      assert(Apply_Family_Single_NonUnit_Per_Row Monoid_RthetaFlags fam).
      {
        subst fam.
        apply SparseEmbedding_Apply_Family_Single_NonUnit_Per_Row.
      }
      generalize dependent fam.
      intros fam _ H. clear a.

      apply SHPointwise_preserves_Apply_Family_Single_NonUnit_Per_Row.
      +
        apply H.
      +
        intros i ic v V.
        unfold IgnoreIndex, const in V.
        apply ne_sym in V.
        apply ne_sym.
        apply abs_nz_nz, V.
    }

    (* Next rule: ISumXXX_YYY *)
    repeat rewrite SHCompose_assoc.
    setoid_rewrite <- SafeCast_GathH.
    rewrite <- SafeCast_SHCompose.
    (* IReduction_absorb_operator as ISumXXX_YYY *)
    rewrite rewrite_IReduction_absorb_operator.
    repeat rewrite <- SHCompose_assoc.

    (* Next rule *)
    rewrite rewrite_PointWise_ScatHUnion by apply abs_0_s.

    (* Next rule *)
    unfold SparseEmbedding, SHOperatorFamilyCompose, UnSafeFamilyCast.
    setoid_rewrite SHCompose_assoc at 5.
    setoid_rewrite <- SHCompose_assoc at 1.

    (* --- BEGIN: hack ---
    I would expect the following to work here:

    setoid_rewrite rewrite_Reduction_ScatHUnion_max_zero with
        (fm := Monoid_RthetaFlags)
        (m := 4%nat)
        (n := 1%nat).

     But it does not (hangs forever), so we have to do some manual rewriting
     *)
    match goal with
    | |- context [(SHFamilyOperatorCompose _ ?f)] =>
      match f with
      | (fun jf => UnSafeCast (?torewrite ⊚ ?rest )) =>
        setoid_replace f with (fun (jf:FinNat 2) => UnSafeCast rest)
      end
    end.
    all:revgoals.
    unfold equiv, SHOperatorFamily_equiv, pointwise_relation.
    intros [j jc].
    f_equiv.
    apply rewrite_Reduction_ScatHUnion_max_zero.
    (* --- END: hack --- *)

    Opaque SHCompose.
    (* Obligations for `rewrite_Reduction_ScatHUnion_max_zero` *)
    setoid_rewrite SHCompose_assoc.
    eapply op_Vforall_P_SHPointwise, abs_always_nonneg.

    (* Next rule *)
    unfold SHFamilyOperatorCompose.
    setoid_rewrite UnSafeCast_SHCompose.
    setoid_rewrite UnSafeCast_Gather.
    setoid_rewrite SHCompose_assoc at 5.
    setoid_rewrite GathH_fold.
    setoid_rewrite rewrite_GathH_GathH.

    (* Next rule *)
    setoid_rewrite (SafeCast_SHBinOp _ 1).
    setoid_rewrite (rewrite_PointWise_BinOp 1).

    (* Next rule *)
    setoid_rewrite (SafeCast_SHBinOp _ 3).
    setoid_rewrite (UnSafeCast_SHBinOp _ 1).
    unshelve setoid_rewrite terminate_ScatHUnion1; auto.
    Local Hint Opaque liftM_HOperator: rewrite.
    setoid_rewrite SafeCast_HReduction.

    (* Next rule *)
    unshelve rewrite terminate_Reduction by apply rings.plus_comm.
    typeclasses eauto. (* apply Zero_Plus_BFixpoint. *)

    (* Next rule *)
    setoid_rewrite terminate_GathH1.

    (* Next rule *)
    setoid_rewrite <- GathH_fold.
    setoid_rewrite <- UnSafeCast_Gather.
    setoid_rewrite GathH_fold.
    setoid_rewrite terminate_GathHN.

    (* some associativity reorganization and applying `SHBinOp_HPrepend_SHPointwise`. *)
    setoid_rewrite SHCompose_assoc at 3.
    setoid_rewrite SHBinOp_HPrepend_SHPointwise.

    (* Next rule: IReduction_SHPointwise *)
    rewrite <- SafeCast_SHPointwise.
    setoid_rewrite SHCompose_assoc at 3.
    rewrite <- SafeCast_SHCompose.
    (* IReduction_absorb_operator as IReduction_SHPointwise *)
    setoid_rewrite rewrite_IReduction_absorb_operator.

    (* Next rule: ISumXXX_YYY *)
    rewrite <- SafeCast_liftM_HOperator.
    setoid_rewrite SHCompose_assoc at 2.
    rewrite <- SafeCast_SHCompose.
    (* IReduction_absorb_operator as ISumXXX_YYY *)
    setoid_rewrite rewrite_IReduction_absorb_operator.

    (* Next rule: Pick_Pointwise *)
    unfold SHFamilyOperatorCompose.
    simpl.

    (* --- BEGIN: hack ---
    I would expect the following to work here:

    setoid_rewrite rewrite_Pick_SHPointwise
      with (g:=mult_by_1st (@le_S 2 2 (le_n 2)) a).

     But it does not (match fails), so we have to do some manual rewriting
     *)

    unfold Pickn.
    match goal with
    | [ |- context [ IReduction plus ?f ]] =>
      match f with
      | (fun (jf:FinNat 3) => SHCompose _ (SHCompose _ (Pick _ ?l) (SHPointwise _ ?c)) ?rest) =>  setoid_replace f with
            (fun (jf:FinNat 3) => SHCompose _ (SHCompose _ (SHPointwise _ (Fin1SwapIndex jf c)) (Pick _ l)) rest)
      end
    end.

    all:revgoals.
    unfold equiv, SHOperatorFamily_equiv, pointwise_relation.
    intros [j jc].
    f_equiv.
    simpl.
    apply rewrite_Pick_SHPointwise.
    (* --- END: hack --- *)

    (* now solve some obligations *)
    {
      intros x z.
      unfold Fin1SwapIndex, const.
      reflexivity.
    }

    (* Next rule: Pick_Induction *)
    setoid_rewrite SHCompose_assoc at 2.

    setoid_rewrite rewrite_Pick_Induction.

    (* Bring `Pick` into `IReduction` *)
    setoid_rewrite SHCompose_assoc at 1.
    rewrite <- SafeCast_SHCompose.
    setoid_rewrite rewrite_IReduction_absorb_operator.

    (* Fix SHBinOp type *)
    rewrite <- SafeCast_SHBinOp.

    setoid_rewrite <- SHInductor_equiv_lifted_HInductor.

    unfold dynwin_SHCOL1.
    unfold NatAsNT.MNatAsNT.NTypeSetoid, NatAsNT.MNatAsNT.NTypeEquiv.
    unfold join_is_sg_op, meet_is_sg_op, le.
    simpl.


    (* we ended up here with two instances of [reflexive_proper_proxy].
       this is a small hack to unify them. Could be done more generaly
       by automation to unify up to proof irrelevance
     *)
    repeat match goal with
           | [|- context [(reflexive_proper_proxy ?a )] ] =>
             generalize (reflexive_proper_proxy a) ; intros
           end.
    replace p with p1 by apply proof_irrelevance.
    reflexivity.
  Qed.


  (* Couple additional structual properties: input and output of the
  dynwin_SHCOL1 is dense *)
  Lemma DynWinSigmaHCOL1_dense_input
        (a: avector 3)
    : Same_set _ (in_index_set _ (dynwin_SHCOL1 a)) (Full_set (FinNat _)).
  Proof.
    split.
    -
      unfold Included.
      intros [x xc].
      intros H.
      apply Full_intro.
    -
      unfold Included.
      intros x.
      intros _.
      unfold In in *.
      Transparent  SHCompose.
      simpl.

      destruct x as [x xc].
      simpl in xc.

      (* The following could be automated with nifty tactics but for
      now we will do it manually. *)

      destruct x.
      (* 0 *)
      repeat apply Union_introl.
      compute; tauto.

      (* 1 *)
      compute in xc.
      destruct x.
      apply Union_intror.
      apply Union_intror.
      apply Union_introl.
      apply Union_intror.
      apply Union_introl.
      compute; tauto.

      (* 2 *)
      compute in xc.
      destruct x.
      apply Union_intror.
      apply Union_introl.
      apply Union_intror.
      apply Union_introl.
      compute; tauto.

      (* 3 *)
      compute in xc.
      destruct x.
      apply Union_intror.
      apply Union_intror.
      apply Union_introl.
      apply Union_introl.
      compute; tauto.

      (* 4 *)
      compute in xc.
      destruct x.
      apply Union_intror.
      apply Union_introl.
      apply Union_introl.
      compute; tauto.

      (* 5 *)
      compute in xc.
      exfalso.
      lia.
  Qed.

  Lemma DynWinSigmaHCOL1_dense_output
        (a: avector 3)
    : Same_set _ (out_index_set _ (dynwin_SHCOL1 a)) (Full_set (FinNat _)).
  Proof.
    split.
    -
      unfold Included.
      intros [x xc].
      intros H.
      apply Full_intro.
    -
      unfold Included.
      intros x.
      intros _.
      unfold In in *.
      simpl.
      apply Full_intro.
  Qed.

  (* Putting it all together: Final proof of SigmaHCOL rewriting which
   includes both value and structual correctenss *)
  Theorem SHCOL_to_SHCOL1_Rewriting
          (a: avector 3)
    : @SHOperator_subtyping
        _ _ _ _ _
        (dynwin_SHCOL1 a)
        (dynwin_SHCOL a)
        (DynWinSigmaHCOL1_Facts _)
        (DynWinSigmaHCOL_Facts _).
  Proof.
    split.
    -
      symmetry.
      apply DynWinSigmaHCOL1_Value_Correctness.
    -
      split.
      +
        pose proof (DynWinSigmaHCOL_dense_input a) as E.
        pose proof (DynWinSigmaHCOL1_dense_input a) as E1.
        apply Extensionality_Ensembles in E.
        apply Extensionality_Ensembles in E1.
        unfold dynwin_i, dynwin_o in *.
        rewrite E, E1.
        unfold Included.
        intros x H.
        auto.
      +
        pose proof (DynWinSigmaHCOL_dense_output a) as E.
        pose proof (DynWinSigmaHCOL1_dense_output a) as E1.
        apply Extensionality_Ensembles in E.
        apply Extensionality_Ensembles in E1.
        unfold dynwin_i, dynwin_o in *.
        rewrite E, E1.
        unfold Same_set.
        split; unfold Included; auto.
  Qed.

End SigmaHCOL_rewriting.

Require Import Coq.Lists.List.
Import ListNotations.

Section SHCOL_to_MSHCOL.

  (*
    This assumptions is required for reasoning about non-negativity and [abs].
    It is specific to [abs] and this we do not make it a global assumption
    on [CarrierA] but rather assume for this particular SHCOL expression.
   *)
  Context `{CarrierASRO: @orders.SemiRingOrder CarrierA CarrierAe CarrierAplus CarrierAmult CarrierAz CarrierA1 CarrierAle}.

  MetaCoq Run (reifySHCOL dynwin_SHCOL1 100 [(BasicAst.MPfile ["DynWin"; "DynWin"; "Helix"], "dynwin_SHCOL1")] "dynwin_MSHCOL1").

  Fact Set_Obligation_1:
    Included (FinNat 2) (Full_set (FinNat 2))
             (Union (FinNat 2) (singleton 1)
                    (Union (FinNat 2) (singleton 0) (Empty_set (FinNat 2)))).
  Proof.

    unfold Included, In.
    intros [x xc] _.

    destruct x.
    +
      apply Union_intror.
      apply Union_introl.
      reflexivity.
    +
      apply Union_introl.
      destruct x.
      *
        reflexivity.
      *
        crush.
  Qed.

  Fact Apply_Family_Vforall_ATT
        {fm}
        {i o n}
        {svalue: CarrierA}
        (op_family: @SHOperatorFamily _ fm i o n svalue):
    Apply_Family_Vforall_P fm (liftRthetaP (ATT CarrierA)) op_family.
  Proof.
    intros x j jc.
    apply Vforall_intro.
    intros y H.
    unfold liftRthetaP.
    cbv;tauto.
  Qed.


  Theorem dynwin_SHCOL_MSHCOL_compat (a: avector 3):
    SH_MSH_Operator_compat (dynwin_SHCOL1 a) (dynwin_MSHCOL1 a).
  Proof.
    unfold dynwin_SHCOL1, dynwin_MSHCOL1.
    unfold ISumUnion.

    solve_facts.
    -
      unfold Included, In.
      intros [x xc] H.

      destruct x.
      apply Union_introl.
      reflexivity.

      apply Union_intror.
      unfold singleton.
      destruct x; crush.
    -
      apply Apply_Family_Vforall_ATT.
    -
      apply Set_Obligation_1.
    -
      (* TODO: refactor to lemma
         [Apply_Family_Vforall_SHCompose_move_P].
       *)
      unfold Apply_Family_Vforall_P.
      intros x j jc.
      apply Vforall_nth_intro.
      intros t tc.
      unfold get_family_op.
      Opaque SigmaHCOLImpl.SHBinOp_impl.
      simpl.
      unfold compose.
      match goal with
      | [|- context[SigmaHCOLImpl.SHBinOp_impl ?ff ?g]] => generalize g
      end.
      clear x; intros x.
      unshelve erewrite SHBinOp_impl_nth.
      lia.
      lia.
      unfold NN, liftRthetaP.
      rewrite evalWriter_Rtheta_liftM2.
      unfold IgnoreIndex, const.
      apply abs_always_nonneg.
    -
      apply Set_Obligation_1.
    -
      apply Set_Obligation_1.
    -
      apply Set_Obligation_1.
    -
      apply Set_Obligation_1.
  Qed.

End SHCOL_to_MSHCOL.

Section MSHCOL_to_AHCOL.

  Import AHCOLEval.

  Opaque CarrierAz zero CarrierA1 one.

  MetaCoq Run (reifyMSHCOL dynwin_MSHCOL1 [(BasicAst.MPfile ["DynWinProofs"; "DynWin"; "Helix"], "dynwin_MSHCOL1")] "dynwin_AHCOL" "dynwin_AHCOL_globals").
  Transparent CarrierAz zero CarrierA1 one.

  (* Import DSHNotation. *)

  Definition nglobals := List.length (dynwin_AHCOL_globals). (* 1 *)
  Definition DSH_x_p := PVar (nglobals+1). (* PVar 2 *)
  Definition DSH_y_p := PVar (nglobals+0). (* PVar 1 *)


  (* This tactics solves both [MSH_DSH_compat] and [DSH_pure] goals along with typical
     obligations *)
  Ltac solve_MSH_DSH_compat :=
    repeat match goal with
      [ |-  @MSH_DSH_compat ?i ?o (@MSHBinOp ?p01 ?p02 ?p03) ?p1 ?p2 ?p3 ?p4 ?p5 ?p6] =>
      replace
        (@MSH_DSH_compat i o (@MSHBinOp p01 p02 p03) p1 p2 p3 p4 p5 p6) with
      (@MSH_DSH_compat (o+o) o (@MSHBinOp p01 p02 p03) p1 p2 p3 p4 p5 p6)
        by apply eq_refl ; eapply BinOp_MSH_DSH_compat; intros
    | |- MSH_DSH_compat (MSHCompose _ _) _ _ _ _ _ => unshelve eapply Compose_MSH_DSH_compat; intros
    | |- MSH_DSH_compat (MApply2Union _ _ _) _ _ _ _ _ => unshelve eapply Apply2Union_MSH_DSH_compat; intros
    | |- MSH_DSH_compat (@MSHIReduction _ _ (S _) _ _ _ _) _ _ _ _ _ => unshelve eapply IReduction_MSH_DSH_compat_S; intros
    | |- MSH_DSH_compat (MSHPick  _) _ _ _ _ _ => apply Pick_MSH_DSH_compat
    | |- MSH_DSH_compat (MSHInductor _ _ _) _ _ _ _ _ => unshelve eapply Inductor_MSH_DSH_compat; intros
    | |- MSH_DSH_compat (MSHPointwise _) _ _ _ _ _ => apply Pointwise_MSH_DSH_compat; intros
    | |- MSH_DSH_compat (MSHEmbed _) _ _ _ _ _ => apply Embed_MSH_DSH_compat; intros
    | |- MSH_DSH_compat (MSHIUnion _) _ _ _ _ _ => unshelve eapply IUnion_MSH_DSH_compat; intros

    (* DSH_Pure *)
    |  [ |-
        DSH_pure
          (DSHSeq
             (DSHMemInit _ _)
             (DSHAlloc ?o
                       (DSHLoop _
                                (DSHSeq
                                   _
                                   (DSHMemMap2 _ _ _ _ _)))))
          _] => apply IReduction_DSH_pure
    | [ |- DSH_pure (DSHSeq _ _) _] => apply Seq_DSH_pure
    | [ |- DSH_pure (DSHAssign _ _) _ ] => apply Assign_DSH_pure
    | [ |- DSH_pure (DSHPower _ _ _ _ _) _] => apply Power_DSH_pure
    | [ |- DSH_pure (DSHIMap _ _ _ _) _] => apply IMap_DSH_pure
    | [ |- DSH_pure (DSHLoop _ _) _] => apply Loop_DSH_pure
    | [ |- DSH_pure (DSHBinOp _ _ _ _) _] => apply BinOp_DSH_pure
    | [ |- DSH_pure (DSHAlloc _ (DSHSeq _ _)) _] => apply Compose_DSH_pure
    | [ |- PVar _ ≡ incrPVar 0 _] => auto

    (* Compat Obligations *)
    | [ |- MSH_DSH_IBinCarrierA_compat _ _ _ _] => constructor ; intros
    | [ |- MSH_DSH_BinCarrierA_compat _ _ _ _] => constructor
    | [ |- ErrorSetoid.herr_f _ _ _ _ _] =>
      let H := fresh "H" in
      constructor;
      cbv;
      intros H;
      inversion H
    | _ => try reflexivity
    end.

  (* TODO: This is a manual proof. To be automated in future. See [[../../doc/TODO.org]] for details *)
  Instance DynWin_pure
    :
      DSH_pure (dynwin_AHCOL) DSH_y_p.
  Proof.
    unfold dynwin_AHCOL, DSH_y_p, DSH_x_p.
    solve_MSH_DSH_compat.
  Qed.

  Section DummyEnv.

    Local Open Scope list_scope. (* for ++ *)

    (* Could be automatically universally quantified on these *)
    Variable a:vector CarrierA 3.
    Variable x:mem_block.

    Definition dynwin_a_addr:nat := 0.
    Definition dynwin_y_addr:nat := (nglobals+0).
    Definition dynwin_x_addr:nat := (nglobals+1).

    Definition dynwin_globals_mem :=
      (memory_set memory_empty dynwin_a_addr (avector_to_mem_block a)).

    (* Initialize memory with X and placeholder for Y. *)
    Definition dynwin_memory :=
      memory_set
        (memory_set dynwin_globals_mem dynwin_x_addr x)
        dynwin_y_addr mem_empty.

    Definition dynwin_σ_globals:evalContext :=
      [
        (DSHPtrVal dynwin_a_addr 3,false)
      ].

    Definition dynwin_σ:evalContext :=
      dynwin_σ_globals ++
      [
        (DSHPtrVal dynwin_y_addr dynwin_o,false)
        ; (DSHPtrVal dynwin_x_addr dynwin_i,false)
      ].

    (* TODO: move, but not sure where. We do not have MemorySetoid.v *)
    Lemma memory_lookup_not_next_equiv {m k v}:
      memory_lookup m k = Some v ->
      k ≢ memory_next_key m.
    Proof.
      intros H.
      destruct (eq_nat_dec k (memory_next_key m)) as [E|NE]; [exfalso|auto].
      rewrite E in H. clear E.
      pose proof (memory_lookup_memory_next_key_is_None m) as N.
      unfold util.is_None in N.
      break_match_hyp; [trivial|some_none].
    Qed.

    (* This lemma could be auto-generated from TemplateCoq *)
    Theorem DynWin_MSH_DSH_compat
      :
        @MSH_DSH_compat dynwin_i dynwin_o (dynwin_MSHCOL1 a) (dynwin_AHCOL)
                        dynwin_σ
                        dynwin_memory
                        DSH_x_p DSH_y_p
                        DynWin_pure.
    Proof.
      unfold dynwin_AHCOL, DSH_y_p, DSH_x_p.
      unfold dynwin_x_addr, dynwin_y_addr, dynwin_a_addr, nglobals in *.
      unfold dynwin_MSHCOL1.
      cbn in *.

      solve_MSH_DSH_compat.

      {
        cbn in *.
        do 2 inl_inr_inv.
        cbv in H, H0.
        lia.
      }

      repeat match goal with
      | [|- evalPExpr_id _ _ ≢ evalPExpr_id _ _] => cbn; apply inr_neq; auto
      end.

      1:{
        cbn in *; apply inr_neq.
        subst.
        invc H; clear H0.
        generalize dependent (memory_set m' 5 mb).
        clear.
        rename m'' into m'; intros m M'.
        intros C.
        rewrite C in M'; clear C.
        assert (memory_lookup m' (memory_next_key m') = Some mbt)
          by (remember (memory_next_key m') as k;
              now rewrite M', memory_lookup_memory_set_eq by reflexivity).
        now apply memory_lookup_not_next_equiv in H.
      }

      2:{
        cbn in *; apply inr_neq.
        inl_inr_inv.
        subst.

        rename m' into m, m'' into m', m''0 into m'', H2 into H1, H3 into H2.
        clear H2.

        remember (memory_next_key (memory_set m 5 mb)) as k.
        assert(kc: k>5).
        {
          subst k.
          eapply memory_set_memory_next_key_gt; eauto.
        }
        clear Heqk.
        specialize (H1 5).
        unfold memory_set in *.
        rewrite Memory.NP.F.add_neq_o in H1 by lia.
        rewrite Memory.NP.F.add_eq_o in H1 by reflexivity.
        apply memory_lookup_not_next_equiv in H1.
        congruence.
      }

      4:{
        cbn in *.
        symmetry in H.
        memory_lookup_err_to_option.
        apply memory_lookup_not_next_equiv in H.
        congruence.
      }

      4:{
        cbn in *.
        unfold dynwin_x_addr in *.
        intros C.
        inl_inr_inv.
        subst.

        symmetry in H.
        memory_lookup_err_to_option.
        apply equiv_Some_is_Some in H.
        apply memory_is_set_is_Some in H.

        rename H into M0.
        rename m' into m0.
        remember (memory_set m0 (memory_next_key m0) mem_empty) as m1 eqn:M1.
        remember (memory_set m1 (memory_next_key m1) mb) as m2 eqn:M2.
        rename m'0 into m1_plus.
        inl_inr_inv.

        assert(memory_next_key m0 > 2) as LM0.
        {
          apply mem_block_exists_next_key_gt in M0.
          apply M0.
        }

        assert(memory_next_key m1 > 3) as LM1.
        {
          apply memory_set_memory_next_key_gt in M1.
          lia.
        }

        remember (memory_set m1_plus (memory_next_key m1_plus) mb) as
            m1_plus'.

        apply memory_set_memory_next_key_gt in Heqm1_plus'.
        apply memory_subset_except_next_keys in H1.
        subst_max.

        remember (memory_next_key (memory_set m0 (memory_next_key m0) mem_empty)) as xx.
        clear Heqxx.
        pose proof memory_set_memory_next_key_gt m1_plus (memory_set m1_plus xx mb) mb xx.
        autospecialize H; [reflexivity |].
        rewrite <-H4 in H.
        lia.
      }

      4:{
        cbn in *.
        unfold dynwin_x_addr in *.
        intros C.
        inl_inr_inv.
        subst.

        symmetry in H.
        memory_lookup_err_to_option.
        apply equiv_Some_is_Some in H.
        apply memory_is_set_is_Some in H.

        rename H into M0.
        rename m' into m0.
        remember (memory_set m0 (memory_next_key m0) mem_empty) as m1 eqn:M1.
        remember (memory_set m1 (memory_next_key m1) mb) as m2 eqn:M2.
        rename m'0 into m1_plus.
        inl_inr_inv.

        assert(memory_next_key m0 > 2) as LM0.
        {
          apply mem_block_exists_next_key_gt in M0.
          apply M0.
        }

        assert(memory_next_key m1 > 3) as LM1.
        {
          apply memory_set_memory_next_key_gt in M1.
          lia.
        }

        remember (memory_set m1_plus (memory_next_key m1_plus) mb) as
            m1_plus'.

        apply memory_set_memory_next_key_gt in Heqm1_plus'.
        apply memory_subset_except_next_keys in H1.
        subst_max.

        remember (memory_next_key (memory_set m0 (memory_next_key m0) mem_empty)) as xx.
        clear Heqxx.
        pose proof memory_set_memory_next_key_gt m1_plus (memory_set m1_plus xx mb) mb xx.
        autospecialize H; [reflexivity |].
        rewrite H5 in H.
        lia.
      }

      6:{
        cbn; apply inr_neq.
        auto.
      }

      (* This remailing obligation proof is not yet automated *)
      1: {
        (* [a] is defined in section *)
        constructor; intros.
        unfold evalIUnCType, Fin1SwapIndex.
        cbn.

        unfold mult_by_nth, const.
        subst tmpk.

        repeat match goal with
               | [H: memory_equiv_except ?m m'' _ |- _] => remember m as m0
               | [H: memory_subset_except _ ?m m' |- _] => remember m as m1
               end.
        cbn in *.

        inversion H. subst y_id; clear H.

        remember (avector_to_mem_block a) as v.
        assert(LM: memory_lookup m1 dynwin_a_addr = Some v).
        {
          subst m1.
          unfold dynwin_memory, dynwin_globals_mem.

          do 4 (rewrite memory_lookup_memory_set_neq
                 by (cbn;unfold dynwin_a_addr,dynwin_y_addr,dynwin_x_addr, nglobals; auto)).
          rewrite memory_lookup_memory_set_eq by reflexivity.
          subst v.
          reflexivity.
        }

        assert(LM': memory_lookup m' dynwin_a_addr = Some v).
        {
          clear - LM H0 Heqv.
          specialize (H0 dynwin_a_addr v LM).
          destruct H0 as [v' [L E]].
          autospecialize E ; [cbv;lia|].
          rewrite E.
          apply L.
        }

        (*
        assert(LM0: memory_lookup m0 dynwin_a_addr = Some v).
        {
          rewrite H2.
          rewrite memory_lookup_memory_set_neq.
          auto.
          apply memory_lookup_not_next_equiv in LM.
          auto.
        }
         *)

        assert(LM'': memory_lookup m'' dynwin_a_addr = Some v).
        {
          rewrite H2.
          rewrite memory_lookup_memory_set_neq.
          rewrite memory_lookup_memory_set_neq.
          assumption.
          apply memory_lookup_not_next_equiv in LM.
          congruence.
          assert (memory_next_key m1 > dynwin_a_addr)
            by (apply mem_block_exists_next_key_gt,
                  mem_block_exists_exists_equiv; eauto).
          remember(memory_set m' (memory_next_key m1) mb) as tm.
          apply memory_set_memory_next_key_gt in Heqtm.
          lia.
        }

        assert(LM''0: memory_lookup m''0 dynwin_a_addr = Some v).
        {
          rewrite H3.
          rewrite memory_lookup_memory_set_neq.
          assumption.
          apply memory_lookup_not_next_equiv in LM''.
          congruence.
        }


        repeat break_match; try inl_inr; try some_none.
        -
          exfalso.
          memory_lookup_err_to_option.
          eq_to_equiv_hyp.
          some_none.
        -
          inversion Heqs0; subst.
          exfalso; clear - Heqs1.
          unfold assert_NT_lt, NatAsNT.MNatAsNT.to_nat in Heqs1.
          destruct t.
          cbn in Heqs1.
          enough (E : x <=? 2 ≡ true) by (rewrite E in Heqs1; inversion Heqs1).
          clear - l.
          apply Nat.leb_le.
          lia.
        -
          memory_lookup_err_to_option.
          destruct t as [t tc].
          cbn in *.
          assert(m = avector_to_mem_block a) as C.
          {
            eq_to_equiv_hyp.
            rewrite LM''0 in Heqs2.
            some_inv.
            inversion Heqs0; subst m0 n.
            rewrite <- Heqs2.
            rewrite Heqv.
            reflexivity.
          }
          err_eq_to_equiv_hyp.
          rewrite C in Heqs.
          unfold mem_lookup_err in Heqs.
          rewrite mem_lookup_avector_to_mem_block_equiv with (kc:=tc) in Heqs.
          inversion Heqs.
        -
          memory_lookup_err_to_option.
          inl_inr_inv.
          subst.
          destruct t as [t tc].
          cbn in *.
          assert(m = avector_to_mem_block a) as C.
          {
            eq_to_equiv_hyp.
            rewrite LM''0 in Heqs2.
            some_inv.
            rewrite <- Heqs2.
            reflexivity.
          }
          err_eq_to_equiv_hyp.
          rewrite C in Heqs.
          unfold mem_lookup_err in Heqs.
          rewrite mem_lookup_avector_to_mem_block_equiv with (kc:=tc) in Heqs.
          inversion Heqs; subst.
          rewrite H4.
          reflexivity.
      }

      {
        apply IReduction_MFacts.
        -
          intros.
          apply SHCompose_MFacts.
          constructor.
          apply SHCompose_MFacts.
          constructor.
          apply SHPointwise_MFacts.
          apply SHInductor_MFacts.
          apply Pick_MFacts.
        -
          intros.
          cbn.
          constructor.
          constructor.
          constructor.
      }

      {
        apply SHCompose_MFacts.
        constructor.
        apply SHCompose_MFacts.
        constructor.
        apply SHPointwise_MFacts.
        apply SHInductor_MFacts.
        apply Pick_MFacts.
      }

      {
        apply IReduction_MFacts.
        -
          intros.
          apply SHCompose_MFacts.
          +
            cbn in *.
            clear H j jc.
            intros xx IN.
            destruct xx as [xx X2].
            cbn in *.
            destruct xx as [| xx].
            *
              right.
              left.
              reflexivity.
            *
              inversion X2; [| lia].
              subst.
              left.
              reflexivity.
          +
            apply SHBinOp_MFacts
              with (f:= (λ (i : FinNat 1) (a0 b : CarrierA),
                         IgnoreIndex abs i (Fin1SwapIndex2
                                              (mkFinNat jc) (IgnoreIndex2 sub) i a0 b))).
          +
            apply IUnion_MFacts.
            intros.
            apply SHCompose_MFacts.
            constructor.
            apply Embed_MFacts.
            apply Pick_MFacts.
            intros.
            cbn.
            constructor.
            intros xx C.
            inversion C; subst.
            inversion H1; subst.
            inversion H2; subst.
            contradict H0.
            reflexivity.
        -
          intros.
          cbn.
          constructor.
          constructor.
          constructor.
      }

      {
        apply SHCompose_MFacts.
        -
          cbn.
          intros xx IN.
          destruct xx as [xx X2].
          cbn in *.
          destruct xx as [| xx].
          *
            right.
            left.
            reflexivity.
          *
            inversion X2; [| lia].
            subst.
            left.
            reflexivity.
        -
          clear.
          apply SHBinOp_MFacts with (f := λ (i : FinNat 1) (a0 b : CarrierA),
                                          IgnoreIndex abs i
                                                      (Fin1SwapIndex2 (mkFinNat jc)
                                                                      (IgnoreIndex2 sub)
                                                                      i a0 b)).
        -
          solve_facts.
      }
    Qed.

  End DummyEnv.

End MSHCOL_to_AHCOL.

Require Import Helix.MSigmaHCOL.CType.

Module CTypeSimpl(CTM:CType).
  Import CTM.

  Lemma simplCTypeRefl:
    forall a,
      (CTypeEquivDec a a) ≡ left (reflexivity _).
  Proof.
    intros a.
    destruct (CTypeEquivDec a a) as [H|NH].
    -
      f_equiv.
      apply proof_irrelevance.
    -
      contradict NH.
      reflexivity.
  Qed.

  Lemma simplCType_Z_neq_One:
    CTypeEquivDec CTypeZero CTypeOne ≡ right CTypeZeroOneApart.
  Proof.
    destruct (CTypeEquivDec _ _) as [H|NH].
    -
      contradict H.
      apply CTypeZeroOneApart.
    -
      f_equiv.
      apply proof_irrelevance.
  Qed.

  Fact CType_One_neq_Z: CTypeOne ≠ CTypeZero.
  Proof.
    intros H.
    pose proof CTypeZeroOneApart as P.
    auto.
  Qed.

  Lemma simplCType_One_neq_Z:
    CTypeEquivDec CTypeOne CTypeZero ≡ right CType_One_neq_Z.
  Proof.
    destruct (CTypeEquivDec _ _) as [H|NH].
    -
      contradict H.
      apply CType_One_neq_Z.
    -
      f_equiv.
      apply proof_irrelevance.
  Qed.

End CTypeSimpl.


Require Import Helix.MSigmaHCOL.CarrierAasCT.
Require Import Helix.RSigmaHCOL.RasCT.
Module CarrierASimpl := CTypeSimpl(CarrierAasCT).

Lemma AzCtZ: CarrierAz ≡ CarrierAasCT.CTypeZero. Proof. reflexivity. Qed.
Lemma A1Cr1: CarrierA1 ≡ CarrierAasCT.CTypeOne. Proof. reflexivity. Qed.
Lemma AeCtE: CarrierAequivdec ≡ CarrierAasCT.CTypeEquivDec. Proof. reflexivity. Qed.

Hint Rewrite
     AeCtE
     AzCtZ
     A1Cr1
     CarrierASimpl.simplCTypeRefl
     CarrierASimpl.simplCType_Z_neq_One
     CarrierASimpl.simplCType_One_neq_Z
  : CarrierAZ1equalities.

(* Print Rewrite HintDb CarrierAZ1equalities. *)

Section AHCOL_to_RHCOL.
    Context `{CTT: AHCOLtoRHCOL.CTranslationOp}
            `{CTP: @AHCOLtoRHCOL.CTranslationProps CTT}
            `{NTT: AHCOLtoRHCOL.NTranslationOp}
            `{NTP: @AHCOLtoRHCOL.NTranslationProps NTT}.

    Definition dynwin_RHCOL := AHCOLtoRHCOL.translate dynwin_AHCOL.

  (*
     For debug printing
  Definition dynwin_RHCOL1 : RHCOL.DSHOperator.
  Proof.
    remember dynwin_RHCOL as a eqn:H.
    cbv in H.
    autorewrite with CarrierAZ1equalities in H.
    destruct a.
    -
      inv H.
    -
      inl_inr_inv.
      (* Set Printing All.
      Redirect "dynwin_RHCOL" Show 1. *)
      exact d.
  Defined.
   *)

End AHCOL_to_RHCOL.

Require Import Rdefinitions.
Module RSimpl := CTypeSimpl(MRasCT).

Lemma RzCtZ: R0 ≡ MRasCT.CTypeZero. Proof. reflexivity. Qed.
Lemma R1Cr1: R1 ≡ MRasCT.CTypeOne. Proof. reflexivity. Qed.

Hint Rewrite
     RzCtZ
     R1Cr1
     RSimpl.simplCTypeRefl
     RSimpl.simplCType_Z_neq_One
     RSimpl.simplCType_One_neq_Z
  : RZ1equalities.

Require Import AltBinNotations.


Section RHCOL_to_FHCOL.
  Context `{AR_CTT: AHCOLtoRHCOL.CTranslationOp}
          `{RF_CTT: RHCOLtoFHCOL.CTranslationOp}.

  (* Notation for shorter printing of `int64` constants *)
  Local Declare Scope int64.
  Local Notation "v" := (Int64.mkint v _) (at level 10, only printing) : int64.
  Local Delimit Scope int64 with int64.

  (* Relation between RCHOL and DHCOL programs.
     It is parametrized by:

    - [InMemRel] - describes relation between initial memory states
    - [InSigmaRel] - describes relation between initial env. states
    - [OutMemRel] - describes relation which must hold between resulting memory states.
   *)
  Definition RHCOL_FHCOL_rel
             (InMemRel: RHCOL.memory → FHCOL.memory -> Prop)
             (InSigmaRel: RHCOLEval.evalContext -> FHCOLEval.evalContext -> Prop)
             (OutMemRel: RHCOL.memory → FHCOL.memory -> Prop):
    RHCOL.DSHOperator -> FHCOL.DSHOperator -> Prop :=
    fun rhcol fhcol =>
      forall fuel rsigma fsigma rmem fmem,
        InMemRel rmem fmem ->
        InSigmaRel rsigma fsigma ->
        hopt_r (herr_c OutMemRel)
               (RHCOLEval.evalDSHOperator rsigma rhcol rmem fuel)
               (FHCOLEval.evalDSHOperator fsigma fhcol fmem fuel).


  Inductive ferr_c {A B:Type} (f: A -> err B) (R: A -> B -> Prop) : (err A) -> Prop :=
  | ferr_c_inl : forall e, ferr_c f R (inl e)
  | ferr_c_inr : forall a, err_p (R a) (f a) -> ferr_c f R (inr a).

  (* This is the most generic formulation of semantic preservation lemma for
     RHCOL to FHCOL translation. It allows to specify arbitrary user-defined
     relations between states.
   *)
  Definition RHCOL_to_FHCOL_correctness
             (InMemRel: RHCOL.memory → FHCOL.memory -> Prop)
             (InSigmaRel: RHCOLEval.evalContext -> FHCOLEval.evalContext -> Prop)
             (OutMemRel: RHCOL.memory → FHCOL.memory -> Prop)
    : err RHCOL.DSHOperator -> Prop :=
    ferr_c RHCOLtoFHCOL.translate (RHCOL_FHCOL_rel InMemRel InSigmaRel OutMemRel).

  Theorem dynwin_RHCOL_to_FHCOL_correctness
          (InMemRel: RHCOL.memory → FHCOL.memory -> Prop)
          (InSigmaRel: RHCOLEval.evalContext -> FHCOLEval.evalContext -> Prop)
          (OutMemRel: RHCOL.memory → FHCOL.memory -> Prop)
    : RHCOL_to_FHCOL_correctness InMemRel InSigmaRel OutMemRel
        dynwin_RHCOL.
  Proof.
    unfold RHCOL_to_FHCOL_correctness.
    destruct dynwin_RHCOL as [errs|rhcol] eqn:R;constructor.

    Opaque CarrierAequivdec CarrierAz CarrierA1 CarrierAe CarrierAle CarrierAlt CarrierAneg CarrierAasCT.CTypeZero.
    cbv in R.
    autorewrite with CarrierAZ1equalities in R.
    inl_inr_inv.
    subst rhcol.
    Opaque Float64asCT.Float64Zero Float64asCT.Float64One.
    remember (translate _) as fhcol eqn:F.
    cbv in F.
    autorewrite with RZ1equalities in F.
    subst fhcol.
    constructor.
    match goal with
    | [|- RHCOL_FHCOL_rel _ _ _ ?r ?f] => remember r as rhcol; remember f as fhcol
    end.
    Transparent CarrierAequivdec CarrierAz CarrierA1 CarrierAe CarrierAle CarrierAlt CarrierAneg CarrierAasCT.CTypeZero.
    Transparent Float64asCT.Float64Zero Float64asCT.Float64One.
    (* ... proof specific to given relations here *)
    admit.
  Admitted.

  (*
     For debug printing

  Definition dynwin_FHCOL := RHCOLtoFHCOL.translate dynwin_RHCOL1.

  (* Import DSHNotation. *)
  (* Notation for shorter printing of `int64` constants *)
  Local Declare Scope int64.
  Local Notation "v" := (Int64.mkint v _) (at level 10, only printing) : int64.
  Local Delimit Scope int64 with int64.

  Definition dynwin_FSHCOL1 : FHCOL.DSHOperator.
  Proof.
    remember dynwin_FHCOL as a eqn:H.
    Opaque Float64asCT.Float64Zero.
    Opaque Float64asCT.Float64One.

    (* Simplify AHCOL *)
    unfold dynwin_FHCOL in H.
    remember dynwin_RHCOL1 as rhcol eqn:R.
    cbv in R.
    (* Not sure why the following does not work here:
       `autorewrite with CarrierAZ1equalities in R.`
       but manual rewrite works:
     *)
    repeat rewrite AzCtZ in R.
    repeat rewrite A1Cr1 in R.
    repeat rewrite AeCtE in R.
    repeat rewrite CarrierASimpl.simplCTypeRefl in R.
    repeat rewrite CarrierASimpl.simplCType_Z_neq_One in R.
    repeat rewrite CarrierASimpl.simplCType_One_neq_Z in R.
    subst rhcol.

    (* Simpl RHCOL *)
    cbv in H.
    autorewrite with RZ1equalities in H.
    destruct a.
    -
      inv H.
    -
      inl_inr_inv.
      (* Set Printing All. *)
      (* Redirect "dynwin_FSHCOL" Show 1. *)
      exact d.
  Defined.
   *)

End RHCOL_to_FHCOL.

Local Set Warnings "-ssr-search-moved".

Section TopLevel.

  Context
    (* Assumptions for AHCOL to RHCOL mapping *)
    `{CTT: AHCOLtoRHCOL.CTranslationOp}
    `{CTP: @AHCOLtoRHCOL.CTranslationProps CTT}
    `{NTT: AHCOLtoRHCOL.NTranslationOp}
    `{NTP: @AHCOLtoRHCOL.NTranslationProps NTT}
    (* Assumptions for RHCOL to FHCOL mapping *)
    `{CTTF: RHCOLtoFHCOL.CTranslationOp}
    `{NTTF: RHCOLtoFHCOL.NTranslationOp}
(*
     Note: the following are not assumed, as they
     could not be true for Real -> Float and Nat -> Int64
     translations.

     `{CTPF: @RHCOLtoFHCOL.CTranslationProps CTTF}
    `{NTPF: @RHCOLtoFHCOL.NTranslationProps NTTF}
*)
    `{CarrierASRO: @orders.SemiRingOrder CarrierA CarrierAe CarrierAplus CarrierAmult CarrierAz CarrierA1 CarrierAle}.

  (* We assuming that there is an injection of CType to Reals *)
  Hypothesis AHCOLtoRHCOL_total:
    (* always succeeds *)
    (forall c r, AHCOLtoRHCOL.translateCTypeValue c ≡ inr r).
    (* Q: Do we need injectivity as well?
    (∀ x y, AHCOLtoRHCOL.translateCTypeValue x ≡ AHCOLtoRHCOL.translateCTypeValue y → x ≡ y). *)


  (* Initialize memory with X and placeholder for Y. *)
  Definition build_dynwin_memory (a:avector 3) (x:avector dynwin_i) :=
    AHCOLEval.memory_set
      (AHCOLEval.memory_set (AHCOLEval.memory_set AHCOLEval.memory_empty dynwin_a_addr (avector_to_mem_block a)) dynwin_x_addr (avector_to_mem_block x))
      dynwin_y_addr AHCOLEval.mem_empty.

  (* User can specify optional constraints on input values and
     arguments. For example, for cyber-physical system it could
     include ranges and relatoin between parameters. *)
  Parameter InConstr: (* a *) RHCOLEval.mem_block -> (*x*) RHCOLEval.mem_block -> Prop.

  Definition build_dynwin_σ := [
          (AHCOLEval.DSHPtrVal dynwin_a_addr 3,false)
          ; (AHCOLEval.DSHPtrVal dynwin_y_addr dynwin_o,false)
          ; (AHCOLEval.DSHPtrVal dynwin_x_addr dynwin_i,false)
        ].

  (* Parametric relation between RHCOL and FHCOL coumputation results  *)
  Parameter OutRel: (* a *) RHCOLEval.mem_block -> (*x*) RHCOLEval.mem_block -> (*y*) RHCOLEval.mem_block -> (* y_mem *) FHCOLEval.mem_block -> Prop.

  (*
    Translation validation proof of semantic preservation
    of successful translation of [dynwin_orig] into FHCOL program.

    Using following definitons from DynWin.v:
     1. dynwin_i
     2. dynwin_o
     3. dynwin_orig

     And the following definition are produced with TemplateCoq:
     1. dynwin_AHCOL
   *)
  Theorem HCOL_to_FHCOL_Correctness (a: avector 3):
    forall x y,
      (* evaluatoion of original operator *)
      dynwin_orig a x = y ->

      forall dynwin_R_memory dynwin_F_memory dynwin_R_σ dynwin_F_σ dynwin_rhcol dynwin_fhcol,
        (* Compile AHCOL -> RHCOL -> FHCOL *)
        AHCOLtoRHCOL.translate dynwin_AHCOL = inr dynwin_rhcol ->
        translate dynwin_rhcol = inr dynwin_fhcol ->

        (* Compile memory *)
        (AHCOLtoRHCOL.translate_memory (build_dynwin_memory a x) = inr dynwin_R_memory /\
         RHCOLtoFHCOL.translate_memory dynwin_R_memory = inr dynwin_F_memory) ->

        (* compile σ *)
        (AHCOLtoRHCOL.translateEvalContext build_dynwin_σ = inr dynwin_R_σ /\
         RHCOLtoFHCOL.translateEvalContext dynwin_R_σ = inr dynwin_F_σ) ->

        (forall a_rmem x_rmem,
            RHCOLEval.memory_lookup dynwin_R_memory dynwin_a_addr = Some a_rmem /\
            RHCOLEval.memory_lookup dynwin_R_memory dynwin_x_addr = Some x_rmem /\
            InConstr a_rmem x_rmem ->

            exists r_omemory,
              RHCOLEval.evalDSHOperator
                dynwin_R_σ
                dynwin_rhcol
                dynwin_R_memory
                (RHCOLEval.estimateFuel dynwin_rhcol) = Some (inr r_omemory) ->

              forall y_rmem,
                RHCOLEval.memory_lookup r_omemory dynwin_y_addr = Some y_rmem ->

                (* Everything correct on Reals *)
                AHCOLtoRHCOL.translate_mem_block (avector_to_mem_block y) ≡ inr y_rmem /\

                (* And floats *)
                exists f_omemory y_fmem,
                  FHCOLEval.evalDSHOperator
                    dynwin_F_σ dynwin_fhcol
                    dynwin_F_memory
                    (FHCOLEval.estimateFuel dynwin_fhcol) = (Some (inr f_omemory)) /\
                  FHCOLEval.memory_lookup f_omemory dynwin_y_addr = Some y_fmem /\

                  OutRel a_rmem x_rmem y_rmem y_fmem).

  Proof.
    intros x y HC dynwin_R_memory dynwin_F_memory dynwin_R_σ dynwin_F_σ dynwin_rhcol
           dynwin_fhcol CA CR [CAM CRM] [CAE CRE] a_rmem x_rmem [RA [RX C]].

    remember (AHCOLEval.memory_set
                (build_dynwin_memory a x)
                dynwin_y_addr
                (avector_to_mem_block y)) as a_omemory eqn:AOM.

    assert(AHCOLEval.evalDSHOperator
             dynwin_σ
             dynwin_AHCOL
             (build_dynwin_memory a x)
             (AHCOLEval.estimateFuel dynwin_AHCOL) = Some (inr a_omemory)) as AE.
    {
      pose proof (DynWin_MSH_DSH_compat a) as MAHCOL.
      pose proof (DynWin_pure) as MAPURE.
      pose proof (dynwin_SHCOL_MSHCOL_compat a) as MCOMP.
      pose proof (SHCOL_to_SHCOL1_Rewriting a) as SH1.
      pose proof (DynWinSigmaHCOL_Value_Correctness a) as HSH.
      pose proof (DynWinHCOL a x x) as HH.
      autospecialize HH; [reflexivity|].
      rewrite HC in HH. clear HC.

      (* moved from [dynwin_orig] to [dynwin_HCOL] *)

      remember (sparsify Monoid_RthetaFlags x) as sx eqn:SX.
      remember (sparsify Monoid_RthetaFlags y) as sy eqn:SY.
      assert(SHY: op _ (dynwin_SHCOL a) sx = sy).
      {
        subst sy.
        rewrite_clear HH.

        specialize (HSH sx sx).
        autospecialize HSH; [reflexivity|].
        rewrite <- HSH. clear HSH.
        unfold liftM_HOperator.
        Opaque dynwin_HCOL equiv.
        cbn.
        unfold SigmaHCOLImpl.liftM_HOperator_impl.
        unfold compose.
        f_equiv.
        subst sx.
        rewrite densify_sparsify.
        reflexivity.
      }
      Transparent dynwin_HCOL equiv.
      clear HH HSH.

      (* moved from [dynwin_HCOL] to [dynwin_SHCOL] *)

      assert(SH1Y: op _ (dynwin_SHCOL1 a) sx = sy).
      {
        rewrite <- SHY. clear SHY.
        destruct SH1.
        rewrite H.
        reflexivity.
      }
      clear SHY SH1.

      (* moved from [dynwin_SHCOL] to [dynwin_SHCOL1] *)

      assert(M1: mem_op (dynwin_MSHCOL1 a) (svector_to_mem_block Monoid_RthetaFlags sx) = Some (svector_to_mem_block Monoid_RthetaFlags sy)).
      {
        cut(Some (svector_to_mem_block Monoid_RthetaFlags (op Monoid_RthetaFlags (dynwin_SHCOL1 a) sx)) = mem_op (dynwin_MSHCOL1 a) (svector_to_mem_block Monoid_RthetaFlags sx)).
        {
          intros M0.
          rewrite <- M0. clear M0.
          apply Some_proper.

          cut(svector_is_dense _ (op Monoid_RthetaFlags (dynwin_SHCOL1 a) sx)).
          intros YD.

          apply svector_to_mem_block_dense_kind_of_proper.
          apply YD.

          subst sy.
          apply sparsify_is_dense.
          typeclasses eauto.

          apply SH1Y.

          {
            clear - SX SY.

            pose proof (@out_as_range _ _ _ _ _ _ (DynWinSigmaHCOL1_Facts a)) as D.
            specialize (D sx).

            autospecialize D.
            {
              intros j jc H.
              destruct (dynwin_SHCOL1 a).
              cbn in H.
              subst sx.
              rewrite Vnth_sparsify.
              apply Is_Val_mkValue.
            }

            unfold svector_is_dense.
            apply Vforall_nth_intro.
            intros i ip.
            apply D.
            cbn.
            constructor.
          }
        }
        {
          destruct MCOMP.
          apply mem_vec_preservation.
          cut(svector_is_dense Monoid_RthetaFlags (sparsify _ x)).
          intros SD.
          unfold svector_is_dense in SD.

          intros j jc H.
          apply (Vforall_nth jc) in SD.
          subst sx.
          apply SD.
          apply sparsify_is_dense.
          typeclasses eauto.
        }
      }
      clear SH1Y MCOMP.

      (* moved from [dynwin_SHCOL1] to [dynwin_MSHCOL1] *)

      remember (svector_to_mem_block Monoid_RthetaFlags sx) as mx eqn:MX.
      remember (svector_to_mem_block Monoid_RthetaFlags sy) as my eqn:MY.

      specialize (MAHCOL (avector_to_mem_block x)).
      replace (dynwin_memory a (avector_to_mem_block x)) with (build_dynwin_memory a x) in MAHCOL by reflexivity.
      destruct MAHCOL as [MAHCOL].
      specialize (MAHCOL (avector_to_mem_block x) AHCOLEval.mem_empty).
      autospecialize MAHCOL.
      reflexivity.
      autospecialize MAHCOL.
      reflexivity.

      destruct_h_opt_opterr_c MM AE.
      -
        destruct s; inversion_clear MAHCOL.
        f_equiv; f_equiv.
        rename m0 into m'.
        destruct (lookup_PExpr dynwin_σ m' DSH_y_p) eqn:RY.
        +
          exfalso.
          (* contradiction in RY. Use [mem_stable] from [MAPURE] *)
          admit.
        +
          inversion_clear H.
          rename m into ym.
          rename m0 into ym'.
          subst.
          destruct (dynwin_MSHCOL1 a).
          rewrite 2!svector_to_mem_block_avector_to_mem_block in M1; try typeclasses eauto.
          Opaque avector_to_mem_block.
          cbn in M1.
          cbn in MM.
          rewrite MM in M1.
          clear MM.
          some_inv.
          symmetry.

          (* Use [mem_write_safe]? *)

          Transparent avector_to_mem_block.
          admit.
      -
        exfalso.
        pose proof (@AHCOLEval.evalDSHOperator_estimateFuel dynwin_σ dynwin_AHCOL (build_dynwin_memory a x)) as CC.
        clear - CC AE.
        apply util.is_None_def in AE.
        generalize dependent (AHCOLEval.evalDSHOperator dynwin_σ dynwin_AHCOL
                                                        (build_dynwin_memory a x) (AHCOLEval.estimateFuel dynwin_AHCOL)).
        intros o AE CC.
        some_none.
      -
        exfalso.
        remember (dynwin_MSHCOL1 a) as m.
        destruct m.
        subst sx mx.
        rewrite svector_to_mem_block_avector_to_mem_block in M1.
        eq_to_equiv.
        some_none.
        typeclasses eauto.
      -
        exfalso.
        remember (dynwin_MSHCOL1 a) as m.
        destruct m.
        subst sx mx.
        rewrite svector_to_mem_block_avector_to_mem_block in M1.
        eq_to_equiv.
        some_none.
        typeclasses eauto.
    }

    (* moved from [dynwin_MSHCOL1] to [dynwin_rhcol] *)

    assert(RM: exists r_omemory, AHCOLtoRHCOL.translate_memory a_omemory = inr r_omemory).
    {
      (* To prove it for arbirary memory value (not only constants
         defined in CType) we need [AHCOLtoRHCOL_total] assumption
         to know that [translateCTypeValue] always succeeds.
       *)

      pose proof (AHCOLtoRHCOL.translation_semantics_always_correct dynwin_AHCOL dynwin_rhcol CA) as ARC.
      specialize (ARC build_dynwin_σ dynwin_R_σ
                      (build_dynwin_memory a x) dynwin_R_memory).
      (*
      autospecialize ARC.
      apply AHCOLtoRHCOL.translateEvalContext_heq_heq_evalContext.
      autospecialize ARC.
      apply AHCOLtoRHCOL.translate_memory_heq_memory, CAM.
      specialize (ARC a_omemory r_omemory).
       *)
      admit.
    }
    destruct RM as [r_omemory RM].
    exists (r_omemory).

    intros ER y_rmem RY.

    split.
    -
      (* Proof of correctness up to R *)
      admit.
    -
      eexists.
      eexists.

      repeat split.
      +
        (* eval of floats must succeed *)
        admit.
      +
        (* y_mem lookup in floats must succeed *)
        admit.
      +
        (* OutRel must hold (a,x,y_R,y_F) *)
        admit. (* this is provided by user *)

  Admitted.


End TopLevel.
