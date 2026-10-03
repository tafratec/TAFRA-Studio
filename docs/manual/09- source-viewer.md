# 09 - Source Viewer

TAFRA Studio includes a read-only source viewer in the Workspace.

The viewer is implemented with Lazarus SynEdit and is designed for inspecting
project files without turning TAFRA Studio into a general-purpose IDE.

## Entry Points

Open a file in the Source tab by:

- selecting a file node in the Project Tree;
- double-clicking a file line in the Analyzer `Files` tab.

## Supported Highlighting

The current viewer applies syntax highlighting for:

- PHP
- JavaScript
- CSS
- HTML
- SQL

Other text files are displayed without a dedicated highlighter.

## Safety Rules

The source viewer is read-only.

It does not open:

- missing files;
- binary files;
- files larger than the configured safe preview limit.

The current safe preview limit is 5 MB.

## Font Settings

The source viewer font can be changed from:

```text
Settings
`-- Application Settings...
```

The setting controls the font name and size used by the SynEdit preview area.

## Editing Boundary

Editing is intentionally not enabled yet.

Future edit mode should be explicit and should add save handling, dirty-state
tracking, reload warnings, and external editor conflict checks before project
files can be modified from the viewer.
