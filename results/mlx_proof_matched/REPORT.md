# MLX Proof-Matched Experiments

    ## Lean theorem alignment

    - `postprocess_successCount_eq`: deterministic gap = 0
    - `candidateBest_postprocess_eq_lifted`: candidate-best gap = 0
    - `deterministic_dpi_exact`: code-cost gap = 0
    - `fanoStyle_valid_student_to_transcript`: student valid = True, transcript valid = True
    - `monteCarlo_transcript_pass_implies_student_pass`: transcript pass = True, student pass = True

    ## Assumption-bug result

    Route-metadata success exceeds transcript-simulator success by:

    `7500`

    This is not a contradiction of the Lean theorem.  It means the real training function is not `Transcript -> Student`; it is `Transcript -> RouteMetadata -> Student`.
    