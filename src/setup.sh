#!/bin/bash

echo "Creating release $NEW_RELEASE"

echo "Getting AUR SSH Public keys"
ssh-keyscan aur.archlinux.org >> $HOME/.ssh/known_hosts

echo "Writing SSH Private keys to file"
echo -e "${INPUT_SSH_PRIVATE_KEY//_/\\n}" >$HOME/.ssh/aur

chmod 600 $HOME/.ssh/aur*

echo "Setting up Git"
sudo git config --global user.name "$INPUT_GIT_USERNAME"
sudo git config --global user.email "$INPUT_GIT_EMAIL"

# Add github token to the git credential helper
sudo git config --global core.askPass /src/cred-helper.sh
sudo git config --global credential.helper cache

# Add the working directory as a save directory
sudo git config --global --add safe.directory /github/workspace

REPO_URL="ssh://aur@aur.archlinux.org/${INPUT_PACKAGE_NAME}.git"

# Make the working directory
mkdir -p /tmp/package

# Copy the PKGBUILD file into the working directory
cp "$GITHUB_WORKSPACE/$INPUT_PKGBUILD_PATH" /tmp/package/PKGBUILD

echo "Changing directory from $PWD to $HOME/package"
cd /tmp/package
