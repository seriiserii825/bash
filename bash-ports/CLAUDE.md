# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A bash utility library for detecting web project types and handling port assignments. Intended to be sourced into larger shell scripts, not run directly.

## Architecture

- **`getProjectType.sh`** — exports `getProjectType()`. Detects project type (`vue`, `react`, `nuxt`, `next`, `wordpress`) by checking for `functions.php` (WordPress) or grepping `package.json`. Must be run from the project root. Exits with error if `package.json` is missing.
- **`p.sh`** — exports `portsHandler()`. Sources/depends on `getProjectType()` and dispatches on its output via a `case` statement.
- **`ports.csv`** — CSV registry of port-to-project mappings (`port,project` header).
- **`project_type.csv`** — CSV registry of type-to-file mappings (`type,files` columns), listing which config files are associated with each project type.

## Usage pattern

These files are shell function libraries — source them into other scripts:

```bash
source /path/to/getProjectType.sh
source /path/to/p.sh
portsHandler
```

## Extending project types

To add a new project type (e.g. `svelte`):
1. Add it to the `types` array in `getProjectType.sh`
2. Add a case branch in `p.sh`'s `portsHandler()`
3. Add a row to `project_type.csv` listing its associated config files
