# 06 - Project Analyzer

The Project Analyzer is the first implemented Phase 2 milestone.

Its job is to build a wider read-only understanding of an opened TAFRA project
before later phases attempt route analysis, PHP component analysis, database
convention analysis, pattern recognition, or code generation.

## Scope

The analyzer currently performs:

- project type classification;
- recursive relevant file inventory;
- file category counting;
- module and submodule ownership inference from paths;
- summary, selected-node files, and diagnostics display in the Workspace.

It does not modify project files.

## Project Classification

The analyzer stores the detected type on `TTAFRAProject.ProjectType`.

Current classifications:

```text
TAFRA ERP
TAFRA OTA
Standard TAFRA Framework
Partial TAFRA-compatible project
Unknown project
```

Current ERP/OTA detection is intentionally simple and based on project naming.
Standard and partial TAFRA detection use expected project structure. Later
versions should improve this with framework markers, configuration files, and
ERP/OTA reference conventions.

## File Inventory

The analyzer records relevant files in `TTAFRAProject.Files`.

Included extensions:

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

Each inventory item stores:

- name
- absolute path
- relative path
- extension
- category
- size
- modified time
- owning module, when inferable
- owning submodule, when inferable

## Analyzer UI

The main Workspace contains runtime-created Analyzer tabs:

- `Analyzer`
- `Files`
- `Diagnostics`

The `Analyzer` tab shows:

- project name
- project path
- project type
- module count
- relevant file count
- validation issue count
- file counts by category

The `Files` tab shows the relevant file inventory for the selected Project
Explorer node. Selecting the project root shows all relevant files. Selecting a
module, submodule, real folder, or file node narrows the list to files that
belong to that selected node.

The Project Explorer renders real folders and files discovered on disk under
each module/submodule. It does not create fixed placeholder folders such as
`Controllers`, `Models`, `Services`, `Views`, `Routes`, or `Assets` unless those
folders really exist in the opened project.

The `Diagnostics` tab shows validation and analyzer findings.

## Scan Command

The File menu includes:

```text
Scan Project
```

The command is enabled only when a project is open.

Opening a project also runs analysis automatically once the Phase 1 scan has
created the project model.

## Current Boundary

The analyzer is deliberately not a full source analyzer yet.

Pending Phase 2 work:

- route analyzer;
- lightweight PHP component analyzer;
- SQL/database convention analyzer;
- recurring TAFRA pattern recognition;
- richer analyzer diagnostics;
- better ERP/OTA classification rules.

The next recommended implementation step is route analysis, because routes are
the cleanest bridge between project structure and application behavior.
