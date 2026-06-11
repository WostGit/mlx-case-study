import PACXAI.Core

namespace PACXAI
namespace InfoTheory

/-- Sum a natural-number statistic over a finite support list. -/
def sumBy {A : Type} (f : A -> Nat) : List A -> Nat
  | [] => 0
  | x :: xs => f x + sumBy f xs

/-- A finite distribution represented by natural weights over an explicit support. -/
structure FiniteDist (A : Type) where
  support : List A
  mass : A -> Nat

/-- Total mass of a finite natural-weight distribution. -/
def totalMass {A : Type} (p : FiniteDist A) : Nat :=
  sumBy p.mass p.support

/-- Push a finite distribution through a deterministic map. -/
def mapDist {A B : Type} [BEq B]
    (f : A -> B)
    (p : FiniteDist A) : FiniteDist B where
  support := p.support.map f
  mass := fun b => sumBy (fun a => if f a == b then p.mass a else 0) p.support

/-- A code assigns a natural code length/budget to each outcome. -/
abbrev Code (A : Type) := A -> Nat

/-- Expected code cost, represented as an integer numerator. -/
def expectedCodeCost {A : Type} (p : FiniteDist A) (code : Code A) : Nat :=
  sumBy (fun a => p.mass a * code a) p.support

/-- Relative code cost: finite audit analogue of KL-style excess code length. -/
def relativeCodeCost {A : Type} (p : FiniteDist A) (pCode qCode : Code A) : Nat :=
  sumBy (fun a => p.mass a * (qCode a - pCode a)) p.support

/-- A code transformer for deterministic post-processing. -/
def pullCode {A B : Type} (f : A -> B) (code : Code B) : Code A :=
  fun a => code (f a)

/-- Expected code cost after applying a deterministic map equals the pulled-back cost. -/
theorem expectedCodeCost_pullback {A B : Type}
    (p : FiniteDist A)
    (f : A -> B)
    (code : Code B) :
    sumBy (fun a => p.mass a * pullCode f code a) p.support =
    sumBy (fun a => p.mass a * code (f a)) p.support := by
  rfl

/-- The total mass definition unfolds to a finite support sum. -/
theorem totalMass_unfold {A : Type} (p : FiniteDist A) :
    totalMass p = sumBy p.mass p.support := by
  rfl

end InfoTheory
end PACXAI
