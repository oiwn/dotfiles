# Current Task Context: tasks 0001 (fish tmuxp-init) + 0002 (multi-host kodo) both in approval, awaiting user switch + acceptance

State: in progress

## Context

- Active task: specs/tasks/0002-multihost-kodo.md — implemented and verified (prek + 4 eval checks; bakodo regression-proofed: 27 casks, same primaryUser). In approval. Manual check outstanding: kodo fresh-clone switch (waivable).
- Task 0001 (fish tmuxp-init) also sits in approval — one switch on bakodo activates both.

## Next

User runs `sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)`, checks `type tmuxp-init` in fresh fish, accepts → close both with `specdev task done 0001 0002`. Kodo bootstrap (fresh clone + `switch --flake .#kodo`) whenever the machine is at hand.
