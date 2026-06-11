import PACXAI.Core
import PACXAI.Recovery
import PACXAI.Conditioning
import PACXAI.Transcript

namespace PACXAI

/-- A distillation campaign is the exact structure needed for the post-processing theorem. -/
structure DistillationCampaign (Secret Transcript Student Guess : Type) where
  population : Population Secret
  criterion : Criterion Secret Guess
  transcript : Observation Secret Transcript
  train : Transcript -> Student
  studentAttack : Student -> Guess

/-- Student artifact as a deterministic post-processing of the transcript. -/
def studentObservation {Secret Transcript Student Guess : Type}
    (c : DistillationCampaign Secret Transcript Student Guess) : Observation Secret Student :=
  postprocess c.transcript c.train

/-- The transcript-level simulator corresponding to the student-level attack. -/
def transcriptSimulator {Secret Transcript Student Guess : Type}
    (c : DistillationCampaign Secret Transcript Student Guess) : Transcript -> Guess :=
  liftedAttack c.train c.studentAttack

/-- Main theorem: every successful attack on a deterministic student is the same attack on the transcript plus training. -/
theorem student_attack_lifts_to_transcript {Secret Transcript Student Guess : Type}
    (c : DistillationCampaign Secret Transcript Student Guess) :
    observedSuccessCount c.population c.criterion (studentObservation c) c.studentAttack =
    observedSuccessCount c.population c.criterion c.transcript (transcriptSimulator c) := by
  rfl

/-- Same theorem stated for empirical rates. -/
theorem student_rate_lifts_to_transcript {Secret Transcript Student Guess : Type}
    (c : DistillationCampaign Secret Transcript Student Guess) :
    observedSuccessRate c.population c.criterion (studentObservation c) c.studentAttack =
    observedSuccessRate c.population c.criterion c.transcript (transcriptSimulator c) := by
  rfl

/-- Same theorem after conditioning on a subgroup/campaign/account cluster. -/
theorem conditional_student_attack_lifts_to_transcript {Secret Transcript Student Guess : Type}
    (c : DistillationCampaign Secret Transcript Student Guess)
    (condition : Secret -> Bool) :
    conditionalObservedSuccessCount c.population condition c.criterion (studentObservation c) c.studentAttack =
    conditionalObservedSuccessCount c.population condition c.criterion c.transcript (transcriptSimulator c) := by
  rfl

/-- Candidate-best version for a class of student-level adversaries. -/
theorem student_candidate_best_is_transcript_candidate_best_lifted
    {Secret Transcript Student Guess : Type}
    (population : Population Secret)
    (criterion : Criterion Secret Guess)
    (transcript : Observation Secret Transcript)
    (train : Transcript -> Student)
    (candidates : CandidateClass Student Guess) :
    candidateBestSuccess population criterion (postprocess transcript train) candidates =
    candidateBestSuccess population criterion transcript (liftCandidateClass train candidates) := by
  exact candidateBest_postprocess_eq_lifted population criterion transcript train candidates

end PACXAI
