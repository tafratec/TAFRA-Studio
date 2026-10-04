# 10 - Generic Tools

Generic Tools are Studio utilities that are not tied to the currently opened
TAFRA project.

Open them from:

```text
Tools
`-- Password Generator...
```

The `Tools` menu is always enabled. It does not require an opened project.

## Password Generator

The Password Generator creates a password locally inside TAFRA Studio.

It provides:

- password length selection;
- password content selection;
- generated password display;
- copy-to-clipboard action;
- regenerate action;
- reset action.

## Password Length

The available password lengths are:

```text
4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 30
```

The default length is `16`.

## Password Content

The available password content modes are:

- characters, symbols, and numbers;
- characters and numbers;
- characters only;
- numbers only.

The default mode is characters, symbols, and numbers.

For mixed modes, TAFRA Studio ensures that the generated password includes at
least one character from each required group.

## Actions

### Generate

Creates a password using the selected length and content mode.

### Copy

Copies the generated password to the system clipboard.

The button is enabled only after a password has been generated.

### Regenerate

Creates another password using the same current selections.

The button is enabled only after a password has been generated.

### Reset

Clears the generated password and restores the default selections.

## Scope

The Password Generator is a local desktop utility implemented in Lazarus /
Free Pascal.

It does not:

- require an opened project;
- call PHP;
- call Composer;
- use the project PHP runtime;
- save generated passwords.

Generated passwords are displayed only in the form until copied, regenerated,
reset, or the form is closed.
