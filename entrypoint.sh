#!/bin/bash

set -o errexit -o pipefail -o nounset

NEW_RELEASE=${GITHUB_REF##*/v}
NEW_RELEASE=${NEW_RELEASE##*/}

export HOME=/home/builder

echo "::group::Setup"

echo "Creating release $NEW_RELEASE"

echo "Getting AUR SSH Public keys"
ssh-keyscan aur.archlinux.org >> $HOME/.ssh/known_hosts

echo "Writing SSH Private keys to file"
echo -e "${INPUT_SSH_PRIVATE_KEY//_/\\n}" > $HOME/.ssh/aur

chmod 600 $HOME/.ssh/aur*

echo "Setting up Git"
git config --global user.name "$INPUT_GIT_USERNAME"
git config --global user.email "$INPUT_GIT_EMAIL"

# Add github token to the git credential helper
git config --global core.askPass /cred-helper.sh
git config --global credential.helper cache

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

echo "Clone the AUR repo [${REPO_URL}]"
git clone "$REPO_URL"

echo "Building and installing dependencies"
makepkg --noconfirm -s -c

echo "Make the .SRCINFO file"
makepkg --printsrcinfo > .SRCINFO
echo "The new .SRCINFO is:"
cat .SRCINFO

echo "Copy the new PKGBUILD and .SRCINFO files into the AUR repo"
cp PKGBUILD .SRCINFO "$INPUT_PACKAGE_NAME/"

echo "::endgroup::Build"

echo "::group::Commit"

cd "$INPUT_PACKAGE_NAME"

echo "Push the new PKGBUILD and .SRCINFO files to the AUR repo"
git add PKGBUILD .SRCINFO
git commit --allow-empty -m "$(generate_commit_message "" "$NEW_RELEASE")"
git push

if [[ -z "${INPUT_SUBMODULE_PATH}" ]]; then
  echo "No submodule path provided, skipping submodule update"
else
  echo "Updating submodule"
  cd "$GITHUB_WORKSPACE"
  git submodule update --remote "$INPUT_SUBMODULE_PATH"
  git add "$INPUT_SUBMODULE_PATH"
  git commit --allow-empty -m "$(generate_commit_message "submodule" "$NEW_RELEASE")"
  git push
fi

echo "Update the PKGBUILD file in the main repo"
cd "$GITHUB_WORKSPACE"
cp $HOME/package/PKGBUILD "$INPUT_PKGBUILD_PATH"
git add "$INPUT_PKGBUILD_PATH"
git commit -m "$(generate_commit_message "PKGBUILD" "$NEW_RELEASE")"
git push

echo "::endgroup::Commit"

function generate_commit_message {
  local file_name=$1
  local new_version=$2

  echo "${INPUT_COMMIT_MESSAGE}" > /tmp/commit_message

  sed -i "s/%VERSION%/${new_version}/g" /tmp/commit_message

  FILENAME_REGEX="%FILENAME%"
  if [[ -z "$file_name" ]]; then
    FILENAME_REGEX="%FILENAME% "
  fi
  sed -i "s/${FILENAME_REGEX}/${file_name}/g" /tmp/commit_message

  # shellcheck disable=SC2005
  echo "$(cat /tmp/commit_message)"
}
