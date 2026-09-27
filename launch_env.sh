#!/usr/bin/env bash

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1

# models get lower priority than ui
# - ui is ~5ms
# - modeld is 20ms
# - DM is 10ms
# in order to run ui at 60fps (16.67ms), we need to allow
# it to preempt the model workloads. we have enough
# headroom for this until ui is moved to the CPU.
export QCOM_PRIORITY=12

if [ -z "$AGNOS_VERSION" ]; then
  # NOTE: this branch shipped with AGNOS_VERSION=16, but that predates the
  # AGNOS 18.1+ / raylib 6.0 bump this UI actually needs (see
  # commaai/openpilot@93ed08ba2 "agnos 18.1.2 + raylib 6.0"). Forcing an
  # "update" to 16 would downgrade this comma 4 onto an AGNOS that doesn't
  # have the raylib/DRM bits this UI relies on. Pin to what's actually
  # installed and known-good instead.
  export AGNOS_VERSION="18.4"
fi

export STAGING_ROOT="/data/safe_staging"
