# Prior-Art Audit and Claim Boundary

Date: September 22, 2026  
Scope: No. 3 and No. 4 in the project series.  
Status: targeted literature audit; **not a certification of novelty**.

## Papers covered

1. **No. 3** — *A Logarithmic Local-Memory Tax for Explicitly Terminating Binary Consensus in Anonymous Dynamic Networks*.
2. **No. 4** — *Internal Time as Local Memory: State–Phase Tradeoffs for Explicit Termination in Anonymous Dynamic Binary Consensus*.

## Newly checked adjacent literature

### Blanc, Di Luna, and Viglietta (2026)

Thibaut Blanc, Giuseppe Antonio Di Luna, and Giovanni Viglietta, *Computing in Anonymous Dynamic Networks with One-Bit Communications*, arXiv:2607.08358, July 9, 2026.

https://arxiv.org/abs/2607.08358

This work studies deterministic computation in anonymous dynamic networks under a one-bit broadcast/aggregate-observation interface. It gives terminating and stabilizing algorithms for general multiset computation under assumptions including leaders and size knowledge.

**Boundary:** this is highly relevant to the communication model, but it does not by itself establish the No. 3 binary-consensus-specific tight local-memory separation between constant-memory stabilization and explicit termination, nor the No. 4 periodic-phase state–memory tradeoff.

### Schmid, Felber, and Rincon Galeana (2026)

Ulrich Schmid, Stephan Felber, and Hugo Rincon Galeana, *A topological characterization of stabilizing consensus*, Distributed Computing 39, Article 17 (2026), published June 22, 2026.

https://doi.org/10.1007/s00446-026-00508-z

This work gives a general topological characterization of deterministic stabilizing consensus and explicitly distinguishes stabilizing consensus from terminating consensus through the regularity required of decision functions.

**Boundary:** the qualitative distinction between stabilizing and terminating consensus is therefore not claimed here as novel. The residual claim of No. 3 is quantitative and model-specific: the local-memory cost of **explicit termination** for deterministic binary consensus under the paper's anonymous dynamic one-bit model, contrasted with constant-memory stabilization. No. 4 further studies how a free common periodic phase changes the required persistent state.

### Turau (2026)

Volker Turau, *Broadcasts in Anonymous, Dynamic Networks: A New Algorithm and Impossibility Results*, SAND 2026, LIPIcs 373, Article 6.

https://doi.org/10.4230/LIPIcs.SAND.2026.6

Turau gives a randomized broadcast algorithm with stabilizing termination using O(log log n) memory per node with high probability in anonymous synchronous 1-interval-connected dynamic networks, together with impossibility results for termination-detection variants.

**Boundary:** this is a different task (broadcast), uses randomization, and studies stabilizing termination / termination-detection variants. It is evidence that no broad statement of the form “termination in anonymous dynamic networks inherently costs Theta(log n) memory” should be made.

## Claim boundary after the September 22 audit

For **No. 3**, the novelty claim should be read narrowly as the binary-consensus-specific quantitative result in the stated model: constant-memory stabilization versus a tight logarithmic local-memory cost for deterministic explicit termination (under the paper's stated size-knowledge and communication assumptions).

For **No. 4**, the novelty claim is the corresponding **state–phase tradeoff** when a common periodic phase `t mod P` is supplied as a free resource. It is not a claim that periodic clocks, clock-memory tradeoffs, or the qualitative stabilization/termination distinction are new.

## Audit conclusion

The literature checked above materially narrows the wording of the novelty claim, but this audit did **not** identify a result that directly reproduces the central No. 3 tight binary-consensus local-memory theorem or the No. 4 quantitative periodic-phase tradeoff in the same model.

This conclusion is deliberately scoped. A literature audit can reduce prior-art risk but cannot certify novelty.
