# git-filter-repo-docker-action
A GitHub Docker Action to run git-filter-repo and push the result to a GitHub repository using a token or ssh

This repo contains a github action to trigger a custom git-repo-filter command.

It is designed to be run on pushes to the main or master branch of a repository
and to then push the resulting filtered repo to another remote.

# Authentication

Provide one of:

- `token`: pushes over HTTPS. Recommended: use a GitHub App installation token
  minted per run with [`actions/create-github-app-token`](https://github.com/actions/create-github-app-token),
  scoped to the target repository with `contents: write`. The token is sent as an
  HTTP header supplied through environment config, so it is never written to the
  repository's git config, and any credentials persisted by `actions/checkout`
  are ignored for the push.
- `privateKey`: pushes over SSH with the given private key (e.g. a deploy key
  with write access on the target repository).

If both are set, `token` is used.

# Example Workflow
```
name: CI
on:
  push:
    branches: [ master ]

jobs:
  filter:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v7
      with:
        fetch-depth: 0
    - uses: actions/create-github-app-token@v3
      id: app-token
      with:
        client-id: ${{ vars.APP_CLIENT_ID }}
        private-key: ${{ secrets.APP_PRIVATE_KEY }}
        owner: wikimedia
        repositories: wikibase-changes
        permission-contents: write
    - name: git-filter-repo
      uses: wmde/git-filter-repo-docker-action@v1
      with:
        token: ${{ steps.app-token.outputs.token }}
        targetOrg: wikimedia
        targetRepo: wikibase-changes
        targetBranch: main
        filterArguments: >-
          --path=lib/includes/changes/
          --path=lib/includes/Changes/
          --path=lib/tests/phpunit/changes/
          --path=lib/tests/phpunit/Changes/
          --path lib/packages/wikibase/changes/
          --path .mailmap
          --path-rename=lib/includes/changes:src
          --path-rename=lib/includes/Changes:src
          --path-rename=lib/tests/phpunit/changes:tests
          --path-rename=lib/tests/phpunit/Changes:tests
          --path-rename lib/packages/wikibase/changes/:
          --message-callback 'return re.sub(b"^changes: ", b"", message)'
```
