# AUR Release action: Release a new version of a package on the AUR and update the PKGBUILD file and the aur submodule

## Inputs
| Name                         | Description                                                                                | Default                                          |
|------------------------------|--------------------------------------------------------------------------------------------|--------------------------------------------------|
| `package_name`               | The name in AUR of the package to release if different from the repository name            | `{{ github.event.repository.name }}` (Repo name) |
| `git_username`               | The username to use for the git commit                                                     | `AUR Release Action`                             |
| `git_email`                  | The email to use for the git commit                                                        | `github-action-bot@no-reply.com`                 |
| `ssh_private_key` (Required) | The private SSH key to use to push the changes to the AUR                                  |                                                  |
| `pkgbuild_path`              | The path to the PKGBUILD file                                                              | `PKGBUILD`                                       |
| `update_pkgbuild`            | Whether to update the PKGBUILD file with the new version                                   | `true`                                           |
| `try_build_and_install`      | Whether to try to build and install the package                                            | `true`                                           |
| `aur_submodule_path`         | The path to the AUR submodule, if empty the AUR submodule will not be updated              |                                                  |
| `github_token` (Required)    | The GitHub token to use to update the PKGBUILD file and the AUR submodule                  |                                                  |
| `commit_message`             | The commit message to use for the git commit, it accepts the REGEX (%FILENAME%, %VERSION%) | `Bumb %FILENAME% to %VERSION%`                   |
| `prescript`                  | The script to run before the action makes any changes                                      |                                                  |
| `postscript`                 | The script to run after the action makes changes, and finishes                             |                                                  |

## Example usage
```yaml
name: aur-publish

on:
  push:
    tags:
      - "*"

jobs:
  aur-publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Publish AUR package
        uses: anas-elgarhy/aur-release-action@v3.7
        with:
          package_name: aur-package-name # Optional (default: repository name)
          ssh_private_key: ${{ secrets.AUR_SSH_PRIVATE_KEY }} # The private SSH key to use to push the changes to the AUR
          github_token: ${{ secrets.GITHUB_TOKEN }} # The GitHub token to use to update the PKGBUILD file and the AUR submodule
```
- And you can use tha all arguments in the action like this:
```yaml
name: aur-publish

on:
  push:
    tags:
      - "*"

jobs:
    aur-publish:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v2
    
        - name: Publish AUR package
          uses: anas-elgarhy/aur-release-action@v3.7
          with:
            package_name: aur-package-name # Use this if the package name in AUR is different from the repository name
            ssh_private_key: ${{ secrets.AUR_SSH_PRIVATE_KEY }} # The private SSH key to use to push the changes to the AUR
            github_token: ${{ secrets.GITHUB_TOKEN }} # The GitHub token to use to update the PKGBUILD file and the AUR submodule
            pkgbuild_path: aur/PKGBUILD # Use this if the PKGBUILD file is not in the root directory
            update_pkgbuild: true # Use this if you want to update the PKGBUILD in the main repository
            try_build_and_install: true # Use this if you want to try to build and install the package before publishing
            aur_submodule_path: aur/aur-package-name
            git_username: Anas Elgarhy # Use this if you want to change the git username (recommended)
            git_email: anas.elgarhy.dev@gmail.com # Use this if you want to change the git email (recommended)
            commit_message: UpUp Update %FILENAME% to %VERSION% # Use this if you want to change the commit message
            prescript: echo "Hello World" # Use this if you want to run a script before the action makes any changes, you can pass files also
            postscript: scripts/post.sh # Use this if you want to run a script after the action makes changes, and finishes
```
