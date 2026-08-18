#!/bin/sh
set -eu

ROOT="$1"
EVIDENCE="$2"
HELPER="$ROOT/skills/sops-age/scripts/sops-safe.sh"
export PATH="$EVIDENCE/fakebin:/usr/bin:/bin"

printf '$ sops-safe.sh probe\n'
"$HELPER" probe

printf '\n$ sops-safe.sh detect-age-identity (operator-managed file)\n'
SOPS_AGE_KEY_FILE="$EVIDENCE/operator-key.txt" "$HELPER" detect-age-identity

printf '\n$ sops-safe.sh with-age-key file ... -- sops --decrypt secret.enc.yaml\n'
decrypt_output=$("$HELPER" with-age-key file "$EVIDENCE/operator-key.txt" -- sops --decrypt secret.enc.yaml)
printf 'exit=0 decrypted_stdout_bytes=%s\n' "${#decrypt_output}"

printf '\n$ sops-safe.sh with-age-key bws project-fixture -- sops --decrypt secret.enc.yaml\n'
decrypt_output=$("$HELPER" with-age-key bws project-fixture -- sops --decrypt secret.enc.yaml)
printf 'exit=0 decrypted_stdout_bytes=%s\n' "${#decrypt_output}"

printf '\n$ sops-safe.sh with-age-key file ... -- env sops --decrypt secret.enc.yaml\n'
set +e
refusal_output=$("$HELPER" with-age-key file "$EVIDENCE/operator-key.txt" -- env sops --decrypt secret.enc.yaml 2>&1)
refusal_rc=$?
set -e
printf 'exit=%s\n' "$refusal_rc"
printf '%s\n' "$refusal_output" | sed -n '1p'
