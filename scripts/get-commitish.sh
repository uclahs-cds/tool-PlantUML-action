#!/bin/bash
set -o pipefail
set +o histexpand
shopt -s expand_aliases

GITHUB_EVENT_BEFORE=$1
GITHUB_SHA=$2

# create file descriptor 9 to shortcut redirection to STDERR
exec 9>&2

alias select_sha='awk '"'"'$2 ~ /\(origin/{printf $1;exit}'"'"' || (exit_code=$?; [ $exit_code -eq 141 ] && : || exit $exit_code)'

echo Searching branch for new PUML files ... >&9
echo Previous commit SHA: "'$GITHUB_EVENT_BEFORE'" >&9
echo Current SHA: "'$GITHUB_SHA'" >&9
if [[ "$GITHUB_EVENT_BEFORE" == "" || "$GITHUB_EVENT_BEFORE" == "0000000000000000000000000000000000000000" ]]; then
  echo Workflow was triggered from a non-push event. >&9
  echo Detected PUML files will contain all PUML files in the branch that differ from the parent branch. >&9

  # If the exit code of the pipeline is 141, that means awk exited
  # before git did. This is expected, as awk explicitly exits on the
  # first match we want to print. The last part of this command traps
  # that exit code and ignores it, while letting other exit codes
  # fail the shell command.
  PARENT_BRANCH_SHA=`git --no-pager log --pretty=oneline --decorate | select_sha`
  COMMITISH="$PARENT_BRANCH_SHA..HEAD"
else
  echo Workflow was triggered by a push event. >&9
  echo Detected PUML files will contain only PUML files committed since the previous push. >&9

  # It's possible this event was triggered by a rebase
  # followed by a push, in which case the "before"  SHA
  # is invalid. This selects the new "parent" SHA.
  if ! git branch "$GITHUB_SHA" --contains "$GITHUB_EVENT_BEFORE" > /dev/null 2>&1; then
    echo Detected invalid previous commit SHA. Determining new parent SHA ... >&9
    GITHUB_EVENT_BEFORE=`git --no-pager log -g --pretty=oneline --decorate | select_sha`
  fi

  COMMITISH="$GITHUB_EVENT_BEFORE..$GITHUB_SHA"
fi

echo Detected range of relevant commits are $COMMITISH >&9
# this is an output of the action step
echo -n $COMMITISH