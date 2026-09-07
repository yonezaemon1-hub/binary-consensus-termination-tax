# Computational evidence backfill for Paper 3

Target preprint: **A Logarithmic Local-Memory Tax for Explicitly Terminating Binary Consensus in Anonymous Dynamic Networks**.

This is a post-publication evidence file for the clockless v1 result. The current Zenodo v1 preprint is not modified by this branch.

Run the shared audit:

```bash
python audit/computational_evidence.py
```

The `clockless_finite_table.csv` output evaluates the published finite state bounds for both known network size `n` and known dynamic diameter `D`. The purpose is to display the linear-in-parameter state growth that becomes a logarithmic bit-memory law after applying `ceil(log2 S)`.

Representative values:

| regime | parameter | lower states | upper states |
|---|---:|---:|---:|
| known D | 8 | 5 | 18 |
| known D | 16 | 9 | 34 |
| known n | 16 | 5 | 32 |
| known n | 32 | 9 | 64 |

This finite arithmetic check is not a proof and does not tighten the constants in the published asymptotic `Theta(log n)` / `Theta(log(D+1))` statements.
