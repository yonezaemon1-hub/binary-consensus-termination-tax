# Computational evidence backfill

Status: candidate for the next manuscript version; not part of the currently published Zenodo PDF.

This repository contains two related preprints in the same research line. The computational backfill is intended to make the finite-parameter behavior behind the asymptotic state/memory results directly inspectable. It is an audit and visualization aid, not a substitute for the proofs.

## Added audit

Run:

```bash
python audit/computational_evidence.py
```

The script writes finite tables for:

- the clockless known-size and known-dynamic-diameter termination bounds;
- the periodic-phase state--phase bounds from the v2 paper;
- representative values showing how increasing the free phase period `P` reduces the persistent-state requirement.

The audit uses only integer arithmetic and the Python standard library. It deliberately checks boundary values and monotonicity rather than simulating a dynamic-network protocol.

## Interpretation

The useful computational picture is that the persistent-state requirement is approximately linear in the amount of elapsed-time evidence that is not supplied externally. For the periodic-clock model, increasing `P` compresses the required persistent state count by the corresponding block factor, while the theorem proofs remain the source of the universal guarantees.

## Claim discipline

These finite tables do not strengthen the published theorems and do not certify optimality beyond the stated proven regimes. The current Zenodo PDFs remain the authoritative published versions until a new manuscript version is explicitly released.
