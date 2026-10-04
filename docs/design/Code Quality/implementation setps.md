Final implementation steps:

1. Add Code Quality menu

```text
Project
`-- Code Quality
    `-- Analyze Code Quality
```

Keep it enabled only when a project is open.

2. Create core models

Add models for:

- code quality finding
- severity: `Info / Warning / Critical`
- risk: `Safe / Low / Medium / High`
- tool name
- file path
- line number
- category
- recommendation

3. Create service layer

Add:

- `TCodeQualityService`
- `TCodeQualityReport`
- `TCodeQualityToolRunner`

Use existing:

- `TProcessRunner`
- `TPHPToolRunner`

No direct process execution from forms.

4. Add tool detection

Detect availability/configuration for:

- PHP-CS-Fixer
- PHPCS
- PHPStan
- Rector later

Initially only report missing tools; do not install automatically.

5. Implement Phase 1 read-only foundation

Add configuration for:

- included folders
- excluded folders: `vendor`, `node_modules`, cache/temp folders
- timeout
- enabled tools

6. Implement Phase 2 analysis

Run tools in read-only/dry-run mode:

- PHP-CS-Fixer dry-run
- PHPCS report mode
- PHPStan analysis
- initial TAFRA-specific checks

Normalize all outputs into one report format.

7. Add Code Quality UI

Create a workspace tab or form showing:

- summary counts
- findings grid/list
- file
- line
- severity
- risk
- tool
- recommendation

8. Add filtering

Allow filtering by:

- severity
- risk
- tool
- selected project tree node/module/submodule

9. Add validation output

Show execution errors clearly:

- missing PHP
- missing Composer tool
- timeout
- invalid config
- tool failure

10. Later add safe cleanup

Only after read-only analysis works:

```text
Analyze → Preview Diff → User Approval → Backup/Git Checkpoint → Apply → Validate
```

Start with formatting only, then add Rector/refactoring later.