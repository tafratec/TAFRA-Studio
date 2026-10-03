# 05 - Project Understanding

Phase 1 teaches TAFRA Studio to safely understand an existing TAFRA Framework
project. The first Phase 2 Analyzer milestone builds on that by classifying the
project and creating a recursive relevant file inventory.

The scanner and validation flow must remain read-only toward the opened project.

## Expected TAFRA Structure

Basic Phase 1 validation checks for:

```text
public
app
app/bootstrap
app/config
app/core
app/modules
```

Missing expected directories are reported as validation issues.

## Internal Model

The internal project model is independent from UI controls.

```text
TTAFRAProject
`-- TTAFRAModule
    `-- TTAFRASubmodule
        |-- Controllers
        |-- Models
        |-- Services
        |-- Views
        |-- Routes
        `-- Assets
```

Implemented model classes:

- `TTAFRAProject`
- `TTAFRAModule`
- `TTAFRASubmodule`
- `TTAFRAProjectFile`
- `TTAFRAValidationIssue`

The project model now also stores:

- project type
- relevant file inventory
- file relative path
- file extension
- file category
- file size
- file modified time
- inferred owning module
- inferred owning submodule

## Scanner

`TProjectScanner` currently scans:

- `app/modules`
- module `submodules`
- submodule `controllers`
- submodule `models`
- submodule `services`
- submodule `views`
- submodule `routes`
- submodule `assets`

The scanner does not perform full PHP parsing in Phase 1.

## Analyzer

`TProjectAnalyzer` currently adds Phase 2 read-only analysis:

- project classification
- recursive file inventory
- relevant file filtering
- directory exclusion
- module/submodule ownership inference from paths

Project classification values:

- `TAFRA ERP`
- `TAFRA OTA`
- `Standard TAFRA Framework`
- `Partial TAFRA-compatible project`
- `Unknown project`

Relevant file extensions:

```text
.php
.js
.css
.html
.json
.sql
.md
```

Excluded directories:

```text
vendor
node_modules
.git
cache
logs
```

## Framework Rules

`TTAFRAFrameworkRules` owns TAFRA-specific structural knowledge.

The main form must not contain TAFRA framework rules.

Future rule expansion should cover:

- module naming conventions
- submodule naming conventions
- required versus optional module files
- required versus optional submodule files
- checks against ERP and OTA reference projects

## Project Explorer

`TProjectExplorerPresenter` renders the internal model into `TTreeView`.

The `TTreeView` is only a presentation surface. It must not become the source of
project state or validation truth.

Pending improvements:

- Basic file navigation from Explorer.
- More detailed validation grouping.
- Route analysis.
- PHP component analysis.
- Database convention analysis.
