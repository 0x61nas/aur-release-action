#!/bin/bash

set -o errexit -o pipefail -o nounset

source /utils.sh

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

echo "Creating release $NEW_RELEASE"

echo "Getting AUR SSH Public keys"
ssh-keyscan aur.archlinux.org >>$HOME/.ssh/known_hosts

echo "Writing SSH Private keys to file"
echo -e "${INPUT_SSH_PRIVATE_KEY//_/\\n}" >$HOME/.ssh/aur

chmod 600 $HOME/.ssh/aur*

echo "Setting up Git"
git config --global user.name "$INPUT_GIT_USERNAME"
git config --global user.email "$INPUT_GIT_EMAIL"

# Add github token to the git credential helper
git config --global core.askPass /cred-helper.sh
git config --global credential.helper cache

# Add the working directory as a save directory
git config --global --add safe.directory /github/workspace

REPO_URL="ssh://aur@aur.archlinux.org/${INPUT_PACKAGE_NAME}.git"

# Make the working directory
mkdir -p $HOME/package

# Copy the PKGBUILD file into the working directory
cp "$GITHUB_WORKSPACE/$INPUT_PKGBUILD_PATH" $HOME/package/PKGBUILD

echo "Changing directory from $PWD to $HOME/package"
cd $HOME/package

echo "::endgroup::Setup"

echo "::group::Build"

echo "::group::Build::Prepare"
echo "Current directory: $(pwd)"

echo "Update the PKGBUILD with the new version [${NEW_RELEASE}]"
sed -i "s/^pkgver.*/pkgver=${NEW_RELEASE}/g" PKGBUILD
sed -i "s/^pkgrel.*/pkgrel=1/g" PKGBUILD

echo "Update the PKGBUILD with the new checksums"
updpkgsums
echo "new_sha256sums=$(grep sha256sums PKGBUILD)"

echo "The new PKGBUILD is:"
cat PKGBUILD

echo "::endgroup::Build::Prepare"

echo "Make the .SRCINFO file"
makepkg --printsrcinfo >.SRCINFO
echo "The new .SRCINFO is:"
cat .SRCINFO

if [[ "${INPUT_TRY_BUILD_AND_INSTALL}" == "true" ]]; then
  echo "::group::Build::Install"
  echo "Try building the package"
  makepkg --syncdeps --noconfirm --cleanbuild --rmdeps --install
  echo "::endgroup::Build::Install"
fi

echo "Clone the AUR repo [${REPO_URL}]"
git clone "$REPO_URL"

echo "Copy the new PKGBUILD and .SRCINFO files into the AUR repo"
cp -f PKGBUILD .SRCINFO "$INPUT_PACKAGE_NAME/"

echo "::endgroup::Build"

echo "::group::Commit"

cd "$INPUT_PACKAGE_NAME"

echo "Push the new PKGBUILD and .SRCINFO files to the AUR repo"
git add PKGBUILD .SRCINFO
commit "$(generate_commit_message "" "$NEW_RELEASE")"
git push

if [[ "$INPUT_UPDATE_PKGBUILD" == "true" || -n "$INPUT_AUR_SUBMODULE_PATH" ]]; then
  echo "::group::Commit::Update main repo"

  if [[ -z "${INPUT_AUR_SUBMODULE_PATH}" ]]; then
    echo "No submodule path provided, skipping submodule update"
  else
    echo "Updating submodule"
    cd "$GITHUB_WORKSPACE"
    sudo git submodule update --init "$INPUT_AUR_SUBMODULE_PATH"
    sudo git add "$INPUT_AUR_SUBMODULE_PATH"
    sudo commit "$(generate_commit_message 'submodule' "$NEW_RELEASE")"
  fi

  if [[ "$INPUT_UPDATE_PKGBUILD" == "true" ]]; then
    echo "Update the PKGBUILD file in the main repo"
    cd "$GITHUB_WORKSPACE"
    cp $HOME/package/PKGBUILD "$INPUT_PKGBUILD_PATH"
    sudo git add "$INPUT_PKGBUILD_PATH"
    sudo commit "$(generate_commit_message 'PKGBUILD' "$NEW_RELEASE")"
  fi

  echo "::endgroup::Commit::Update main repo"

  echo "::endgroup::Commit"

  echo "::group::Push"
  git push
  echo "::endgroup::Push"
else
  echo "Skipping submodule update and PKGBUILD update"
  echo "::endgroup::Commit"
fi

# Run post script
if [[ -n "${INPUT_POSTSCRIPT}" ]]; then
  cd "$GITHUB_WORKSPACE"
  echo "::group::Running post script"
  echo "Running post script"
  eval "${INPUT_POSTSCRIPT}"
  echo "::endgroup::Running post script"
fi
