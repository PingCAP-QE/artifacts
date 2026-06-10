ARG BASE_IMG=ghcr.io/pingcap-qe/bases/tiflash-base:v1.11.3
FROM $BASE_IMG
ENV LD_LIBRARY_PATH=/tiflash
COPY --chmod=755 tiflash /tiflash

# Wrapper at /tiflash/tiflash to keep compatibility with legacy TiFlash deployments
# that hardcode this path. Actual binaries live under
# /tiflash/binaries/{tiflash,tiflash-columnar}/tiflash.
RUN if [ ! -e /tiflash/tiflash ]; then cat > /tiflash/tiflash <<'EOF' && chmod 755 /tiflash/tiflash; fi
#!/usr/bin/env bash
# Copyright 2026 PingCAP, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

TIFLASH_DIR=/tiflash/binaries/tiflash
TIFLASH_COLUMNAR_DIR=/tiflash/binaries/tiflash-columnar

# TIFLASH_COLUMNAR unset or "false" -> classic tiflash under /tiflash/binaries/tiflash.
# "true" -> columnar build under /tiflash/binaries/tiflash-columnar when the binary exists.
tiflash_columnar="${TIFLASH_COLUMNAR:-false}"
tiflash_columnar_lower="$(echo "${tiflash_columnar}" | tr '[:upper:]' '[:lower:]')"

if [ "${tiflash_columnar_lower}" = "true" ] && [ -x "${TIFLASH_COLUMNAR_DIR}/tiflash" ]; then
    export LD_LIBRARY_PATH="${TIFLASH_COLUMNAR_DIR}"
    # exec replaces this shell; lines below are not run on success.
    exec "${TIFLASH_COLUMNAR_DIR}/tiflash" "$@"
fi

# Reached only when columnar mode is off, or columnar binary is missing.
export LD_LIBRARY_PATH="${TIFLASH_DIR}"
exec "${TIFLASH_DIR}/tiflash" "$@"
EOF

# Enable jemalloc profiling, inactive by default.
# See https://jemalloc.net/jemalloc.3.html for details.
ENV MALLOC_CONF="prof:true,prof_active:false"
ENTRYPOINT ["/tiflash/tiflash", "server"]
