import PACXAI.Core

namespace PACXAI
namespace Leakage

/-- Finite output-cover leakage: whether an output appears on the audited population. -/
def appears {Secret Out : Type} [BEq Out]
    (secrets : Population Secret)
    (obs : Observation Secret Out)
    (y : Out) : Bool :=
  secrets.any (fun s => obs s == y)

/-- Count distinct outputs by filtering a supplied finite list of possible outputs. -/
def outputCoverSize {Secret Out : Type} [BEq Out]
    (secrets : Population Secret)
    (obs : Observation Secret Out)
    (outputs : List Out) : Nat :=
  (outputs.filter (appears secrets obs)).length

/-- Cartesian product of two finite lists. -/
def cartesian {A B : Type} : List A -> List B -> List (A × B)
  | [], _ => []
  | a :: as, bs => bs.map (fun b => (a,b)) ++ cartesian as bs

/-- Joint observation from two observations. -/
def pairObs {Secret A B : Type}
    (obsA : Observation Secret A)
    (obsB : Observation Secret B) : Observation Secret (A × B) :=
  fun s => (obsA s, obsB s)

/-- Exact post-processing preserves the pointwise output value. -/
theorem postprocess_output_pointwise {Secret Raw Out : Type}
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (s : Secret) :
    (postprocess obs f) s = f (obs s) := by
  rfl

/-- Pair observations are pointwise deterministic functions of the secret. -/
theorem pairObs_pointwise {Secret A B : Type}
    (obsA : Observation Secret A)
    (obsB : Observation Secret B)
    (s : Secret) :
    pairObs obsA obsB s = (obsA s, obsB s) := by
  rfl

end Leakage
end PACXAI
