#!/bin/bash
set -o pipefail

git diff-tree -z -r --no-commit-id --name-status $COMMITISH \*.puml `# get all changed PUML files and output w/ binary separators` \
| sed -z 's/\n/\\n/g;s/ /\\ /g;s/\.puml$/.puml\n/' `# replace all newlines in filenames with literals; replace all spaces in filenames with literals; replace the end of each changed file with a newline` \
| sed 's/^\x0//g' # remove all null characters at the start of each filename