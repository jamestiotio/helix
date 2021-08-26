(* Deep embedding of a subset of SigmaHCOL *)

Require Import Coq.Strings.String.
Require Import Coq.Arith.Compare_dec.

Require Import Helix.Tactics.HelixTactics.
Require Import Helix.HCOL.CarrierType.
Require Import Helix.Util.Misc.

Require Import Helix.MSigmaHCOL.Memory.
Require Import Helix.MSigmaHCOL.MemSetoid.
Require Import Helix.MSigmaHCOL.CType.

Require Import MathClasses.interfaces.abstract_algebra.
Require Import MathClasses.interfaces.canonical_names.
Require Import MathClasses.implementations.peano_naturals.
Require Import MathClasses.misc.decision.

Require Import Helix.DSigmaHCOL.NType.

Global Open Scope nat_scope.

Module Type MDSigmaHCOL (Import CT: CType) (Import NT: NType).

  Include MMemSetoid CT.

  (* Variable on stack (De-Brujn index) *)
  Definition var_id := nat.

  Inductive DSHType :=
  | DSHnat : DSHType
  | DSHCType : DSHType
  (* pointer to memory block of size [n] *)
  | DSHPtr (n:NT.t) : DSHType.

  Inductive DSHVal :=
  | DSHnatVal (n:NT.t): DSHVal
  | DSHCTypeVal (a:CT.t): DSHVal
  | DSHPtrVal (a:nat) (size:NT.t): DSHVal.

  (* Expressions which evaluate to `NT.t` *)
  Inductive NExpr : Type :=
  | NVar  : var_id -> NExpr
  | NConst: NT.t -> NExpr
  | NDiv  : NExpr -> NExpr -> NExpr
  | NMod  : NExpr -> NExpr -> NExpr
  | NPlus : NExpr -> NExpr -> NExpr
  | NMinus: NExpr -> NExpr -> NExpr
  | NMult : NExpr -> NExpr -> NExpr
  | NMin  : NExpr -> NExpr -> NExpr
  | NMax  : NExpr -> NExpr -> NExpr.

  (* Expressions which evaluate to [mem_block]  *)
  Inductive PExpr: Type :=
  | PVar:  var_id -> PExpr
  (*  | PConst:  constant memory addresses are not implemneted *)
  .

  (* Expressions which evaluate to [mem_block] *)
  Inductive MExpr: Type :=
  | MPtrDeref:  PExpr -> MExpr (* Dereference operator *)
  | MConst: mem_block -> NT.t -> MExpr. (* constant block with size *)

  (* Expressions which evaluate to `CType` *)
  Inductive AExpr : Type :=
  | AVar  : var_id -> AExpr
  | AConst: CT.t -> AExpr
  | ANth  : MExpr -> NExpr -> AExpr
  | AAbs  : AExpr -> AExpr
  | APlus : AExpr -> AExpr -> AExpr
  | AMinus: AExpr -> AExpr -> AExpr
  | AMult : AExpr -> AExpr -> AExpr
  | AMin  : AExpr -> AExpr -> AExpr
  | AMax  : AExpr -> AExpr -> AExpr
  | AZless: AExpr -> AExpr -> AExpr.


  (* Memory variable along with offset *)
  Definition MemRef: Type := (PExpr * NExpr).

  Inductive DSHOperator :=
  | DSHNop (* no-op. *)
  | DSHAssign (src dst: MemRef) (* formerly [Pick] and [Embed] *)
  | DSHIMap (n: nat) (x_p y_p: PExpr) (f: AExpr) (* formerly [Pointwise] *)
  | DSHBinOp (n: nat) (x_p y_p: PExpr) (f: AExpr) (* formerly [BinOp] *)
  | DSHMemMap2 (n: nat) (x0_p x1_p y_p: PExpr) (f: AExpr) (* No direct correspondance in SHCOL *)
  | DSHPower (n:NExpr) (src dst: MemRef) (f: AExpr) (initial: CT.t) (* formely [Inductor] *)
  | DSHLoop (n:nat) (body: DSHOperator) (* Formerly [IUnion] *)
  | DSHAlloc (size:NT.t) (body: DSHOperator) (* allocates new uninitialized memory block and puts pointer to it on stack. The new block will be visible in the scope of [body] *)
  | DSHMemInit (y_p: PExpr) (value: CT.t) (* Initialize memory block with given value *)
  | DSHSeq (f g: DSHOperator) (* execute [g] after [f] *)
  .

  Definition DSHType_of_DSHVal (v:DSHVal) :=
    match v with
    | DSHnatVal _ => DSHnat
    | DSHCTypeVal _ => DSHCType
    | DSHPtrVal _ size => DSHPtr size
    end.

  (* Some Setoid stuff below *)

  Inductive DSHType_equiv: Equiv DSHType :=
  | DSHnat_equiv: DSHType_equiv DSHnat DSHnat
  | DSHCType_equiv: DSHType_equiv DSHCType DSHCType
  | DSHPtr_equiv {s0 s1:NT.t}: s0 = s1 -> DSHType_equiv (DSHPtr s0) (DSHPtr s1).

  Existing Instance DSHType_equiv.

  Instance DSHType_equiv_Decision (a b:DSHType):
    Decision (equiv a b).
  Proof.
    simpl_relation.
    destruct a,b.
    1,5: left;constructor.
    7:{
      destruct (NTypeEqDec n n0).
      left;constructor;assumption.
      right; intros H; inv H; congruence.
    }
    all: right; intros H; inversion H.
  Qed.

  Inductive DSHVal_equiv: Equiv DSHVal :=
  | DSHnatVal_equiv {n0 n1:NT.t}: n0=n1 -> DSHVal_equiv (DSHnatVal n0) (DSHnatVal n1)
  | DSHCTypeVal_equiv {a b: CT.t}: a=b -> DSHVal_equiv (DSHCTypeVal a) (DSHCTypeVal b)
  | DSHPtrVal_equiv {p0 p1: nat} {s0 s1:NT.t}: s0 = s1 /\ p0=p1 -> DSHVal_equiv (DSHPtrVal p0 s0) (DSHPtrVal p1 s1).

  Existing Instance DSHVal_equiv.

  Instance DSHVar_Equivalence:
    Equivalence DSHVal_equiv.
  Proof.
    split.
    -
      intros x.
      destruct x; constructor; auto.
    -
      intros x y E.
      inversion E; constructor; try split; symmetry; apply H.
    -
      intros x y z Exy Eyz.
      inversion Exy; inversion Eyz; subst y; try inversion H3.
      +
        constructor.
        rewrite H.
        rewrite <- H5.
        apply H2.
      +
        constructor.
        rewrite <- H2.
        rewrite H5.
        apply H.
      +
        subst.
        constructor.
        destruct H as [Hs Hp].
        destruct H2 as [H2s H2p].
        split.
        * rewrite Hs; auto.
        * rewrite Hp; auto.
  Qed.

  Instance DSHVar_Setoid:
    @Setoid DSHVal DSHVal_equiv.
  Proof.
    apply DSHVar_Equivalence.
  Qed.

  Inductive NExpr_equiv: NExpr -> NExpr -> Prop :=
  | NVar_equiv  {n1 n2}: n1=n2 -> NExpr_equiv (NVar n1)  (NVar n2)
  | NConst_equiv {a b}: a=b -> NExpr_equiv (NConst a) (NConst b)
  | NDiv_equiv  {a a' b b'}: NExpr_equiv a a' -> NExpr_equiv b b' -> NExpr_equiv (NDiv a b)   (NDiv a' b')
  | NMod_equiv  {a a' b b'}: NExpr_equiv a a' -> NExpr_equiv b b' -> NExpr_equiv (NMod a b)   (NMod a' b')
  | NPlus_equiv {a a' b b'}: NExpr_equiv a a' -> NExpr_equiv b b' -> NExpr_equiv (NPlus a b)  (NPlus a' b')
  | NMinus_equiv {a a' b b'}: NExpr_equiv a a' -> NExpr_equiv b b' -> NExpr_equiv (NMinus a b) (NMinus a' b')
  | NMult_equiv {a a' b b'}: NExpr_equiv a a' -> NExpr_equiv b b' -> NExpr_equiv (NMult a b)  (NMult a' b')
  | NMin_equiv  {a a' b b'}: NExpr_equiv a a' -> NExpr_equiv b b' -> NExpr_equiv (NMin a b)   (NMin a' b')
  | NMax_equiv  {a a' b b'}: NExpr_equiv a a' -> NExpr_equiv b b' -> NExpr_equiv (NMax a b)   (NMax a' b').

  Instance NExpr_Equiv: Equiv NExpr  := NExpr_equiv.

  Instance NExpr_Equivalence:
    Equivalence NExpr_equiv.
  Proof.
    split.
    -
      intros x.
      induction x; constructor; auto.
    -
      intros x y E.
      induction E; constructor; try symmetry; assumption.
    -

      intros x y z.
      dependent induction x;
        dependent induction y;
        dependent induction z; intros Exy Eyz; try inversion Exy; try inversion Eyz; subst.
      + constructor; auto.
      + constructor; auto.
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
  Qed.

  Inductive PExpr_equiv : PExpr -> PExpr -> Prop :=
  | PVar_equiv {n0 n1}: n0=n1 -> PExpr_equiv (PVar n0) (PVar n1).

  Instance PExpr_Equiv: Equiv PExpr := PExpr_equiv.

  Instance PExpr_Equivalence:
    Equivalence PExpr_equiv.
  Proof.
    split.
    -
      intros x.
      induction x; constructor; auto.
    -
      intros x y E.
      induction E; constructor; try symmetry; assumption.
    -
      intros x y z Exy Eyz.
      induction Exy; inversion Eyz; subst;
        constructor; auto.
  Qed.

  Inductive MExpr_equiv : MExpr -> MExpr -> Prop :=
  | MPtrDeref_equiv {p0 p1}: p0=p1 -> MExpr_equiv (MPtrDeref p0) (MPtrDeref p1)
  | MConst_equiv {a b: mem_block} (asize bsize:NT.t) : (a=b /\ asize=bsize) -> MExpr_equiv (MConst a asize) (MConst b bsize).

  Instance MExpr_Equiv: Equiv MExpr := MExpr_equiv.

  Instance MExpr_Equivalence:
    Equivalence MExpr_equiv.
  Proof.
    split.
    -
      intros x.
      induction x; constructor; auto.
    -
      intros x y E.
      induction E.
      +
        constructor.
        symmetry.
        assumption.
      +
        constructor.
        destruct H.
        split;try symmetry; auto.
    -
      intros x y z Exy Eyz.

      induction Exy; inversion Eyz; subst.
      +
        destruct H1.
        constructor.
        rewrite <- H0.
        auto.
      +
        destruct H3.
        constructor.
        rewrite <- H0, <- H1.
        auto.
  Qed.


  Inductive AExpr_equiv: AExpr -> AExpr -> Prop :=
  | AVar_equiv  {n0 n1}: n0=n1 -> AExpr_equiv (AVar n0) (AVar n1)
  | AConst_equiv {a b}: a=b -> AExpr_equiv (AConst a) (AConst b)
  | ANth_equiv {v1 v2:MExpr} {n1 n2:NExpr} :
      NExpr_equiv n1 n2 ->
      MExpr_equiv v1 v2 ->
      AExpr_equiv (ANth v1 n1)  (ANth v2 n2)
  | AAbs_equiv  {a b}: AExpr_equiv a b -> AExpr_equiv (AAbs a)  (AAbs b)
  | APlus_equiv {a a' b b'}: AExpr_equiv a a' -> AExpr_equiv b b' -> AExpr_equiv (APlus a b) (APlus a' b')
  | AMinus_equiv{a a' b b'}: AExpr_equiv a a' -> AExpr_equiv b b' -> AExpr_equiv (AMinus a b) (AMinus a' b')
  | AMult_equiv {a a' b b'}: AExpr_equiv a a' -> AExpr_equiv b b' -> AExpr_equiv (AMult a b) ( AMult a' b')
  | AMin_equiv  {a a' b b'}: AExpr_equiv a a' -> AExpr_equiv b b' -> AExpr_equiv (AMin a b) (  AMin a' b')
  | AMax_equiv  {a a' b b'}: AExpr_equiv a a' -> AExpr_equiv b b' -> AExpr_equiv (AMax a b) (  AMax a' b')
  | AZless_equiv {a a' b b'}: AExpr_equiv a a' -> AExpr_equiv b b' -> AExpr_equiv (AZless a b) (AZless a' b').


  Instance AExpr_Equiv: Equiv AExpr := AExpr_equiv.

  Instance AExpr_Equivalence:
    Equivalence AExpr_equiv.
  Proof.
    split.
    -
      intros x.
      induction x; constructor; auto; reflexivity.
    -
      intros x y.
      dependent induction x; dependent induction y; intros E; try inversion E; subst.
      + constructor; auto.
      + constructor; auto.
      + constructor.
        * symmetry; auto.
        *
          inversion E.
          inv_exitstT.
          subst.
          symmetry.
          auto.
      + constructor; apply IHx; auto.
      + constructor;[ apply IHx1; auto | apply IHx2; auto].
      + constructor;[ apply IHx1; auto | apply IHx2; auto].
      + constructor;[ apply IHx1; auto | apply IHx2; auto].
      + constructor;[ apply IHx1; auto | apply IHx2; auto].
      + constructor;[ apply IHx1; auto | apply IHx2; auto].
      + constructor;[ apply IHx1; auto | apply IHx2; auto].
    -
      intros x y z.
      dependent induction x;
        dependent induction y;
        dependent induction z; intros Exy Eyz; try inversion Exy; try inversion Eyz; subst.
      + constructor; auto.
      + constructor; auto.
      +
        inversion Exy. inversion Eyz.
        inv_exitstT; subst.
        constructor.
        apply transitivity with (y:=n0); auto.
        eapply transitivity with (y:=m0); auto.
      + constructor; apply IHx with (y:=y); auto.
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
      + constructor; [apply IHx1 with (y:=y1); auto | apply IHx2 with (y:=y2); auto].
  Qed.

  Inductive DSHOperator_equiv: relation DSHOperator :=
  | heq_DSHNop: DSHOperator_equiv DSHNop DSHNop
  | heq_DSHAssign:
      forall src_p src_n dst_p dst_n src_p' src_n' dst_p' dst_n',
        src_n = src_n' ->
        dst_n = dst_n' ->
        src_p = src_p' ->
        dst_p = dst_p' ->
        DSHOperator_equiv (DSHAssign (src_p,src_n) (dst_p, dst_n))
                          (DSHAssign (src_p',src_n') (dst_p', dst_n'))
  | heq_DSHIMap:
      forall n x_p y_p f n' x_p' y_p' f',
        n=n' ->
        x_p = x_p' ->
        y_p = y_p' ->
        f = f' ->
        DSHOperator_equiv (DSHIMap n x_p y_p f) (DSHIMap n' x_p' y_p' f')

  | heq_DSHBinOp:
      forall n x_p y_p f n' x_p' y_p' f',
        n=n' ->
        x_p = x_p' ->
        y_p = y_p' ->
        f = f' ->
        DSHOperator_equiv (DSHBinOp n x_p y_p f) (DSHBinOp n' x_p' y_p' f')
  | heq_DSHMemMap2:
      forall n x0_p x1_p y_p f n' x0_p' x1_p' y_p' f',
        n=n' ->
        x0_p = x0_p' ->
        x1_p = x1_p' ->
        y_p = y_p' ->
        f = f' ->
        DSHOperator_equiv (DSHMemMap2 n x0_p x1_p y_p f) (DSHMemMap2 n' x0_p' x1_p' y_p' f')
  | heq_DSHPower:
      forall n src_p src_n dst_p dst_n f ini n' src_p' src_n' dst_p' dst_n' f' ini',
        n = n' ->
        src_n = src_n' ->
        dst_n = dst_n' ->
        src_p = src_p' ->
        dst_p = dst_p' ->
        f = f' ->
        ini = ini' ->
        DSHOperator_equiv
          (DSHPower n (src_p,src_n) (dst_p, dst_n) f ini)
          (DSHPower n' (src_p',src_n') (dst_p', dst_n') f' ini')
  | heq_DSHLoop:
      forall n n' body body',
        n=n' ->
        DSHOperator_equiv body body' ->
        DSHOperator_equiv (DSHLoop n body) (DSHLoop n' body')
  | heq_DSHAlloc:
      forall n n' body body',
        n = n' ->
        DSHOperator_equiv body body' ->
        DSHOperator_equiv (DSHAlloc n body) (DSHAlloc n' body')
  | heq_DSHMemInit:
      forall p p' v v',
        p = p' ->
        v = v' ->
        DSHOperator_equiv (DSHMemInit p v) (DSHMemInit p' v')
  | heq_DSHSeq:
      forall f f' g g',
        DSHOperator_equiv f f' ->
        DSHOperator_equiv g g' ->
        DSHOperator_equiv (DSHSeq f g) (DSHSeq f' g').


  Instance DSHOperator_Equiv: Equiv DSHOperator  := DSHOperator_equiv.

  Definition incrPVar (skip:nat) (p: PExpr): PExpr :=
    match p with
    | PVar var_id =>
      PVar (if le_dec skip var_id then (S var_id) else var_id)
    end.

  Definition incrMVar (skip:nat) (m: MExpr): MExpr :=
    match m with
    | MPtrDeref p => MPtrDeref (incrPVar skip p)
    | _ => m
    end.

  Fixpoint incrNVar (skip:nat) (p: NExpr): NExpr :=
    match p with
    | NVar var_id => NVar (if le_dec skip var_id then (S var_id) else var_id)
    | NConst _ => p
    | NDiv  a b => NDiv (incrNVar skip a) (incrNVar skip b)
    | NMod  a b => NMod (incrNVar skip a) (incrNVar skip b)
    | NPlus a b => NPlus (incrNVar skip a) (incrNVar skip b)
    | NMinus a b => NMinus (incrNVar skip a) (incrNVar skip b)
    | NMult a b => NMult (incrNVar skip a) (incrNVar skip b)
    | NMin  a b => NMin (incrNVar skip a) (incrNVar skip b)
    | NMax  a b => NMax (incrNVar skip a) (incrNVar skip b)
    end.

  Fixpoint incrAVar (skip:nat) (p: AExpr) : AExpr :=
    match p with
    | AVar var_id => AVar (if le_dec skip var_id then (S var_id) else var_id)
    | AConst _ => p
    | ANth m n =>  ANth (incrMVar skip m) (incrNVar skip n)
    | AAbs a => AAbs (incrAVar skip a)
    | APlus  a b => APlus (incrAVar skip a) (incrAVar skip b)
    | AMinus a b => AMinus (incrAVar skip a) (incrAVar skip b)
    | AMult  a b => AMult (incrAVar skip a) (incrAVar skip b)
    | AMin   a b => AMin (incrAVar skip a) (incrAVar skip b)
    | AMax   a b => AMax (incrAVar skip a) (incrAVar skip b)
    | AZless a b => AZless (incrAVar skip a) (incrAVar skip b)
    end.

  Definition incrDSHIUnCType (skip:nat) := incrAVar (skip + 2).
  Definition incrDSHIBinCType (skip:nat) := incrAVar (skip + 3).
  Definition incrDSHBinCType (skip:nat) := incrAVar (skip + 2).

  Fixpoint incrOp (skip:nat) (d:DSHOperator) : DSHOperator
    := match d with
       | DSHNop => DSHNop
       | DSHAssign (src_p,src_o) (dst_p,dst_o) => DSHAssign (incrPVar skip src_p, incrNVar skip src_o) (incrPVar skip dst_p, incrNVar skip dst_o)
       | DSHIMap n x_p y_p f => DSHIMap n (incrPVar skip x_p) (incrPVar skip y_p) (incrDSHIUnCType skip f)
       | DSHBinOp n x_p y_p f => DSHBinOp n (incrPVar skip x_p) (incrPVar skip y_p) (incrDSHIBinCType skip f)
       | DSHMemMap2 n x0_p x1_p y_p f => DSHMemMap2 n (incrPVar skip x0_p) (incrPVar skip x1_p) (incrPVar skip y_p) (incrDSHBinCType skip f)
       | DSHPower n (src_p,src_o) (dst_p,dst_o) f initial =>
         DSHPower (incrNVar skip n) (incrPVar skip src_p, incrNVar skip src_o) (incrPVar skip dst_p, incrNVar skip dst_o) (incrDSHBinCType skip f) initial
       | DSHLoop n body => DSHLoop n (incrOp (S skip) body)
       | DSHAlloc size body => DSHAlloc size (incrOp (S skip) body)
       | DSHMemInit y_p value => DSHMemInit (incrPVar skip y_p) value
       | DSHSeq f g => DSHSeq (incrOp skip f) (incrOp skip g)
       end.

  Section Printing.

    (* List of keys of elements in memblock as string.
       E.g. "{1,2,5}"
     *)
    Definition string_of_mem_block_keys (m:mem_block) : string
      :=
        "{"++(concat "," (List.map string_of_nat (mem_keys_lst m)))++"}".

    Definition string_of_PExpr (p:PExpr) : string :=
      match p with
      | PVar x => "(PVar " ++ string_of_nat x ++ ")"
      end.

    (* TODO: Implement *)
    Definition string_of_NExpr (n:NExpr) : string :=
      match n with
      | NVar x => "(NVar " ++ string_of_nat x ++ ")"
      | NConst x => NT.to_string x
      | _ => "?"
      end.

    Definition string_of_MemRef (m:MemRef) : string :=
      let '(p,n) := m in
      "(" ++ string_of_PExpr p ++ "," ++ string_of_NExpr n ++ ")".

    Definition string_of_DSHOperator (d:DSHOperator) : string :=
      match d with
      | DSHNop => "DSHNop"
      | DSHAssign src dst =>
        "DSHAssign " ++
                     string_of_MemRef src ++ " " ++
                     string_of_MemRef dst ++ " "
      | DSHIMap n x_p y_p f =>
        "DSHIMap " ++
                   string_of_nat n ++ " " ++
                   string_of_PExpr x_p ++ " " ++
                   string_of_PExpr y_p ++ " ..."
      | DSHBinOp n x_p y_p f =>
        "DSHBinOp " ++
                    string_of_nat n ++ " " ++
                    string_of_PExpr x_p ++ " " ++
                    string_of_PExpr y_p ++ " ..."
      | DSHMemMap2 n x0_p x1_p y_p f =>
        "DSHMemMap2 " ++
                      string_of_nat n ++ " " ++
                      string_of_PExpr x0_p ++ " " ++
                      string_of_PExpr x1_p ++ " " ++
                      string_of_PExpr y_p ++ " ..."
      | DSHPower n src dst f initial =>
        "DSHPower " ++
                    string_of_NExpr n ++ " " ++
                    string_of_MemRef src ++ " " ++
                    string_of_MemRef dst ++ "..."
      | DSHLoop n body =>
        "DSHLoop " ++
                   string_of_nat n ++ " "
      | DSHAlloc size body =>
        "DSHAlloc " ++
                    NT.to_string size
      | DSHMemInit y_p value =>
        "DSHMemInit " ++
                      string_of_PExpr y_p ++ " ..."
      | DSHSeq f g => "DSHSeq"
      end.

  End Printing.

  Module DSHNotation.

    Notation "A ; B" := (DSHSeq A B) (at level 99, right associativity, only printing).
    Notation "A * B" := (AMult A B) (only printing).
    Notation "A - B" := (AMinus A B) (only printing).
    Notation "A + B" := (APlus A B) (only printing).
    Notation "A * B" := (NMult A B) (only printing).
    Notation "A - B" := (NMinus A B) (only printing).
    Notation "A + B" := (NPlus A B) (only printing).
    Notation "A %'N'" := (NConst A) (at level 99, only printing,
                                     format "A %'N'").

  End DSHNotation.

End MDSigmaHCOL.
