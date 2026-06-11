import PACXAI.Core

namespace PACXAI

/-- A candidate attack consumes an observed artifact and returns a guess. -/
abbrev CandidateAttack (Observation Guess : Type) := Observation -> Guess

/-- Success count for attacking an observation rather than the raw secret. -/
def observedSuccessCount {Secret Obs Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Obs)
    (attack : CandidateAttack Obs Guess) : Nat :=
  successCount secrets criterion (fun s => attack (obs s))

/-- Empirical rate for an observed-artifact attack. -/
def observedSuccessRate {Secret Obs Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Obs)
    (attack : CandidateAttack Obs Guess) : EmpiricalRate :=
  successRate secrets criterion (fun s => attack (obs s))

/-- A finite list of attacks is the candidate class used by a practical audit. -/
abbrev CandidateClass (Obs Guess : Type) := List (CandidateAttack Obs Guess)

/-- All observed success counts for a candidate class. -/
def candidateScores {Secret Obs Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Obs)
    (candidates : CandidateClass Obs Guess) : List Nat :=
  candidates.map (fun attack => observedSuccessCount secrets criterion obs attack)

/-- A simple finite best operator over natural-number scores. -/
def bestNat : List Nat -> Nat
  | [] => 0
  | x :: xs => Nat.max x (bestNat xs)

/-- Candidate-best empirical success count. -/
def candidateBestSuccess {Secret Obs Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Obs)
    (candidates : CandidateClass Obs Guess) : Nat :=
  bestNat (candidateScores secrets criterion obs candidates)

/-- Map every student-level attack into the equivalent transcript-level simulator. -/
def liftCandidateClass {Raw Out Guess : Type}
    (f : Raw -> Out)
    (candidates : CandidateClass Out Guess) : CandidateClass Raw Guess :=
  candidates.map (liftedAttack f)

/-- Candidate scores are exactly preserved by deterministic post-processing and lifting. -/
theorem candidateScores_postprocess_eq {Secret Raw Out Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (candidates : CandidateClass Out Guess) :
    candidateScores secrets criterion (postprocess obs f) candidates =
    candidateScores secrets criterion obs (liftCandidateClass f candidates) := by
  induction candidates with
  | nil => rfl
  | cons a rest ih =>
      simp [candidateScores, liftCandidateClass, observedSuccessCount, postprocess, liftedAttack,
        successCount, countWhere]

/-- Candidate-best success is exactly preserved when the raw candidate class contains the lifted attacks. -/
theorem candidateBest_postprocess_eq_lifted {Secret Raw Out Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (candidates : CandidateClass Out Guess) :
    candidateBestSuccess secrets criterion (postprocess obs f) candidates =
    candidateBestSuccess secrets criterion obs (liftCandidateClass f candidates) := by
  simp [candidateBestSuccess, candidateScores_postprocess_eq]

/-- Risk is represented as failures. Lower failure means more privacy harm. -/
def empiricalRisk {Secret Obs Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Obs)
    (attack : CandidateAttack Obs Guess) : Nat :=
  failureCount secrets criterion (fun s => attack (obs s))

/-- Risk is also preserved by lifted deterministic post-processing. -/
theorem empiricalRisk_postprocess_eq {Secret Raw Out Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (attack : CandidateAttack Out Guess) :
    empiricalRisk secrets criterion (postprocess obs f) attack =
    empiricalRisk secrets criterion obs (liftedAttack f attack) := by
  rfl

end PACXAI
