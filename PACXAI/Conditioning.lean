import PACXAI.Core
import PACXAI.Recovery

namespace PACXAI

/-- Conditioning is finite filtering of the audit population. -/
def conditionPopulation {Secret : Type}
    (secrets : Population Secret)
    (condition : Secret -> Bool) : Population Secret :=
  secrets.filter condition

/-- Conditional observed success count: evaluate only on the filtered population. -/
def conditionalObservedSuccessCount {Secret Obs Guess : Type}
    (secrets : Population Secret)
    (condition : Secret -> Bool)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Obs)
    (attack : CandidateAttack Obs Guess) : Nat :=
  observedSuccessCount (conditionPopulation secrets condition) criterion obs attack

/-- Post-processing preservation also holds after conditioning on a subgroup/campaign. -/
theorem conditional_postprocess_success_eq {Secret Raw Out Guess : Type}
    (secrets : Population Secret)
    (condition : Secret -> Bool)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (attack : CandidateAttack Out Guess) :
    conditionalObservedSuccessCount secrets condition criterion (postprocess obs f) attack =
    conditionalObservedSuccessCount secrets condition criterion obs (liftedAttack f attack) := by
  rfl

/-- Candidate-best equality also holds after finite conditioning. -/
theorem conditional_candidateBest_postprocess_eq_lifted {Secret Raw Out Guess : Type}
    (secrets : Population Secret)
    (condition : Secret -> Bool)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (candidates : CandidateClass Out Guess) :
    candidateBestSuccess (conditionPopulation secrets condition) criterion (postprocess obs f) candidates =
    candidateBestSuccess (conditionPopulation secrets condition) criterion obs (liftCandidateClass f candidates) := by
  exact candidateBest_postprocess_eq_lifted (conditionPopulation secrets condition) criterion obs f candidates

end PACXAI
