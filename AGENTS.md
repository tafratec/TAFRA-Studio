# TAFRA Studio — AGENTS.md

## 1. Project Purpose

TAFRA Studio is a lightweight desktop development environment and
engineering tool specifically designed for projects based on the
TAFRA Framework.

It is NOT intended to replace VS Code, PhpStorm, or another
general-purpose source-code editor.

TAFRA Studio provides framework-aware tools for:

- TAFRA project management
- Module and submodule management
- Code generation
- Project structure analysis
- Configuration management
- Database/DDL tooling
- Validation
- PHP tooling
- Composer-based tooling
- Git integration
- Codex-assisted development
- External editor integration

The Studio will primarily manage projects containing:

- PHP
- JavaScript
- HTML
- CSS
- SQL
- JSON
- Markdown
- configuration files


## 2. Primary Technology

TAFRA Studio is a native desktop application.

Primary development environment:

- Lazarus 4.8
- Free Pascal
- Lazarus LCL

The application must open, compile, debug, and run normally from
the Lazarus IDE.

Do not introduce technologies that prevent normal Lazarus IDE
development.


## 3. Core Architectural Principle

TAFRA Studio uses a hybrid architecture.

Responsibilities are divided between:

### Lazarus / Free Pascal

Use Pascal for:

- Desktop GUI
- Project navigation
- Filesystem operations
- Application configuration
- Process execution
- Operating-system integration
- Project orchestration
- Studio services
- User interaction

### PHP

PHP is a secondary tooling engine.

Use PHP CLI when functionality is naturally better implemented
using the PHP ecosystem, particularly:

- PHP source-code analysis
- PHP AST processing
- Composer libraries
- PHP validation
- Framework-specific PHP tooling
- Future TAFRA command-line tools

Do NOT duplicate mature PHP functionality in Pascal without a
clear technical reason.


## 4. PHP Runtime Architecture

TAFRA Studio must support a private PHP CLI runtime.

PHP is NOT used as a web server for TAFRA Studio.

The Studio must not require:

- Apache
- Nginx
- IIS
- XAMPP
- a browser-based runtime

The intended architecture is:

    Lazarus
        |
        v
    TPHPToolRunner
        |
        v
    TProcessRunner
        |
        v
    PHP CLI
        |
        v
    TAFRA PHP Tool
        |
        v
    Composer libraries
        |
        v
    JSON response


## 5. PHP Runtime Separation

Keep the Studio PHP runtime separate from the PHP runtime used
by a TAFRA project.

Conceptually:

    TAFRA Studio
    |
    +-- Studio PHP Runtime
    |     Used internally by TAFRA Studio
    |
    +-- Project PHP Runtime
          Used by the developer's TAFRA project

Never assume that both runtimes use the same PHP version.

Future Studio versions may use a different PHP version from the
target TAFRA application.


## 6. Process Execution

External processes must not be executed randomly throughout the
application.

Create a centralized process execution abstraction.

Primary service:

    TProcessRunner

Responsibilities include:

- executable path
- arguments
- working directory
- exit code
- stdout capture
- stderr capture
- timeout handling
- execution errors

PHP execution must be implemented through:

    TPHPToolRunner

TPHPToolRunner must internally use TProcessRunner.

Do not directly invoke php.exe from forms or unrelated units.


## 7. PHP Tool Communication

Communication between Lazarus and PHP tools should use JSON
whenever structured information is returned.

Successful example:

    {
        "success": true,
        "php_version": "8.2.27",
        "message": "TAFRA PHP runtime available"
    }

Failure example:

    {
        "success": false,
        "error_code": "PHP_RUNTIME_ERROR",
        "message": "Unable to execute PHP runtime"
    }

Avoid parsing human-readable console output when structured JSON
can be returned.


## 8. Directory Philosophy

Keep application responsibilities separated.

Suggested structure:

    /src
        /core
        /services
        /ui
        /models
        /utils

    /runtime
        /php

    /tools
        /php

    /resources
        /templates

    /config

Exact directories may evolve as the architecture develops.

Do not reorganize the entire project without a concrete
architectural requirement.


## 9. Phase 1 Scope

Phase 1 establishes the application foundation only.

Implement:

- Lazarus project
- Main application shell
- Core directory structure
- Application configuration
- Path handling
- TProcessRunner
- TPHPToolRunner
- PHP runtime configuration
- PHP health-check tool
- JSON response handling
- Basic error handling
- Basic logging

The Phase 1 PHP integration is a proof of architecture.

Do NOT implement advanced PHP tooling during Phase 1.


## 10. Out of Scope for Phase 1

Do NOT implement unless explicitly requested:

- PHP AST parsing
- Composer package management UI
- TAFRA module generation
- TAFRA submodule generation
- Automatic controller generation
- Automatic model generation
- Database designer
- Git GUI
- Codex integration
- VS Code integration
- Full source-code editor
- syntax highlighting engine
- debugging environment
- deployment management

These belong to later phases.


## 11. Composer Strategy

TAFRA Studio may use Composer packages through its PHP tooling
layer.

Composer is primarily a development/dependency-management tool.

Production/release builds should eventually be capable of
shipping the required PHP dependencies with TAFRA Studio.

Do not assume Composer must be globally installed on the user's
Windows machine.

Do not introduce a Composer dependency unless it provides a
clear benefit.


## 12. Windows Deployment

TAFRA Studio is initially Windows-focused.

The target deployment model is approximately:

    TAFRA Studio/
    |
    +-- TafraStudio.exe
    |
    +-- runtime/
    |   +-- php/
    |       +-- php.exe
    |       +-- php.ini
    |       +-- ext/
    |
    +-- tools/
    |   +-- php/
    |
    +-- vendor/
    |
    +-- resources/
    |
    +-- config/

The final installer should eventually be capable of installing
TAFRA Studio without requiring the user to separately configure
PHP, Composer, XAMPP, or a web server.


## 13. Coding Rules

Prefer:

- simple architecture
- small focused units
- explicit dependencies
- readable Pascal
- meaningful class names
- centralized configuration
- reusable services
- clear error handling

Avoid:

- unnecessary abstraction
- premature frameworks
- global state
- duplicated process execution code
- hard-coded absolute paths
- GUI logic mixed with tooling logic
- premature optimization


## 14. Development Philosophy

TAFRA Studio must grow incrementally.

For every feature:

1. Define the responsibility.
2. Define the architectural layer.
3. Implement the smallest useful version.
4. Test it.
5. Document important decisions.
6. Continue to the next capability.

Do not build speculative functionality simply because it may be
useful later.


## 15. Codex Instructions

When modifying TAFRA Studio:

- Read this AGENTS.md first.
- Respect the current project structure.
- Inspect existing code before creating replacements.
- Prefer modifying existing abstractions over duplicating them.
- Keep Lazarus 4.8 compatibility.
- Keep Free Pascal compatibility.
- Keep Windows compatibility.
- Do not introduce unnecessary dependencies.
- Do not convert TAFRA Studio into a PHP application.
- Do not introduce a web server requirement.
- Route PHP execution through TPHPToolRunner.
- Route generic external processes through TProcessRunner.
- Keep UI and tooling/business logic separated.
- Keep changes scoped to the requested phase or task.
- Compile/test relevant changes whenever practical.


## 16. Phase 1 Completion Criteria

Phase 1 is complete when:

1. TAFRA Studio opens successfully in Lazarus 4.8.
2. The project compiles without errors.
3. The application runs as a Windows desktop application.
4. Core paths/configuration are initialized.
5. TProcessRunner can execute an external process.
6. TPHPToolRunner can invoke the configured PHP CLI runtime.
7. The PHP health-check tool executes successfully.
8. Lazarus receives and parses the JSON response.
9. PHP/process failures are handled without crashing the Studio.
10. The architecture is ready for Phase 2 without major restructuring.