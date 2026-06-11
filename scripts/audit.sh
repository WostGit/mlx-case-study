#!/usr/bin/env bash
set -euo pipefail

echo "[audit] forbidden token scan"
if grep -RIn --include='*.lean' \
  -e '\bsorry\b' -e '\badmit\b' -e '\baxiom\b' -e '\bconstant\b' \
  -e '\bunsafe\b' -e '\bopaque\b' -e 'TODO' -e 'FIXME' \
  PACXAI PACXAI.lean lakefile.lean; then
  echo "Forbidden token found" >&2
  exit 1
else
  echo "No forbidden tokens found"
fi

echo "[audit] theorem check"
cat > /tmp/PACXAIPrint.lean <<'LEAN'
import PACXAI
#print axioms PACXAI.postprocess_successCount_eq
#print axioms PACXAI.postprocess_successRate_eq
#print axioms PACXAI.distilled_student_attack_is_transcript_attack
#print axioms PACXAI.distilled_student_rate_is_transcript_rate
#print axioms PACXAI.candidateBest_postprocess_eq_lifted
#print axioms PACXAI.conditional_candidateBest_postprocess_eq_lifted
#print axioms PACXAI.student_attack_lifts_to_transcript
#print axioms PACXAI.student_rate_lifts_to_transcript
#print axioms PACXAI.conditional_student_attack_lifts_to_transcript
#print axioms PACXAI.student_candidate_best_is_transcript_candidate_best_lifted
#print axioms PACXAI.InfoTheory.deterministic_dpi_exact
#print axioms PACXAI.InfoTheory.conditional_deterministic_dpi_exact
#print axioms PACXAI.InfoTheory.infoGain_postprocess_exact
#print axioms PACXAI.InfoTheory.fanoStyle_valid_student_to_transcript
#print axioms PACXAI.InfoTheory.fanoStyle_budget_violation_lifts
#print axioms PACXAI.PAC.monteCarlo_transcript_pass_implies_student_pass
#print axioms PACXAI.PAC.monteCarlo_candidateClass_postprocess_eq
LEAN
lake env lean /tmp/PACXAIPrint.lean
