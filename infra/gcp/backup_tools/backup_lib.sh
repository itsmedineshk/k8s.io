#!/usr/bin/env bash
#
# Copyright 2019 The Kubernetes Authors.
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

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# GCRANE_REF is the commit SHA to use for building the gcrane binary.
# Known-good commit from 2019-11-15
export GCRANE_REF="f8574ec722f4dd4e2703689ea2ffe10c2021adc9"

build_gcrane()
{
    git clone https://github.com/google/go-containerregistry "${GCRANE_CHECKOUT_DIR}"
    pushd "${GCRANE_CHECKOUT_DIR}/cmd/gcrane"
    git reset --hard "${GCRANE_REF}"
    # Build offline from vendored sources.
    go build -mod=vendor
    popd
}

copy_with_date()
{
    local source_gcr_repo
    local backup_gcr_repo
    local timestamp

    if (( $# != 3 )); then
        cat << EOF >&2
copy_with_date: usage <source_gcr_repo> <backup_gcr_repo> <timestamp>
e.g. copy_with_date "us.gcr.io/k8s-artifacts-prod" "us.gcr.io/k8s-artifacts-prod-bak" "2019/01/01/00"
EOF
        exit 1
    fi

    source_gcr_repo="${1}" # "us.gcr.io/k8s-artifacts-prod"
    backup_gcr_repo="${2}" # "us.gcr.io/k8s-artifacts-prod-bak"
    timestamp="${3}" # "2019/01/01/00"

    # Perform backup by copying all images recursively over.
    "${GCRANE_CHECKOUT_DIR}/cmd/gcrane/gcrane" cp -r "${source_gcr_repo}" "${backup_gcr_repo}/${timestamp}"
}

check_creds_exist()
{
    if [[ ! -f "${GOOGLE_APPLICATION_CREDENTIALS}" ]]; then
        echo >&2 "\$GOOGLE_APPLICATION_CREDENTIALS (${GOOGLE_APPLICATION_CREDENTIALS}) does not exist"
        exit 1
    fi
}
