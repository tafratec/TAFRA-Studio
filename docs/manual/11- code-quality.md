# 11 - Code Quality

Code Quality tools help review an opened TAFRA project for style, static
analysis, and early TAFRA convention issues.

Open them from:

```text
Project
`-- Code Quality
    `-- Analyze Code Quality
```

The `Code Quality` menu is enabled only when a project is open.

## Current Scope

The current implementation is read-only.

It can:

- create a unified Code Quality report model;
- detect local project quality tools;
- detect common tool configuration files;
- run available enabled tools in report/dry-run mode;
- parse supported JSON reports into unified findings;
- run initial TAFRA convention checks;
- show a summary dialog;
- write findings to the Output panel.

It does not:

- install Composer packages;
- modify project files;
- apply formatting;
- apply Rector transformations;
- create backups;
- write report files.

## Supported Tools

TAFRA Studio currently detects project-local Composer binaries under:

```text
vendor/bin
```

Supported tools:

- PHP-CS-Fixer;
- PHPCS;
- PHPStan;
- Rector.

Rector is detected but disabled by default in the current read-only
configuration.

## Detected Configuration Files

TAFRA Studio checks for common configuration files:

```text
.php-cs-fixer.php
.php-cs-fixer.dist.php
phpcs.xml
phpcs.xml.dist
phpstan.neon
phpstan.neon.dist
rector.php
rector.php.dist
```

Detection is informational only. TAFRA Studio does not create or modify these
files.

## Default Read-Only Configuration

Included paths:

```text
app
public
config
routes
```

Excluded paths:

```text
.git
vendor
node_modules
cache
temp
tmp
logs
```

Default timeout:

```text
60000 ms
```

Default enabled tools:

```text
PHP-CS-Fixer: enabled
PHPCS: enabled
PHPStan: enabled
Rector: disabled
```

## Read-Only Analysis Behavior

When available, enabled tools are executed in non-mutating modes:

```text
PHP-CS-Fixer: fix --dry-run --format=json --using-cache=no
PHPCS:        --report=json
PHPStan:      analyse --error-format=json --no-progress
```

TAFRA Studio accepts non-zero tool exit codes when valid JSON output is
available, because code quality tools commonly return non-zero when findings
exist.

## Unified Findings

Each finding is normalized into the Code Quality model:

```text
Tool
File
Relative path
Line
Column
Category
Severity
Risk
Message
Recommendation
```

Severity values:

```text
Info
Warning
Critical
```

Risk values:

```text
Safe
Low
Medium
High
```

## Initial TAFRA Checks

The first TAFRA-specific checks are intentionally lightweight.

They currently report:

- missing expected `app/modules` project structure;
- possible database or business logic inside PHP controller files.

These checks are recommendations only. They do not change source code.

## Output

Until a dedicated Code Quality workspace is added, findings are written to the
Output panel and a summary dialog is shown.

The summary includes:

- project path;
- total findings;
- critical findings;
- warnings;
- information findings.

## Recommended Workflow

Use the current feature as a review tool:

```text
Open project
Analyze Code Quality
Review Output panel
Install/configure missing tools manually if needed
Run analysis again
```

Future phases should add a dedicated report workspace, filters, preview diffs,
and approval-based cleanup.
