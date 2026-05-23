# Git Mirror

GitHub Action to mirror a repository via SSH with verified host keys.

## Features

- **True Mirror:** Always mirrors all branches and tags, including deletions and force pushes.
- **Security:** Hardcoded public keys for major providers. No "Trust on First Use" (TOFU) by default.
- **Pure Shell:** Zero dependencies, no Docker, no JavaScript.

## Usage

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0 # Required for a true mirror

- uses: run-action/mirror-repo@v1
  with:
    target_url: "git@codeberg.org:user/repo.git"
    ssh_key: ${{ secrets.SSH_KEY }}
```

## Inputs

| Input        | Description                                       | Default |
| ------------ | ------------------------------------------------- | ------- |
| `target_url` | **Required** SSH URL of the mirror repository.    |         |
| `ssh_key`    | **Required** Private SSH key.                     |         |
| `lfs`        | Mirror LFS objects.                               | `false` |
| `strict`     | Enforce strict host key checking.                 | `true`  |
| `host_keys`  | Additional SSH host keys in `known_hosts` format. |         |

## Security

This action prevents MITM attacks by verifying host keys against a list of known-good keys before pushing. Set `strict: false` to allow unknown hosts while still verifying known ones.
