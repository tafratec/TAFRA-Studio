# TAFRA Studio — Codex Development Instructions

## 1. Project Overview

**TAFRA Studio** is a lightweight desktop development tool dedicated to projects built with the **TAFRA Framework**.

The Studio is not intended to replace a general-purpose IDE.

Its primary responsibilities are:

- Understand TAFRA project structure.
- Inspect modules and submodules.
- Validate TAFRA Framework conventions.
- Generate TAFRA-compatible project components.
- Provide project management utilities.
- Prepare structured project context and development instructions for Codex.
- Eventually act as a specialized development assistant for TAFRA ERP, OTA, and other TAFRA-based applications.

Existing TAFRA ERP and OTA projects may be used as reference implementations when defining framework conventions.

---

## 2. Technology Stack

Primary development environment:

- Lazarus IDE: **4.8**
- Language: **Object Pascal**
- Compiler: Free Pascal Compiler supplied/supported by the Lazarus 4.8 environment
- GUI framework: Lazarus LCL
- Primary target: Windows
- Architecture: 64-bit where supported

Future Linux support should remain possible.

Do not introduce Delphi-specific dependencies unless explicitly requested.

Do not introduce third-party Lazarus packages without approval.

Prefer standard FPC/Lazarus libraries whenever practical.

---

## 3. Core Design Principles

TAFRA Studio must remain:

- Lightweight
- Modular
- Maintainable
- Easy to extend
- Easy to understand
- Loosely coupled
- Conservative in external dependencies

Avoid unnecessary abstraction and over-engineering.

Prefer simple, explicit Object Pascal code over complex design patterns.

Forms must NOT contain significant application or framework logic.

UI code should primarily:

1. Collect user input.
2. Call application services.
3. Display results.

---

## 4. Initial Project Structure

Use the following logical structure unless an existing repository structure requires otherwise:

```text
TAFRAStudio/
├── src/
│   ├── forms/
│   ├── core/
│   ├── project/
│   ├── framework/
│   ├── services/
│   └── utils/
│
├── resources/
│   ├── icons/
│   └── templates/
│
├── config/
├── docs/
├── tests/
│
├── AGENTS.md
├── README.md
├── tafrastudio.lpi
└── tafrastudio.lpr
```

Responsibilities:

### `src/forms`

Lazarus forms and UI-related units.

Keep business logic out of forms.

### `src/core`

Application-level infrastructure and common abstractions.

Examples:

- application initialization
- configuration
- logging
- shared types
- application constants

### `src/project`

TAFRA project inspection and representation.

Examples:

- project loader
- directory scanner
- project metadata
- project model
- project validation

### `src/framework`

Knowledge about the TAFRA Framework itself.

Examples:

- naming conventions
- expected directories
- module conventions
- submodule conventions
- component definitions
- framework validation rules

This layer must remain independent from the GUI.

### `src/services`

Application services coordinating operations between the UI, project layer, framework layer, and future Codex integration.

### `src/utils`

Small reusable utility functions.

Do not turn `utils` into a location for unrelated application logic.

---

## 5. Phase 1 Scope

Current development is **Phase 1 — Studio Foundation & Project Understanding**.

Phase 1 should implement only the foundation necessary for TAFRA Studio to understand an existing TAFRA project.

Primary Phase 1 capabilities:

1. Studio application shell.
2. Open/close project.
3. Recent-project support.
4. Basic application configuration.
5. Logging.
6. TAFRA project detection.
7. Project directory scanning.
8. Module detection.
9. Submodule detection.
10. Component detection.
11. Project Explorer.
12. Internal TAFRA project metadata model.
13. Basic framework validation.
14. Preparation of structured project context for future Codex operations.

Do NOT prematurely implement later Studio functionality.

---

## 6. Main Application UI

The initial main window should provide a clean Studio shell containing approximately:

```text
+----------------------------------------------------------+
| Menu                                                     |
+----------------------------------------------------------+
| Toolbar                                                  |
+-------------------+--------------------------------------+
|                   |                                      |
| Project Explorer  |          Workspace                   |
|                   |                                      |
|                   |                                      |
+-------------------+--------------------------------------+
| Output / Log                                             |
+----------------------------------------------------------+
| Status Bar                                               |
+----------------------------------------------------------+
```

The exact UI may evolve.

Avoid embedding framework processing directly into UI event handlers.

---

## 7. TAFRA Project Model

The Studio should eventually recognize entities including:

```text
TAFRA Project
    |
    +-- Modules
          |
          +-- Submodules
                |
                +-- Controllers
                +-- Models
                +-- Services
                +-- Views
                +-- Routes
                +-- Assets
```

Design internal classes/records around these concepts rather than manipulating TreeView nodes as the authoritative project model.

The Project Explorer is a **view of the project model**, not the project model itself.

---

## 8. TAFRA Framework Knowledge

Do not infer framework rules solely from generic PHP MVC conventions.

TAFRA Framework has its own architecture and conventions.

Framework knowledge should be obtained from:

1. Explicit project documentation.
2. Existing TAFRA Framework code.
3. Existing TAFRA ERP implementation.
4. Existing TAFRA OTA implementation.
5. Instructions supplied for the current development task.

When ERP and OTA implementations differ, do not automatically treat either implementation as the framework standard.

Identify the difference and isolate project-specific behavior from framework-level rules.

---

## 9. Existing Codebase Usage

Existing ERP and OTA repositories are valuable reference material.

Codex may analyze them to identify:

- recurring directory structures
- module patterns
- submodule patterns
- controllers
- models
- services
- routes
- views
- configuration conventions
- naming conventions

However:

**Existing application code is evidence of framework usage, not automatically the framework specification.**

Do not copy business-specific ERP or OTA logic into TAFRA Studio framework rules.

---

## 10. Codex Role

Codex is expected to be the primary code-building assistant for TAFRA Studio.

For every implementation task:

1. Read this `AGENTS.md`.
2. Inspect the existing repository.
3. Understand the current implementation before modifying it.
4. Reuse existing architecture where appropriate.
5. Make the smallest coherent change necessary.
6. Avoid unrelated refactoring.
7. Preserve backward compatibility unless instructed otherwise.
8. Compile/test affected functionality whenever practical.
9. Report modified files and verification results.

Do not redesign established architecture merely because another design is possible.

---

## 11. Coding Conventions

Use clear Object Pascal naming.

Recommended conventions:

```pascal
TTAFRAProject
TTAFRAModule
TTAFRASubmodule
TTAFRAProjectScanner
TTAFRAProjectValidator
TTAFRAFrameworkRules
```

Interfaces:

```pascal
ITAFRAProjectService
```

Private fields:

```pascal
FProjectPath
FProjectName
FModules
```

Methods should clearly communicate intent:

```pascal
LoadProject
CloseProject
ScanProject
ValidateProject
DetectModules
DetectSubmodules
```

Constants should be explicit and centralized where appropriate.

Avoid excessive global variables.

---

## 12. Unit Design

Prefer focused units with one clear responsibility.

Example:

```text
uTAFRAProject.pas
uTAFRAModule.pas
uTAFRASubmodule.pas

uProjectScanner.pas
uProjectValidator.pas

uFrameworkRules.pas

uAppConfig.pas
uLogger.pas
```

Do not create extremely large units containing unrelated classes.

Likewise, do not create unnecessary one-class abstractions where they provide no architectural benefit.

---

## 13. Error Handling

Operations involving files and directories must handle failures safely.

Examples:

- project directory does not exist
- access denied
- malformed configuration
- missing TAFRA directories
- unsupported project structure
- invalid module configuration

Errors should normally:

1. Produce a useful internal error/result.
2. Be logged where appropriate.
3. Be presented by the UI in understandable language.

Avoid silently swallowing exceptions.

---

## 14. File-System Safety

TAFRA Studio will eventually generate and modify application code.

Therefore file-system operations must be conservative.

During Phase 1, project scanning should be **read-only by default**.

Never:

- delete application files automatically
- overwrite existing source files without explicit intent
- modify a project merely while scanning it
- change framework files as a side effect of project detection

Future generators must check for existing files before writing.

---

## 15. Path Handling

Never assume Windows path separators manually.

Use appropriate FPC/Lazarus path utilities.

TAFRA Studio should remain capable of supporting projects located on Windows or Linux-compatible file systems.

Avoid code such as:

```pascal
Path := BasePath + '\app\modules';
```

Prefer platform-safe path construction.

---

## 16. Configuration

Studio-specific settings should remain separate from TAFRA application configuration.

Potential Studio settings include:

- recent projects
- preferred external editor
- Codex-related configuration
- UI preferences
- project scanning options

Do not modify the target application's configuration simply to store Studio preferences.

---

## 17. Logging

Provide centralized logging rather than scattered file writes.

At minimum support:

```text
INFO
WARNING
ERROR
DEBUG
```

Logs should assist development and diagnosis without becoming a dependency for normal application behavior.

Never log secrets, credentials, API keys, database passwords, or authentication tokens.

---

## 18. Testing

Core logic should be testable independently from Lazarus forms.

Prioritize tests for:

- project detection
- project scanning
- module detection
- submodule detection
- path handling
- framework validation

Where practical, use small fixture directories representing valid and invalid TAFRA projects.

Do not require the GUI to test project scanning logic.

---

## 19. Documentation

Significant components should have concise documentation under `/docs`.

Documentation should explain architecture and behavior rather than duplicate source code.

When introducing an important subsystem, document:

- purpose
- responsibilities
- inputs
- outputs
- dependencies
- important design decisions

Keep documentation synchronized with implementation.

---

## 20. Codex Change Discipline

Before implementing a requested feature:

### Inspect

Determine which existing files and components are relevant.

### Plan

Identify the minimum files that require modification.

### Implement

Follow existing project architecture and this document.

### Verify

Compile or test the affected components where possible.

### Report

Provide a concise completion report containing:

```text
Implemented:
- ...

Files created:
- ...

Files modified:
- ...

Verification:
- ...

Remaining issues:
- ...
```

Do not claim compilation or tests succeeded unless they were actually executed successfully.

---

## 21. Dependency Policy

Default rule:

**Use Lazarus/FPC standard capabilities first.**

A third-party package should only be introduced when it provides substantial value that would otherwise require significant custom implementation.

Before introducing one, identify:

- purpose
- package/library
- license where relevant
- reason it is required
- alternative using standard FPC/Lazarus functionality

Do not introduce dependencies merely for convenience.

---

## 22. Future Codex Integration

TAFRA Studio will eventually provide structured context to Codex.

Design current components so the Studio can later produce information such as:

```text
Project
Framework Version
Modules
Submodules
Relevant Files
Routes
Database Objects
Framework Rules
Requested Operation
```

Codex integration must remain separated from project scanning and framework modeling.

Conceptually:

```text
TAFRA Project
      |
      v
Project Scanner
      |
      v
Internal Project Model
      |
      +------> Project Explorer
      |
      +------> Validator
      |
      +------> Future Generator
      |
      +------> Codex Context Builder
                    |
                    v
                  Codex
```

The internal project model should therefore become the common source of project information.

---

## 23. Architectural Boundary

Maintain this fundamental separation:

```text
UI
 |
 v
Services
 |
 +-------------------+
 |                   |
 v                   v
Project Layer    Framework Layer
 |
 v
File System
```

Future:

```text
Services
   |
   +--> Generators
   |
   +--> Codex Integration
   |
   +--> Database Tools
```

Avoid dependencies flowing from core/framework logic back toward forms.

---

## 24. Current Priority

During Phase 1, optimize for:

**Correct understanding of a TAFRA project before automatic generation of a TAFRA project.**

The preferred implementation sequence is:

```text
Studio Shell
     ↓
Project Detection
     ↓
Project Scanner
     ↓
Internal Project Model
     ↓
Project Explorer
     ↓
Framework Validation
     ↓
Codex Context Preparation
```

Do not move significant code-generation functionality ahead of reliable project understanding.

---

## 25. General Rule

When requirements are ambiguous:

- preserve existing behavior
- prefer the simplest implementation
- avoid destructive operations
- avoid speculative features
- keep framework rules configurable where reasonable
- clearly identify assumptions

TAFRA Studio should evolve incrementally through small, testable phases rather than becoming a large monolithic IDE.