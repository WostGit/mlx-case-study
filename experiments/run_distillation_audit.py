#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Callable, Dict, Iterable, List

CAPABILITIES = ["reasoning", "coding", "tool_use", "computer_use", "policy_edge", "domain_expert"]
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

def population(n: int = 10_000) -> List[Dict[str, object]]:
    rows: List[Dict[str, object]] = []
    for i in range(n):
        group = GROUPS[(i * 13 + 3) % len(GROUPS)]
        capability = CAPABILITIES[(i * 7 + (2 if group == "suspicious_campaign" else 0)) % len(CAPABILITIES)]
        query_family = QUERY_FAMILIES[(i * 11 + len(group)) % len(QUERY_FAMILIES)]
        route_id = CAPABILITY_TO_ROUTE[capability]
        campaign_id = f"camp_{(i * 17 + (5 if group == 'proxy_cluster' else 0)) % 97:03d}"
        difficulty = ["easy", "medium", "hard"][(i * 5 + len(capability)) % 3]
        rows.append({
            "secret_id": i,
            "capability": capability,
            "group": group,
            "query_family": query_family,
            "difficulty": difficulty,
            "route_id": route_id,
            "campaign_id": campaign_id
        })
    return rows

def audited_transcript(secret: Dict[str, object]) -> Dict[str, str]:
    capability = str(secret["capability"])
    query_family = str(secret["query_family"])
    if capability in {"coding", "tool_use", "computer_use"}:
        answer_signature = "agentic"
    elif capability == "policy_edge":
        answer_signature = "safety"
    else:
        answer_signature = "language_reasoning"

    if query_family in {"code_generation", "tool_planning"}:
        explanation_style = "procedural"
    elif query_family == "policy_edge":
        explanation_style = "guarded"
    else:
        explanation_style = "generic"

    return {
        "query_family": query_family,
        "answer_signature": answer_signature,
        "explanation_style": explanation_style,
        "difficulty": str(secret["difficulty"])
    }

def auxiliary_metadata(secret: Dict[str, object]) -> Dict[str, str]:
    return {
        "route_id": str(secret["route_id"]),
        "campaign_id": str(secret["campaign_id"]),
        "group": str(secret["group"])
    }

def train_from_transcript(t: Dict[str, str]) -> str:
    if t["answer_signature"] == "safety":
        return "policy_edge"
    if t["answer_signature"] == "agentic":
        if t["query_family"] == "code_generation":
            return "coding"
        if t["query_family"] == "tool_planning":
            return "tool_use"
        return "coding"
    if t["query_family"] == "domain":
        return "domain_expert"
    return "reasoning"

def train_with_route_metadata(t: Dict[str, str], aux: Dict[str, str]) -> str:
    return ROUTE_TO_CAPABILITY.get(aux["route_id"], train_from_transcript(t))

def train_with_partial_aux_for_proxy(t: Dict[str, str], aux: Dict[str, str]) -> str:
    if aux["group"] in {"proxy_cluster", "suspicious_campaign"}:
        return train_with_route_metadata(t, aux)
    return train_from_transcript(t)

def success_count(pop: Iterable[Dict[str, object]], attack: Callable[[Dict[str, object]], str]) -> int:
    return sum(1 for s in pop if attack(s) == s["capability"])

def row(scope: str, attack_name: str, subset: List[Dict[str, object]], attack: Callable[[Dict[str, object]], str]) -> Dict[str, object]:
    succ = success_count(subset, attack)
    total = len(subset)
    return {
        "scope": scope,
        "attack": attack_name,
        "success": succ,
        "failure": total - succ,
        "total": total,
        "rate": round(succ / total, 6) if total else 0.0
    }

def main() -> None:
    pop = population()

    transcript_simulator = lambda s: train_from_transcript(audited_transcript(s))
    deterministic_student = lambda s: train_from_transcript(audited_transcript(s))
    route_metadata_student = lambda s: train_with_route_metadata(audited_transcript(s), auxiliary_metadata(s))
    subgroup_aux_student = lambda s: train_with_partial_aux_for_proxy(audited_transcript(s), auxiliary_metadata(s))

    attacks = [
        ("transcript_simulator", transcript_simulator),
        ("deterministic_student", deterministic_student),
        ("route_metadata_student", route_metadata_student),
        ("subgroup_aux_student", subgroup_aux_student)
    ]

    scopes = [("all", pop)]
    scopes += [(f"group={g}", [s for s in pop if s["group"] == g]) for g in GROUPS]
    scopes += [(f"query_family={q}", [s for s in pop if s["query_family"] == q]) for q in QUERY_FAMILIES]

    audit_rows: List[Dict[str, object]] = []
    for scope, subset in scopes:
        for name, attack in attacks:
            audit_rows.append(row(scope, name, subset, attack))

    by = {(r["scope"], r["attack"]): r for r in audit_rows}

    sound_gap = by[("all", "deterministic_student")]["success"] - by[("all", "transcript_simulator")]["success"]
    route_gap = by[("all", "route_metadata_student")]["success"] - by[("all", "transcript_simulator")]["success"]
    subgroup_gap = by[("all", "subgroup_aux_student")]["success"] - by[("all", "transcript_simulator")]["success"]

    budget = int(by[("all", "transcript_simulator")]["success"] + 0.02 * len(pop))
    route_false_pass = by[("all", "transcript_simulator")]["success"] <= budget and by[("all", "route_metadata_student")]["success"] > budget

    worst_group = max(
        GROUPS,
        key=lambda g: by[(f"group={g}", "subgroup_aux_student")]["rate"] - by[(f"group={g}", "transcript_simulator")]["rate"]
    )

    out = Path("results")
    out.mkdir(exist_ok=True)
    case = out / "killer_case_study"
    case.mkdir(exist_ok=True)

    with (case / "population.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(pop[0].keys()))
        w.writeheader()
        w.writerows(pop)

    with (case / "audit_table.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["scope", "attack", "success", "failure", "total", "rate"])
        w.writeheader()
        w.writerows(audit_rows)

    summary = {
        "population_size": len(pop),
        "budget_allowed_successes": budget,
        "deterministic_student_minus_transcript_simulator_success": sound_gap,
        "route_metadata_student_minus_transcript_simulator_success": route_gap,
        "subgroup_aux_student_minus_transcript_simulator_success": subgroup_gap,
        "route_metadata_false_pass_under_transcript_audit": route_false_pass,
        "worst_conditioned_group": worst_group,
        "worst_conditioned_group_transcript_rate": by[(f"group={worst_group}", "transcript_simulator")]["rate"],
        "worst_conditioned_group_subgroup_aux_rate": by[(f"group={worst_group}", "subgroup_aux_student")]["rate"]
    }

    (out / "audit_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    (case / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

    report = f"""# Killer Case Study: Route Metadata Leak

## Result summary

- Population size: {summary['population_size']}
- Audit budget (allowed successes): {summary['budget_allowed_successes']}
- Sound deterministic student gap: {summary['deterministic_student_minus_transcript_simulator_success']}
- Route-metadata student gap: {summary['route_metadata_student_minus_transcript_simulator_success']}
- Subgroup auxiliary student gap: {summary['subgroup_aux_student_minus_transcript_simulator_success']}
- Route metadata creates false pass under transcript audit: {summary['route_metadata_false_pass_under_transcript_audit']}
- Worst conditioned group: {summary['worst_conditioned_group']}
- Worst group transcript rate: {summary['worst_conditioned_group_transcript_rate']}
- Worst group subgroup-aux rate: {summary['worst_conditioned_group_subgroup_aux_rate']}

## Interpretation

The deterministic student is genuine post-processing of the audited transcript, so its success count exactly matches the transcript simulator.

The route-metadata student uses `route_id`, which is omitted from the audited transcript. The transcript-only audit therefore certifies the wrong boundary: it checks `Transcript -> Student`, while the real pipeline is `Transcript -> RouteMetadata -> Student`.

The subgroup auxiliary case shows why conditioning is not optional. Aggregate results can hide concentrated leakage in proxy or suspicious campaign groups.
"""
    (case / "CASE_STUDY_REPORT.md").write_text(report, encoding="utf-8")

    print(json.dumps(summary, indent=2))

if __name__ == "__main__":
    main()
