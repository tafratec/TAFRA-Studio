# 07 - Modules Management

Modules Management is exposed through native TAFRA Studio UI commands.

The current implementation routes supported commands through the Studio PHP CLI
tool runner and receives structured JSON responses from:

```text
tools/php/module-management.php
```

Project-changing actions are previewed and confirmed in the desktop UI before
execution.

## Entry Points

Top menu:

```text
Project
`-- Modules Management
```

The `Project` menu is enabled only when a project is open.

Project Explorer right-click menu:

```text
Create Module
Create Submodule
Edit Module Properties
Edit Submodule Properties
Reorder Submodules
Delete Submodule
Delete Module
Check Module Naming Case
Check Submodule Naming Case
```

## Context Rules

Project root:

- Create Module

Module node:

- Create Submodule
- Edit Module Properties
- Reorder Submodules
- Delete Module
- Check Module Naming Case

Submodule node:

- Edit Submodule Properties
- Delete Submodule
- Check Submodule Naming Case

Other folder/file nodes do not enable module-management mutations.

## Service Boundary

Commands are routed through:

```text
TModuleManagementService
```

The intended execution path is:

```text
Project Explorer node
  -> context command
  -> Pascal preview/confirmation UI
  -> TModuleManagementService
  -> TPHPToolRunner
  -> tools/php/module-management.php
  -> refresh project scanner/analyzer
```

## Implemented Actions

- Create Module
- Create Submodule
- Delete Submodule
- Delete Module

These actions update `moduleConfig.php`, create or remove the corresponding
module/submodule folders, and refresh the project explorer/analyzer after a
successful response.

## Pending Backend/UI Work

The following commands have native menu entries but still require richer UI
forms or reporting before they can fully replace the legacy interactive CLI
workflow:

- Edit Module Properties
- Edit Submodule Properties
- Reorder Submodules
- Check Module Naming Case
- Check Submodule Naming Case

The backend must remain non-interactive, return JSON, and continue to run
through `TPHPToolRunner`.
