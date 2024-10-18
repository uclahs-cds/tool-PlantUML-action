# PlantUML GitHub Action

[![GitHub release](https://img.shields.io/github/v/release/uclahs-cds/tool-PlantUML-action)](https://github.com/uclahs-cds/tool-PlantUML-action/actions/workflows/prepare-release.yaml)

This repository is a GitHub Action that generates UML diagrams (as SVGs) from PlantUML files.

## How to use this action in your repository

This example GitHub Action will cause SVG diagrams to be generated from PUML files when they are committed and pushed the the repository.

```yaml
---
name: PlantUML Generation

on:
  push:
    paths:
      - '**.puml'
  workflow_dispatch:

jobs:
  plantuml:
    runs-on: ubuntu-latest

    steps:
      - name: Generate PUML diagrams
        uses: uclahs-cds/tool-PlantUML-action@v1.0.0
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          ghcr-username: ${{ github.actor }}
          ghcr-password: ${{ secrets.GITHUB_TOKEN }}
```

### Variables

| | |
|-|-|
| `github-token` | A PAT used to commit and push generated and removed SVGs back into the repository. |
| `ghcr-username` | The username used to authenticate with ghcr.io to pull the PlantUML docker image. |
| `ghcr-password` | The password used with `ghcr-username`. |

## Description

When this action is triggered on a branch, it will scan git commits to find the last commit since a push or all commits in a branch, depending on how the Action is triggered. It will look for additions, deletions, and modifications to files ending with the `.puml` extension. Three operations occur following this lookup:

* Deleted `.puml` files remove orphaned `.svg` UML diagrams. This works by matching the `.puml` filename to the `.svg` filename. If the UML diagram was generated with a name using `@startuml` (or any of the other `@start` directives) that does not match the filename, orphaned files will not be found, and thus not removed.
* Added and modified `.puml` files are fed into `plantuml` to generate SVGs
* The added and removed `.svg` files are committed and pushed to the same branch the Action is running for. The commit authors are both the user that triggered the Action and "github-actions[bot]"


## How this works
This action makes heavy use of both `awk` and `bash` constructs that need to be understood to fully grok the inner workings of the action. It is recommended to read the man pages and guides on `awk` and `bash` scripting.

This action attempts to find all PlantUML files that changed or were removed since the last
commit in a branch. The workflow can be triggered from either a push, or manually (or through other means).
If the workflow is triggered by a push, the commits searched are limited to the last commit that was pushed.
If the workflow is triggered through other means, then the range of commits include from when the branch
was first created, up until HEAD.

Once the commit range is discovered, the workflow uses `git diff-tree`, `sed`, and `awk` to parse
the filenames and how they were altered in the commits. The workflow avoids parsing filenames
directly _as much as possible_. As such, the use of null bytes in diff-tree and sed allow
the workflow to isolate what parts of the output are files (and how they changed) without running
into issues with, e.g., spaces, newlines, special characters, or any other unexpected data in
the file names.

To further reduce the need to directly work with the file names, this workflow makes use of
an ad hoc data format that is generated with the use of `awk`. This is done to avoid working
with potentially unsafe data in `bash`.

### Key terms and symbols:

* Header - sections of the data format that specify lengths and positions of file names
* Position - the byte count at which a particular piece of data starts
* Length - the length of the data that starts at the aforementioned position
* Orphaned - SVG files that should be removed when a PUML file is moved or deleted
* Modified - PUML files with changes other than deletion (Added, Modified)
* `>` - separates individual parts of the header
* `:` - separates positional and length information

### The data format

```
A header indicating the length of the combined header and file names for each of the orphaned and modified files.
For each of the orphaned and modified files:
    A header indicating the length of the header for the [orphaned or modified] file names.
    A header indicating the position and lengths of each file name for the [orphaned or modified] files.
    The file names.
File names are specified in the order of orphaned files first, then modified.
```

In the action script you will find shorter examples, but we will document a full example here.
Take this output (the value of $changed_files returns from `awk`).
```
169:538>16>0:44>44:52>96:54docs/models/technician_domain/code/assay.svgdocs/models/technician_domain/code/control_plate.svgdocs/models/technician_domain/code/treatment_plate.svg59>0:51>51:56>107:64>171:48>219:50>269:54>323:45>368:56>424:52docs/models/technician_domain/code/assay_plate.pumldocs/models/technician_domain/code/assay_plate_well.pumldocs/models/technician_domain/code/assay_plate_well_mapping.pumldocs/models/technician_domain/code/compound.pumldocs/models/technician_domain/code/individual.pumldocs/models/technician_domain/code/plate_grouping.pumldocs/models/technician_domain/code/staff.pumldocs/models/technician_domain/code/well_measurement.pumldocs/models/technician_domain/technician_domain.puml
```

---

Breaking this into new lines to go over each part, we end up with:
```
169:538>
16>
0:44>44:52>96:54
docs/models/technician_domain/code/assay.svgdocs/models/technician_domain/code/control_plate.svgdocs/models/technician_domain/code/treatment_plate.svg
59>
0:51>51:56>107:64>171:48>219:50>269:54>323:45>368:56>424:52
docs/models/technician_domain/code/assay_plate.pumldocs/models/technician_domain/code/assay_plate_well.pumldocs/models/technician_domain/code/assay_plate_well_mapping.pumldocs/models/technician_domain/code/compound.pumldocs/models/technician_domain/code/individual.pumldocs/models/technician_domain/code/plate_grouping.pumldocs/models/technician_domain/code/staff.pumldocs/models/technician_domain/code/well_measurement.pumldocs/models/technician_domain/technician_domain.puml
```

---

This part of the header indicates the combined length of the headers and filenames.
- The combined lengths and the remainder of the data are separated by `>`.
- A `:` separated the lengths for the orphaned and modified headers and file names.
```
169:538>
```
For example, the combined length of this string (the orphaned file names) is 169 bytes:
```
16>0:44>44:52>96:54docs/models/technician_domain/code/assay.svgdocs/models/technician_domain/code/control_plate.svgdocs/models/technician_domain/code/treatment_plate.svg
```
The number `538` is the length for the modified files.

---

Following this is the header containing both the length of the header and the lengths and positions of individual file names.
- The header length and the header are separated by `>`.
```
16>
```
For example, the length of the header for the orphaned file names is 16 bytes:
```
0:44>44:52>96:54
```

---

This header then consists of the starting position and the length of each [orphaned] file name.
- Each file name position is separated by `>`.
- The starting byte and length are separated by `:`.
```
0:44
```
This indicates that a file name exists from bytes `0` to `44` (`docs/models/technician_domain/code/assay.svg`).

`44:52` indicates that a file name exists _starting at_ position `44`, with a length of `52` bytes (`docs/models/technician_domain/code/control_plate.svg`). This is followed for each range in the header.

---

This data format is then followed again to process the modified files.

Individual file names are shell-escaped using bash's built-in `printf %q` format specifier.

Once all data has been consumed, the individual file names are output to `$GITHUB_OUTPUT` for use in subsequent jobs.

## License

Author: Aaron Holmes (aholmes@mednet.ucla.edu)

tool-PlantUML-action is licensed under the GNU General Public License version 2. See the file LICENSE.md for the terms of the GNU GPL license.

Generate UML diagrams from PlantUML files.

Copyright (C) 2021 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
