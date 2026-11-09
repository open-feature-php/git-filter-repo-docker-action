FROM docker.io/library/python:3.15-alpine

ARG GIT_FILTER_REPO_VERSION=2.47.0

RUN apk upgrade --no-cache && \
    apk add --no-cache bash git git-fast-import openssh

RUN pip3 install --no-cache-dir "git-filter-repo==${GIT_FILTER_REPO_VERSION}"

# T314987: Git require the .git folder to be owned by the same user
RUN git config --system --add safe.directory /github/workspace

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
