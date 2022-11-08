# AUR Release action: Release a new version of a package on the AUR and update the PKGBUILD file and the aur submodule

## Inputs
| Name                         | Description                                                                     | Default                                          |
|------------------------------|---------------------------------------------------------------------------------|--------------------------------------------------|
| `package_name`               | The name in AUR of the package to release if different from the repository name | `{{ github.event.repository.name }}` (Repo name) |
| `git_username`               | The username to use for the git commit                                          | `AUR Release Action`                             |
| `git_email`                  | The email to use for the git commit                                             | `github-action-bot@no-reply.com`                 |
| `ssh_private_key` (Required) | The private SSH key to use to push the changes to the AUR                       |                                                  |
| `pkgbuild_path`              | The path to the PKGBUILD file                                                   | `PKGBUILD`                                       |
| `aur_submodule_path`         | The path to the AUR submodule, if empty the AUR submodule will not be updated   |                                                  |
| `github_token` (Required)    | The GitHub token to use to update the PKGBUILD file and the AUR submodule       |                                                  |

