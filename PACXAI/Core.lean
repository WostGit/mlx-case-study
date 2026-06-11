namespace PACXAI

/-- A finite transcript-derived artifact is represented by an observation function. -/
abbrev Observation (Secret Output : Type) := Secret -> Output

/-- A reconstruction criterion says whether a guess successfully recovers the protected feature. -/
abbrev Criterion (Secret Guess : Type) := Secret -> Guess -> Bool

/-- A finite audit population. The same secret may appear more than once to model empirical sampling. -/
abbrev Population (Secret : Type) := List Secret

/-- Count list elements satisfying a Boolean predicate. -/
def countWhere {A : Type} (xs : List A) (p : A -> Bool) : Nat :=
  (xs.filter p).length

/-- Count successful reconstructions over a finite population. -/
def successCount {Secret Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (attack : Secret -> Guess) : Nat :=
  countWhere secrets (fun s => criterion s (attack s))

/-- Count failed reconstructions over a finite population. -/
def failureCount {Secret Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (attack : Secret -> Guess) : Nat :=
  countWhere secrets (fun s => !(criterion s (attack s)))

/-- A count-based rate: numerator successes over denominator population size. -/
structure EmpiricalRate where
  numerator : Nat
  denominator : Nat
  deriving Repr, BEq

/-- Empirical success rate represented without real numbers. -/
def successRate {Secret Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (attack : Secret -> Guess) : EmpiricalRate :=
  { numerator := successCount secrets criterion attack, denominator := secrets.length }

/-- A privacy audit passes if successful reconstructions are at most the budget. -/
def passesBudget {Secret Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (budget : Nat)
    (attack : Secret -> Guess) : Prop :=
  successCount secrets criterion attack <= budget

/-- Deterministic post-processing of an observation. -/
def postprocess {Secret Raw Out : Type}
    (obs : Observation Secret Raw)
    (f : Raw -> Out) : Observation Secret Out :=
  fun s => f (obs s)

/-- Any attack on a post-processed observation is simulated by an attack on the raw observation. -/
def liftedAttack {Raw Out Guess : Type}
    (f : Raw -> Out)
    (attack : Out -> Guess) : Raw -> Guess :=
  fun r => attack (f r)

/-- Pointwise equality behind the transcript-to-student reduction. -/
theorem postprocess_attack_pointwise {Secret Raw Out Guess : Type}
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (attack : Out -> Guess)
    (s : Secret) :
    attack ((postprocess obs f) s) = (liftedAttack f attack) (obs s) := by
  rfl

/-- Empirical success is exactly preserved by the lifted transcript-level simulator. -/
theorem postprocess_successCount_eq {Secret Raw Out Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (attack : Out -> Guess) :
    successCount secrets criterion (fun s => attack ((postprocess obs f) s)) =
    successCount secrets criterion (fun s => (liftedAttack f attack) (obs s)) := by
  rfl

/-- Empirical success-rate numerators and denominators are preserved by lifting. -/
theorem postprocess_successRate_eq {Secret Raw Out Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (attack : Out -> Guess) :
    successRate secrets criterion (fun s => attack ((postprocess obs f) s)) =
    successRate secrets criterion (fun s => (liftedAttack f attack) (obs s)) := by
  rfl

/-- If the raw transcript-level simulator passes the budget, the post-processed attack passes too. -/
theorem postprocess_budget_sound {Secret Raw Out Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (budget : Nat)
    (obs : Observation Secret Raw)
    (f : Raw -> Out)
    (attack : Out -> Guess)
    (h : passesBudget secrets criterion budget (fun s => (liftedAttack f attack) (obs s))) :
    passesBudget secrets criterion budget (fun s => attack ((postprocess obs f) s)) := by
  exact h

/-- A compact theorem statement for CI and paper-facing artifact checks. -/
theorem distilled_student_attack_is_transcript_attack
    {Secret Transcript Student Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (transcript : Observation Secret Transcript)
    (train : Transcript -> Student)
    (studentAttack : Student -> Guess) :
    successCount secrets criterion (fun s => studentAttack (train (transcript s))) =
    successCount secrets criterion (fun s => (fun t => studentAttack (train t)) (transcript s)) := by
  rfl

/-- The same reduction stated for count-based rates. -/
theorem distilled_student_rate_is_transcript_rate
    {Secret Transcript Student Guess : Type}
    (secrets : Population Secret)
    (criterion : Criterion Secret Guess)
    (transcript : Observation Secret Transcript)
    (train : Transcript -> Student)
    (studentAttack : Student -> Guess) :
    successRate secrets criterion (fun s => studentAttack (train (transcript s))) =
    successRate secrets criterion (fun s => (fun t => studentAttack (train t)) (transcript s)) := by
  rfl

end PACXAI
