Require Import Helix.LLVMGen.Correctness_Prelude.
Require Import Helix.LLVMGen.VariableBinding.
Require Import Helix.LLVMGen.IdLemmas.
Set Implicit Arguments.
Set Strict Implicit.

Section LidBound.  
  (* Says that a given local id would have been generated by an earlier IRState *)
  Definition lid_bound (s : IRState) (lid: local_id) : Prop
    := state_bound local_count incLocalNamed s lid.

  Definition lid_bound_between (s1 s2 : IRState) (lid : local_id) : Prop
    := state_bound_between local_count incLocalNamed s1 s2 lid.

  Lemma incLocalNamed_count_gen_injective :
    count_gen_injective local_count incLocalNamed.
  Proof.
    unfold count_gen_injective.
    intros s1 s1' s2 s2' name1 name2 id1 id2 GEN1 GEN2 H1 H2 H3.

    inv GEN1.
    inv GEN2.

    intros CONTRA.
    apply Name_inj in CONTRA.
    apply valid_prefix_string_of_nat_forward in CONTRA; auto.
    intuition.
  Qed.

  Lemma incLocalNamed_count_gen_mono :
    count_gen_mono local_count incLocalNamed.
  Proof.
    unfold count_gen_mono.
    intros s1 s2 name id H.

    cbn in H; simp.
    cbn. auto.
  Qed.

  Lemma lid_bound_incLocalNamed :
    forall name s1 s2 id,
      is_correct_prefix name ->
      incLocalNamed name s1 ≡ inr (s2, id) ->
      lid_bound s2 id.
  Proof.
    intros name s1 s2 id NENDS GEN.
    exists name. exists s1. exists s2.
    cbn in GEN; simp.
    repeat split; auto.
  Qed.

  Lemma not_lid_bound_incLocalNamed :
    forall name s1 s2 id,
      is_correct_prefix name ->
      incLocalNamed name s1 ≡ inr (s2, id) ->
      ~ lid_bound s1 id.
  Proof.
    intros name s1 s2 id NENDS GEN.
    eapply not_id_bound_gen_mono; eauto.
    apply incLocalNamed_count_gen_injective.
  Qed.


  Lemma lid_bound_between_incLocalNamed :
    forall name s1 s2 id,
      is_correct_prefix name ->
      incLocalNamed name s1 ≡ inr (s2, id) ->
      lid_bound_between s1 s2 id.
  Proof.
    intros name s1 s2 id NENDS GEN.
    apply state_bound_bound_between.
    - eapply lid_bound_incLocalNamed; eauto.
    - eapply not_lid_bound_incLocalNamed; eauto.
  Qed.

  Lemma not_lid_bound_incLocal :
    forall s1 s2 id,
      incLocal s1 ≡ inr (s2, id) ->
      ~ lid_bound s1 id.
  Proof.
    intros s1 s2 id GEN.
    Transparent incLocal.
    eapply not_lid_bound_incLocalNamed; eauto.
    reflexivity.
    Opaque incLocal.
  Qed.

  Lemma lid_bound_between_incLocal :
    forall s1 s2 id,
      incLocal s1 ≡ inr (s2, id) ->
      lid_bound_between s1 s2 id.
  Proof.
    intros s1 s2 id GEN.
    Transparent incLocal.
    eapply lid_bound_between_incLocalNamed; eauto.
    reflexivity.
    Opaque incLocal.
  Qed.

  Lemma incBlockNamed_local_count:
    forall s s' msg id,
      incBlockNamed msg s ≡ inr (s', id) ->
      local_count s' ≡ local_count s.
  Proof.
    intros; cbn in *; inv_sum; reflexivity.
  Qed.

  Lemma incVoid_local_count:
    forall s s' id,
      incVoid s ≡ inr (s', id) ->
      local_count s' ≡ local_count s.
  Proof.
    intros; cbn in *; inv_sum; reflexivity.
  Qed.

  Lemma incLocal_local_count: forall s s' x,
      incLocal s ≡ inr (s',x) ->
      local_count s' ≡ S (local_count s).
  Proof.
    Transparent incLocal.
    intros; cbn in *; inv_sum; reflexivity.
    Opaque incLocal.
  Qed.

  Lemma incLocalNamed_local_count: forall s s' msg x,
      incLocalNamed msg s ≡ inr (s',x) ->
      local_count s' ≡ S (local_count s).
  Proof.
    intros; cbn in *; inv_sum; reflexivity.
  Qed.

  Lemma lid_bound_incBlockNamed_mono :
    forall name s1 s2 bid bid',
      lid_bound s1 bid ->
      incBlockNamed name s1 ≡ inr (s2, bid') ->
      lid_bound s2 bid.
  Proof.
    intros name s1 s2 bid bid' (lname & s' & s'' & NEND & COUNT1 & COUNT2) INC.
    exists lname. exists s'. exists s''.
    repeat (split; auto).
    erewrite incBlockNamed_local_count with (s':=s2); eauto.
  Qed.

  (* TODO: typeclasses for these mono lemmas to make automation easier? *)
  Lemma lid_bound_incVoid_mono :
    forall s1 s2 bid bid',
      lid_bound s1 bid ->
      incVoid s1 ≡ inr (s2, bid') ->
      lid_bound s2 bid.
  Proof.
    intros s1 s2 bid bid' BOUND INC.
    destruct BOUND as (n1 & s1' & s1'' & N_S1 & COUNT_S1 & GEN_bid).
    unfold lid_bound.
    exists n1. exists s1'. exists s1''.
    intuition.
    apply incVoid_local_count in INC.
    lia.
  Qed.

  Lemma lid_bound_incLocal_mono :
    forall s1 s2 bid bid',
      lid_bound s1 bid ->
      incLocal s1 ≡ inr (s2, bid') ->
      lid_bound s2 bid.
  Proof.
    intros s1 s2 bid bid' BOUND INC.
    destruct BOUND as (n1 & s1' & s1'' & N_S1 & COUNT_S1 & GEN_bid).
    unfold lid_bound.
    exists n1. exists s1'. exists s1''.
    intuition.
    apply incLocal_local_count in INC.
    lia.
  Qed.

  Lemma incLocalNamed_lid_bound :
    forall s1 s2 id name,
      is_correct_prefix name ->
      incLocalNamed name s1 ≡ inr (s2, id) ->
      lid_bound s2 id.
  Proof.
    intros s1 s2 id name CORR INC.
    unfold lid_bound.
    unfold state_bound.
    exists name. exists s1. exists s2.
    split; eauto.
    split; auto.
    pose proof incLocalNamed_local_count INC.
    lia.
  Qed.

  Lemma incLocal_lid_bound :
    forall s1 s2 id,
      incLocal s1 ≡ inr (s2, id) ->
      lid_bound s2 id.
  Proof.
    intros s1 s2 id INC.
    Transparent incLocal.
    unfold incLocal in *.
    eapply incLocalNamed_lid_bound; eauto.
    reflexivity.
    Opaque incLocal.
  Qed.

  (* Lemma lid_bound_genNExpr_mono : *)
  (*   forall s1 s2 bid nexp e c, *)
  (*     lid_bound s1 bid -> *)
  (*     genNExpr nexp s1 ≡ inr (s2, (e, c)) -> *)
  (*     lid_bound s2 bid. *)
  (* Proof. *)
  (*   intros s1 s2 bid nexp e c BOUND GEN. *)
  (*   apply genNExpr_local_count in GEN. *)
  (*   destruct BOUND as (n1 & s1' & s1'' & N_S1 & COUNT_S1 & GEN_bid). *)
  (*   unfold lid_bound. *)
  (*   exists n1. exists s1'. exists s1''. *)
  (*   repeat (split; auto). *)
  (*   rewrite GEN. *)
  (*   auto. *)
  (* Qed. *)

  (* Lemma lid_bound_genMExpr_mono : *)
  (*   forall s1 s2 bid mexp e c, *)
  (*     lid_bound s1 bid -> *)
  (*     genMExpr mexp s1 ≡ inr (s2, (e, c)) -> *)
  (*     lid_bound s2 bid. *)
  (* Proof. *)
  (*   intros s1 s2 bid mexp e c BOUND GEN. *)
  (*   apply genMExpr_local_count in GEN. *)
  (*   destruct BOUND as (n1 & s1' & s1'' & N_S1 & COUNT_S1 & GEN_bid). *)
  (*   unfold lid_bound. *)
  (*   exists n1. exists s1'. exists s1''. *)
  (*   repeat (split; auto). *)
  (*   rewrite GEN. *)
  (*   auto. *)
  (* Qed. *)

  (* Lemma lid_bound_genAExpr_mono : *)
  (*   forall s1 s2 bid aexp e c, *)
  (*     lid_bound s1 bid -> *)
  (*     genAExpr aexp s1 ≡ inr (s2, (e, c)) -> *)
  (*     lid_bound s2 bid. *)
  (* Proof. *)
  (*   intros s1 s2 bid nexp e c BOUND GEN. *)
  (*   apply genAExpr_local_count in GEN. *)
  (*   destruct BOUND as (n1 & s1' & s1'' & N_S1 & COUNT_S1 & GEN_bid). *)
  (*   unfold lid_bound. *)
  (*   exists n1. exists s1'. exists s1''. *)
  (*   repeat (split; auto). *)
  (*   rewrite GEN. *)
  (*   auto. *)
  (* Qed. *)

  (* Lemma lid_bound_genIR_mono : *)
  (*   forall s1 s2 bid op nextblock b bks, *)
  (*     lid_bound s1 bid -> *)
  (*     genIR op nextblock s1 ≡ inr (s2, (b, bks)) -> *)
  (*     lid_bound s2 bid. *)
  (* Proof. *)
  (*   intros s1 s2 bid op nextblock b bks BOUND GEN. *)
  (*   apply genIR_local_count in GEN. *)
  (*   destruct BOUND as (n1 & s1' & s1'' & N_S1 & COUNT_S1 & GEN_bid). *)
  (*   unfold lid_bound. *)
  (*   exists n1. exists s1'. exists s1''. *)
  (*   repeat (split; auto). *)
  (*   lia. *)
  (* Qed. *)

End LidBound.
