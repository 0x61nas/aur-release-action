#!/bin/bash

set -o errexit -o pipefail -o nounset

source /src/utils.sh

NEW_RELEASE=${GITHUB_REF##*/v}
NEW_RELEASE=${NEW_RELEASE##*/}

export HOME=/home/builder

# Run pre script
if [[ -n "${INPUT_PRESCRIPT}" ]]; then
  echo "::group::Running pre script"
  echo "Running pre script"
  eval "${INPUT_PRESCRIPT}"
  echo "::endgroup::Running pre script"
fi

echo "::group::Setup"
source /src/setup.sh
echo "::endgroup::Setup"

echo "::group::Build"
source /src/build.sh
echo "::endgroup::Build"

source /src/commit.sh

# Run post script
if [[ -n "${INPUT_POSTSCRIPT}" ]]; then
  cd "$GITHUB_WORKSPACE"
  echo "::group::Running post script"
  echo "Running post script"
  eval "${INPUT_POSTSCRIPT}"
  echo "::endgroup::Running post script"
fi
