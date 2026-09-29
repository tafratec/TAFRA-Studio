# Task: Create Initial TAFRA Studio Lazarus Project

Create the initial **TAFRA Studio** desktop application using **Lazarus 4.8 and Free Pascal**.

Before implementation:

1. Read the root `AGENTS.md` completely.
2. Follow its architecture, naming, dependency, and coding rules.
3. Inspect the current repository before creating files.
4. Do not implement functionality beyond the scope described below.

## Objective

Create a clean, compilable Lazarus application that acts as the initial container/shell for future TAFRA Studio development.

This task establishes the application foundation only.

## Target Environment

- Lazarus 4.8
- Free Pascal
- Lazarus LCL
- Primary target: Windows 64-bit
- Keep future Linux compatibility where practical.
- Do not use Delphi-specific libraries.
- Do not add third-party packages.

## Required Project Structure

Create or prepare:

```text
TAFRAStudio/
├── src/
│   ├── forms/
│   ├── core/
│   ├── project/
│   ├── framework/
│   ├── services/
│   └── utils/
├── resources/
│   ├── icons/
│   └── templates/
├── config/
├── docs/
├── tests/
├── AGENTS.md
├── README.md
├── tafrastudio.lpi
└── tafrastudio.lpr
```

Preserve the existing `AGENTS.md`.

Empty directories may contain suitable placeholder files when required by Git.

## Application Entry Point

Create `tafrastudio.lpr` as the application entry point.

It should:

- initialize the Lazarus application
- create the main form
- start the application
- contain no business logic

Use an appropriate application title:

`TAFRA Studio`

## Main Form

Create the initial main form under:

```text
src/forms/
```

Suggested unit:

```text
uMainForm.pas
```

Create the corresponding Lazarus form resource as required.

The main form should provide this general layout:

```text
+----------------------------------------------------------+
| Main Menu                                                |
+----------------------------------------------------------+
| Toolbar                                                  |
+-------------------+--------------------------------------+
|                   |                                      |
| Project Explorer  |            Workspace                 |
|                   |                                      |
|                   |                                      |
+-------------------+--------------------------------------+
| Output / Log                                             |
+----------------------------------------------------------+
| Status Bar                                               |
+----------------------------------------------------------+
```

Use standard Lazarus LCL controls only.

Recommended controls include:

- `TMainMenu`
- `TToolBar`
- `TTreeView` for Project Explorer
- `TPanel` or suitable container for workspace
- `TMemo` for initial Output/Log display
- `TStatusBar`
- `TSplitter` where useful

The layout should resize correctly with the main window.

## Initial Menu

Create a minimal menu structure:

```text
File
 ├─ Open Project...
 ├─ Close Project
 ├─ Recent Projects
 ├─ -
 └─ Exit

View
 ├─ Project Explorer
 └─ Output

Help
 └─ About
```

Only basic UI behavior is required.

`Exit` should close the application.

Other commands may initially be placeholders where their real functionality belongs to later tasks.

## Initial Project Opening

Implement only a minimal project-directory selection operation.

When the user selects:

`File -> Open Project...`

allow the user to select a directory.

For this initial task:

- store the selected project path in memory
- display the selected path in the status bar
- optionally display a simple root node in Project Explorer
- write an informational message to the Output area

Example:

```text
Project opened: C:\Projects\TAFRA_ERP
```

Do NOT scan or analyze the project yet.

TAFRA project detection and scanning belong to subsequent Phase 1 tasks.

## Close Project

Implement basic closing behavior:

- clear the current project path
- clear the Project Explorer
- reset relevant status information
- write a message to Output

No project files should ever be modified.

## About Dialog

Provide a very simple About dialog or message containing:

```text
TAFRA Studio
TAFRA Framework Development Studio
```

Do not spend significant effort on visual design at this stage.

## Architecture Requirement

Keep the main form thin.

Do not start placing future project scanning, framework validation, or code-generation logic inside form event handlers.

Where appropriate, introduce only the minimum supporting application structure required for the shell.

Do not create speculative classes merely to fill directories.

## Important Restrictions

For this task, DO NOT implement:

- TAFRA project scanning
- module detection
- submodule detection
- framework validation
- PHP parsing
- database access
- module generators
- submodule generators
- code generation
- Codex API integration
- AI functionality
- Git integration
- FTP/SFTP/SSH
- deployment functionality
- plugin systems

These belong to later development phases.

## File-System Safety

The application must treat selected project directories as read-only for this task.

Opening a project must NOT:

- create files
- modify files
- delete files
- change permissions
- modify configuration

## README

Create or update `README.md` with a concise description containing:

- TAFRA Studio purpose
- Lazarus 4.8 requirement
- Free Pascal/LCL usage
- current Phase 1 status
- basic project structure
- basic build/open instructions

Keep it concise.

## Compilation

After implementation, attempt to compile/build the project using the available Lazarus/FPC environment.

Fix compilation errors caused by the implementation.

Do not claim compilation succeeded unless it was actually executed successfully.

If Lazarus 4.8 is unavailable in the execution environment, perform static inspection and clearly report that compilation could not be verified.

## Completion Criteria

The task is complete when:

1. The Lazarus project exists.
2. It can be opened in Lazarus 4.8.
3. The main application shell is implemented.
4. The main form contains Project Explorer, Workspace, Output and Status areas.
5. A directory can be selected as the current project.
6. The project can be closed.
7. No selected TAFRA project files are modified.
8. The architecture is ready for the next Phase 1 task: **TAFRA Project Detection**.

## Completion Report

At completion, report:

```text
Implemented:
- ...

Files created:
- ...

Files modified:
- ...

Compilation/Test:
- ...

Notes / remaining issues:
- ...
```

Do not begin the next Phase 1 feature automatically.