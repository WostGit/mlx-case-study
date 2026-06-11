# Killer Case Study: Route Metadata Leak

## Result summary

- Population size: 10000
- Audit budget (allowed successes): 4367
- Sound deterministic student gap: 0
- Route-metadata student gap: 5833
- Subgroup auxiliary student gap: 3334
- Route metadata creates false pass under transcript audit: True
- Worst conditioned group: suspicious_campaign
- Worst group transcript rate: 0.0
- Worst group subgroup-aux rate: 1.0

## Interpretation

The deterministic student is genuine post-processing of the audited transcript, so its success count exactly matches the transcript simulator.

The route-metadata student uses `route_id`, which is omitted from the audited transcript. The transcript-only audit therefore certifies the wrong boundary: it checks `Transcript -> Student`, while the real pipeline is `Transcript -> RouteMetadata -> Student`.

The subgroup auxiliary case shows why conditioning is not optional. Aggregate results can hide concentrated leakage in proxy or suspicious campaign groups.
