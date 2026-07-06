# WhatKey Splits

Frozen development/test split definitions. These files are committed before the
first detector tuning run so model selection cannot adapt to held-out pieces.

## Files

- `when-in-rome-v1.json`: the license-gated When-in-Rome v1 split generated from
  Contrapunctus benchmark commit `b9e011c8cf34c5e76691dcf2c835b8c99ebd9d59` and
  When-in-Rome commit `aa7539f1cf480997a68998405c0783ebf6339c16`.

## Rules

- Development split: tuning, ablation, threshold selection, and model selection.
- Test split: evaluated once per reported result set.
- If a split is wrong, add a new split file and a dated log entry. Do not
  rewrite a split after tuning has begun.
