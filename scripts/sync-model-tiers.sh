#!/usr/bin/env bash
set -euo pipefail

readonly begin_marker='<!-- BEGIN GENERATED MODEL-TIER POLICY -->'
readonly end_marker='<!-- END GENERATED MODEL-TIER POLICY -->'
readonly repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly canonical="$repo_root/MODEL_TIERS.md"
readonly targets=(
  "$repo_root/plan-task/SKILL.md"
  "$repo_root/pr-triage/SKILL.md"
  "$repo_root/README.md"
)

check_only=0
case "${1:-}" in
  "")
    ;;
  --check)
    check_only=1
    ;;
  *)
    printf 'usage: %s [--check]\n' "${0##*/}" >&2
    exit 2
    ;;
esac

if [ ! -f "$canonical" ]; then
  printf 'error: canonical model-tier policy not found: %s\n' "$canonical" >&2
  exit 1
fi

policy_file=''
temporary_files=()

cleanup() {
  [ -z "$policy_file" ] || rm -f "$policy_file"
  for temporary_file in "${temporary_files[@]-}"; do
    [ -z "$temporary_file" ] || rm -f "$temporary_file"
  done
}
trap cleanup EXIT HUP INT TERM

validate_markers() {
  local file=$1

  if ! awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin {
      if (inside || ++begins > 1) {
        exit 1
      }
      inside = 1
    }
    $0 == end {
      if (!inside || ++ends > 1) {
        exit 1
      }
      inside = 0
    }
    END {
      exit begins != 1 || ends != 1 || inside
    }
  ' "$file"; then
    printf 'error: expected one well-formed model-tier marker pair in %s\n' "$file" >&2
    exit 1
  fi
}

render_target() {
  local target=$1
  local output=$2

  awk -v begin="$begin_marker" -v end="$end_marker" -v policy="$policy_file" '
    BEGIN {
      while ((getline line < policy) > 0) {
        replacement = replacement line ORS
      }
      close(policy)
    }
    $0 == begin {
      printf "%s", replacement
      inside = 1
      next
    }
    inside {
      if ($0 == end) {
        inside = 0
      }
      next
    }
    {
      print
    }
  ' "$target" > "$output"
}

validate_markers "$canonical"
policy_file="$(mktemp "${TMPDIR:-/tmp}/sync-model-tiers.policy.XXXXXX")"
awk -v begin="$begin_marker" -v end="$end_marker" '
  $0 == begin {
    inside = 1
  }
  inside {
    print
  }
  $0 == end {
    inside = 0
  }
' "$canonical" > "$policy_file"

for target in "${targets[@]}"; do
  if [ ! -f "$target" ]; then
    printf 'error: model-tier consumer not found: %s\n' "$target" >&2
    exit 1
  fi
  validate_markers "$target"
done

outputs=()
out_of_sync=0
for target in "${targets[@]}"; do
  output="$(mktemp "${TMPDIR:-/tmp}/sync-model-tiers.target.XXXXXX")"
  temporary_files+=("$output")
  outputs+=("$output")
  render_target "$target" "$output"
  if ! cmp -s "$target" "$output"; then
    printf '%s: model-tier policy is out of sync\n' "${target#"$repo_root"/}" >&2
    out_of_sync=1
  fi
done

if [ "$check_only" -eq 1 ]; then
  if [ "$out_of_sync" -ne 0 ]; then
    exit 1
  fi
  printf 'Model-tier consumers are in sync.\n'
  exit 0
fi

if [ "$out_of_sync" -eq 0 ]; then
  printf 'Model-tier consumers are already in sync.\n'
  exit 0
fi

for index in "${!targets[@]}"; do
  mv "${outputs[$index]}" "${targets[$index]}"
done
temporary_files=()
printf 'Synchronized model-tier consumers.\n'
