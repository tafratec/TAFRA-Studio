# 02 - Architecture

TAFRA Studio uses a hybrid architecture.

Pascal owns the desktop application, project orchestration, filesystem access,
configuration, process execution, service layer, project model, validation
flow, and user interaction.

PHP is used only as a CLI tooling engine for work that naturally belongs to the
PHP ecosystem, such as future PHP source analysis, Composer-backed tooling, and
framework-specific PHP validation.

## Source Layout

```text
src/forms       Lazarus forms and form event wiring
src/core        App paths, logging, and shared result types
src/models      Internal TAFRA project model
src/services    Project session, scanner, analyzer, process runner, PHP runner
src/framework   TAFRA framework rules and validation
src/ui          UI presenters that render models into controls
src/utils       Small reusable utilities
```

Supporting folders:

```text
tools/php       Studio PHP CLI tools
runtime/php     Private Studio PHP runtime location
resources       Icons and templates
config          Studio configuration
tests           Tests and fixtures
vendor          Future bundled Composer dependencies for Studio tools
docs            Design notes, prompts, and manuals
```

## Main Runtime Flow

The main form should stay thin. It should call services and presenters rather
than owning business logic.

```text
TMainForm
  -> TProjectSession
  -> TProjectScanner
  -> TProjectAnalyzer
  -> TTAFRAProject model
  -> TProjectExplorerPresenter
  -> TTreeView
```

Validation follows the same separation:

```text
TProjectScanner
  -> TTAFRAFrameworkRules
  -> TTAFRAValidationIssue
  -> Project Explorer and Output/Log
```

Analyzer flow:

```text
TMainForm
  -> TProjectAnalyzer
  -> TTAFRAProject.ProjectType
  -> TTAFRAProject.Files
  -> Workspace Analyzer tabs
```

The scanner understands the TAFRA directory shape. The analyzer builds a wider
read-only inventory and classification on top of the scanned project model.

## Important Rules

- Do not execute external processes directly from forms.
- Use `TProcessRunner` for generic process execution.
- Use `TPHPToolRunner` for PHP tooling.
- Keep the Studio PHP runtime separate from any PHP runtime used by an opened
  TAFRA project.
- Keep `TTreeView` as a presentation of the model, not the source of truth.
- Keep analysis read-only toward opened projects.
