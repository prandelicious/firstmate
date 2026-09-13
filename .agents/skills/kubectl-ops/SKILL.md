---
name: kubectl-ops
description: >-
  Agent-only load stub for safe kubectl and K3s operations.
  Use before any `kubectl` operation: applying or deleting resources, `kubectl cp`, exec into pods, scaling, draining, or any operation that reads or changes cluster state.
  The procedure lives in the iafk project at `.agents/skills/kubectl-ops/SKILL.md` (reachable in this home under `projects/iafk/`); read and follow that file completely after loading this stub.
user-invocable: false
metadata:
  internal: true
---

# kubectl-ops

This stub exists because firstmate loads skills from `.agents/skills/`, while the authoritative procedure lives in the iafk project at `.agents/skills/kubectl-ops/SKILL.md`.
In this home that procedure is the clone under `projects/iafk/`.

After this stub loads, read and follow that file completely.
Never treat this stub as the procedure owner.
