# Internal Time as Local Memory: Explicit Termination in Anonymous Dynamic Binary Consensus

**Author:** Ryutaro Yonezu  
**Affiliation:** Independent Researcher  
**Version:** v2.0.0

**Zenodo status:** v2 record pending publication.  
Previous preprint version (v1.0.0): https://doi.org/10.5281/zenodo.22206514  
Previous software version (v1.0.0): https://doi.org/10.5281/zenodo.22206519

## Main results

In deterministic anonymous synchronous 1-interval-connected dynamic networks under one-bit broadcast-counting communication:

- Stabilizing binary consensus needs exactly one bit of persistent local state.
- With known network size `n` and no free round clock, explicit termination has local-memory complexity `Theta(log n)`.
- With unknown `n` but known temporal dissemination bound (dynamic diameter) `D` and no free round clock, explicit termination has local-memory complexity `Theta(log(D+1))`.
- If the global round number is supplied for free, the known-`D` terminating problem uses `Theta(1)` persistent local memory.

The comparison isolates the logarithmic cost of representing elapsed-time evidence internally rather than the consensus value itself.

## Paper files

- `Yonezu_2026_Internal_Time_Local_Memory.pdf` — current integrated manuscript
- `paper.tex` — LaTeX source for the current manuscript

The original v1.0.0 release remains available through Git history and the v1.0.0 tag.

## Licenses

- Paper: CC BY 4.0
- Software / scripts: MIT

## Claim boundary

Flooding, locality, dynamic-diameter notions, finite-state pumping, and the general distinction between stabilization and termination are not claimed as new. The mathematical claim is restricted to the stated binary-consensus local-space characterizations and their comparison. Targeted prior-art screening is not a certification of novelty.
