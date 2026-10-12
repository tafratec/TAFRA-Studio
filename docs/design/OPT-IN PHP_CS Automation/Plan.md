## Goal

Add opt-in PHP-CS-Fixer automation without allowing silent changes. Keep Rector disabled and out of the execution path.

## Phase A — Preview only

1. Add a Code Quality action:

   ```text
   Project → Code Quality → Preview PHP-CS-Fixer Changes...
   ```

2. Require an open project and a detected PHP-CS-Fixer binary.

   Tool selection remains:

   - project-local `vendor\bin\php-cs-fixer` first;
   - Studio-bundled tool only as fallback.

3. Reuse the project config when available:

   - `.php-cs-fixer.php`
   - `.php-cs-fixer.dist.php`

4. Run PHP-CS-Fixer through the centralized runner with non-writing preview arguments:

   ```text
   fix --dry-run --diff --format=json --using-cache=no
   ```

5. Parse the response into a dedicated preview model:

   - file path
   - whether changes are proposed
   - unified diff text
   - tool source and runtime
   - elapsed time
   - stdout/stderr and exit code

6. Display a preview form with:

   - list of affected files;
   - number of proposed changes;
   - file selector;
   - read-only diff viewer;
   - copy/save preview report;
   - clear warning: “No files have been changed.”

No Apply button is included in this phase.

## Phase B — Explicit Apply workflow

1. Add a separate action, not a shortcut from automatic analysis:

   ```text
   Project → Code Quality → Apply Approved PHP-CS-Fixer Changes...
   ```

2. Require the user to first create a preview in the current session.

   Refuse applying if:

   - no preview exists;
   - project path changed;
   - selected configuration changed;
   - tool path/runtime changed;
   - preview is stale.

3. Let the user select exactly which previewed files may be changed.

   Default: no files selected.

4. Show a confirmation dialog containing:

   - count and paths of selected files;
   - tool and PHP runtime;
   - config file used;
   - backup location;
   - a clear irreversible-action warning;
   - explicit confirmation text such as `APPLY`.

5. Create backups before invoking PHP-CS-Fixer.

   Recommended location:

   ```text
   <project>/.tafra-studio/backups/php-cs-fixer/<timestamp>/
   ```

   Preserve the original relative paths. Write a small JSON manifest recording:

   - project path;
   - timestamp;
   - tool/runtime/config versions;
   - selected files;
   - original file hashes;
   - backup paths.

6. Run PHP-CS-Fixer only against the approved file list, never the entire project implicitly.

   Use:

   ```text
   fix --using-cache=no --config=<project-config> <selected-file-paths>
   ```

7. Show an apply result view:

   - changed files;
   - unchanged files;
   - tool failures;
   - stderr;
   - backup location;
   - “Restore Backup” action.

## Phase C — Restore and auditability

1. Add:

   ```text
   Project → Code Quality → Restore PHP-CS-Fixer Backup...
   ```

2. Show backup manifests, timestamps, and changed-file counts.

3. Require explicit confirmation before restoration.

4. Log every preview, apply, failure, backup, and restore action through the existing logging system.

5. Export automation activity in the Code Quality JSON/CSV/HTML report.

## Architecture

Keep responsibilities separated:

```text
UI form/menu
  → PHP-CS-Fixer preview/apply service
    → CodeQualityToolRunner
      → TPHPToolRunner / TProcessRunner
        → PHP-CS-Fixer
```

Suggested new units:

- `uPHPCodeFixPreviewModel`
- `uPHPCodeFixService`
- `uPHPCodeFixPreviewForm`
- `uPHPCodeFixBackupService`

Do not put command construction, file backup logic, or diff parsing in `uMainForm`.

## Safety rules

- Never run `fix` without an explicit user action.
- Never include Rector in preview or apply flows initially.
- Never write outside the open project directory.
- Never apply to a file not shown in the current preview.
- Never delete backups automatically.
- Never run “fix all” as the default action.
- Treat a changed config/tool/runtime as invalidating the preview.

## Tests

Before enabling Apply:

- preview produces no file changes;
- project config is passed correctly;
- missing config shows default-rules warning;
- only selected files are changed;
- backup copies match pre-change file hashes;
- restore returns files exactly to their original content;
- failures leave originals and backups intact;
- paths with spaces and Unicode work;
- no open project, missing tool, invalid config, timeout, and permission-denied cases are handled without crashing.