Require Import Coq.Logic.FunctionalExtensionality.
Require Import Coq.Program.Basics.
Require Import Coq.Init.Specif.
Require Import Coq.ZArith.ZArith.
Local Open Scope program_scope.
Local Open Scope Z_scope.

(* Integer functoins used in this example:
       Z.sqrt - square root. For negative values returns 0.
       Z.abs - absolute value.
       Z.sgn - sign (returns -1|0|1).
 *)

(* Unrelated simple lemma showing use of function composition, and
pointfree style,proven using function extensionality. SPIRAL ideally
should be written like that. *)
Lemma abs_sgn_comm: (Z.abs ∘ Z.sgn) = (Z.sgn ∘ Z.abs).
Proof.
  apply functional_extensionality.
  intros.
  unfold compose.
  destruct x; auto.
Qed.

(* -- Some helpful facts about zabs, used int this example -- *)
Section ZAbs_facts.

  Fact zabs_always_nneg: forall x, (Z.abs x) >= 0.
  Proof.
    intros.
    unfold Z.abs.
    destruct x.
    - omega.
    - induction p;auto;omega.
    - induction p;auto;omega.
  Qed.

  Fact zabs_nneg: forall x, x>=0 -> Z.abs x = x.
  Proof.
    intros.
    destruct x.
    - auto.
    - auto.
    - assert(Z.neg p < 0) by apply Pos2Z.neg_is_neg.
      omega.
  Qed.

End ZAbs_facts.


(* -- Naive approach. No preconditions on sqrt. --
PROS:
  * can use composition notation
  * can define experessions before reasoning about them.
CONS:
  * not pointfree
  * allows to construct incorrect expresions. E.g. 'bar' below.
  * does not allow to express post-conditions
  *)
Section Naive.

  (* example of incorrect expression *)
  Definition bar := Z.sqrt (-1234).

  (* We can use composition, but not pointfree because of constraint x>=0 *)
  Lemma foo (x:Z) (xp:x>=0):
    (Z.sqrt ∘ Z.abs) x = Z.sqrt x.
  Proof.
    unfold compose.
    rewrite zabs_nneg.
    - reflexivity.
    - apply xp.
  Qed.

End Naive.


(* -- Pre-conditoins approach. Simple precondition on sqrt. --
PROS:
  * does not allow to construct incorrect expresions.
  * all preconditions are clearly spelled and have to be proven manually before constructing the expression. No automatic proof search.
CONS:
  * can not easily compose experessions before reasoning about them.
  * can not use composition notation
  * not pointfree
  * does not allow to express post-conditions
  *)
Section PreCondition.

  (* Version of sqrt with pre-condition *)
  Definition zsqrt_p (x:Z) {ac:x>=0} := Z.sqrt x.

  (* Fails: Cannot infer the implicit parameter ac of zsqrt_p whose type is  "-1234 >= 0". Since it is unporovable, this experession could not be constructed.
   *)
  Fail Definition bar := zsqrt_p (-1234).

  (* This is lemma about composition of 'zsqrt_p' and 'Z.abs'. Unfortunately we could not write this in pointfree style using functoin composition *)
  Lemma foo_p (x:Z) (xp:x>=0):
    @zsqrt_p (Z.abs x) (zabs_always_nneg x) = @zsqrt_p x xp.
  Proof.
    unfold zsqrt_p.
    rewrite zabs_nneg.
    - reflexivity.
    - apply xp.
  Qed.

End PreCondition.

(* -- Spec approach. Using specifications to refine types of arguments of sqrt as well as return value of abs --
PROS:
  * allows to use composition
  * pointfree
  * values along with their properties are nicely bundled using `sig` or {|}.
  * does not allow to construct incorrect expresions.
  * all preconditions are clearly spelled out. Constructing correct expression is just a matter of correctly matching parameter and return types of expressions.
CONS:
  * requires a bit of syntactic sugar here and there (e.g. use of `proj1_sig_ge0` in 'foo_s'.
  * predicates in spec must match exactly. For example if we have value {a|a>0} we could not directly use it instead of {a|a>=0}.
  * there is no logical inference performed on specs. Not even simple structural rules application https://en.wikipedia.org/wiki/Structural_rule. For example {a|(P1 a)/\(P2 a)} could not be used in place of {a|(P2 a)/\(P1 a)} or {a|P1 a}
  * Return values could contain only one spec. Multiple post-conditions have to be bundled together.
  *)
Section Specs.

  (* "Refined" with specifications versions of sqrt and abs *)
  Definition zsqrt_s (a:{x:Z|x>=0}) := Z.sqrt (proj1_sig a).
  Definition zabs_s: Z -> {x:Z|x>=0} :=
    fun a => exist _ (Z.abs a) (zabs_always_nneg a).

  (* Fails: Cannot infer this placeholder of type "(fun x : Z => x >= 0) (-1234)". *)
  Fail Definition bar := zsqrt_s (exist _ (-1234) _).

  (* Helper syntactic sugar to make sure projection types are properly guessed *)
  Definition proj1_sig_ge0 (a:{x:Z|x>=0}): Z := proj1_sig a.

  (* Using specifications we can use pointfree style, but we have to add as projection function as zabs_s takes a value without any specification *)
  Lemma foo_s:
    zsqrt_s ∘ zabs_s ∘ proj1_sig_ge0  = @zsqrt_s.
  Proof.
    apply functional_extensionality.
    intros a.
    unfold compose, proj1_sig_ge0, zsqrt_s, zabs_s.
    simpl.
    rewrite zabs_nneg.
    - reflexivity.
    - apply (proj2_sig a).
  Qed.

End Specs.

(* -- Typelcass approach. Using type classes to refine types of arguments of sqrt --
PROS:
  * properies are hidden and in some cases could be resolved implicitly.
  * does not allow to construct incorrect expresions.
  * One have to ballance between specifying type class instances explicitly or let them implicit and letting typeclass resolution to resolve them automatically.
  * Multiple post-conditions can be specified using multiple type class instances.
CONS:
  * does not allow to use composition
  * not pointfree
  * Automatic type class resolution sometimes difficult to debug. It is not very transparent and difficult to guide it in right direction.
  * It is difficult to construct even correct impression. The burden of proofs imposed by pre-conditions is a significant barrier.
  *)
Section Typeclasses.

  (* Type class denoting nonnegative numbers *)
  Class NnegZ (val:Z) := nneg: val>=0.

  (* Argument of sqrt is constrained by typeclass NnegZ *)
  Definition zsqrt_t (a:Z) `{NnegZ a} : Z := Z.sqrt a.

  (* Fails:
         Unable to satisfy the following constraints:
         ?H : "NnegZ (-1234)"
   *)
  Fail Definition bar := zsqrt_t (-1234).

  (* NnegZ class instance for Z.abs, stating that Z.abs always positive *)
  Local Instance Zabs_nnegZ:
    forall x, NnegZ (Z.abs x).
  Proof.
    intros.
    unfold NnegZ.
    apply zabs_always_nneg.
  Qed.

  Lemma foo_t (x:Z) `{PZ:NnegZ x}:
    zsqrt_t (Z.abs x) = zsqrt_t x.
  Proof.
    unfold compose, zsqrt_t.
    rewrite zabs_nneg.
    - reflexivity.
    - apply PZ.
  Qed.

End Typeclasses.

Section ImplicitTypeclasses.

  (* Type class denoting nonnegative numbers *)
  Class NnegZ_x (val:Z) := nneg_x: val>=0.

  (* Argument of sqrt is constrained by typeclass NnegZ *)
  Definition zsqrt_x (a:Z) `{NN: NnegZ_x a} : Z := Z.sqrt a.

  (* Fails:
         Unable to satisfy the following constraints:
         ?H : "NnegZ (-1234)"
   *)
  Fail Definition bar := zsqrt_x (-1234).

  Lemma foo1_t:
    exists PA, forall (x:Z) `{PZ:NnegZ_x x}, @zsqrt_x (Z.abs x) (PA x) = @zsqrt_x x PZ.
  Proof.
    unshelve eexists.
    -
      unfold NnegZ.
      apply zabs_always_nneg.
    -
      intros x PZ.
      unfold zsqrt_x.
      rewrite zabs_nneg.
      + reflexivity.
      + apply PZ.
  Qed.

End ImplicitTypeclasses.