# TAFRA Studio

TAFRA Studio is a lightweight desktop development tool for understanding and
working with projects built on the TAFRA Framework. It is not intended to be a
general-purpose IDE.

## Requirements

- Lazarus 4.8
- Free Pascal Compiler supplied with Lazarus
- Lazarus Component Library (LCL)

## Phase 1 status

The initial application shell is available. It provides a resizable main window
with Project Explorer, Workspace, Output/Log, and status areas. You can select
and close a project directory; the selected directory is only stored in memory
and is never scanned or changed.

Project detection and all project analysis are future Phase 1 work.

## Structure

```text
src/forms       Lazarus forms and UI
src/core        Application infrastructure
src/project     Project representation and inspection (future)
src/framework   TAFRA framework knowledge (future)
src/services    Application services (future)
src/utils       Small reusable utilities
resources       Icons and templates
config          Studio configuration
tests           Tests and fixtures
```

## Build and run

Open `tafrastudio.lpi` in Lazarus 4.8, then choose **Run → Run** (F9), or build
the project from the IDE. The project uses only standard Lazarus LCL controls.
