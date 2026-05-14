#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="${ROOT_DIR}/k8s"

usage() {
  cat <<'EOF'
Usage:
  scripts/helm-images.sh list [chart_dir]
  scripts/helm-images.sh package <chart_dir> <amd64|arm64> <output_dir>
EOF
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$command_name" >&2
    exit 1
  fi
}

chart_name_from_dir() {
  basename "$1"
}

normalize_image() {
  local image="$1"
  local last_segment="${image##*/}"

  if [[ "$image" == *@sha256:* ]]; then
    printf '%s\n' "$image"
  elif [[ "$last_segment" == *:* ]]; then
    printf '%s\n' "$image"
  else
    printf '%s:latest\n' "$image"
  fi
}

list_images() {
  local chart_dir="$1"
  local release_name

  if [[ ! -f "${chart_dir}/Chart.yaml" ]]; then
    printf 'chart not found: %s\n' "$chart_dir" >&2
    exit 1
  fi

  release_name="$(chart_name_from_dir "$chart_dir")"

  helm template "$release_name" "$chart_dir" \
    | sed -n 's/^[[:space:]]*image:[[:space:]]*"\{0,1\}\([^"[:space:]]\{1,\}\)"\{0,1\}[[:space:]]*$/\1/p' \
    | while IFS= read -r image; do normalize_image "$image"; done \
    | sort -u
}

package_images() {
  local chart_dir="$1"
  local arch="$2"
  local output_dir="$3"
  local chart_name
  local archive_path
  local image_list_file

  case "$arch" in
    amd64|arm64) ;;
    *)
      printf 'unsupported architecture: %s\n' "$arch" >&2
      exit 1
      ;;
  esac

  chart_name="$(chart_name_from_dir "$chart_dir")"
  archive_path="${output_dir}/${chart_name}-${arch}-images.tar.gz"
  image_list_file="${output_dir}/${chart_name}-${arch}-images.txt"

  mkdir -p "$output_dir"

  mapfile -t images < <(list_images "$chart_dir")
  if [[ ${#images[@]} -eq 0 ]]; then
    printf 'no images found for chart: %s\n' "$chart_name" >&2
    exit 1
  fi

  printf '%s\n' "${images[@]}" > "$image_list_file"

  for image in "${images[@]}"; do
    printf 'Pulling %s for linux/%s\n' "$image" "$arch"
    docker pull --platform "linux/${arch}" "$image"
  done

  docker save "${images[@]}" | gzip -c > "$archive_path"

  for image in "${images[@]}"; do
    docker image rm "$image" >/dev/null 2>&1 || true
  done

  printf 'Created %s\n' "$archive_path"
}

main() {
  local subcommand="${1:-}"

  case "$subcommand" in
    list)
      require_command helm
      if [[ $# -eq 2 ]]; then
        list_images "$2"
      else
        for chart_dir in "${K8S_DIR}"/*; do
          [[ -f "${chart_dir}/Chart.yaml" ]] || continue
          printf '[%s]\n' "$(chart_name_from_dir "$chart_dir")"
          list_images "$chart_dir"
          printf '\n'
        done
      fi
      ;;
    package)
      require_command helm
      require_command docker
      if [[ $# -ne 4 ]]; then
        usage
        exit 1
      fi
      package_images "$2" "$3" "$4"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
