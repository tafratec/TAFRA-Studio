# 04 - PHP Tooling

TAFRA Studio supports PHP as a secondary CLI tooling engine. PHP is not used as
a web server for the Studio.

TAFRA Studio must not require Apache, Nginx, IIS, XAMPP, or a browser-based
runtime.

## Runtime Separation

There are two different PHP runtime concepts:

```text
TAFRA Studio
|-- Studio PHP Runtime
|   Used internally by TAFRA Studio
|
`-- Project PHP Runtime
    Used by the opened TAFRA application
```

Never assume these are the same PHP version.

## Phase 1 Tool Chain

The required Phase 1 chain is:

```text
Lazarus
  -> TPHPToolRunner
  -> TProcessRunner
  -> runtime/php/php.exe
  -> tools/php/health-check.php
  -> JSON response
  -> parsed Pascal result
  -> Output/Log
```

## Implemented Components

- `TProcessRunner`
  - executable path
  - arguments
  - working directory
  - exit code
  - stdout
  - stderr
  - timeout
  - execution error

- `TPHPToolRunner`
  - calls PHP tools through `TProcessRunner`
  - uses the Studio PHP runtime path from `TAppPaths`
  - parses JSON responses into `TPHPToolResult`

- `tools/php/health-check.php`
  - verifies PHP CLI execution
  - returns PHP version
  - returns JSON

## Health-Check Response

Successful response:

```json
{
  "success": true,
  "php_version": "8.2.27",
  "message": "TAFRA PHP runtime available"
}
```

Failure responses should use the same basic shape:

```json
{
  "success": false,
  "error_code": "PHP_RUNTIME_ERROR",
  "message": "Unable to execute PHP runtime"
}
```

## Composer Position

Composer support is prepared but not required for the Phase 1 health check.

Rules:

- Do not assume global Composer is installed.
- Do not add Composer dependencies without a clear benefit.
- Future Studio PHP dependencies may be bundled under `vendor`.
- Composer dependencies belong to the Studio tooling layer, not to the opened
  TAFRA project.
