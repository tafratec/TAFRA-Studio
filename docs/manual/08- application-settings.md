# 08 - Application Settings

Application Settings controls runtime paths used by TAFRA Studio tooling.

Open it from:

```text
Settings
`-- Application Settings...
```

## PHP Runtime Settings

TAFRA Studio keeps two PHP runtime concepts separate:

- Studio PHP executable
- Project PHP executable

The Studio PHP executable is used by internal Studio PHP tools, such as health
checks and JSON tool backends.

The Project PHP executable is reserved for commands that should run in the
context of the opened TAFRA project.

By default, Studio PHP points to:

```text
runtime/php/php.exe
```

## Composer Settings

Composer settings define:

- Composer executable or `composer.phar` path
- Composer PHP runtime mode
- optional custom Composer PHP executable

Composer runtime modes:

```text
project_php
studio_php
custom_php
```

When Composer uses `project_php` and no Project PHP executable is configured,
the current implementation falls back to Studio PHP for the test command.

## Persistence

Settings are saved to:

```text
config/studio-settings.json
```

This file stores application behavior settings only. It is separate from any
configuration inside an opened TAFRA project.

## Validation

The Settings dialog provides test actions for:

- Studio PHP
- Project PHP
- Composer

All process execution remains centralized through service classes. Forms do not
directly invoke PHP or Composer.
