# 01 - Overview

TAFRA Studio is a lightweight native desktop development tool for projects built
on the TAFRA Framework.

It is not intended to replace VS Code, PhpStorm, or another general-purpose
source-code editor. Its purpose is to provide framework-aware project
management, structure inspection, validation, tooling integration, and later
safe code generation for TAFRA applications.

## Current Phase

The project has the first Phase 1 foundation in place and now includes the
first practical Phase 2 Analyzer milestone.

The current Studio behavior remains read-only toward opened TAFRA projects. It
may inspect, validate, classify, and inventory project structure, but it should
not create, rewrite, or delete files inside the target TAFRA project.

## Implemented Foundation

- Native Lazarus 4.8 LCL application shell.
- File menu, View menu, Help/About dialog, Project Explorer, Workspace,
  Output/Log, and Status Bar.
- Project open/close lifecycle through a project session service.
- Read-only scanner for the expected TAFRA project structure.
- Internal model for projects, modules, submodules, files, and validation
  issues.
- Project Explorer rendering from the internal model.
- Basic framework validation rules.
- Centralized logging and result/error types.
- Generic process runner.
- PHP tool runner.
- PHP health-check tool returning JSON.
- Phase 2 project analyzer service.
- Project type classification.
- Recursive relevant file inventory.
- Analyzer workspace tabs for summary, files, and diagnostics.

## Current Analyzer Capability

The analyzer currently:

- classifies opened projects as ERP, OTA, standard TAFRA, partial TAFRA, or
  unknown;
- scans relevant files with extensions `.php`, `.js`, `.css`, `.html`, `.json`,
  `.sql`, and `.md`;
- excludes `vendor`, `node_modules`, `.git`, `cache`, and `logs`;
- records file metadata in the normalized project model;
- displays summary counts, file inventory, and diagnostics in the Workspace.

## Intentionally Out of Scope

- PHP AST parsing.
- Module generation.
- Submodule generation.
- Controller or model generation.
- Composer package management UI.
- Git GUI.
- Codex integration.
- VS Code integration.
- Full source-code editor.
- Syntax highlighting engine.
- Deployment management.
