
Require Import Spiral.
Require Import Rtheta.
Require Import SVector.
Require Import SigmaHCOL.
Require Import HCOL.
Require Import THCOL.
Require Import IndexFunctions.

Require Import Arith.
Require Import Compare_dec.
Require Import Coq.Arith.Peano_dec.
Require Import Coq.Logic.Eqdep_dec.
Require Import Coq.Logic.ProofIrrelevance.
Require Import Program.
Require Import Coq.Logic.FunctionalExtensionality.
Require Import Psatz.

Require Import CpdtTactics.
Require Import JRWTactics.
Require Import CaseNaming.
Require Import SpiralTactics.

(* CoRN MathClasses *)
Require Import MathClasses.interfaces.abstract_algebra MathClasses.interfaces.orders.
Require Import MathClasses.orders.minmax MathClasses.orders.orders MathClasses.orders.rings.
Require Import MathClasses.theory.rings MathClasses.theory.abs.

(*  CoLoR *)
Require Import CoLoR.Util.Vector.VecUtil.
Import VectorNotations.

Local Open Scope hcol_scope. (* for compose *)


Section SigmaHCOLRewriting.

  Open Scope vector_scope.
  Global Open Scope nat_scope.

  Fact ScatH_1_to_n_range_bound base o stride:
    base < o ->
    ∀ x : nat, x < 1 → base + x * stride < o.
  Proof.
    intros.
    nia.
  Qed.

  Fact GathH_j1_domain_bound base i (bc:base<i):
    ∀ x : nat, x < 1 → base + x * 1 < i.
  Proof.
    intros.
    lia.
  Qed.

  Lemma Is_Struct_Rtheta_szero:
    Is_Struct Rtheta_szero.
  Proof.
    unfold Rtheta_szero.
    unfold Is_Struct, RthetaIsStruct.
    simpl.
    trivial.
  Qed.


  Lemma Is_StructNonErr_Rtheta_szero:
    Is_StructNonErr Rtheta_szero.
  Proof.
    unfold Is_StructNonErr.
    split.
    apply Is_Struct_Rtheta_szero.
    crush.
  Qed.

  Lemma VecUnion_structs:
    ∀ (m : nat) (x : svector m),
      Vforall Is_StructNonErr x → VecUnion x ≡ Rtheta_szero.
  Proof.
    intros m x H.
    unfold VecUnion.
    induction x.
    crush.
    simpl.
    rewrite IHx.
    simpl in H. destruct H as [Hh Hx].
    unfold Is_Val, Is_StructNonErr, Is_Struct, Is_SErr in Hh.
    destruct Hh.

    destruct_Rtheta h.
    unfold Rtheta_szero.
    destruct h1, h2; crush.
    apply H.
  Qed.


  Lemma Vfold_OptionUnion_val_with_empty:
    ∀ (m : nat) (h : Rtheta) (x : svector m),
      Is_Val h -> Vforall Is_StructNonErr x → Vfold_left Union h x ≡ h.
  Proof.
    intros m h x V E.
    induction x.
    auto.
    simpl.
    simpl in E. destruct E as [Eh Ex].
    rewrite IHx; try assumption.
    rewrite Union_Val_with_Struct; try assumption.
    reflexivity.
  Qed.

  Lemma Lemma3 m j (x:svector m) (jc:j<m):
    (forall i (ic:i<m),
        (i ≡ j -> Is_Val (Vnth x ic)) /\ (i ≢ j -> Is_StructNonErr (Vnth x ic)))
    -> (VecUnion x ≡ Vnth x jc).
  Proof.
    intros SZ.
    dependent induction m.
    - dep_destruct x.
      destruct j.
      omega.
      omega.
    -
      dep_destruct x.
      destruct (eq_nat_dec j 0).
      +
        Case ("j=0").
        rewrite Vnth_cons_head; try assumption.
        rewrite VecUnion_cons.

        assert(Vforall Is_StructNonErr x0).
        {
          apply Vforall_nth_intro.
          intros.
          assert(ipp:S i < S m) by lia.
          replace (Vnth x0 ip) with (Vnth (Vcons h x0) ipp) by apply Vnth_Sn.
          apply SZ; lia.
        }

        assert(Is_Val h).
        {
          specialize SZ with (i:=j) (ic:=jc).
          destruct SZ as [SZ0 SZ1].
          subst j.
          simpl in *.
          apply SZ0.
          reflexivity.
        }
        rewrite VecUnion_structs.
        apply Union_Struct_with_Val.
        assumption.
        apply Is_StructNonErr_Rtheta_szero.
        assumption.
      +
        Case ("j!=0").
        rewrite VecUnion_cons.
        assert(Zc: 0<(S m)) by lia.

        assert (HS: Is_StructNonErr h).
        {
          cut (Is_StructNonErr (Vnth (Vcons h x0) Zc)).
          rewrite Vnth_0.
          auto.
          apply SZ; auto.
        }

        destruct j; try congruence.
        simpl.
        generalize (lt_S_n jc).
        intros l.
        rewrite IHm with (jc:=l).

        assert(Is_Val (Vnth x0 l)).
        {
          assert(ics: S j < S m) by lia.
          specialize SZ with (i:=S j) (ic:=ics).
          destruct SZ as [SZ0 SZ1].
          simpl in *.
          replace (lt_S_n ics) with l in SZ0 by apply proof_irrelevance.
          apply SZ0.
          reflexivity.
        }
        rewrite Union_comm.
        apply Union_Struct_with_Val; assumption.

        intros i ic.
        assert(ics: S i < S m) by lia.
        rewrite <- Vnth_Sn with (v:=h) (ip:=ics).
        specialize SZ with (i:=S i) (ic:=ics).
        crush.
  Qed.


  Lemma InverseIndex_1_hit:
    ∀ (n k s : nat) (kp : k < n) (v : Rtheta),
      (@VnthInverseIndexMapped 1 n [v]
                               (@build_inverse_index_map 1 n
                                                         (@h_index_map 1 n k s
                                                                       (ScatH_1_to_n_range_bound k n s kp) )) k kp) ≡ v.
  Proof.
    intros n k s kp v.
    destruct (@build_inverse_index_map 1 n
                                       (@h_index_map 1 n k s
                                                     (ScatH_1_to_n_range_bound k n s kp) )) as [h' h'_spec] eqn:P.
    unfold h_index_map in P.
    inversion P. rename H0 into HH. symmetry in HH. clear P.
    assert(PH': h' k ≡ Some 0).
    {
      subst h'.
      break_if; [reflexivity | omega].
    }
    unfold VnthInverseIndexMapped, partial_index_f, partial_index_f_spec.
    generalize (h'_spec k).
    destruct (h' k); crush.
  Qed.

  Lemma InverseIndex_1_miss:
    ∀ (n s i j : nat) (ip : i < n) (jp: j<n) (v : Rtheta),
      i ≢ j ->
      @VnthInverseIndexMapped 1 n [v]
                              (@build_inverse_index_map 1 n
                                                        (@h_index_map 1 n j s
                                                                      (ScatH_1_to_n_range_bound j n s jp)
                              ))
                              i ip ≡ Rtheta_szero.
  Proof .
    intros n s i j ip jp v N.
    destruct (@build_inverse_index_map 1 n
                                       (@h_index_map 1 n j s
                                                     (ScatH_1_to_n_range_bound j n s jp)
             )) as [h' h'_spec] eqn:P.
    unfold h_index_map in P.
    inversion P. rename H0 into HH. symmetry in HH.
    assert(PH': h' i ≡ None).
    {
      subst h'.
      break_if ; [omega | reflexivity ].
    }
    assert (N0: i ≢ j + 0) by omega.
    unfold VnthInverseIndexMapped, partial_index_f, partial_index_f_spec.
    generalize (h'_spec i).
    destruct (h' i); crush.
  Qed.

  Fact ScatH_stride1_constr:
  forall {a b:nat}, 1 ≢ 0 ∨ a < b.
  Proof.
    auto.
  Qed.

  (* TODO: here is probably a good place to introduce a notion of "proper" family of functions *)
  Lemma U_SAG1:
    ∀ (n : nat) (x : vector Rtheta n)
      (f: { i | i<n} -> Rtheta -> Rtheta) `{pF: !Proper ((=) ==> (=) ==> (=)) f}
      (i : nat) (ip : i < n),
      svector_is_dense x ->
      (forall i (ic: i<n) y, Is_Val y -> Is_Val (f (i ↾ ic) y)) ->
      Vnth
        (SumUnion
           (Vbuild
              (λ (i0 : nat) (id : i0 < n),
               ((ScatH i0 1
                       (snzord0:=ScatH_stride1_constr)
                       (range_bound:=ScatH_1_to_n_range_bound i0 n 1 id))
                  ∘ Atomic (f (i0 ↾ id))
                  ∘ (GathH i0 1
                           (domain_bound:=GathH_j1_domain_bound i0 n id))
               ) x))) ip
        ≡
        Vnth (Pointwise f x) ip.
  Proof.
    intros n x f pF i ip V F.
    unfold HCompose, compose.
    unfold svector_is_dense in V.
    remember (λ (i0 : nat) (id : i0 < n),
              ScatH i0 1 (Atomic (f (i0 ↾ id)) (GathH i0 1 x))) as bf.
    assert(B1: bf ≡ (λ (i0 : nat) (id : i0 < n),
                     ScatH i0 1 (snzord0:=ScatH_stride1_constr) (range_bound:=ScatH_1_to_n_range_bound i0 n 1 id) (Atomic (f (i0 ↾ id)) [Vnth x id]))
          ).
    {
      subst bf.
      extensionality j.
      extensionality jn.
      unfold GathH, Gather.
      rewrite Vbuild_1.
      unfold VnthIndexMapped.
      simpl.
      generalize (h_index_map_obligation_1 1 n j 1
                                           (GathH_j1_domain_bound j n jn) 0 (lt_0_Sn 0)).
      intros ln.
      simpl in ln.
      rewrite Vnth_cast_index with (jc:=jn) by omega.
      reflexivity.
    }
    assert (B2: bf ≡ (λ (i0 : nat) (id : i0 < n),
                      ScatH i0 1 (snzord0:=ScatH_stride1_constr) (range_bound:=ScatH_1_to_n_range_bound i0 n 1 id)  [f (i0 ↾ id) (Vnth x id)])).
    {
      rewrite B1.
      extensionality j.
      extensionality jn.
      unfold Atomic.
      reflexivity.
    }
    rewrite B2.
    clear B1 B2 Heqbf bf.

    unfold Pointwise.
    rewrite Vbuild_nth.

    (* Lemma5 emebdded below *)
    rewrite AbsorbUnionIndex.
    rewrite Vmap_Vbuild.

    (* Preparing to apply Lemma3. Prove some peoperties first. *)
    remember (Vbuild
                (λ (z : nat) (zi : z < n), Vnth (ScatH z 1 [f (z ↾ zi) (Vnth x zi)]) ip)) as b.

    assert
      (L3pre: forall ib (icb:ib<n),
          (ib ≡ i -> Is_Val (Vnth b icb)) /\ (ib ≢ i -> Is_StructNonErr (Vnth b icb))).
    {
      intros ib icb.

      subst.
      rewrite Vbuild_nth.
      unfold ScatH, Scatter.
      rewrite Vbuild_nth.
      split.

      intros H.
      subst ib.
      remember (f (i ↾ icb) (Vnth x icb)) as v eqn: W.
      replace ip with icb by apply proof_irrelevance.
      rewrite InverseIndex_1_hit.
      cut(Is_Val (Vnth x icb)); try crush.
      apply Vforall_nth with (i:=i) (ip:=icb) in V; apply V.

      intros H.
      rewrite InverseIndex_1_miss.
      apply Is_StructNonErr_Rtheta_szero.
      auto.
    }
    rewrite Lemma3 with (j:=i) (jc:=ip).
    subst b.
    rewrite Vbuild_nth.
    unfold ScatH, Scatter.
    rewrite Vbuild_nth.
    apply InverseIndex_1_hit.
    assumption.
  Qed.

  Theorem U_SAG1_PW:
    forall n (x:svector n)
      (f: { i | i<n} -> Rtheta -> Rtheta) `{pF: !Proper ((=) ==> (=) ==> (=)) f},
      Vforall Is_Val x ->
      (forall i (ic: i<n) y, Is_Val y -> Is_Val (f (i ↾ ic) y)) ->
      SumUnion
        (@Vbuild (svector n) n
                 (fun i id =>
                    (
                      (ScatH i 1
                             (snzord0:=ScatH_stride1_constr)
                             (range_bound:=ScatH_1_to_n_range_bound i n 1 id))
                        ∘ (Atomic (f (i ↾ id)))
                        ∘ (GathH i 1
                                 (domain_bound:=GathH_j1_domain_bound i n id)
                          )
                    ) x
        ))
        ≡
        Pointwise f x.
  Proof.
    intros n x f pF V F.
    apply vec_eq_elementwise.
    apply Vforall2_intro_nth.
    intros i ip.
    apply U_SAG1; assumption.
  Qed.

  Fact GathH_jn_domain_bound i n:
    i < n ->
    ∀ x : nat, x < 2 → i + x * n < (n+n).
  Proof.
    intros.
    nia.
  Qed.

  Lemma HBinOp_nth:
    ∀ (n : nat) (x : vector Rtheta (n + n))
      (f : nat -> Rtheta → Rtheta → Rtheta)
      `{f_mor: !Proper ((=) ==> (=) ==> (=) ==> (=)) f}
      (k : nat) (kp : k < n) (kn: k < n + n) (knn: k + n < n + n),
      Vnth (HBinOp f x) kp ≡ f k (Vnth x kn) (Vnth x knn).
  Proof.
    intros n x f f_mor k kp kn knn.
    unfold HBinOp, compose, vector2pair, HCOLImpl.BinOp.
    break_let.  rename t into a. rename t0 into b.

    rewrite Vnth_Vmap2Indexed.
    assert(A: Vnth a kp ≡ Vnth x kn).
    {
      apply Vbreak_arg_app in Heqp.
      subst x.
      rewrite Vnth_app.
      break_match.
      crush.
      replace kp with g by apply proof_irrelevance.
      reflexivity.
    }
    assert(B: Vnth b kp ≡ Vnth x knn).
    {
      apply Vbreak_arg_app in Heqp.
      subst x.
      rewrite Vnth_app.
      break_match.
      generalize (Vnth_app_aux n knn l) as g.
      intros.
      apply Vnth_cast_index.
      omega.
      crush.
    }
    rewrite A, B.
    reflexivity.
  Qed.

  Lemma U_SAG2:
    ∀ (n : nat) (x : vector Rtheta (n + n))
      (f: nat->Rtheta->Rtheta->Rtheta)
      `{f_mor: !Proper ((=) ==> (=) ==> (=) ==> (=)) f}
      (k : nat) (kp : k < n),
      Vforall Is_Val x
      → (∀ (j:nat) (a b : Rtheta), Is_Val a → Is_Val b → Is_Val (f j a b))
      → Vnth
          (SumUnion
             (@Vbuild (svector n) n
                      (fun i id =>
                         ((ScatH i 1
                                 (snzord0:=ScatH_stride1_constr)
                                 (range_bound:=ScatH_1_to_n_range_bound i n 1 id))
                            ∘ (HBinOp (o:=1) (SwapIndex2 i f))
                            ∘ (GathH i n
                                     (domain_bound:=GathH_jn_domain_bound i n id))
                         ) x
          ))) kp
          ≡ Vnth (HBinOp (o:=n) (f) x) kp.
  Proof.
    intros n x f f_mor k kp V F.
    unfold HCompose, compose.

    remember (fun i id =>
                ScatH i 1
                      (range_bound:=ScatH_1_to_n_range_bound i n 1 id)
                      (HBinOp (o:=1) (SwapIndex2 i f)
                              (GathH i n
                                     (domain_bound:=GathH_jn_domain_bound i n id) x)))
      as bf.

    assert(ILTNN: forall y:nat,  y<n -> y<(n+n)) by (intros; omega).
    assert(INLTNN: forall y:nat,  y<n -> y+n<(n+n)) by (intros; omega).

    assert(B1: bf ≡ (fun i id =>
                       (ScatH i 1
                              (snzord0:=ScatH_stride1_constr)
                              (range_bound:=ScatH_1_to_n_range_bound i n 1 id)
                              (HBinOp (o:=1) (SwapIndex2 i f)
                                      [(Vnth x (ILTNN i id));  (Vnth x (INLTNN i id))])))).
    {
      subst bf.
      extensionality j. extensionality jn.
      unfold GathH, Gather, compose.
      rewrite Vbuild_2.
      unfold VnthIndexMapped.
      generalize
        (index_f_spec 2 (n + n) (@h_index_map 2 (n + n) j n (GathH_jn_domain_bound j n jn)) 0  (lt_0_SSn 0)) as l0
                                                                                                                , (index_f_spec 2 (n + n) (@h_index_map 2 (n + n) j n (GathH_jn_domain_bound j n jn)) 1  (lt_1_SSn 0)) as l1,  (ILTNN j jn) as l00, (INLTNN j jn) as l01.
      intros.
      simpl in *.
      rewrite Vnth_cast_index with (jc:=l00) (ic:=l0) by omega.
      rewrite Vnth_cast_index with (jc:=l01) (ic:=l1) by omega.
      reflexivity.
    }

    assert (B2: bf ≡ (λ (i : nat) (id : i < n),
                      ScatH i 1
                            (snzord0:=ScatH_stride1_constr)
                            (range_bound:=ScatH_1_to_n_range_bound i n 1 id)
                            [ f i (Vnth x (ILTNN i id)) (Vnth x (INLTNN i id)) ])).
    {
      rewrite B1.
      reflexivity.
    }
    rewrite B2.
    clear B1 B2 Heqbf bf.

    (* Lemma5 embedded below*)

    rewrite AbsorbUnionIndex.
    rewrite Vmap_Vbuild.

    (* Preparing to apply Lemma3. Prove some peoperties first. *)
    remember (Vbuild
                (λ (z : nat) (zi : z < n),
                 Vnth (ScatH z 1 [f z (Vnth x (ILTNN z zi)) (Vnth x (INLTNN z zi))]) kp)) as b.

    assert
      (L3pre: forall ib (icb:ib<n),
          (ib ≡ k -> Is_Val (Vnth b icb)) /\ (ib ≢ k -> Is_StructNonErr (Vnth b icb))).
    {
      intros ib icb.

      subst.
      rewrite Vbuild_nth.
      unfold ScatH, Scatter.
      rewrite Vbuild_nth.
      split.

      intros H.
      subst ib.
      replace icb with kp by apply proof_irrelevance.
      remember (f k (Vnth x (ILTNN k kp)) (Vnth x (INLTNN k kp))) as v eqn: W.
      rewrite InverseIndex_1_hit.

      assert(Is_Val (Vnth x (ILTNN k kp))); try crush.
      apply Vforall_nth with (i:=k) (ip:=(ILTNN k kp)) in V.
      apply V.

      assert(Is_Val (Vnth x (INLTNN k kp))); try crush.
      apply Vforall_nth with (i:=k+n) (ip:=(INLTNN k kp)) in V.
      apply V.

      intros H.
      rewrite InverseIndex_1_miss.
      apply Is_StructNonErr_Rtheta_szero.
      auto.
    }
    rewrite Lemma3 with (j:=k) (jc:=kp).
    subst b.
    rewrite Vbuild_nth.
    unfold ScatH, Scatter.
    rewrite Vbuild_nth.
    rewrite InverseIndex_1_hit.
    symmetry; apply HBinOp_nth.
    assumption.
  Qed.

  (*
    BinOp := (self, o, opts) >> When(o.N=1, o, let(i := Ind(o.N),
        ISumUnion(i, i.range, OLCompose(
        ScatHUnion(o.N, 1, i, 1),
        BinOp(1, o.op),
        GathH(2*o.N, 2, i, o.N)
        )))),
   *)
  Lemma expand_BinOp:
    forall n (x:svector (n+n))
      (f: nat->Rtheta->Rtheta->Rtheta)
      `{f_mor: !Proper ((=) ==> (=) ==> (=) ==> (=)) f},
      Vforall Is_Val x ->
      (forall j a b, Is_Val a -> Is_Val b -> Is_Val (f j a b)) ->
      HBinOp (o:=n) (f) x ≡
             SumUnion
             (@Vbuild (svector n) n
                      (fun i id =>
                         (
                           (ScatH i 1
                                  (snzord0:=ScatH_stride1_constr)
                                  (range_bound:=ScatH_1_to_n_range_bound i n 1 id))
                             ∘ (HBinOp (o:=1) (SwapIndex2 i f))
                             ∘ (GathH i n
                                      (domain_bound:=GathH_jn_domain_bound i n id)
                               )
                         ) x
             )).
  Proof.
    intros n x f pF x_dense f_dense.
    apply vec_eq_elementwise.
    apply Vforall2_intro_nth.
    intros i ip.
    symmetry.
    apply U_SAG2; assumption.
  Qed.


  Fact h_bound_first_half (o1 o2:nat):
    ∀ x : nat, x < o1 → 0 + x * 1 < o1 + o2.
  Proof.
    intros.
    lia.
  Qed.

  Fact h_bound_second_half (o1 o2:nat):
    ∀ x : nat, x < o2 → o1 + x * 1 < o1 + o2.
  Proof.
    intros.
    lia.
  Qed.

  Lemma Partial_index_in_range:
    ∀ (o1 o2 i : nat) (partial_index_f : nat → option nat),
      partial_index_f
        ≡ (λ y : nat,
                 List.fold_right
                   (λ (x' : nat) (p : option nat),
                    if eq_nat_dec y (o1 + x' * 1) then Some x' else p) None
                   (rev_natrange_list o2))
      → o1 <= i
      → i < o1 + o2
      -> partial_index_f i ≡ Some (i-o1).
  Proof.
    intros.
    subst.
    induction o2.
    crush.
    simpl.
    break_if.
    crush.
    rewrite IHo2.
    reflexivity.
    omega.
  Qed.

  Lemma Partial_index_out_of_range_is_none:
    ∀ (o1 o2 i : nat) (partial_index_f : nat → option nat),
      partial_index_f
        ≡ (λ y : nat,
                 List.fold_right
                   (λ (x' : nat) (p : option nat),
                    if eq_nat_dec y (o1 + x' * 1) then Some x' else p) None
                   (rev_natrange_list o2))
      → (o1 > i) \/ (i>=o1+o2)
      → is_None (partial_index_f i).
  Proof.
    intros.
    subst.
    apply is_None_def.

    induction o2.
    crush.
    simpl.
    break_if.
    crush.
    rewrite IHo2.
    reflexivity.
    omega.
  Qed.

  (*
   ApplyFunc(SUMUnion, List([1..Length(ch)], i->OLCompose(
            ScatHUnion(Rows(o), Rows(ch[i]), Sum(List(ch{[1..i-1]}, c->c.dims()[1])), 1),
            self(ch[i], opts),
            GathH(Cols(o), Cols(ch[i]), Sum(List(ch{[1..i-1]}, c->c.dims()[2])), 1))))),
   *)
  Lemma expand_HTDirectSum
        {i1 o1 i2 o2}
        (f: svector i1 -> svector o1)
        (g: svector i2 -> svector o2)
        `{hop1: !HOperator f}
        `{hop2: !HOperator g}
        (x: svector (i1+i2)) (* input vector *)
        (D: svector_is_dense x) (* input must be dense *)
        (Df: forall u, svector_is_dense u -> svector_is_dense (f u)) (* f is density-preserving *)
        (Dg: forall u, svector_is_dense u -> svector_is_dense (g u)) (* g is density-preserving *)
    :
      HTDirectSum f g x ≡
                  (HTSUMUnion
                     ((ScatH 0 1 (snzord0:=ScatH_stride1_constr) (range_bound := h_bound_first_half o1 o2)
                      ) ∘ f ∘ (GathH 0 1 (domain_bound := h_bound_first_half i1 i2)))
                     ((ScatH o1 1 (snzord0:=ScatH_stride1_constr) (range_bound := h_bound_second_half o1 o2)
                      ) ∘ g ∘ (GathH i1 1 (domain_bound := h_bound_second_half i1 i2))))
                  x.
  Proof.
    unfold HTDirectSum, HCross, THCOLImpl.Cross, HCompose, compose,
    HTSUMUnion, pair2vector.
    break_let. break_let.
    rename t1 into x0, t2 into x1.
    tuple_inversion.
    symmetry.

    assert(LS: @ScatH o1 (o1 + o2) 0 1 (h_bound_first_half o1 o2)
                      (@ScatH_stride1_constr o1 2)
                      (f (@GathH (i1 + i2) i1 0 1 (h_bound_first_half i1 i2) x)) ≡ Vapp (f x0) (szero_svector o2)).
    {
      replace (@GathH (i1 + i2) i1 0 1 (h_bound_first_half i1 i2) x) with x0.
      -
        unfold ScatH, Scatter.
        apply Veq_nth.
        intros.

        assert(DX0: svector_is_dense (f x0)).
        {
          apply Df.
          apply Vbreak_dense_vector in Heqp0. destruct Heqp0.
          assumption.
          assumption.
        }
        rewrite Vbuild_nth.
        generalize dependent (f x0). intros fx0 DX0.
        rewrite Vnth_app.
        break_match.
        + (* Second half of x, which is all zeros *)
          unfold szero_svector.  rewrite Vnth_const.
          remember ((build_inverse_index_map (h_index_map 0 1))) as h'.
          destruct h'.
          inversion Heqh'. rename H0 into H. clear Heqh'.
          unfold VnthInverseIndexMapped.
          simpl.
          assert (HZI: partial_index_f i ≡ None).
          {
            apply is_None_def.
            apply Partial_index_out_of_range_is_none with (o1:=0) (o2:=o1).
            assumption.
            simpl.
            omega.
          }
          generalize (partial_index_f_spec i ip).
          rewrite HZI.
          reflexivity.
        + (* First half of x, which is fx0 *)
          remember ((build_inverse_index_map (h_index_map 0 1))) as h'.
          destruct h'.
          inversion Heqh'. rename H0 into H. clear Heqh'.
          unfold VnthInverseIndexMapped; simpl.
          assert (HZI: partial_index_f i ≡ Some i).
          {
            replace (Some i) with (Some (i-0)).
            apply Partial_index_in_range with (o2:=o1) (o1:=O).
            assumption.
            omega.
            omega.
            f_equal; omega.
          }
          generalize (partial_index_f_spec i ip) as some_spec.
          rewrite HZI.
          intros.
          replace (some_spec i eq_refl) with g0 by apply proof_irrelevance.
          reflexivity.
      - unfold GathH, Gather.
        apply Veq_nth.
        intros.
        rewrite Vbuild_nth.
        unfold h_index_map.
        unfold VnthIndexMapped.
        simpl.
        apply Vbreak_arg_app in Heqp0.
        subst x.
        rewrite Vnth_app.
        break_match.
        omega.
        revert g0.
        rewrite Mult.mult_1_r.
        unfold gt.
        intros g0.
        replace g0 with ip by apply proof_irrelevance.
        reflexivity.
    }

    assert(RS: @ScatH o2 (o1 + o2) o1 1 (h_bound_second_half o1 o2)
                      (@ScatH_stride1_constr o2 2)
                      (g (@GathH (i1 + i2) i2 i1 1 (h_bound_second_half i1 i2) x)) ≡ Vapp (szero_svector o1) (g x1)).
    {
      replace (@GathH (i1 + i2) i2 i1 1 (h_bound_second_half i1 i2) x) with x1.
      -
        unfold ScatH, Scatter.
        apply Veq_nth.
        intros.
        assert(DX1: svector_is_dense (g x1)).
        {
          apply Dg.
          apply Vbreak_dense_vector in Heqp0. destruct Heqp0.
          assumption.
          assumption.
        }
        rewrite Vbuild_nth.
        generalize dependent (g x1). intros gx0 DX1.
        rewrite Vnth_app.
        break_match.
        + (* Second half of x, which is gx0 *)
          remember (build_inverse_index_map (h_index_map o1 1)) as h'.
          destruct h'.
          inversion Heqh'. rename H0 into H. clear Heqh'.
          unfold VnthInverseIndexMapped; simpl.
          assert (HZI: partial_index_f i ≡ Some (i-o1))
            by (apply Partial_index_in_range with (o2:=o2); assumption).
          generalize (partial_index_f_spec i ip) as some_spec.
          rewrite HZI.
          intros.
          replace (some_spec (i-o1) eq_refl) with (Vnth_app_aux o2 ip l) by apply proof_irrelevance.
          reflexivity.
        + (* First half of x, which is all zeros *)
          unfold szero_svector.  rewrite Vnth_const.
          remember ((build_inverse_index_map (h_index_map o1 1))) as h'.
          destruct h'.
          inversion Heqh'. rename H0 into H. clear Heqh'.
          unfold VnthInverseIndexMapped.
          simpl.
          assert (HZI: partial_index_f i ≡ None).
          {
            apply is_None_def.
            apply Partial_index_out_of_range_is_none with (o1:=o1) (o2:=o2).
            assumption.
            omega.
          }
          generalize (partial_index_f_spec i ip).
          rewrite HZI.
          reflexivity.
      - unfold GathH, Gather.
        apply Veq_nth.
        intros.
        rewrite Vbuild_nth.
        unfold h_index_map.
        unfold VnthIndexMapped.
        simpl.
        apply Vbreak_arg_app in Heqp0.
        subst x.
        rewrite Vnth_app.
        break_match.
        generalize (Vnth_app_aux i2
                                 (h_index_map_obligation_1 i2 (i1 + i2) i1 1
                                                           (h_bound_second_half i1 i2) i ip) l) as ip'.
        revert ip.
        replace (i1 + i * 1 - i1) with i by omega.
        intros ip ip'.
        replace ip with ip' by apply proof_irrelevance.
        reflexivity.
        crush. (* contradiction in g0 *)
    }
    rewrite LS, RS.
    apply Vbreak_dense_vector in Heqp0.  destruct Heqp0.
    unfold Vec2Union. rewrite VMapp2_app.
    rewrite Vec2Union_szero_svector, Vec2Union_comm, Vec2Union_szero_svector.
    reflexivity.
    apply Dg; assumption.
    apply Df; assumption.
    assumption.
  Qed.

End SigmaHCOLRewriting.


