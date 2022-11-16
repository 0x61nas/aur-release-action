#!/bin/bash

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

