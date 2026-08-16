#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${repo_root}/build"

if ! command -v iverilog >/dev/null 2>&1; then
  echo "error: iverilog is required" >&2
  exit 127
fi

mkdir -p "${build_dir}"

iverilog \
  -g2012 \
  -Wall \
  -s tb_mem_controller \
  -o "${build_dir}/mem_controller_sim" \
  "${repo_root}/rtl/mem_controller.sv" \
  "${repo_root}/tb/tb_mem_controller.sv"

(
  cd "${build_dir}"
  vvp ./mem_controller_sim | tee rtl-simulation.log
)

grep -q "ALL TESTS PASSED" "${build_dir}/rtl-simulation.log"
