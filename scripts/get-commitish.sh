#!/bin/bash
set -o pipefail

GITHUB_EVENT_BEFORE=$1
GITHUB_SHA=$2

# create file descriptor 9 to shortcut redirection to STDERR
exec 9>&2

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
  PARENT_BRANCH_SHA=`git --no-pager log --decorate | awk '$1 ~ /^commit/ && $2 ~ /[a-z0-9]+/ && $3 ~ /\(origin/{printf $2;exit}' || (exit_code=$?; [ $exit_code -eq 141 ] && : || exit $exit_code)`
  COMMITISH="$PARENT_BRANCH_SHA..HEAD"
else
  echo Workflow was triggered by a push event. >&9
  echo Detected PUML files will contain only PUML files committed since the previous push. >&9
  COMMITISH="$GITHUB_EVENT_BEFORE..$GITHUB_SHA"
fi

# TODO remove this - for testing
#COMMITISH=0dc2e225ea889cb40deac752d20099cc5400d252..HEAD
echo Detected range of relevant commits are $COMMITISH >&9
# this is an output of the action step
echo -n $COMMITISH