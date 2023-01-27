# PlantUML GitHub Action

This repository is a GitHub Action that generates UML diagrams (as SVGs) from PlantUML files.

## Description

When this action is triggered on a branch, it will scan git commits to find the last commit since a push or all commits in a branch, depending on how the Action is triggered. It will look for additions, deletions, and modifications to files ending with the `.puml` extension. Three operations occur following this lookup:

* Deleted `.puml` files remove orphaned `.svg` UML diagrams. This works by matching the `.puml` filename to the `.svg` filename. If the UML diagram was generated with a name using `@startuml` (or any of the other `@start` directives) that does not match the filename, orphaned files will not be found, and thus not removed.
* Added and modified `.puml` files are fed into `plantuml` to generate SVGs
* The added and removed `.svg` files are committed and pushed to the same branch the Action is running for. The commit authors are both the user that triggered the Action and "github-actions[bot]"

## License

Author: Aaron Holmes (aholmes@mednet.ucla.edu)

tool-PlantUML-action is licensed under the GNU General Public License version 2. See the file LICENSE.md for the terms of the GNU GPL license.

Generate UML diagrams from PlantUML files.

Copyright (C) 2021 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.