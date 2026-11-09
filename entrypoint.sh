#!/bin/bash
set -e

# Authenticate over HTTPS with a token (e.g. a GitHub App installation token)
# without writing it to the repository config or passing it on the command line.
configure_token_auth() {
    local basic
    basic=$(printf 'x-access-token:%s' "$TARGET_TOKEN" | base64 | tr -d '\n')
    echo "::add-mask::$basic"

    # Config supplied via GIT_CONFIG_* is applied after the repository config.
    # The empty value clears any extraheader persisted by actions/checkout, so
    # only this token is sent to github.com.
    export GIT_CONFIG_COUNT=2
    export GIT_CONFIG_KEY_0="http.https://github.com/.extraheader"
    export GIT_CONFIG_VALUE_0=""
    export GIT_CONFIG_KEY_1="http.https://github.com/.extraheader"
    export GIT_CONFIG_VALUE_1="AUTHORIZATION: basic $basic"
}

configure_ssh_auth() {
    ssh-keyscan -t rsa github.com >> /etc/ssh/ssh_known_hosts
    eval "$(ssh-agent -s)"
    ssh-add - <<< "$SSH_PRIVATE_KEY"
}

if [ -n "$TARGET_TOKEN" ]; then
    if [ -n "$SSH_PRIVATE_KEY" ]; then
        echo "::warning::Both token and privateKey were provided; using token."
    fi
    TARGET_URL="https://github.com/$TARGET_ORG/$TARGET_REPO.git"
    configure_token_auth
elif [ -n "$SSH_PRIVATE_KEY" ]; then
    TARGET_URL="git@github.com:$TARGET_ORG/$TARGET_REPO.git"
    configure_ssh_auth
else
    echo "::error::Either the token or the privateKey input is required."
    exit 1
fi

# workaround! tag-callback doesn't appear to be dropping commits as intended.
if [ -n "$TAG_FILTER" ]; then
    git tag --list \
        | grep -v -E "$TAG_FILTER" \
        | sed -E 's#^#delete refs/tags/#g' \
        | git update-ref --no-deref --stdin
fi

# split single parameter of this script into multiple params for the command
eval "set -- $1"
git-filter-repo "$@"

# triage data
echo "git tags found:"
git tag --list

# push to the target branch
if [ -n "$TARGET_BRANCH" ]; then
    git push "$TARGET_URL" HEAD:"$TARGET_BRANCH"
else
    # push all tags
    git remote add origin "$TARGET_URL"
    git fetch --all
    git push origin --tags
fi
