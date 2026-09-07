#!/usr/bin/env python3
"""Finite arithmetic audit for the binary-consensus termination papers.

This script is computational evidence only; it is not a proof.
It uses the finite bound formulas stated in the manuscripts and emits CSV tables
that make thresholds, monotonicity, and off-by-one behavior inspectable.
"""

from __future__ import annotations

import csv
import math
from pathlib import Path

OUT = Path(__file__).resolve().parent


def ceil_div(a: int, b: int) -> int:
    return (a + b - 1) // b


def clockless_known_d(D: int) -> tuple[int, int]:
    # Published v1 clockless bounds.
    return math.ceil(D / 2) + 1, 2 * (D + 1)


def clockless_known_n(n: int) -> tuple[int, int]:
    # Published v1 clockless bounds for n >= 4.
    return (n + 2) // 4 + 1, 2 * n


def phase_known_d(D: int, P: int) -> tuple[int, int]:
    # Published v2 state--phase bounds.
    lb = max(3, ceil_div(math.ceil(D / 2) + 1, P))
    ub = ceil_div(D, P) + 2
    return lb, ub


def phase_known_n(n: int, P: int) -> tuple[int, int]:
    # Published v2 state--phase bounds.
    lb = max(3, ceil_div((n + 2) // 4 + 1, P))
    ub = ceil_div(n - 1, P) + 2
    return lb, ub


def write_clockless() -> None:
    path = OUT / "clockless_finite_table.csv"
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["parameter", "value", "lower_states", "upper_states", "lower_bits", "upper_bits"])
        for D in range(1, 41):
            lo, hi = clockless_known_d(D)
            w.writerow(["D", D, lo, hi, math.ceil(math.log2(lo)), math.ceil(math.log2(hi))])
        for n in range(4, 41):
            lo, hi = clockless_known_n(n)
            w.writerow(["n", n, lo, hi, math.ceil(math.log2(lo)), math.ceil(math.log2(hi))])


def write_phase() -> None:
    path = OUT / "state_phase_finite_table.csv"
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["regime", "parameter", "P", "lower_states", "upper_states", "gap"])
        for D in range(1, 41):
            prev_hi = None
            for P in range(1, 17):
                lo, hi = phase_known_d(D, P)
                assert lo <= hi
                if prev_hi is not None:
                    assert hi <= prev_hi
                prev_hi = hi
                w.writerow(["known_D", D, P, lo, hi, hi - lo])
        for n in range(4, 41):
            prev_hi = None
            for P in range(1, 17):
                lo, hi = phase_known_n(n, P)
                assert lo <= hi
                if prev_hi is not None:
                    assert hi <= prev_hi
                prev_hi = hi
                w.writerow(["known_n", n, P, lo, hi, hi - lo])


def main() -> None:
    write_clockless()
    write_phase()
    print("PASS_FINITE_STATE_PHASE_AUDIT")
    print("clockless_finite_table.csv")
    print("state_phase_finite_table.csv")


if __name__ == "__main__":
    main()
