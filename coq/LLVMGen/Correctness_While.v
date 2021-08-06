Require Import Helix.LLVMGen.Correctness_Prelude.
Require Import Helix.LLVMGen.Correctness_Invariants.
Require Import Helix.LLVMGen.Correctness_NExpr.
Require Import Helix.LLVMGen.LidBound.
Require Import Helix.LLVMGen.BidBound.
Require Import Helix.LLVMGen.IdLemmas.
Require Import Helix.LLVMGen.VariableBinding.
Require Import Helix.LLVMGen.StateCounters.

Opaque incBlockNamed.
Opaque incVoid.
Opaque incLocal.

Set Implicit Arguments.
Set Strict Implicit.

Import FHCOL.
Import D.

Import ListNotations.
Import MonadNotation.
Local Open Scope monad_scope.
Local Open Scope nat_scope.

From Paco Require Import paco.
From ITree Require Import Basics.HeterogeneousRelations.

(* IY: TODO: move to ITrees*)
Instance eutt_Proper_mono : forall {A B E},
        Proper ((@subrelationH A B) ==> (@subrelationH _ _)) (eutt (E := E)).
Proof.
  intros A B. do 3 red.
    intros E x y. pcofix CIH. pstep. red.
    intros sub a b H.
    do 2 red in H. punfold H. red in H.
    remember (observe a) as a'.
    remember (observe b) as b'.
    generalize dependent a. generalize dependent b.
    induction H; intros; eauto.
    + constructor. red in REL. destruct REL.
      right. apply CIH. assumption. assumption.
      destruct H.
    + constructor. red in REL. intros.
      specialize (REL v). unfold id.
      destruct REL. right. apply CIH. assumption. assumption.
      destruct H.
Qed.

Lemma fold_left_acc_app : forall {a t} (l : list t) (f : t -> list a) acc,
    (fold_left (fun acc bk => acc ++ f bk) l acc ≡
    acc ++ fold_left (fun acc bk => acc ++ f bk) l [])%list.
Proof.
  intros. induction l using List.list_rev_ind; intros; cbn.
  - rewrite app_nil_r. reflexivity.
  - rewrite 2 fold_left_app, IHl.
    cbn.
    rewrite app_assoc.
    reflexivity.
Qed.

Lemma blk_id_map_convert_typ : forall env bs,
    map blk_id (convert_typ env bs) ≡ inputs bs.
Proof.
  induction bs as [| b bs IH]; cbn; auto.
  f_equal; auto.
Qed.


(* Useful lemmas about rcompose. TODO: Move? *)
Lemma rcompose_eq_r :
  forall A B (R: relationH A B), eq_rel (R) (rcompose R (@Logic.eq B)).
Proof.
  repeat intro. red. split; repeat intro; auto. econstructor.
  apply H. reflexivity.
  inversion H. subst. auto.
Qed.

Lemma rcompose_eq_l :
  forall A B (R: relationH A B), eq_rel (R) (rcompose (@Logic.eq A) R).
Proof.
  repeat intro. red. split; repeat intro; auto. econstructor.
  reflexivity. apply H.
  inversion H. subst. auto.
Qed.

From Vellvm Require Import Numeric.Integers.
Definition imp_rel {A B : Type} (R S: A -> B -> Prop): Prop :=
  forall a b, R a b -> S a b.

Lemma incLocal_fresh:
    forall i i' i'' r r' , incLocal i ≡ inr (i', r) ->
                      incLocal i' ≡ inr (i'', r') ->
                      r ≢ r'.
Proof.
  intros. cbn in H, H0. Transparent incLocal. unfold incLocal in *.
  intro. cbn in *. inversion H. inversion H0. subst. cbn in H6. clear -H6.
  cbn in H6. apply Name_inj in H6.
  apply append_simplify_l in H6.
  apply string_of_nat_inj in H6. auto.
  apply Nat.neq_succ_diag_l.
Qed.

Require Import String. Open Scope string_scope.

(* ZX TODO: move to reasonable place *)
Lemma skipn_split {A : Type} (l l2 : list A) (k : nat) :
  skipn k l ≡ l2 ->
  exists l1, l ≡ List.app l1 l2.
Proof.
  exists (firstn k l).
  subst.
  now rewrite firstn_skipn.
Qed.

Lemma __fresh:
    forall prefix i i' i'' r r' , incLocal i ≡ inr (i', r) ->
                        incLocalNamed (prefix @@ "_next_i") i' ≡ inr (i'', r') -> r ≢ r'.
Proof.
  intros * H1 H2. cbn.
  unfold incLocal, incLocalNamed in *.
  cbn in *; inv H1; inv H2.
  intros abs; apply Name_inj in abs.
  pose proof @string_of_nat_inj. specialize (H (local_count i) (S (local_count i))).
  assert (local_count i ≢ S (local_count i)) by lia.
  specialize (H H0).
  clear H0.
  (* apply String.string_dec_sound in abs. *)
  pose proof string_dec.
  match goal with
  | [ H : ?l ≡ ?r |- _] => remember l; remember r
  end.
  specialize (H0 s s0).

  pose proof (string_dec "l" prefix). destruct H1. subst.
  destruct H0. 2 : { contradiction. }
  rewrite <- append_assoc in e. apply append_simplify_l in e.
  -
    generalize dependent (local_count i); intros n _ _ C.
    pose proof (string_of_nat_not_alpha n).
    rewrite C in H; clear C.
    rewrite string_forall_forallb in H.
    rewrite list_ascii_of_string_append in H.
    inversion H.
  -
    subst.
    clear H H0 n; rename abs into C.
    generalize dependent (local_count i); intros n C.
    apply f_equal with (f:=list_ascii_of_string) in C.
    rewrite !list_ascii_of_string_append in C.
    rewrite <-!app_assoc in C.
    generalize dependent (list_ascii_of_string prefix); intros p C.
    apply f_equal with (f:=skipn (List.length p)) in C.
    rewrite skipn_length_app in C.

    generalize dependent (Datatypes.length p); intros k C.
    rewrite skipn_app in C.
    destruct k; [cbn in *; invc C |].
    rewrite skipn_all2 in C by (cbn; lia).
    rewrite app_nil_l in C.
    replace (S k - Datatypes.length (list_ascii_of_string "l"))
      with k in * by (cbn; lia).

    assert (head
              (skipn k (list_ascii_of_string (string_of_nat n)))
            ≡ head
                (list_ascii_of_string "_next_i" ++
                                      list_ascii_of_string (string_of_nat (S n))))
      by congruence.
    clear C.
    cbn in H.
    unfold hd_error in H.
    break_match; invc H.
    apply skipn_split in Heql.
    destruct Heql as [l' C].

    pose proof (string_of_nat_not_alpha n).
    apply string_forall_forallb in H.
    rewrite C in H.
    rewrite forallb_app in H.
    cbn in H.
    now rewrite Bool.andb_false_r in H.
Qed.

Opaque incLocalNamed.
Opaque incLocal.

Lemma lt_antisym: forall x, Int64.lt x x ≡ false.
Proof.
  intros.
  pose proof Int64.not_lt x x.
  rewrite Int64.eq_true, Bool.orb_comm in H.
  cbn in H.
  rewrite Bool.negb_true_iff in H; auto.
Qed.

Lemma ltu_antisym: forall x, Int64.ltu x x ≡ false.
Proof.
  intros.
  pose proof Int64.not_ltu x x.
  rewrite Int64.eq_true, Bool.orb_comm in H.
  cbn in H.
  rewrite Bool.negb_true_iff in H; auto.
Qed.

Import Int64 Int64asNT.Int64 DynamicValues.Int64.
Lemma __arith: forall j, j> 0 ->
                    (Z.of_nat j < half_modulus)%Z ->
                    add (repr (Z.of_nat (j - 1))) (repr 1) ≡
                        repr (Z.of_nat j).
Proof.
  intros .
  unfold Int64.add.
  rewrite !Int64.unsigned_repr_eq.
  cbn.
  f_equal.
  rewrite Zdiv.Zmod_small; try lia.
  unfold half_modulus in *.
  split; try lia.
  transitivity (Z.of_nat j); try lia.
  eapply Z.lt_le_trans; eauto.
  transitivity (modulus / 1)%Z.
  eapply Z.div_le_compat_l; try lia.
  unfold modulus.
  pose proof Coqlib.two_power_nat_pos wordsize; lia.
  rewrite Z.div_1_r.
  reflexivity.
Qed.

Lemma __arithu: forall j, j> 0 ->
                    (Z.of_nat j < modulus)%Z ->
                    add (repr (Z.of_nat (j - 1))) (repr 1) ≡
                        repr (Z.of_nat j).
Proof.
  intros .
  unfold Int64.add.
  rewrite !Int64.unsigned_repr_eq.
  cbn.
  f_equal.
  rewrite Zdiv.Zmod_small; try lia.
Qed.

Lemma lt_nat_to_Int64: forall j n,
    0 <= j ->
    j < n ->
    (Z.of_nat n < half_modulus)%Z ->
    lt (repr (Z.of_nat j)) (repr (Z.of_nat n)) ≡ true.
Proof.
  intros.
  unfold lt.
  rewrite !signed_repr.
  2,3:unfold min_signed, max_signed; try lia.
  break_match_goal; auto.
  lia.
Qed.

Lemma ltu_nat_to_Int64: forall j n,
    0 <= j ->
    j < n ->
    (Z.of_nat n < modulus)%Z ->
    ltu (repr (Z.of_nat j)) (repr (Z.of_nat n)) ≡ true.
Proof.
  intros.
  unfold ltu.
  rewrite !unsigned_repr.
  2,3:unfold max_unsigned; try lia.
  break_match_goal; auto.
  lia.
Qed.

Lemma ltu_nat_to_Int64_false: forall j n,
    0 <= j ->
    j >= n ->
    (Z.of_nat j < modulus)%Z ->
    ltu (repr (Z.of_nat j)) (repr (Z.of_nat n)) ≡ false.
Proof.
  intros.
  unfold ltu.
  rewrite !unsigned_repr.
  2,3:unfold max_unsigned; try lia.
  break_match_goal; auto.
  lia.
Qed.

Lemma lt_Z_to_Int64: forall j n,
    (0 <= j)%Z ->
    (n < half_modulus)%Z ->
    (j < n)%Z ->
    lt (repr j) (repr n) ≡ true.
Proof.
  intros.
  unfold lt.
  rewrite !signed_repr. break_match_goal; auto.
  1,2:unfold min_signed, max_signed; lia.
Qed.

Lemma ltu_Z_to_Int64: forall j n,
    (0 <= j)%Z ->
    (n < modulus)%Z ->
    (j < n)%Z ->
    ltu (repr j) (repr n) ≡ true.
Proof.
  intros.
  unfold ltu.
  rewrite !unsigned_repr. break_match_goal; auto.
  1,2:unfold max_unsigned; lia.
Qed.

Import AlistNotations.

(* TODO: Figure out how to avoid this *)
Arguments tfmap _ _ /.
Arguments TFunctor_block _ _ _ _/.

(** Inductive lemma to reason about while loops.
    The code generated is of the shape:
         block_entry ---> nextblock
             |
    ---->loopblock
    |        |
    |    body_entry
    |        |
    |      (body)
    |        |
     ----loopcontblock --> nextblock

 The toplevel lemma [genWhileLoop] will specify a full execution of the loop, starting from [block_entry].
 But to be inductive, this lemma talks only about the looping part:
 - we start from [loopcontblock]
 - we assume that [j] iterations have already been executed
 We therefore assume (I j) initially, and always end with (I n).
 We proceed by induction on the number of iterations remaining, i.e. (n - j).

 Since in order to reach [loopcontblock], we need to have performed at least one iteration, we have the
 following numerical bounds:
 - j > 0
 - j <= n
 - Z.of_nat n < Int64.modulus (or the index would overflow)
 *)

Ltac vbranch_r := vred_BR3.
Ltac vbranch_l := vred_BL3.
Import SemNotations.
(* Requiring [wf_ocfg_bid bks] is a bit strong, we should be able to only require something on [body_blocks] *)
Lemma genWhileLoop_tfor_ind:
  forall (prefix : string)
    (loopvar : raw_id)            (* lvar storing the loop index *)
    (loopcontblock : block_id)    (* reentry point from the body back to the loop *)
    (body_entry : block_id)       (* entry point of the body *)
    (body_blocks : ocfg typ) (* (llvm) body to be iterated *)
    (nextblock : block_id)        (* exit point of the overall loop *)
    (entry_id : block_id)         (* entry point of the overall loop *)
    (s1 s2 sb1 sb2 : IRState)
    (bks : list (LLVMAst.block typ)) ,

    In body_entry (inputs body_blocks) ->

    is_correct_prefix prefix ->
    (* All labels generated are distinct *)
    wf_ocfg_bid bks ->
    lid_bound_between sb1 sb2 loopvar ->
    free_in_cfg bks nextblock ->

    forall (n : nat)                     (* Number of iterations *)

      (* Generation of the LLVM code wrapping the loop around bodyV *)
      (HGEN: genWhileLoop prefix (EXP_Integer 0%Z) (EXP_Integer (Z.of_nat n))
                          loopvar loopcontblock body_entry body_blocks [] nextblock s1
                          ≡ inr (s2,(entry_id, bks)))

      (* Computation on the other side, operating over some type of accumulator [A], *)
      (* i.e. the counterpart to bodyV (body_blocks) *)
      (A : Type)
      (bodyF: nat -> A -> itree _ A)


      (j : nat)                       (* Next iteration to be performed *)
      (UPPER_BOUND : 0 < j <= n)
      (NO_OVERFLOW : (Z.of_nat n < Int64.modulus)%Z)

      (* Main relations preserved by iteration *)
      (I : nat (* -> A *) -> A -> _)
      a0,

      (* We assume that we know how to relate the iterations of the bodies *)
      (forall g li mV a k _label,
          (conj_rel (I k)
                    (fun _ '(_, (l, _)) => l @ loopvar ≡ Some (uvalue_of_nat k)
                                        /\ j <= k < n
                                        /\ Returns a (tfor bodyF j k a0))
                    a (mV,(li,g))) ->
          eutt
            (fun a' '(memV, (l, (g, x))) =>
                 l @ loopvar ≡ Some (uvalue_of_nat k) /\
                 (exists _label', x ≡ inl (_label', loopcontblock)) /\
                 I (S k) a' (memV, (l, g)) /\
                 local_scope_modif sb1 sb2 li l)
            (bodyF k a)
            (interp_cfg (denote_ocfg (convert_typ [] body_blocks) (_label, body_entry)) g li mV)
      ) ->

      (* Invariant is stable under the administrative bookkeeping that the loop performs *)
      (forall k a l mV g id v,
          (lid_bound_between s1 s2 id \/ lid_bound_between sb1 sb2 id) ->
          I k a (mV, (l, g)) ->
          I k a (mV, ((alist_add id v l), g))) ->

      sb1 << sb2 ->
      local_count sb2 ≡ local_count s1 ->

    (* Main result. Need to know initially that P holds *)
    forall g li mV _label,
      (conj_rel
         (I j)
         (fun _ '(_, (l, _)) => l @ loopvar ≡ Some (uvalue_of_nat (j - 1)))
         a0 (mV,(li,g))
      ) ->
      eutt (fun a '(memV, (l, (g,x))) =>
              x ≡ inl (loopcontblock, nextblock) /\
              I n a (memV,(l,g)) /\
              local_scope_modif sb1 s2 li l
           )
           (tfor bodyF j n a0)
           (interp_cfg (denote_ocfg (convert_typ [] bks)
                                                (_label, loopcontblock)) g li mV).
Proof.
  intros * IN PREF UNIQUE_IDENTS LOOPVAR_SCOPE NEXTBLOCK_ID * GEN A *.
  unfold genWhileLoop in GEN. cbn* in GEN. simp.
  intros BOUND OVER * FBODY STABLE LAB LAB'.

  remember (n - j) as k eqn:K_EQ.
  revert j a0 K_EQ BOUND FBODY.
  induction k as [| k IH]; intros j a0 EQidx.

  - (* Base case: we enter through [loopcontblock] and jump out immediately to [nextblock] *)
    intros BOUND FBODY * (INV & LOOPVAR).
    (* This ugly preliminary is due to the conversion of types, as most ugly things on Earth are. *)
    apply wf_ocfg_bid_convert_typ with (env := []) in UNIQUE_IDENTS; cbn in UNIQUE_IDENTS; rewrite ?convert_typ_ocfg_app in UNIQUE_IDENTS; cbn in UNIQUE_IDENTS.
    apply free_in_convert_typ with (env := []) in NEXTBLOCK_ID; cbn in NEXTBLOCK_ID; rewrite ?convert_typ_ocfg_app in NEXTBLOCK_ID; cbn in NEXTBLOCK_ID.
    cbn; rewrite ?convert_typ_ocfg_app. 

    cbn.
    hide_cfg.

    (* We jump into [loopcontblock]
       We denote the content of the block.
     *)

    vjmp.

    cbn.
    assert (n ≡ j) by lia; subst.

    vred.
    Import ProofMode.
    vred.
    vred.
    vstep.
    {
      vstep.
      vstep; solve_lu; reflexivity.
      vstep; reflexivity.
      all: reflexivity.
    }
    vred.
    vstep.
    {
      cbn.
      vstep.
      vstep; solve_lu; reflexivity.
      vstep; reflexivity.
      all:reflexivity.
    }

    (* We now branch to [nextblock] *)
    vbranch_r.
    { vstep.
      solve_lu.
      apply eutt_Ret; repeat f_equal.
      cbn.
      clear - BOUND OVER.
      destruct BOUND as [? _].
      rewrite __arithu; try lia.
      unfold eval_int_icmp.
      rewrite ltu_antisym.
      reflexivity.
    }

    vjmp_out.

    cbn.
    replace (j - j) with 0 by lia.
    cbn; vred.

    rewrite tfor_0.
    (* We have only touched local variables that the invariant does not care about, we can reestablish it *)
    rename s2 into FINAL_STATE, i into s2, i0 into s3, i1 into s4, i2 into s5.
    apply eutt_Ret.
    split; split.
    + eapply STABLE; [left; solve_lid_bound_between |].
      eapply STABLE; [| eauto].
      left; eapply lid_bound_between_shrink; [eapply lid_bound_between_incLocalNamed; [| eauto]; eapply is_correct_prefix_append; auto | | ]; solve_local_count.

    + eapply local_scope_modif_add'.
      solve_lid_bound_between.
      eapply local_scope_modif_add'.
      eapply lid_bound_between_shrink_down with (s2 := s5).
      solve_local_count.
      eapply lid_bound_between_incLocalNamed. 2 : eauto.
      apply string_forall_append. auto. auto. auto.

  - (* Inductive case *)
    cbn in *. intros [LT LE] FBODY * (INV & LOOPVAR).
    (* This ugly preliminary is due to the conversion of types *)
    apply wf_ocfg_bid_convert_typ with (env := []) in UNIQUE_IDENTS; cbn in UNIQUE_IDENTS; rewrite ?convert_typ_ocfg_app in UNIQUE_IDENTS; cbn in UNIQUE_IDENTS.
    apply free_in_convert_typ with (env := []) in NEXTBLOCK_ID; cbn in NEXTBLOCK_ID; rewrite ?convert_typ_ocfg_app in NEXTBLOCK_ID; cbn in NEXTBLOCK_ID.
    cbn; rewrite ?convert_typ_ocfg_app; cbn.
    cbn in IH; rewrite ?convert_typ_ocfg_app in IH; cbn in IH.
    hide_cfg.

    (* RHS : Reducing RHS to apply Body Hypothesis *)
    (* Step 1 : First, process [loopcontblock] and check that k<n, and hence that we do not exit *)
    vjmp.
    vred.
    vred.
    vred.
    vstep.
    { 

      vstep.
      vstep; solve_lu.
      vstep; solve_lu.
      all: reflexivity.
    }
    vred.
    vstep.
    {
      cbn; vstep.
      vstep; solve_lu.
      vstep; solve_lu.
      all: reflexivity.
    }
    vred.

    (* Step 2 : Jump to b0, i.e. loopblock (since we have checked k < n). *)
    vbranch_l.
    { cbn; vstep.
      solve_lu.
      rewrite __arithu; try lia.
      apply eutt_Ret.
      repeat f_equal.
      clear - EQidx LT LE OVER.
      unfold eval_int_icmp; rewrite ltu_nat_to_Int64; try lia.
      reflexivity.
    }

    vjmp.
    (* We update [loopvar] via the phi-node *)
    cbn; vred.

    (* BEGIN TODO: infrastructure to deal with non-empty phis *)
    unfold denote_phis.
    cbn.
    rewrite denote_phi_tl; cycle 1.
    {
      inv VG. inversion UNIQUE_IDENTS.
      subst. intro. subst. apply H1. right.
      rewrite inputs_app.
      apply in_or_app. right. constructor. reflexivity.
    }

    rewrite denote_phi_hd.
    cbn.
    (* TOFIX: broken automation, a wild translate sneaked in where it shouldn't *)
    rewrite translate_bind.
    rewrite ?interp_cfg3_ret, ?bind_ret_l;
      rewrite ?interp_cfg3_bind, ?bind_bind.

  Notation i64 := UVALUE_I64. 
  Notation "j" := (repr (Z.of_nat j)).

    vstep.
    {
      setoid_rewrite lookup_alist_add_ineq.
      setoid_rewrite lookup_alist_add_eq. reflexivity. subst.
      intros ?; eapply __fresh; eauto.
    }
    (* TOFIX: broken automation, a wild translate sneaked in where it shouldn't *)
    rewrite translate_ret.
    repeat vred.
    cbn.
    repeat vred.
    (* TOFIX: we leak a [LocalWrite] event *)
    rewrite interp_cfg3_LW.
    repeat vred.
    subst.
    cbn.
    (* END TODO: infrastructure to deal with non-empty phis *)

    (* Step 3 : we jump into the body *)

    (* In order to use our body hypothesis, we need to restrict the ambient cfg to only the body *)
    inv VG.
    rewrite denote_ocfg_prefix; cycle 1; auto.
    {
      match goal with
        |- ?x::?y::?z ≡ _ => replace (x::y::z) with ([x;y]++z)%list by reflexivity
      end; f_equal.
    }
    hide_cfg.

    cbn; vred.
    destruct j as [| j]; [lia |].
    rewrite tfor_unroll; [| lia].

    eapply eutt_clo_bind_returns.
    (* We can now use the body hypothesis *)
    eapply FBODY.
    {
      (* A bit of arithmetic is needed to prove that we have the right precondition *)
      split; [| split; [| split]].

      + repeat (eapply STABLE; eauto).
        left; solve_lid_bound_between.
        left; eapply lid_bound_between_shrink; [eapply lid_bound_between_incLocalNamed; [| eauto]; eapply is_correct_prefix_append; auto | | ]; solve_local_count.

      + rewrite alist_find_add_eq. reflexivity.

      + lia.

      + rewrite tfor_0; apply ReturnsRet; reflexivity.
    }

    (* Step 4 : Back to starting from loopcontblock and have reestablished everything at the next index:
        conclude by IH *)
    intros a1 (m1 & l1 & g1 & ?) (LOOPVAR' & [? ->] & (IH' & LOC)) RET1 _.
    typ_to_dtyp_simplify.
    eapply eqit_mon; auto.
    2 :{
      eapply IH.
      lia.
      lia.
     - intros * (? & ? & ? & ?).
        apply FBODY.
        do 3 (split; auto).
        lia.
        rewrite tfor_unroll; [| lia]. 
        eapply Returns_bind; eauto.
     - split; auto.
    }
    intros acc (mf & lf & gf & ?) (? & INV' & LOC').
    split; try split; auto.
    subst.
    clear STABLE FBODY OVER IH IN LOOPVAR' LOOPVAR. 
    clean_goal.

    eapply local_scope_modif_trans'; [| eassumption]. 
    clear LOC'.
    eapply local_scope_modif_trans'.
    2:{
      eapply local_scope_modif_shrink; eauto.
      solve_local_count.
    }
    repeat apply local_scope_modif_add'. 
    4: apply local_scope_modif_refl.
    eapply lid_bound_between_shrink; eauto; solve_local_count.
    solve_lid_bound_between.
    eapply lid_bound_between_shrink.
    eapply lid_bound_between_incLocalNamed; [| eauto |..].
    apply is_correct_prefix_append; auto.
    solve_local_count.
    solve_local_count.
Qed.

(* "Ideal world" refactoring that can happen

   * A separation predicate about [bodyF]
         The function call should not change the memory and local variables of
         the caller (i.e. should not change the local variable that is the loop
          index)-- right now, this is enforced in a rather ad-hoc way.

   * Elimination of [local_scope_modif]:
         [local_scope_modif] states that two local environments have changed
          exactly on the local id's bound between states [s] and [s'].
         A separation logic statement should (?) be able to refer to the local
        id's bound exactly between the two states.

   * Smarter way to reason about aliasing?
         [IRState] states that no pointers and ids can be aliased. This statement
         holds true for the generated code in this compiler, but perhaps we want
         more subtle reasoning about pointers..
 *)
(** *IRState
   Initial state : [s1]

   Intermediate state [sb1]
                (loopvar is bound)
   Intermediate state [sb2]

   Final state (after while loop generation) : [s2]
 *)
Theorem genWhileLoop_tfor_correct:
  forall (prefix : string)
    (loopvar : raw_id)            (* lvar storing the loop index *)
    (loopcontblock : block_id)    (* reentry point from the body back to the loop *)
    (body_entry : block_id)       (* entry point of the body *)
    (body_blocks : list (LLVMAst.block typ)) (* (llvm) body to be iterated *)
    (nextblock : block_id)        (* exit point of the overall loop *)
    (entry_id : block_id)         (* entry point of the overall loop *)
    (s1 s2 sb1 sb2 : IRState)
    (bks : list (LLVMAst.block typ)) ,

    In body_entry (inputs body_blocks) ->
    is_correct_prefix prefix ->

    (* All labels generated are distinct *)
    wf_ocfg_bid bks ->
    (* [loopvar] is bound between intermediate states *)
    lid_bound_between sb1 sb2 loopvar ->
    (* [nextblock] is not in the input list for the [bks] generated by the LLVM code *)
    free_in_cfg bks nextblock ->

    forall (n : nat)                     (* Number of iterations *)

      (* Generation of the LLVM code wrapping the loop around bodyV *)
      (HGEN: genWhileLoop prefix (EXP_Integer 0%Z) (EXP_Integer (Z.of_nat n))
                          loopvar loopcontblock body_entry body_blocks [] nextblock s1
                          ≡ inr (s2,(entry_id, bks)))

      (* Computation on the Helix side performed at each cell of the vector, *)
      (*    the counterpart to bodyV (body_blocks) *)
      A
      (bodyF: nat -> A -> itree _ A)

      (NO_OVERFLOW : (Z.of_nat n < Int64.modulus)%Z)

      (* Main relations preserved by iteration *)
      (I : nat -> _)
      (* Pre- and Post- conditions of the while loop *)
      P Q
      (* Initial value of the accumulator *)
      a0,

      (* We assume that we know how to relate the iterations of the bodies *)
      (forall g li mV a k _label,
          (conj_rel (I k)
                    (fun _ '(_, (l, _)) => l @ loopvar ≡ Some (uvalue_of_nat k)
                                        /\ k < n
                                        /\ Returns a (tfor bodyF 0 k a0))
                    a (mV,(li,g))) ->
          eutt
            (fun a' '(memV, (l, (g, x))) =>
               l @ loopvar ≡ Some (uvalue_of_nat k) /\
               (exists _label', x ≡ inl (_label', loopcontblock)) /\
               I (S k) a' (memV, (l, g)) /\
               local_scope_modif sb1 sb2 li l)
            (bodyF k a)
            (interp_cfg (denote_ocfg (convert_typ [] body_blocks) (_label, body_entry)) g li mV)
      )
      ->

      (* Invariant is stable under the administrative bookkeeping that the loop performs *)
      (forall k a l mV g id v,
          (lid_bound_between s1 s2 id \/ lid_bound_between sb1 sb2 id) ->
          I k a (mV, (l, g)) ->
          I k a (mV, ((alist_add id v l), g))) ->

      sb1 << sb2 ->
      local_count sb2 ≡ local_count s1 ->

    (* We bake in the weakening on the extremities to ease the use of the lemma *)
    imp_rel P (I 0) ->
    imp_rel (I n) Q ->

    (* Main result. Need to know initially that P holds *)
    forall g li mV _label,
      P a0 (mV,(li,g)) ->
      eutt (fun a '(memV, (l, (g,x))) =>
              (x ≡ inl (loopcontblock, nextblock) \/ x ≡ inl (entry_id, nextblock)) /\
              Q a (memV,(l,g)) /\
              (* The difference between local environment [li] and [l] was made during state [sb1] and [s2] *)
              local_scope_modif sb1 s2 li l)
           (tfor bodyF 0 n a0)
           (interp_cfg (denote_ocfg (convert_typ [] bks) (_label ,entry_id)) g li mV).
Proof.

  intros * IN PREFIX UNIQUE LOOPVAR EXIT * GEN * BOUND * IND STABLE LE1 LE2 pre post * PRE.
  pose proof @genWhileLoop_tfor_ind as GEN_IND.

  specialize (GEN_IND prefix loopvar loopcontblock body_entry body_blocks nextblock entry_id s1 s2 sb1 sb2 bks).
  specialize (GEN_IND IN PREFIX UNIQUE LOOPVAR EXIT n GEN A bodyF).
  unfold genWhileLoop in GEN. cbn* in GEN. simp.
  destruct n as [| n].
  - (* 0th index *)
    cbn.

    apply free_in_convert_typ with (env := []) in EXIT; cbn in EXIT; rewrite ?convert_typ_ocfg_app in EXIT.
    cbn; rewrite ?convert_typ_ocfg_app.
    cbn in GEN_IND; rewrite ?convert_typ_ocfg_app in GEN_IND.

    hide_cfg.
    vjmp.

    vred. vred. vred. vstep.
    {
      cbn.
      vstep.
      vstep; solve_lu; reflexivity.
      vstep; reflexivity.
      all:reflexivity.
    }

    (* We now branch to [nextblock] *)
    vbranch_r.
    { vstep.
      solve_lu.
      apply eutt_Ret; repeat f_equal.
    }

    vjmp_out.
    vred.
    cbn.
    rewrite tfor_0.

    (* We have only touched local variables that the invariant does not care about, we can reestablish it *)
    apply eutt_Ret. cbn. split. right. reflexivity.
    split.
    + eapply post; eapply STABLE; eauto.
      left; solve_lid_bound_between.
    + solve_local_scope_modif.

  - cbn in *.
    specialize (GEN_IND 1).
    forward GEN_IND; [lia |].
    forward GEN_IND; [lia |].
    
    (* Clean up convert_typ junk *)
    apply free_in_convert_typ with (env := []) in EXIT; cbn in EXIT; rewrite ?convert_typ_ocfg_app in EXIT; cbn in EXIT.
    apply wf_ocfg_bid_convert_typ with (env := []) in UNIQUE; cbn in UNIQUE; rewrite ?convert_typ_ocfg_app in UNIQUE; cbn in UNIQUE.
    cbn; rewrite ?convert_typ_ocfg_app; cbn.
    cbn in GEN_IND; rewrite ?convert_typ_ocfg_app in GEN_IND; cbn in GEN_IND.

    hide_cfg.

    vjmp.
    cbn.
    vred. vred. vred.
    vstep.
    {
      vstep. vstep; solve_lu.
      vstep; solve_lu.
      all :reflexivity.
    }
    vstep.

    (* Step 1 : Jump to b0, i.e. loopblock (since we have checked k < n). *)
    vbranch_l.
    {
      cbn; vstep.
      match goal with
        |- Maps.lookup ?k (alist_add ?k ?a ?b) ≡ _ =>
        rewrite (lookup_alist_add_eq _ _ b)
      end; reflexivity.
      unfold eval_int_icmp. cbn.
      rewrite ltu_Z_to_Int64; try lia.
      reflexivity.
    }
    vjmp. vred.
    (* We update [loopvar] via the phi-node *)
    cbn; vred.

    (* BEGIN TODO: infrastructure to deal with non-empty phis *)
    unfold denote_phis.
    cbn.
    rewrite denote_phi_hd.
    cbn.

    (* TOFIX: broken automation, a wild translate sneaked in where it shouldn't *)
    rewrite translate_bind.
    rewrite ?interp_cfg3_ret, ?bind_ret_l;
      rewrite ?interp_cfg3_bind, ?bind_bind.

    vstep. tred. repeat vred.
    unfold map_monad. cbn. vred.
    rewrite interp_cfg3_LW. vred. vred. vred. vred.

    subst.
    vred.
    vred.
    inv VG.
    
    rewrite denote_ocfg_prefix; cycle 1; auto.
    {
      match goal with
        |- ?x::?y::?z ≡ _ => replace (x::y::z) with ([x;y]++z)%list by reflexivity
      end; f_equal.
    }
    hide_cfg.
    vred.

    rewrite tfor_unroll; [| lia].
    eapply eutt_clo_bind_returns.

    + (* Base case : first iteration of loop. *)
      eapply IND.
      split; [| split; [|split]].
      eapply STABLE; eauto.
      eapply STABLE; eauto.
      left; solve_lid_bound_between.
      unfold Maps.add, Map_alist.
      apply alist_find_add_eq.
      lia.
      rewrite tfor_0; apply ReturnsRet; reflexivity.
    + intros ? (? & ? & ? & ?) (LU & [? ->] & []) RET1 _.
      typ_to_dtyp_simplify.
      eapply eutt_Proper_mono.
      2: apply GEN_IND; eauto.
      { intros ? (? & ? & ? & ?) [-> []]; split; [|split]; eauto.
        clear GEN_IND IND STABLE.
        eapply local_scope_modif_trans'; [| eassumption]. 
        eapply local_scope_modif_trans'.
        2:{
          eapply local_scope_modif_shrink; eauto.
          solve_local_count.
        }
        repeat apply local_scope_modif_add'.
        3: apply local_scope_modif_refl.
        eapply lid_bound_between_shrink; eauto; solve_local_count.
        solve_lid_bound_between.
      }
      clear GEN_IND.
      {
        intros * (? & ? & ? & ?).
        eapply IND.
        do 3 (split; auto).
        lia.
        rewrite tfor_unroll; [| lia].
        eapply Returns_bind; eauto.
      }
      split; auto.
Qed.

Lemma genWhileLoop_tfor_ind_lid :
  forall (prefix : string)
    (loopvar : raw_id)            (* lvar storing the loop index *)
    (loopcontblock : block_id)    (* reentry point from the body back to the loop *)
    (body_entry : block_id)       (* entry point of the body *)
    (body_blocks : ocfg typ) (* (llvm) body to be iterated *)
    (nextblock : block_id)        (* exit point of the overall loop *)
    (entry_id : block_id)         (* entry point of the overall loop *)
    (s1 s2 sb1 sb2 : IRState)
    (bks : list (LLVMAst.block typ)) ,

    In body_entry (inputs body_blocks) ->

    is_correct_prefix prefix ->
    (* All labels generated are distinct *)
    wf_ocfg_bid bks ->
    lid_bound_between sb1 sb2 loopvar ->
    free_in_cfg bks nextblock ->

    forall (to : raw_id) (s_to : IRState)
      (STO_LTS1 : s_to << s1)
      (STO_LTSB1 : s_to << sb1)
      (TO_BOUND : lid_bound s_to to)
      (n : MInt64asNT.t)

      (* Generation of the LLVM code wrapping the loop around bodyV *)
      (HGEN: genWhileLoop prefix (EXP_Integer 0%Z) (EXP_Ident (ID_Local to))
                          loopvar loopcontblock body_entry body_blocks [] nextblock s1
                          ≡ inr (s2,(entry_id, bks)))

      (* Computation on the other side, operating over some type of accumulator [A], *)
      (* i.e. the counterpart to bodyV (body_blocks) *)
      (A : Type)
      (bodyF: nat -> A -> itree _ A)


      (j : nat)                       (* Next iteration to be performed *)
      (* (UPPER_BOUND : 0 < j <= n) *)
      (* (NO_OVERFLOW : (Z.of_nat n < Int64.modulus)%Z) *)

      (* Main relations preserved by iteration *)
      (I : nat (* -> A *) -> A -> _)
      a0,

      (* We assume that we know how to relate the iterations of the bodies *)
      (forall g li mV a k _label,
          (conj_rel (I k)
                    (fun _ '(_, (l, _)) => l @ loopvar ≡ Some (uvalue_of_nat k)
                                        /\ li @ to ≡ Some (UVALUE_I64 n)
                                        /\ j <= k < (MInt64asNT.to_nat n)
                                        /\ Returns a (tfor bodyF j k a0))
                    a (mV,(li,g))) ->
          eutt
            (fun a' '(memV, (l, (g, x))) =>
                 l @ loopvar ≡ Some (uvalue_of_nat k) /\
                 (exists _label', x ≡ inl (_label', loopcontblock)) /\
                 I (S k) a' (memV, (l, g)) /\
                 local_scope_modif sb1 sb2 li l)
            (bodyF k a)
            (interp_cfg (denote_ocfg (convert_typ [] body_blocks) (_label, body_entry)) g li mV)
      ) ->

      (* Invariant is stable under the administrative bookkeeping that the loop performs *)
      (forall k a l mV g id v,
          (lid_bound_between s1 s2 id \/ lid_bound_between sb1 sb2 id) ->
          I k a (mV, (l, g)) ->
          I k a (mV, ((alist_add id v l), g))) ->

      sb1 << sb2 ->
      local_count sb2 ≡ local_count s1 ->

    (* Main result. Need to know initially that P holds *)
    forall g li mV _label,
      (conj_rel
         (I j)
         (fun _ '(_, (l, _)) => l @ loopvar ≡ Some (uvalue_of_nat (j - 1))
                             /\ 0 < j <= MInt64asNT.to_nat n
                             /\ li @ to ≡ Some (UVALUE_I64 n))
         a0 (mV,(li,g))
      ) ->
      eutt (fun a '(memV, (l, (g,x))) =>
              x ≡ inl (loopcontblock, nextblock) /\
              I (MInt64asNT.to_nat n) a (memV,(l,g)) /\
              local_scope_modif sb1 s2 li l
           )
           (tfor bodyF j (MInt64asNT.to_nat n) a0)
           (interp_cfg (denote_ocfg (convert_typ [] bks)
                                                (_label, loopcontblock)) g li mV).
Proof. 
  intros * IN PREF UNIQUE_IDENTS LOOPVAR_SCOPE NEXTBLOCK_ID * STO_LTS1 STO_LTSB1 TO_BOUND n GEN A *.
  assert (to ≢ loopvar) as LOOPVARNEQ.
  { eapply lid_bound_earlier.
    solve_lid_bound.
    solve_lid_bound_between.
    solve_local_count.
  }
  unfold genWhileLoop in GEN. cbn* in GEN. simp.
  intros FBODY STABLE LT * COUNT.

  remember (MInt64asNT.to_nat n - j) as k eqn:K_EQ.
  revert j a0 K_EQ FBODY.
  induction k as [| k IH];
    intros j a0 K_EQ FBODY g li mV _label (INV & LOOPVAR & (LOWER_BOUND & UPPER_BOUND) & INLG).
  - (* Base case: we enter through [loopcontblock] and jump out immediately to [nextblock] *)
    Import ProofMode.
    (* This ugly preliminary is due to the conversion of types, as most ugly things on Earth are. *)
    apply wf_ocfg_bid_convert_typ with (env := []) in UNIQUE_IDENTS; cbn in UNIQUE_IDENTS; rewrite ?convert_typ_ocfg_app in UNIQUE_IDENTS; cbn in UNIQUE_IDENTS.
    apply free_in_convert_typ with (env := []) in NEXTBLOCK_ID; cbn in NEXTBLOCK_ID; rewrite ?convert_typ_ocfg_app in NEXTBLOCK_ID; cbn in NEXTBLOCK_ID.
    cbn; rewrite ?convert_typ_ocfg_app. 

    cbn.
    hide_cfg.

    (* We jump into [loopcontblock]
       We denote the content of the block.
     *)
  
    vjmp.

    cbn.
    assert (MInt64asNT.to_nat n ≡ j) by lia; subst.
    (* replace (j - S j) with 0 by lia. *)

    vred.
    vred.
    vred.
    vstep.
    {
      vstep.
      vstep; solve_lu; reflexivity.
      vstep; reflexivity.
      all: reflexivity.
    }
    vred.
    vstep.
    {
      cbn.
      vstep.
      vstep; solve_lu; reflexivity.
      vstep.

      solve_alist_in.
      all: reflexivity.
    }

    assert (dvalue_to_uvalue
                  (eval_int_icmp Ult
                                 (add (Int64asNT.Int64.repr (Z.of_nat (MInt64asNT.to_nat n - 1))) (repr 1)) n)
                  ≡ UVALUE_I1 DynamicValues.Int1.zero) as CMP.
    {
      rewrite __arithu; try lia.
      unfold eval_int_icmp.
      cbn.
      rewrite repr_of_nat_to_nat.
      rewrite ltu_antisym.
      reflexivity.
      unfold MInt64asNT.to_nat.
      cbn.
      rewrite intval_to_from_nat_id.
      pose proof (Int64.intrange n).
      lia.
    }


    (* We now branch to [nextblock] *)
    vbranch_r.
    { vstep.
      solve_lu.
      apply eutt_Ret; repeat f_equal.
      eauto.
    }

    vjmp_out.

    cbn.
    cbn; vred.

    rewrite tfor_0.
    (* We have only touched local variables that the invariant does not care about, we can reestablish it *)
    rename s2 into FINAL_STATE, i into s2, i0 into s3, i1 into s4, i2 into s5.
    apply eutt_Ret.
    split; split.
    + eapply STABLE; [left; solve_lid_bound_between |].
      eapply STABLE; [| eauto].
      left; eapply lid_bound_between_shrink; [eapply lid_bound_between_incLocalNamed; [| eauto]; eapply is_correct_prefix_append; auto | | ]; solve_local_count.

    + eapply local_scope_modif_add'.
      solve_lid_bound_between.
      eapply local_scope_modif_add'.
      eapply lid_bound_between_shrink_down with (s2 := s5).
      solve_local_count.
      eapply lid_bound_between_incLocalNamed. 2 : eauto.
      apply string_forall_append. auto. auto. auto.

  - (* Inductive case *)
    cbn in *.
    (* This ugly preliminary is due to the conversion of types, as most ugly things on Earth are. *)
    apply wf_ocfg_bid_convert_typ with (env := []) in UNIQUE_IDENTS; cbn in UNIQUE_IDENTS; rewrite ?convert_typ_ocfg_app in UNIQUE_IDENTS; cbn in UNIQUE_IDENTS.
    apply free_in_convert_typ with (env := []) in NEXTBLOCK_ID; cbn in NEXTBLOCK_ID; rewrite ?convert_typ_ocfg_app in NEXTBLOCK_ID; cbn in NEXTBLOCK_ID.
    cbn; rewrite ?convert_typ_ocfg_app; cbn.
    cbn in IH; rewrite ?convert_typ_ocfg_app in IH; cbn in IH.
    hide_cfg.

    (* RHS : Reducing RHS to apply Body Hypothesis *)
    (* Step 1 : First, process [loopcontblock] and check that k<n, and hence that we do not exit *)
    vjmp.
    cbn.
    vred.
    vred.
    vred.
    vstep.
    {
      vstep.
      vstep; solve_lu.
      vstep; solve_lu.
      all: reflexivity.
    }
    vred.
    vstep.
    {
      cbn; vstep.
      vstep; solve_lu.
      vstep.
      solve_alist_in.
      all: reflexivity.
    }
    vred.

    (* Step 2 : Jump to b0, i.e. loopblock (since we have checked k < n). *)
    vbranch_l.
    { cbn; vstep.
      solve_lu.
      rewrite __arithu; try lia.
      apply eutt_Ret.
      unfold eval_int_icmp.
      cbn.
      pose proof (Int64.intrange n).
      rewrite <- (repr_of_nat_to_nat n).
      rewrite ltu_nat_to_Int64; try lia.
      reflexivity.
      unfold MInt64asNT.to_nat.
      cbn.
      rewrite intval_to_from_nat_id.
      lia.
      pose proof (Int64.intrange n).
      apply Znat.inj_le in UPPER_BOUND.
      unfold MInt64asNT.to_nat in UPPER_BOUND.
      rewrite intval_to_from_nat_id in UPPER_BOUND.
      lia.
    }

    vjmp.
    (* We update [loopvar] via the phi-node *)
    cbn; vred.

    (* BEGIN TODO: infrastructure to deal with non-empty phis *)
    unfold denote_phis.
    cbn.
    rewrite denote_phi_tl; cycle 1.
    {
      inv VG. inversion UNIQUE_IDENTS.
      subst. intro. subst. apply H1. right.
      rewrite inputs_app.
      apply in_or_app. right. constructor. reflexivity.
    }

    rewrite denote_phi_hd.
    cbn.
    (* TOFIX: broken automation, a wild translate sneaked in where it shouldn't *)
    rewrite translate_bind.
    rewrite ?interp_cfg3_ret, ?bind_ret_l;
      rewrite ?interp_cfg3_bind, ?bind_bind.

    vstep.
    {
      setoid_rewrite lookup_alist_add_ineq.
      setoid_rewrite lookup_alist_add_eq. reflexivity. subst.
      intros ?; eapply __fresh; eauto.
    }
    (* TOFIX: broken automation, a wild translate sneaked in where it shouldn't *)
    rewrite translate_ret.
    repeat vred.
    cbn.
    repeat vred.
    (* TOFIX: we leak a [LocalWrite] event *)
    rewrite interp_cfg3_LW.
    repeat vred.
    subst.
    cbn.
    (* END TODO: infrastructure to deal with non-empty phis *)

    vred.
    (* Step 3 : we jump into the body *)
    vred.

    (* In order to use our body hypothesis, we need to restrict the ambient cfg to only the body *)
    inv VG.
    rewrite denote_ocfg_prefix; cycle 1; auto.
    {
      match goal with
        |- ?x::?y::?z ≡ _ => replace (x::y::z) with ([x;y]++z)%list by reflexivity
      end; f_equal.
    }
    hide_cfg.
    (* rewrite <- EQidx. *)

    cbn; vred.
    destruct j as [| j]; [lia |].
    rewrite tfor_unroll; [| lia].

    eapply eutt_clo_bind_returns.
    (* We can now use the body hypothesis *)
    eapply FBODY.
    {
      (* A bit of arithmetic is needed to prove that we have the right precondition *)
      split; [| split; [| split; [| split]]].
      + repeat (eapply STABLE; eauto).
        left; solve_lid_bound_between.
        left; eapply lid_bound_between_shrink; [eapply lid_bound_between_incLocalNamed; [| eauto]; eapply is_correct_prefix_append; auto | | ]; solve_local_count.

      + rewrite alist_find_add_eq; reflexivity.

      + repeat (rewrite alist_find_neq; eauto); solve_id_neq.
      + lia.
      + rewrite tfor_0; apply ReturnsRet; reflexivity.
    }

    (* Step 4 : Back to starting from loopcontblock and have reestablished everything at the next index:
        conclude by IH *)
    intros a1 (m1 & l1 & g1 & ?) (LOOPVAR' & [? ->] & (IH' & LOC)) RET1 _.
    typ_to_dtyp_simplify.

    eapply eqit_mon; auto.
    2 :{
      eapply IH.
      lia.
      - intros * (? & ? & ? & ? & ?).
        eapply FBODY.
        do 3 (split; auto).
        split.
        lia.

        rewrite tfor_unroll; [| lia].
        eapply Returns_bind; eauto.
      - repeat (split; auto).
        lia.

        edestruct lid_bound_before_bound_between with (s2 := sb1).
        solve_lid_bound.
        solve_local_count.

        erewrite local_scope_preserve_modif.
        2: eauto.
        repeat (rewrite alist_find_neq; eauto); solve_id_neq.
        eauto.
    }
    intros x0 (mf & lf & gf & ?) (PR1 & PR2 & PR3).
    repeat split; eauto.
    clean_goal.
    
    eapply local_scope_modif_trans'; [| eassumption]. 
    eapply local_scope_modif_trans'.
    2:{
      eapply local_scope_modif_shrink; eauto.
      solve_local_count.
    }
    repeat apply local_scope_modif_add'. 
    4: apply local_scope_modif_refl.
    eapply lid_bound_between_shrink; eauto; solve_local_count.
    solve_lid_bound_between.
    eapply lid_bound_between_shrink.
    eapply lid_bound_between_incLocalNamed; [| eauto |..].
    apply is_correct_prefix_append; auto.
    solve_local_count.
    solve_local_count.
Qed.

Lemma genWhileLoop_tfor_correct_lid:
  forall (prefix : string)
    (loopvar : raw_id)            (* lvar storing the loop index *)
    (loopcontblock : block_id)    (* reentry point from the body back to the loop *)
    (body_entry : block_id)       (* entry point of the body *)
    (body_blocks : list (LLVMAst.block typ)) (* (llvm) body to be iterated *)
    (nextblock : block_id)        (* exit point of the overall loop *)
    (entry_id : block_id)         (* entry point of the overall loop *)
    (s1 s2 sb1 sb2 : IRState)
    (bks : list (LLVMAst.block typ)) ,

    In body_entry (inputs body_blocks) ->
    is_correct_prefix prefix ->

    (* All labels generated are distinct *)
    wf_ocfg_bid bks ->
    lid_bound_between sb1 sb2 loopvar ->
    free_in_cfg bks nextblock ->

    forall (to : raw_id) (s_to : IRState)  (* Number of iterations in id *)
      (STO_LTS1 : s_to << s1)
      (STO_LTSB1 : s_to << sb1)
      (TO_BOUND : lid_bound s_to to)
      (n : MInt64asNT.t)

      (* Generation of the LLVM code wrapping the loop around bodyV *)
      (HGEN: genWhileLoop prefix (EXP_Integer 0%Z) (EXP_Ident (ID_Local to))
                          loopvar loopcontblock body_entry body_blocks [] nextblock s1
                          ≡ inr (s2,(entry_id, bks)))

      (* Computation on the Helix side performed at each cell of the vector, *)
      (*    the counterpart to bodyV (body_blocks) *)
      A
      (bodyF: nat -> A -> itree _ A)

      (* Main relations preserved by iteration *)
      (I : nat -> _) P Q
      (* Initial value of the accumulator *)
      a0,

      (* We assume that we know how to relate the iterations of the bodies *)
      (forall g li mV a k _label,
          (conj_rel (I k)
                    (fun _ '(_, (l, _)) => l @ loopvar ≡ Some (uvalue_of_nat k)
                                        /\ li @ to ≡ Some (UVALUE_I64 n)
                                        /\ k < (MInt64asNT.to_nat n)
                                        /\ Returns a (tfor bodyF 0 k a0))
                    a (mV,(li,g))) ->
          eutt
            (fun a' '(memV, (l, (g, x))) =>
               l @ loopvar ≡ Some (uvalue_of_nat k) /\
               (exists _label', x ≡ inl (_label', loopcontblock)) /\
               I (S k) a' (memV, (l, g)) /\
               local_scope_modif sb1 sb2 li l)
            (bodyF k a)
            (interp_cfg (denote_ocfg (convert_typ [] body_blocks) (_label, body_entry)) g li mV)
      )
      ->

      (* Invariant is stable under the administrative bookkeeping that the loop performs *)
      (forall k a l mV g id v,
          (lid_bound_between s1 s2 id \/ lid_bound_between sb1 sb2 id) ->
          I k a (mV, (l, g)) ->
          I k a (mV, ((alist_add id v l), g))) ->

      sb1 << sb2 ->
      local_count sb2 ≡ local_count s1 ->

    (* We bake in the weakening on the extremities to ease the use of the lemma *)
    imp_rel P (I 0) ->
    imp_rel (I (MInt64asNT.to_nat n)) Q ->

    (* Main result. Need to know initially that P holds *)
    forall g li mV _label,
      li @ to ≡ Some (UVALUE_I64 n) ->
      P a0 (mV,(li,g)) ->
      eutt (fun a '(memV, (l, (g,x))) =>
              (x ≡ inl (loopcontblock, nextblock) \/ x ≡ inl (entry_id, nextblock)) /\
              Q a (memV,(l,g)) /\
              local_scope_modif sb1 s2 li l)
           (tfor bodyF 0 (MInt64asNT.to_nat n) a0)
           (interp_cfg (denote_ocfg (convert_typ [] bks) (_label ,entry_id)) g li mV).
Proof.
  intros * IN PREF UNIQUE LOOPVAR EXIT * STO_LTS1 STO_LTSB1 TO_BOUND n GEN A *.
  assert (to ≢ loopvar) as LOOPVARNEQ.
  { eapply lid_bound_earlier.
    solve_lid_bound.
    solve_lid_bound_between.
    solve_local_count.
  }
  intros IND STABLE LT * COUNT pre post * INLG PRE.
  pose proof @genWhileLoop_tfor_ind_lid as GEN_IND.

  specialize (GEN_IND prefix loopvar loopcontblock body_entry body_blocks nextblock entry_id s1 s2 sb1 sb2 bks).
  specialize (GEN_IND IN PREF UNIQUE LOOPVAR EXIT to s_to STO_LTS1 STO_LTSB1 TO_BOUND n GEN A bodyF).
  unfold genWhileLoop in GEN. cbn* in GEN. simp.

  remember (MInt64asNT.to_nat n) as n_nat.
  destruct n_nat  as [| n_nat].
  - (* 0th index *)
    cbn.

    apply free_in_convert_typ with (env := []) in EXIT; cbn in EXIT; rewrite ?convert_typ_ocfg_app in EXIT.
    cbn; rewrite ?convert_typ_ocfg_app.
    cbn in GEN_IND; rewrite ?convert_typ_ocfg_app in GEN_IND.

    hide_cfg.
    vjmp.

    vred. vred. vred. vstep.
    {
      cbn.
      vstep.
      vstep; solve_lu; reflexivity.
      vstep.
      solve_alist_in.
      vstep; reflexivity.
      all:reflexivity.
    }

    (* We now branch to [nextblock] *)
    vbranch_r.
    { vstep.
      solve_lu.
      apply eutt_Ret; repeat f_equal.
      unfold eval_int_icmp.
      cbn.
      pose proof (Int64.intrange n).
      rewrite <- (repr_of_nat_to_nat n).
      change (repr 0) with (repr (Z.of_nat (Z.to_nat 0))).
      rewrite ltu_nat_to_Int64_false; try lia.
      reflexivity.
    }

    vjmp_out.
    vred.
    cbn.
    rewrite tfor_0.

    (* We have only touched local variables that the invariant does not care about, we can reestablish it *)
    apply eutt_Ret. cbn. split. right. reflexivity.
    split.
    + eapply post; eapply STABLE; eauto.
      left; solve_lid_bound_between.
    + solve_local_scope_modif.

  - cbn in *.
    specialize (GEN_IND 1).
    
    (* Clean up convert_typ junk *)
    apply free_in_convert_typ with (env := []) in EXIT; cbn in EXIT; rewrite ?convert_typ_ocfg_app in EXIT; cbn in EXIT.
    apply wf_ocfg_bid_convert_typ with (env := []) in UNIQUE; cbn in UNIQUE; rewrite ?convert_typ_ocfg_app in UNIQUE; cbn in UNIQUE.
    cbn; rewrite ?convert_typ_ocfg_app; cbn.
    cbn in GEN_IND; rewrite ?convert_typ_ocfg_app in GEN_IND; cbn in GEN_IND.

    hide_cfg.

    vjmp.
    cbn.
    vred. vred. vred.
    vstep.
    {
      vstep. vstep; solve_lu.
      vstep; solve_lu.
      all :reflexivity.
    }
    vstep.

    (* Step 1 : Jump to b0, i.e. loopblock (since we have checked k < n). *)
    vbranch_l.
    {
      cbn; vstep.
      match goal with
        |- Maps.lookup ?k (alist_add ?k ?a ?b) ≡ _ =>
        rewrite (lookup_alist_add_eq _ _ b)
      end; reflexivity.
      unfold eval_int_icmp. cbn.
      pose proof (Int64.intrange n).
      rewrite <- (repr_of_nat_to_nat n).
      change (repr 0) with (repr (Z.of_nat (Z.to_nat 0))).
      rewrite ltu_nat_to_Int64; try lia.
      reflexivity.
      unfold MInt64asNT.to_nat.
      lia.
    }
    vjmp. vred.
    (* We update [loopvar] via the phi-node *)
    cbn; vred.

    (* BEGIN TODO: infrastructure to deal with non-empty phis *)
    unfold denote_phis.
    cbn.
    rewrite denote_phi_hd.
    cbn.

    (* TOFIX: broken automation, a wild translate sneaked in where it shouldn't *)
    rewrite translate_bind.
    rewrite ?interp_cfg3_ret, ?bind_ret_l;
      rewrite ?interp_cfg3_bind, ?bind_bind.

    vstep. tred. repeat vred.
    unfold map_monad. cbn. vred.
    rewrite interp_cfg3_LW. vred. vred. vred. vred.

    subst.
    vred.
    vred.
    inv VG.
    
    rewrite denote_ocfg_prefix; cycle 1; auto.
    {
      match goal with
        |- ?x::?y::?z ≡ _ => replace (x::y::z) with ([x;y]++z)%list by reflexivity
      end; f_equal.
    }
    hide_cfg.
    vred.

    rewrite tfor_unroll; [| lia].
    eapply eutt_clo_bind_returns.

    + (* Base case : first iteration of loop. *)
      eapply IND.
      split; [| split; [|split]].
      eapply STABLE; eauto.
      eapply STABLE; eauto.
      left; solve_lid_bound_between.
      unfold Maps.add, Map_alist.
      solve_alist_in.
      solve_alist_in.
      split.
      lia.
      rewrite tfor_0; apply ReturnsRet; reflexivity.
    + intros ? (? & ? & ? & ?) (LU & [? ->] & []) RET1 _.
      typ_to_dtyp_simplify.
      eapply eutt_Proper_mono.
      2: apply GEN_IND; eauto.
      { intros ? (? & ? & ? & ?) [-> []]; split; [|split]; eauto.
        auto.
        clear GEN_IND IND STABLE.
        eapply local_scope_modif_trans'; [| eassumption]. 
        eapply local_scope_modif_trans'.
        2:{
          eapply local_scope_modif_shrink; eauto.
          solve_local_count.
        }
        repeat apply local_scope_modif_add'.
        3: apply local_scope_modif_refl.
        eapply lid_bound_between_shrink; eauto; solve_local_count.
        solve_lid_bound_between.
      }
      clear GEN_IND.
      {
        intros * (? & ? & ? & ? & ?).
        eapply IND.
        do 3 (split; auto).
        split.
        lia.
        rewrite tfor_unroll; [| lia].
        eapply Returns_bind; eauto.
      }
      repeat split; auto.
      lia.

      edestruct lid_bound_before_bound_between with (s2 := sb1).
      solve_lid_bound.
      solve_local_count.

      erewrite local_scope_preserve_modif.
      2: eauto.
      cbn.
      repeat (rewrite alist_find_neq; eauto). solve_id_neq.
      eauto.
Qed.


Lemma genWhileLoop_tfor_correct_nexpr :
  forall (prefix : string)
    (loopvar : raw_id)            (* lvar storing the loop index *)
    (loopcontblock : block_id)    (* reentry point from the body back to the loop *)
    (body_entry : block_id)       (* entry point of the body *)
    (body_blocks : list (LLVMAst.block typ)) (* (llvm) body to be iterated *)
    (nextblock : block_id)        (* exit point of the overall loop *)
    (entry_id : block_id)         (* entry point of the overall loop *)
    (σ : evalContext)
    (s1 s2 sb1 sb2 : IRState)
    (bks : list (LLVMAst.block typ)) ,

    In body_entry (inputs body_blocks) ->
    is_correct_prefix prefix ->

    (* All labels generated are distinct *)
    wf_ocfg_bid bks ->
    lid_bound_between sb1 sb2 loopvar ->
    free_in_cfg bks nextblock ->
    
    forall (to : NExpr) (s_to_pre s_to : IRState)  (* Number of iterations in id *)
      (mi_to mf_to : memoryH)
      (e_to : exp typ)
      (c_to : code typ)
      (WF_TO : WF_IRState σ s_to_pre)
      (BOUND_TO : gamma_bound s_to_pre)
      (GEN_TO : genNExpr to s_to_pre ≡ inr (s_to, (e_to, c_to)))

      (STO_LTS1 : s_to << s1)
      (STO_LTSB1 : s_to << sb1)

      (n : MInt64asNT.t)
      (RET_TO : @Returns (CallE +' PickE +' UBE +' DebugE +' FailureE) _ (Some (mf_to, n)) (interp_helix (denoteNExpr σ to) mi_to))

      (* Generation of the LLVM code wrapping the loop around bodyV *)
      (HGEN: genWhileLoop prefix (EXP_Integer 0%Z) e_to
                          loopvar loopcontblock body_entry body_blocks [] nextblock s1
                          ≡ inr (s2,(entry_id, bks)))

      (* Computation on the Helix side performed at each cell of the vector, *)
      (*    the counterpart to bodyV (body_blocks) *)
      A
      (bodyF: nat -> A -> itree _ A)

      (* Main relations preserved by iteration *)
      (I : nat -> _) P Q
      (* Initial value of the accumulator *)
      a0,

      (* We assume that we know how to relate the iterations of the bodies *)
      (forall g li mV a k _label,
          (conj_rel (I k)
                    (fun _ '(_, (l, _)) => l @ loopvar ≡ Some (uvalue_of_nat k)
                                        /\ (forall x, e_to ≡ EXP_Ident (ID_Local x) -> li @ x ≡ Some (UVALUE_I64 n))
                                        /\ k < (MInt64asNT.to_nat n)
                                        /\ Returns a (tfor bodyF 0 k a0))
                    a (mV,(li,g))) ->
          eutt
            (fun a' '(memV, (l, (g, x))) =>
               l @ loopvar ≡ Some (uvalue_of_nat k) /\
               (exists _label', x ≡ inl (_label', loopcontblock)) /\
               I (S k) a' (memV, (l, g)) /\
               local_scope_modif sb1 sb2 li l)
            (bodyF k a)
            (interp_cfg (denote_ocfg (convert_typ [] body_blocks) (_label, body_entry)) g li mV)
      )
      ->

      (* Invariant is stable under the administrative bookkeeping that the loop performs *)
      (forall k a l mV g id v,
          (lid_bound_between s1 s2 id \/ lid_bound_between sb1 sb2 id) ->
          I k a (mV, (l, g)) ->
          I k a (mV, ((alist_add id v l), g))) ->

      sb1 << sb2 ->
      local_count sb2 ≡ local_count s1 ->

    (* We bake in the weakening on the extremities to ease the use of the lemma *)
    imp_rel P (I 0) ->
    imp_rel (I (MInt64asNT.to_nat n)) Q ->

    (* Main result. Need to know initially that P holds *)
    forall g li mV _label,
      (forall x, e_to ≡ EXP_Ident (ID_Local x) -> li @ x ≡ Some (UVALUE_I64 n)) ->
      P a0 (mV,(li,g)) ->
      eutt (fun a '(memV, (l, (g,x))) =>
              (x ≡ inl (loopcontblock, nextblock) \/ x ≡ inl (entry_id, nextblock)) /\
              Q a (memV,(l,g)) /\
              local_scope_modif sb1 s2 li l)
           (tfor bodyF 0 (MInt64asNT.to_nat n) a0)
           (interp_cfg (denote_ocfg (convert_typ [] bks) (_label ,entry_id)) g li mV).
Proof.
  intros * IN PREF UNIQUE LOOPVAR EXIT * WF_TO BOUND_TO GEN_TO STO_LTS1 STO_LTSB1 n RET_TO GEN A *.
  intros IND STABLE LT * COUNT pre post * IFID PRE.

  pose proof (genNExpr_ident_or_int to mi_to WF_TO RET_TO GEN_TO) as [NEXP_INT | NEXP_ID].
  - (* Nexp is a constant integer... *)
    eapply genWhileLoop_tfor_correct; eauto.
    + subst.

      unfold MInt64asNT.to_nat.
      rewrite intval_to_from_nat_id.
      eauto.
    + unfold MInt64asNT.to_nat.
      rewrite intval_to_from_nat_id.
      pose proof Int64.intrange n.
      lia.
    + intros g0 li0 mV0 a k _label0 (HI & LI_LOOP & BOUND & RET).
      eapply IND.
      repeat split; eauto.
      intros x H. inv H.
      inv H0.
  - (* Nexp is an id... *)
    destruct NEXP_ID as (id_to & ETO).
    subst.
    eapply genWhileLoop_tfor_correct_lid.
    9: {
      eauto.
    }
    12: eassumption.
    all: eauto.

    eapply genNExpr_ident_bound; eauto.

    intros g0 li0 mV0 a k _label0 (HI & LI_LOOP & LI_TO & BOUND & RET).
    eapply IND.
    repeat split; eauto.
    intros x H. inv H.
    auto.
Qed.

Arguments TFunctor_code _ _ _ _/.
Arguments TFunctor_list _ _ _ _/.

Lemma genWhileLoop_init : 
  forall prefix from to loopvar loopcontblock body_entry body_blocks init_code nextblock s1 s2 entry_id bks _label,
    genWhileLoop prefix from to loopvar loopcontblock body_entry body_blocks init_code nextblock s1 ≡ inr (s2, (entry_id,bks)) ->
    wf_ocfg_bid bks ->
    ~ In entry_id (outputs body_blocks) ->
    free_in_cfg bks nextblock ->
    In body_entry (inputs body_blocks) ->
    exists bks', genWhileLoop prefix from to loopvar loopcontblock body_entry body_blocks [] nextblock s1 ≡ inr (s2, (entry_id,bks'))
            /\ denote_ocfg (convert_typ [] bks) (_label ,entry_id) ≈
                          denote_code (convert_typ [] init_code);; denote_ocfg (convert_typ [] bks') (_label ,entry_id).
Proof.
  Transparent genWhileLoop.
  intros * GEN WF NIN FREE_NEXT IN_ENTRY; cbn in *; simp.
  apply free_in_convert_typ with (env := []) in FREE_NEXT; cbn in FREE_NEXT; rewrite ?convert_typ_ocfg_app in FREE_NEXT; cbn in FREE_NEXT.
  eexists; split; [reflexivity |].
  cbn.
  cbn; rewrite !convert_typ_ocfg_app.
  cbn in *.
  rewrite map_app in *; cbn. 
  vjmp.
  cbn; vred.
  vred_l.
  vred_l.
  vred_l.
  apply eutt_eq_bind; intros [].
  eutt_hide_left.
  vjmp.
  cbn.
  unfold TFunctor_block; cbn.
  vred_r.
  vred_r.
  subst.
  cbn.
  (* rewrite typ_to_dtyp_equation; cbn. *)
  apply eutt_eq_bind; intros [].
  eapply eutt_post_bind; [apply has_post_translate, denote_terminator_exits_in_outputs |].
  intros []; [|reflexivity].
  cbn.
  intros [<- | [<- | abs]]; [| | inv abs].
  - (* We enter the loop *)
    rewrite list_cons_app, denote_ocfg_app_no_edges; [eutt_hide_left; rewrite list_cons_app, denote_ocfg_app_no_edges | |].
    + subst; reflexivity.
    + cbn.
      rewrite list_cons_app in WF.
      eapply (wf_ocfg_bid_find_None_app_l _ _ b0) in WF.
      * unfold find_block in *; cbn in *.
        destruct (Eqv.eqv_dec_p entry_id b0) as [EQ | INEQ]; [inv WF | auto].
      * apply wf_ocfg_bid_app_r in WF.
        solve_find_block.
    + match goal with
        |- no_reentrance _ (cons ?x ?y) => rewrite (list_cons_app x y)
      end.
      apply no_reentrance_app_r; split.
      { unfold no_reentrance; cbn.
        apply list_disjoint_singletons.
        rewrite list_cons_app in WF.
        intros abs; symmetry in abs.
        eapply wf_ocfg_bid_distinct_labels in WF; eauto.
        cbn; auto.
        cbn; right.
        rewrite map_app.
        apply ListUtil.in_appl; auto.
      }
      apply no_reentrance_app_r; split.
      {
        red; cbn.
        rewrite convert_typ_outputs.
        apply list_disjoint_singleton_right.
        auto.
      }
      { red; cbn.
        clear - WF NIN FREE_NEXT IN_ENTRY.
        apply list_disjoint_singleton_right.
        cbn.
        intros [-> | [-> | []]].
        - apply wf_ocfg_bid_cons_not_in in WF; eapply WF; left; auto.
        - eapply FREE_NEXT; left; auto.
      }

    + cbn.
      rewrite list_cons_app in WF.
      eapply (wf_ocfg_bid_find_None_app_l _ _ b0) in WF.
      * unfold find_block in *; cbn in *.
        destruct (Eqv.eqv_dec_p entry_id b0) as [EQ | INEQ]; [inv WF | auto].
      * apply wf_ocfg_bid_app_r in WF.
        solve_find_block.
    + match goal with
        |- no_reentrance _ (cons ?x ?y) => rewrite (list_cons_app x y)
      end.
      apply no_reentrance_app_r; split.
      { unfold no_reentrance; cbn.
        apply list_disjoint_singletons.
        rewrite list_cons_app in WF.
        intros abs; symmetry in abs.
        eapply wf_ocfg_bid_distinct_labels in WF; eauto.
        cbn; auto.
        cbn; right.
        rewrite map_app.
        apply ListUtil.in_appl; auto.
      }
      apply no_reentrance_app_r; split.
      {
        red; cbn.
        rewrite convert_typ_outputs.
        apply list_disjoint_singleton_right.
        auto.
      }
      { red; cbn.
        clear - WF NIN FREE_NEXT IN_ENTRY.
        apply list_disjoint_singleton_right.
        cbn.
        intros [-> | [-> | []]].
        - apply wf_ocfg_bid_cons_not_in in WF; eapply WF; left; auto.
        - eapply FREE_NEXT; left; auto.
      }
  - (* We don't enter the loop *)
    rewrite !typ_to_dtyp_equation in FREE_NEXT.
    cbn in *.
    vjmp_out.
    vjmp_out.
    reflexivity.
Qed.

Lemma genWhileLoop_entry_block :
  forall prefix from to loopvar loopcontblock body_entry body_blocks init_code nextblock loop_entry loop_blocks s1 s2,
    genWhileLoop prefix from to loopvar loopcontblock body_entry body_blocks init_code nextblock s1 ≡ inr (s2, (loop_entry, loop_blocks)) ->
    loop_entry ≡ ((prefix @@ "_entry") @@ string_of_nat (block_count s1)).
Proof.
  intros prefix from to loopvar loopcontblock body_entry body_blocks init_code nextblock loop_entry loop_blocks s1 s2 GEN.
  Transparent genWhileLoop.
  unfold genWhileLoop in GEN.
  inv GEN.
  repeat break_match; eauto.
  all: inv Heqs.
  Transparent incBlockNamed.
  unfold incBlockNamed in Heqs0.
  inv Heqs0.
  reflexivity.
  Opaque incBlockNamed.
  Opaque genWhileLoop.
Qed.

Lemma genWhileLoop_init' : 
  forall prefix from to loopvar loopcontblock body_entry body_blocks init_code nextblock s1 s2 entry_id bks _label,
    genWhileLoop prefix from to loopvar loopcontblock body_entry body_blocks init_code nextblock s1 ≡ inr (s2, (entry_id,bks)) ->
    wf_ocfg_bid bks ->
    ~ In entry_id (outputs body_blocks) ->
    free_in_cfg bks nextblock ->
    In body_entry (inputs body_blocks) ->
    exists bks',
      genWhileLoop prefix from to loopvar loopcontblock body_entry body_blocks [] nextblock s1 ≡ inr (s2, (entry_id,bks')) /\
      denote_ocfg (convert_typ [] bks) (_label ,entry_id) ≈
                  denote_code (convert_typ [] init_code);; denote_ocfg (convert_typ [] bks') (_label ,entry_id) /\
      wf_ocfg_bid bks' /\
      free_in_cfg bks' nextblock.
Proof.
  Transparent genWhileLoop.
  intros * GEN WF NIN FREE_NEXT IN_ENTRY; cbn in *; simp.
  apply free_in_convert_typ with (env := []) in FREE_NEXT; cbn in FREE_NEXT; rewrite ?convert_typ_ocfg_app in FREE_NEXT; cbn in FREE_NEXT.
  eexists; split; [reflexivity |].
  split.
  cbn.
  cbn; rewrite !convert_typ_ocfg_app.
  cbn in *.
  rewrite map_app in *; cbn. 
  vjmp.
  cbn; vred.
  vred_l.
  vred_l.
  vred_l.
  apply eutt_eq_bind; intros [].
  eutt_hide_left.
  vjmp.
  cbn.
  unfold TFunctor_block; cbn.
  vred_r.
  vred_r.
  subst.
  cbn.
  (* rewrite typ_to_dtyp_equation; cbn. *)
  apply eutt_eq_bind; intros [].
  eapply eutt_post_bind; [apply has_post_translate, denote_terminator_exits_in_outputs |].
  intros []; [|reflexivity].
  cbn.
  intros [<- | [<- | abs]]; [| | inv abs].
  - (* We enter the loop *)
    rewrite list_cons_app, denote_ocfg_app_no_edges; [eutt_hide_left; rewrite list_cons_app, denote_ocfg_app_no_edges | |].
    + subst; reflexivity.
    + cbn.
      rewrite list_cons_app in WF.
      eapply (wf_ocfg_bid_find_None_app_l _ _ b0) in WF.
      * unfold find_block in *; cbn in *.
        destruct (Eqv.eqv_dec_p entry_id b0) as [EQ | INEQ]; [inv WF | auto].
      * apply wf_ocfg_bid_app_r in WF.
        solve_find_block.
    + match goal with
        |- no_reentrance _ (cons ?x ?y) => rewrite (list_cons_app x y)
      end.
      apply no_reentrance_app_r; split.
      { unfold no_reentrance; cbn.
        apply list_disjoint_singletons.
        rewrite list_cons_app in WF.
        intros abs; symmetry in abs.
        eapply wf_ocfg_bid_distinct_labels in WF; eauto.
        cbn; auto.
        cbn; right.
        rewrite map_app.
        apply ListUtil.in_appl; auto.
      }
      apply no_reentrance_app_r; split.
      {
        red; cbn.
        rewrite convert_typ_outputs.
        apply list_disjoint_singleton_right.
        auto.
      }
      { red; cbn.
        clear - WF NIN FREE_NEXT IN_ENTRY.
        apply list_disjoint_singleton_right.
        cbn.
        intros [-> | [-> | []]].
        - apply wf_ocfg_bid_cons_not_in in WF; eapply WF; left; auto.
        - eapply FREE_NEXT; left; auto.
      }

    + cbn.
      rewrite list_cons_app in WF.
      eapply (wf_ocfg_bid_find_None_app_l _ _ b0) in WF.
      * unfold find_block in *; cbn in *.
        destruct (Eqv.eqv_dec_p entry_id b0) as [EQ | INEQ]; [inv WF | auto].
      * apply wf_ocfg_bid_app_r in WF.
        solve_find_block.
    + match goal with
        |- no_reentrance _ (cons ?x ?y) => rewrite (list_cons_app x y)
      end.
      apply no_reentrance_app_r; split.
      { unfold no_reentrance; cbn.
        apply list_disjoint_singletons.
        rewrite list_cons_app in WF.
        intros abs; symmetry in abs.
        eapply wf_ocfg_bid_distinct_labels in WF; eauto.
        cbn; auto.
        cbn; right.
        rewrite map_app.
        apply ListUtil.in_appl; auto.
      }
      apply no_reentrance_app_r; split.
      {
        red; cbn.
        rewrite convert_typ_outputs.
        apply list_disjoint_singleton_right.
        auto.
      }
      { red; cbn.
        clear - WF NIN FREE_NEXT IN_ENTRY.
        apply list_disjoint_singleton_right.
        cbn.
        intros [-> | [-> | []]].
        - apply wf_ocfg_bid_cons_not_in in WF; eapply WF; left; auto.
        - eapply FREE_NEXT; left; auto.
      }
  - (* We don't enter the loop *)
    rewrite !typ_to_dtyp_equation in FREE_NEXT.
    cbn in *.
    vjmp_out.
    vjmp_out.
    reflexivity.
  - split.
    + eauto.
    +
      unfold free_in_cfg in *.
      cbn. cbn in FREE_NEXT.
      rewrite map_app. rewrite map_app in FREE_NEXT.
      rewrite blk_id_map_convert_typ in FREE_NEXT.      
      cbn. cbn in FREE_NEXT.
      eassumption.
Qed.

Opaque genWhileLoop.
