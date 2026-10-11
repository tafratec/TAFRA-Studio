# 13 - Method Flowcharts

Method Flowcharts generate an SVG diagram from a selected PHP function or class
method.

Open the feature from:

```text
Project
`-- Code Intelligence
    `-- Generate Method Flowchart...
```

The menu is enabled only when a project is open.

## Purpose

This feature helps developers understand the logic inside a PHP method without
modifying the source code.

Useful examples:

- controller actions;
- service methods;
- validation methods;
- module/submodule helper functions;
- legacy methods with many statements.

## Basic Workflow

1. Open a TAFRA project.
2. Select a PHP file in the Project Explorer.
3. Alternatively, open a PHP file in the Source Viewer.
4. Choose:

```text
Project > Code Intelligence > Generate Method Flowchart...
```

5. If the file contains multiple functions/methods, select one from the dialog.
6. Choose where to save the SVG file.
7. Open the saved `.svg` file in a browser or SVG viewer.

## File Selection Rules

TAFRA Studio uses:

1. the selected PHP file in the Project Explorer, if one is selected;
2. otherwise, the currently opened PHP file in the Source Viewer.

If no PHP file is selected or open, TAFRA Studio asks the user to select or open
a PHP file first.

## Method Selection

TAFRA Studio detects named PHP functions and class methods.

If one method/function exists, it is used automatically.

If multiple methods/functions exist, TAFRA Studio shows a method-selection
dialog.

Examples:

```text
store
ItemsController::index
ItemsController::create
```

## SVG Output

The generated output is an SVG file.

The user chooses the save location using a Save As dialog.

Default filename pattern:

```text
ClassName-methodName-flowchart.svg
```

Example:

```text
ItemsController-store-flowchart.svg
```

## Current Flowchart Elements

The first implementation creates a simple vertical flowchart.

It can identify:

- start;
- end;
- statements;
- `if` / `elseif`;
- `switch`;
- loops;
- `return`;
- `throw`;
- `try`;
- `catch`;
- `finally`.

## Current Limitations

The current implementation is intentionally lightweight.

It does not yet:

- render full branch geometry for true/false paths;
- resolve dynamic PHP calls;
- follow calls into other files;
- analyze runtime framework behavior;
- require Composer packages;
- modify source code.

The generated diagram should be treated as a visual aid, not a formal execution
proof.

## Technical Notes

TAFRA Studio uses the existing PHP tooling architecture:

```text
Lazarus UI
`-- TFlowchartService
    `-- TPHPToolRunner
        `-- tools/php/method-flowchart.php
```

The PHP helper uses PHP's built-in tokenization to detect functions and methods.

No external Composer package is required for the current version.

## Recommended Usage

Use Method Flowcharts when:

- reviewing unfamiliar code;
- explaining controller/service logic;
- documenting legacy project behavior;
- preparing for refactoring;
- discussing code flow with another developer.

For complex refactoring decisions, use the flowchart together with the Source
Viewer and Code Quality findings.
