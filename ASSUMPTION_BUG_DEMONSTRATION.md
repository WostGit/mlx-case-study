# Assumption Bug Demonstration

Informal claim:

```text
Student = train(Transcript)
```

Real buggy pipeline:

```text
Student = train(Transcript, RouteMetadata)
```

The route-metadata case study shows that this can make a transcript-only audit falsely pass.
