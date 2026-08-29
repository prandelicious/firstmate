# Container cleanup
If your task starts containers (or comparable disposable local infrastructure, such as a scratch database), name each one `fm-evidence-task-...`.
Check for a running `fm-*` container another live task owns before you start one, and reuse it instead of starting a duplicate.
Stop and remove every container you started before you report done.

