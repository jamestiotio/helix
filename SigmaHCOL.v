(* Coq defintions for Sigma-HCOL operator language *)

Require Import Spiral.

Require Import Arith.
Require Import Coq.Arith.Peano_dec.
Require Import ArithRing.

Require Import Program. (* compose *)
Require Import Morphisms.
Require Import RelationClasses.
Require Import Relations.

Require Import CpdtTactics.
Require Import CaseNaming.
Require Import Coq.Logic.FunctionalExtensionality.

(* CoRN MathClasses *)
Require Import MathClasses.interfaces.abstract_algebra.
Require Import MathClasses.orders.minmax MathClasses.interfaces.orders.
Require Import MathClasses.theory.rings.
Require Import MathClasses.interfaces.naturals.


(*  CoLoR *)
Require Import CoLoR.Util.Vector.VecUtil.
Import VectorNotations.

Open Scope vector_scope.

(* === Sigma HCOL Operators === *)

Module SigmaHCOLOperators.

  (* zero - based, (stride-1) parameter *)
  Program Fixpoint GathH_0 {A} {t:nat} (n s:nat) : vector A ((n*(S s)+t)) -> vector A n :=
    let stride := S s in (
      match n return vector A ((n*stride)+t) -> vector A n with
        | 0 => fun _ => Vnil
        | S p => fun a => Vcons (hd a) (GathH_0 p s (t0:=t) (drop_plus stride a))
      end).
  Next Obligation.
    ring.
  Defined.

  Program Definition GathH {A: Type} (n base stride: nat) {s t} {snz: stride≡S s} (v: vector A (base+n*stride+t)) : vector A n :=
    GathH_0 n s (t0:=t) (drop_plus base v).
  Next Obligation.
    ring.
  Defined.

  Section ScatHUnion_workaround.
    (* 0 - based, pad=(stride-1) parameter *)
    
    Definition f1 (pad n:nat) : n ≡ O -> vector nat 0 -> vector nat ((S pad)*n).
    Proof.
      Unset Printing Notations.
      intros. subst.
      rewrite mult_0_r.
      auto.
    Qed.
    
    Definition f2 (pad n n':nat) : n = S n' -> t nat (S pad + (S pad * n')) -> t nat ((S pad)*n).
                                     intros H H0. replace (S pad + S pad * n') with (S pad * S n') in H0 by ring.
                                     subst; auto.
    Qed.
    
    Program Fixpoint ScatHUnion_0 {A} {n:nat} (pad:nat): vector A n -> vector (option A) ((S pad)*n) :=
      match n return (vector A n) -> (vector (option A) ((S pad)*n)) with
      | 0 => fun _ => Vnil
      | S p => fun a => Vcons (Some (hd a)) (Vector.append (Vconst None pad) (ScatHUnion_0 pad (tl a)))
      end.  
    Next Obligation.
    ring.
    Defined.
  End ScatHUnion_workaround.

  Definition ScatHUnion {A} {n:nat} (base:nat) (pad:nat) (v:vector A n): vector (option A) (base+((S pad)*n)) :=
    Vector.append (Vconst None base) (ScatHUnion_0 pad v).
  
(*
Motivating example:

BinOp(2, Lambda([ r4, r5 ], sub(r4, r5)))

-->

ISumUnion(i3, 2,
  ScatHUnion(2, 1, i3, 1) o
  BinOp(1, Lambda([ r4, r5 ], sub(r4, r5))) o
  GathH(4, 2, i3, 2)
)

*)  


End SigmaHCOLOperators.
Import HCOLOperators.

Inductive SHOperator : nat -> nat -> Type :=
  | ScatHUnion {n} base pad 
  | HOPrepend i {n} (a:vector A n): HOperator i (n+i)
  | HOInfinityNorm {i}: HOperator i 1

  
Close Scope vector_scope.
