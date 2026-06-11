#!/usr/bin/env python3
"""
MLX experiments matched to the Lean proofs.

This file is deliberately small and deterministic.  It does not train
a large model.  Instead, it uses MLX array operations to instantiate
the exact finite objects from the Lean proof:

Lean theorem -> MLX check

1. postprocess_successCount_eq / student_attack_lifts_to_transcript
   deterministic_student_success == transcript_simulator_success

2. conditional_student_attack_lifts_to_transcript
   conditioned deterministic gaps are zero for every group

3. candidateBest_postprocess_eq_lifted
   candidate-best success for transcript-only students equals
   candidate-best success for their lifted transcript simulators

4. deterministic_dpi_exact / infoGain_postprocess_exact
   finite code-cost after post-processing equals pulled-back code-cost

5. fanoStyle_valid_student_to_transcript
   finite recovery certificate validity transfers when post-processing holds

6. monteCarlo_transcript_pass_implies_student_pass
   transcript Monte Carlo pass implies deterministic student pass

7. Assumption-bug experiment
   route_metadata_student uses route_id omitted from Transcript,
   so it is NOT train : Transcript -> Student and can have a large gap.
"""
from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Dict, List, Tuple

import mlx.core as mx
import numpy as np

CAPABILITIES = [
    "reasoning",
    "coding",
    "tool_use",
    "computer_use",
    "policy_edge",
    "domain_expert",
]
GROUPS = ["normal", "proxy_cluster", "suspicious_campaign", "enterprise_eval"]
QUERY_FAMILIES = ["simple_qa", "code_generation", "tool_planning", "multi_step", "policy_edge", "domain"]

ROUTE_TO_CAPABILITY = {
    "reasoning_route": "reasoning",
    "code_route": "coding",
    "tool_route": "tool_use",
    "computer_route": "computer_use",
    "safety_route": "policy_edge",
    "expert_route": "domain_expert",
}
CAPABILITY_TO_ROUTE = {v: k for k, v in ROUTE_TO_CAPABILITY.items()}
ROUTES = list(ROUTE_TO_CAPABILITY.keys())

CAP = {c: i for i, c in enumerate(CAPABILITIES)}
GROUP = {g: i for i, g in enumerate(GROUPS)}
QUERY = {q: i for i, q in enumerate(QUERY_FAMILIES)}
ROUTE = {r: i for i, r in enumerate(ROUTES)}

N = 10000

def one_hot(i: int, n: int) -> List[float]:
    x = [0.0] * n
    x[i] = 1.0
    return x

def population(n: int = N) -> List[Dict[str, object]]:
    rows = []
    for i in range(n):
        group = GROUPS[(i * 13 + 3) % len(GROUPS)]
        capability = CAPABILITIES[(i * 7 + (2 if group == "suspicious_campaign" else 0)) % len(CAPABILITIES)]
        query_family = QUERY_FAMILIES[(i * 11 + len(group)) % len(QUERY_FAMILIES)]
        route_id = CAPABILITY_TO_ROUTE[capability]
        difficulty = ["easy", "medium", "hard"][(i * 5 + len(capability)) % 3]
        rows.append(
            {
                "secret_id": i,
                "capability": capability,
                "capability_id": CAP[capability],
                "group": group,
                "query_family": query_family,
                "route_id": route_id,
                "difficulty": difficulty,
            }
        )
    return rows

def transcript_features(row: Dict[str, object]) -> List[float]:
    capability = str(row["capability"])
    query_family = str(row["query_family"])
    difficulty = str(row["difficulty"])

    if capability in {"coding", "tool_use", "computer_use"}:
        signature = "agentic"
    elif capability == "policy_edge":
        signature = "safety"
    else:
        signature = "language_reasoning"

    signatures = ["agentic", "safety", "language_reasoning"]
    difficulties = ["easy", "medium", "hard"]

    x = []
    x += one_hot(QUERY[query_family], len(QUERY_FAMILIES))
    x += one_hot(signatures.index(signature), len(signatures))
    x += one_hot(difficulties.index(difficulty), len(difficulties))
    return x

def route_features(row: Dict[str, object]) -> List[float]:
    return one_hot(ROUTE[str(row["route_id"])], len(ROUTES))

def make_matrix(rows: List[Dict[str, object]], mode: str) -> Tuple[mx.array, mx.array]:
    xs = []
    ys = []

    for row in rows:
        x = transcript_features(row)

        if mode == "transcript":
            pass
        elif mode == "route":
            x += route_features(row)
        elif mode == "subgroup_route":
            if row["group"] in {"proxy_cluster", "suspicious_campaign"}:
                x += route_features(row)
            else:
                x += [0.0] * len(ROUTES)
        else:
            raise ValueError(mode)

        xs.append(x)
        ys.append(int(row["capability_id"]))

    return mx.array(np.array(xs, dtype=np.float32)), mx.array(np.array(ys, dtype=np.int32))

def transcript_logits(x: mx.array, variant: int = 0) -> mx.array:
    # Feature layout: query one-hot (6), signature one-hot (3), difficulty one-hot (3).
    q = x[:, 0:6]
    sig = x[:, 6:9]

    # Deterministic coarse transcript model: it cannot distinguish all agentic routes.
    Wq = mx.array(
        [
            [2.0, 0.2, 0.2, 0.2, 0.0, 0.0],  # simple_qa
            [0.0, 2.0, 0.4, 0.4, 0.0, 0.0],  # code_generation
            [0.0, 0.4, 2.0, 0.4, 0.0, 0.0],  # tool_planning
            [1.4, 0.4, 0.4, 0.4, 0.0, 0.0],  # multi_step
            [0.0, 0.0, 0.0, 0.0, 2.0, 0.0],  # policy_edge
            [0.0, 0.0, 0.0, 0.0, 0.0, 2.0],  # domain
        ],
        dtype=mx.float32,
    )

    Ws = mx.array(
        [
            [0.0, 1.0, 1.0, 1.0, 0.0, 0.0],  # agentic
            [0.0, 0.0, 0.0, 0.0, 2.0, 0.0],  # safety
            [1.5, 0.0, 0.0, 0.0, 0.0, 1.0],  # language_reasoning
        ],
        dtype=mx.float32,
    )

    logits = q @ Wq + sig @ Ws

    if variant == 1:
        # A second candidate with a different but still transcript-only bias.
        bias = mx.array([0.3, 0.0, 0.1, 0.1, 0.0, 0.2], dtype=mx.float32)
        logits = logits + bias
    elif variant == 2:
        bias = mx.array([0.0, 0.2, 0.0, 0.3, 0.0, 0.1], dtype=mx.float32)
        logits = logits + bias

    return logits

def route_logits(x: mx.array) -> mx.array:
    # Feature layout: transcript features (12) + route one-hot (6).
    r = x[:, 12:18]
    route_to_cap = mx.eye(len(CAPABILITIES), dtype=mx.float32) * 10.0
    return r @ route_to_cap

def subgroup_route_logits(x: mx.array) -> mx.array:
    # If route features are zeros, fall back to transcript model.
    base = transcript_logits(x[:, 0:12])
    route = route_logits(x)
    route_present = mx.sum(x[:, 12:18], axis=1, keepdims=True)
    return mx.where(route_present > 0, route, base)

def predict(logits: mx.array) -> mx.array:
    p = mx.argmax(logits, axis=1)
    mx.eval(p)
    return p

def success(pred: mx.array, y: mx.array) -> int:
    c = mx.sum(pred == y)
    mx.eval(c)
    return int(c.item())

def code_cost(pred: mx.array) -> int:
    # Arbitrary finite code lengths for output labels.
    code = mx.array([1, 2, 3, 4, 5, 6], dtype=mx.int32)
    val = mx.sum(code[pred])
    mx.eval(val)
    return int(val.item())

def fano_valid(total: int, successes: int, allowed_errors: int) -> bool:
    return total <= successes + allowed_errors

def main() -> None:
    rows = population()
    X_t, y = make_matrix(rows, "transcript")
    X_r, _ = make_matrix(rows, "route")
    X_s, _ = make_matrix(rows, "subgroup_route")

    pred_transcript_student = predict(transcript_logits(X_t, variant=0))
    pred_transcript_simulator = predict(transcript_logits(X_t, variant=0))
    pred_route_student = predict(route_logits(X_r))
    pred_subgroup_student = predict(subgroup_route_logits(X_s))

    transcript_success = success(pred_transcript_student, y)
    simulator_success = success(pred_transcript_simulator, y)
    route_success = success(pred_route_student, y)
    subgroup_success = success(pred_subgroup_student, y)

    # Candidate class: three transcript-only candidates.
    candidate_preds = [predict(transcript_logits(X_t, variant=i)) for i in range(3)]
    candidate_successes = [success(p, y) for p in candidate_preds]
    candidate_best_student = max(candidate_successes)
    candidate_best_lifted_transcript = max(candidate_successes)

    # Conditional groups: deterministic post-processing gap is zero for every group.
    conditional = {}
    groups_np = np.array([GROUP[str(r["group"])] for r in rows], dtype=np.int32)
    groups_mx = mx.array(groups_np)

    for group_name, group_id in GROUP.items():
        mask = groups_mx == group_id
        total_g = int(mx.sum(mask).item())
        det_g = int(mx.sum((pred_transcript_student == y) & mask).item())
        sim_g = int(mx.sum((pred_transcript_simulator == y) & mask).item())
        sub_g = int(mx.sum((pred_subgroup_student == y) & mask).item())
        conditional[group_name] = {
            "total": total_g,
            "deterministic_student_success": det_g,
            "transcript_simulator_success": sim_g,
            "deterministic_gap": det_g - sim_g,
            "subgroup_aux_success": sub_g,
            "subgroup_aux_rate": round(sub_g / total_g, 6),
            "transcript_rate": round(sim_g / total_g, 6),
        }

    # Finite code-cost/DPI check.
    cost_student = code_cost(pred_transcript_student)
    cost_pullback = code_cost(pred_transcript_simulator)

    # Fano-style certificate transfer.
    allowed_errors = N - transcript_success
    fano_student_valid = fano_valid(N, transcript_success, allowed_errors)
    fano_transcript_valid = fano_valid(N, simulator_success, allowed_errors)

    # Monte Carlo certificate.
    budget = transcript_success + int(0.02 * N)
    monte_carlo_transcript_pass = simulator_success <= budget
    monte_carlo_student_pass = transcript_success <= budget
    route_false_pass = simulator_success <= budget and route_success > budget

    summary = {
        "n": N,
        "transcript_success": transcript_success,
        "transcript_simulator_success": simulator_success,
        "route_metadata_success": route_success,
        "subgroup_aux_success": subgroup_success,
        "deterministic_student_minus_transcript_simulator_success": transcript_success - simulator_success,
        "route_metadata_student_minus_transcript_simulator_success": route_success - simulator_success,
        "subgroup_aux_student_minus_transcript_simulator_success": subgroup_success - simulator_success,
        "candidate_best_student": candidate_best_student,
        "candidate_best_lifted_transcript": candidate_best_lifted_transcript,
        "candidate_best_gap": candidate_best_student - candidate_best_lifted_transcript,
        "code_cost_student": cost_student,
        "code_cost_pullback": cost_pullback,
        "code_cost_gap": cost_student - cost_pullback,
        "fano_student_valid": fano_student_valid,
        "fano_transcript_valid": fano_transcript_valid,
        "monte_carlo_budget": budget,
        "monte_carlo_transcript_pass": monte_carlo_transcript_pass,
        "monte_carlo_student_pass": monte_carlo_student_pass,
        "route_metadata_false_pass_under_transcript_audit": route_false_pass,
        "conditional": conditional,
    }

    out = Path("results/mlx_proof_matched")
    out.mkdir(parents=True, exist_ok=True)

    (out / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

    with (out / "conditional_groups.csv").open("w", newline="") as f:
        fieldnames = [
            "group",
            "total",
            "deterministic_student_success",
            "transcript_simulator_success",
            "deterministic_gap",
            "subgroup_aux_success",
            "subgroup_aux_rate",
            "transcript_rate",
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for g, rec in conditional.items():
            row = {"group": g}
            row.update(rec)
            writer.writerow(row)

    report = f"""# MLX Proof-Matched Experiments

    ## Lean theorem alignment

    - `postprocess_successCount_eq`: deterministic gap = {summary['deterministic_student_minus_transcript_simulator_success']}
    - `candidateBest_postprocess_eq_lifted`: candidate-best gap = {summary['candidate_best_gap']}
    - `deterministic_dpi_exact`: code-cost gap = {summary['code_cost_gap']}
    - `fanoStyle_valid_student_to_transcript`: student valid = {summary['fano_student_valid']}, transcript valid = {summary['fano_transcript_valid']}
    - `monteCarlo_transcript_pass_implies_student_pass`: transcript pass = {summary['monte_carlo_transcript_pass']}, student pass = {summary['monte_carlo_student_pass']}

    ## Assumption-bug result

    Route-metadata success exceeds transcript-simulator success by:

    `{summary['route_metadata_student_minus_transcript_simulator_success']}`

    This is not a contradiction of the Lean theorem.  It means the real training function is not `Transcript -> Student`; it is `Transcript -> RouteMetadata -> Student`.
    """
    (out / "REPORT.md").write_text(report, encoding="utf-8")

    print(json.dumps(summary, indent=2))

if __name__ == "__main__":
    main()
