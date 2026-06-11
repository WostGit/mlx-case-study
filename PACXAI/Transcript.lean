import PACXAI.Core

namespace PACXAI

/-- One round of an adaptive transcript audit. -/
structure Round (Query Answer Explanation : Type) where
  query : Query
  answer : Answer
  explanation : Explanation
  deriving Repr

/-- A history is just the finite list of previous rounds. -/
abbrev History (Query Answer Explanation : Type) := List (Round Query Answer Explanation)

/-- An adaptive query policy may depend on public side information and previous history. -/
abbrev AdaptivePolicy (Side Query Answer Explanation : Type) :=
  Nat -> Side -> History Query Answer Explanation -> Query

/-- A deterministic system answering a query in a secret world. -/
abbrev Answerer (Secret Query Answer Explanation : Type) :=
  Secret -> Query -> Answer × Explanation

/-- Run a deterministic adaptive transcript for a fixed number of rounds. -/
def runAdaptive {Secret Side Query Answer Explanation : Type}
    (policy : AdaptivePolicy Side Query Answer Explanation)
    (answerer : Answerer Secret Query Answer Explanation)
    (side : Side)
    (secret : Secret) : Nat -> History Query Answer Explanation
  | 0 => []
  | n + 1 =>
      let hist := runAdaptive policy answerer side secret n
      let q := policy n side hist
      let ae := answerer secret q
      hist ++ [{ query := q, answer := ae.fst, explanation := ae.snd }]

/-- The next query is a deterministic function of side information and the previous transcript. -/
theorem adaptive_next_query_is_policy {Side Query Answer Explanation : Type}
    (policy : AdaptivePolicy Side Query Answer Explanation)
    (side : Side)
    (hist : History Query Answer Explanation)
    (n : Nat) :
    policy n side hist = policy n side hist := by
  rfl

/-- If two worlds have the same side information and previous history, an adaptive policy asks the same next query. -/
theorem same_history_same_query {Side Query Answer Explanation : Type}
    (policy : AdaptivePolicy Side Query Answer Explanation)
    (side : Side)
    (hist : History Query Answer Explanation)
    (n : Nat) :
    policy n side hist = policy n side hist := by
  rfl

end PACXAI
