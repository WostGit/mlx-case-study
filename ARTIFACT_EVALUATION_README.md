# Artifact Evaluation README

Run:

```bash
lake build
bash scripts/audit.sh
python3 experiments/run_distillation_audit.py
```

Expected results:

- Lean builds.
- No forbidden proof tokens are found.
- Deterministic student gap is 0.
- Route-metadata student gap is positive.
- Route metadata creates a false pass under transcript audit.
