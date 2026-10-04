Based on the files under `docs/design/Code Quality`, I recommend building Code Quality tools as a controlled, staged subsystem, not as one “auto refactor” button.

Core rule should be:

```text
Analyze → Recommend → Preview → User approves → Apply → Validate
```

Recommended main menu placement:

```text
Project
`-- Code Quality
    |-- Analyze Code Quality
    |-- Safe Cleanup
    |-- Refactoring Recommendations
    |-- TAFRA Architecture Review
    `-- Optimization Review
```

For now, start with read-only tools.

## Recommended tools by phase

| Phase | Tool / Capability | Purpose | Change source code? |
|---|---|---:|---:|
| 1 | Code Quality Foundation | configuration, exclusions, environment checks, report format | No |
| 2 | PHP-CS-Fixer dry-run | style/formatting issues | No |
| 2 | PHPCS | coding standard violations | No |
| 2 | PHPStan | static analysis/type/logic problems | No |
| 2 | TAFRA convention checks | framework-specific project structure rules | No |
| 3 | PHP-CS-Fixer apply mode | approved formatting cleanup | Yes, after approval |
| 3 | PHPCBF optional | approved coding-standard fixes | Yes, after approval |
| 4 | Rector dry-run | modernization/refactoring proposals | No |
| 4 | Rector apply mode | approved AST refactoring | Yes, after preview |
| 5 | TAFRA-aware analyzer | controller/model/service responsibility checks | Mostly recommendations |
| 6 | Optimization workspace | high-risk performance/architecture suggestions | Only after explicit approval |

## First implementation recommendation

Start with this menu item:

```text
Project
`-- Code Quality
    `-- Analyze Code Quality
```

This should be read-only and generate a consolidated report.

The report should include:

```text
File
Line
Tool
Category
Severity
Risk
Message
Recommendation
```

Severity:

```text
Info
Warning
Critical
```

Risk:

```text
Safe
Low
Medium
High
```

## Recommended external PHP tools

Use mature Composer tools instead of building a custom parser:

1. `PHP-CS-Fixer`

Best for formatting and style cleanup.

Use first in dry-run mode.

2. `PHP_CodeSniffer`

Best for coding-standard detection.

Later, `phpcbf` may be used for safe automatic fixes.

3. `PHPStan`

Best for static analysis, type problems, impossible conditions, wrong calls, and dead-ish code.

4. `Rector`

Best for structural PHP modernization and AST-based refactoring.

Should initially run only in dry-run / preview mode.

## TAFRA-specific tools to add inside TAFRA Studio

These should use the existing Project Analyzer knowledge:

- module structure validation;
- submodule structure validation;
- route naming checks;
- controller/service/model responsibility checks;
- direct database access warnings;
- duplicate module/submodule logic detection;
- TAFRA naming convention checks;
- misplaced files detection.

These are where TAFRA Studio becomes more useful than generic PHP tools.

## Recommended architecture

```text
TCodeQualityService
    |
    +-- TCodeQualityToolRunner
    |       |
    |       +-- PHP-CS-Fixer runner
    |       +-- PHPCS runner
    |       +-- PHPStan runner
    |       +-- Rector runner
    |
    +-- TTAFRACodeQualityRules
    |
    +-- TCodeQualityReport
```

Execution should follow existing AGENTS.md rules:

- external processes through `TProcessRunner`;
- PHP-based tooling through `TPHPToolRunner`;
- JSON output where possible;
- no direct process calls from forms;
- UI only displays reports and asks for approval.

## Strong recommendation

Implement phases in this order:

1. Code Quality Foundation
2. Read-only Code Quality Analysis
3. Safe Cleanup with preview
4. Rector recommendations
5. TAFRA-aware recommendations
6. Optimization/refactoring workspace

Do not start with automatic refactoring. The first useful version should only analyze and report.

=============================================
Effeciency and added values
=============================================
They would add strong value, especially for PHP/TAFRA projects, but only if TAFRA Studio presents them as a guided quality assistant rather than a noisy “run all tools” dashboard.

The biggest value is not that these tools exist; developers can already run them manually. The value is that TAFRA Studio can combine them with TAFRA project knowledge and show results in a simpler, project-aware way.

## Added value to the project

1. Higher code consistency

`PHP-CS-Fixer` and `PHPCS` help keep formatting, naming, spacing, imports, and coding style consistent across modules and developers.

This reduces “style noise” in commits and makes code review easier.

2. Early bug detection

`PHPStan` can catch many issues before runtime:

- wrong method calls;
- missing classes;
- invalid types;
- impossible conditions;
- nullable value mistakes;
- incorrect return values;
- unreachable code.

For PHP projects, this is very valuable because many errors otherwise appear only during execution.

3. Safer modernization

`Rector` can suggest upgrades such as newer PHP syntax, cleaner constructs, and removal of obsolete patterns.

But it must be controlled carefully. Rector is powerful, and that means it should be preview-first, approval-only.

4. Better TAFRA architecture

This is where TAFRA Studio can add unique value.

Generic tools do not know whether logic belongs in a TAFRA controller, model, service, module, or submodule.

TAFRA Studio can detect:

- business logic inside controllers;
- duplicated module logic;
- wrong route structure;
- misplaced files;
- naming violations;
- direct DB access where a model/service should be used.

That is higher value than generic formatting.

5. Lower maintenance cost

Over time, these tools reduce technical debt by making problems visible earlier. They help keep old modules from becoming hard to change.

## Added value to the developer

1. Less manual review work

The developer does not need to manually inspect every file for formatting, unused imports, obvious mistakes, or common structure problems.

2. Better confidence before changes

Before editing or refactoring a module, the developer can run analysis and understand current risks.

3. Safer refactoring

With preview/diff/approval workflow, the developer stays in control.

Good workflow:

```text
Analyze
→ See recommendations
→ Preview diff
→ Approve selected changes
→ Validate
```

4. Learning benefit

The tool can explain why something is a problem. This helps developers gradually learn TAFRA conventions and PHP quality practices.

5. Faster onboarding

New developers can open a project and quickly understand:

- project quality level;
- risky files;
- architecture violations;
- modules needing attention.

## Efficiency of each tool

| Tool | Efficiency | Added value | Risk |
|---|---:|---:|---:|
| PHP-CS-Fixer | High | Fast cleanup, consistent code style | Low |
| PHPCS | High | Finds coding standard violations | Low |
| PHPStan | Very High | Finds hidden logic/type bugs | Low/Medium |
| Rector | High but sensitive | Modernization and refactoring | Medium/High |
| TAFRA rules | Very High | Framework-aware project quality | Depends on rule |

Best immediate return: `PHPStan + PHPCS + PHP-CS-Fixer dry-run`.

Most unique value: `TAFRA-specific rules`.

Most powerful but most dangerous: `Rector`.

## My recommendation

Yes, these tools are efficient and valuable, but implement them in layers:

First:

- read-only analysis;
- unified report;
- severity/risk classification;
- no source changes.

Then:

- safe cleanup only;
- preview diff;
- user approval.

Later:

- Rector;
- architecture refactoring;
- optimization suggestions.

The real value for TAFRA Studio is not replacing these tools. It is orchestrating them, simplifying their output, and adding TAFRA-aware meaning.