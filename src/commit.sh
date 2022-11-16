#!/bin/bash

echo "::group::Commit"

cd "$INPUT_PACKAGE_NAME"

echo "Push the new PKGBUILD and .SRCINFO files to the AUR repo"
git add PKGBUILD .SRCINFO
commit "$(generate_commit_message "" "$NEW_RELEASE")"
git push

if [[ "$INPUT_UPDATE_PKGBUILD" != "true" || -z "$INPUT_AUR_SUBMODULE_PATH" ]]; then
    echo "Skipping submodule update and PKGBUILD update"
    echo "::endgroup::Commit"
    exit
fi

echo "::group::Commit::Main_repo"

echo "The available branches are:"
git branch -a

echo "The current branch is: $(git branch --show-current)"

echo "Checkout to the temporary branch"
temp_branch="update_${INPUT_PACKAGE_NAME}_to_${NEW_RELEASE}"

sudo git checkout -b $temp_branch

cd "$GITHUB_WORKSPACE"

if [[ "$INPUT_UPDATE_PKGBUILD" == "true" ]]; then
    echo "Update the PKGBUILD file in the main repo"
    sudo cp /tmp/package/PKGBUILD "$INPUT_PKGBUILD_PATH"
    sudo git add "$INPUT_PKGBUILD_PATH"
    commit "$(generate_commit_message 'PKGBUILD' "$NEW_RELEASE")"
fi

if [[ -n "${INPUT_AUR_SUBMODULE_PATH}" ]]; then
    echo "Updating submodule"
    sudo git submodule update --init "$INPUT_AUR_SUBMODULE_PATH"
    sudo git add "$INPUT_AUR_SUBMODULE_PATH"
    commit "$(generate_commit_message 'submodule' "$NEW_RELEASE")"
else
    echo "No submodule path provided, skipping submodule update"
fi

echo "::endgroup::Commit::Main_repo"

echo "::endgroup::Commit"

echo "::group::Push"
sudo git checkout master
sudo git merge $temp_branch
sudo git push origin master
echo "::endgroup::Push"

