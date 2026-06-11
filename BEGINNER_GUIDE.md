# Beginner Guide

The proof checks one simple safety rule:

```text
If student = train(transcript),
then attack(student) can be simulated by attack(train(transcript)).
```

If the student also uses route metadata, campaign IDs, or other auxiliary data, then it is not just post-processing of the transcript.

The case study demonstrates this by creating a route-metadata student that falsely passes a transcript-only audit.
