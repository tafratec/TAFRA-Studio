# 12 - Code Quality Package Setup

This manual explains when and how TAFRA Studio users should install PHP
packages used by Code Quality analysis.

TAFRA Studio currently detects and runs project-local Composer tools from:

```text
vendor/bin
```

It does not install these packages automatically.

## When to Install Code Quality Packages

Install the packages when:

- the project is actively developed;
- the project has a `composer.json` file;
- developers want repeatable code analysis across machines;
- Code Quality reports show missing tools;
- the project should use the same tools in CI/CD later.

Do not install them when:

- the project is only being inspected temporarily;
- the project has no Composer setup yet;
- you are not allowed to change project dependencies;
- you only need TAFRA Studio's built-in structural checks.

## Recommended Installation Location

Install the packages inside the opened TAFRA project, not globally.

Recommended location:

```text
your-tafra-project/
|-- composer.json
|-- composer.lock
`-- vendor/
    `-- bin/
```

Project-local packages make analysis more reliable because every developer uses
the same versions.

## Step 1 - Open the Project Folder

Open a terminal in the TAFRA project root.

Example:

```text
cd C:\path\to\your-tafra-project
```

The folder should contain:

```text
composer.json
```

If the project does not have `composer.json`, create or initialize Composer only
after confirming this is acceptable for the project.

## Step 2 - Check Composer

Run:

```text
composer --version
```

If Composer is not available globally, use the Composer path configured for the
project or install Composer according to your team's environment policy.

TAFRA Studio should not require global Composer in the long term, but current
manual setup may use it.

## Step 3 - Install PHP-CS-Fixer

PHP-CS-Fixer is used for formatting and style cleanup analysis.

Install:

```text
composer require --dev friendsofphp/php-cs-fixer
```

TAFRA Studio detects:

```text
vendor/bin/php-cs-fixer.bat
vendor/bin/php-cs-fixer.cmd
vendor/bin/php-cs-fixer.exe
vendor/bin/php-cs-fixer
```

Optional configuration files:

```text
.php-cs-fixer.php
.php-cs-fixer.dist.php
```

## Step 4 - Install PHPCS

PHPCS is used for coding-standard analysis.

Install:

```text
composer require --dev squizlabs/php_codesniffer
```

TAFRA Studio detects:

```text
vendor/bin/phpcs.bat
vendor/bin/phpcs.cmd
vendor/bin/phpcs.exe
vendor/bin/phpcs
```

Optional configuration files:

```text
phpcs.xml
phpcs.xml.dist
```

## Step 5 - Install PHPStan

PHPStan is used for static analysis.

Install:

```text
composer require --dev phpstan/phpstan
```

TAFRA Studio detects:

```text
vendor/bin/phpstan.bat
vendor/bin/phpstan.cmd
vendor/bin/phpstan.exe
vendor/bin/phpstan
```

Optional configuration files:

```text
phpstan.neon
phpstan.neon.dist
```

## Step 6 - Install Rector Only When Needed

Rector is used for PHP modernization and AST-based refactoring.

Install only when the team is ready to review structural refactoring proposals:

```text
composer require --dev rector/rector
```

TAFRA Studio detects:

```text
vendor/bin/rector.bat
vendor/bin/rector.cmd
vendor/bin/rector.exe
vendor/bin/rector
```

Optional configuration files:

```text
rector.php
rector.php.dist
```

Rector is currently disabled by default in TAFRA Studio Code Quality
configuration.

## Step 7 - Install All Recommended Tools

To install the commonly recommended read-only analysis tools together:

```text
composer require --dev friendsofphp/php-cs-fixer squizlabs/php_codesniffer phpstan/phpstan
```

Add Rector separately only when needed:

```text
composer require --dev rector/rector
```

## Step 8 - Commit Composer Files

After installation, commit:

```text
composer.json
composer.lock
```

Usually do not commit:

```text
vendor/
```

unless the project has a specific policy requiring vendored dependencies.

## Step 9 - Reopen or Reanalyze in TAFRA Studio

In TAFRA Studio:

```text
Project
`-- Code Quality
    `-- Analyze Code Quality
```

The Output panel should report detected tools instead of missing-tool warnings.

## Current TAFRA Studio Behavior

TAFRA Studio currently:

- detects installed tools;
- detects common configuration files;
- runs enabled available tools in read-only modes;
- parses supported JSON reports;
- adds initial TAFRA convention findings;
- writes findings to the Output panel.

TAFRA Studio currently does not:

- run `composer require`;
- modify project files;
- create tool configuration files;
- apply fixes automatically.

## Recommended Team Policy

For most TAFRA projects, recommended baseline packages are:

```text
friendsofphp/php-cs-fixer
squizlabs/php_codesniffer
phpstan/phpstan
```

Recommended optional package:

```text
rector/rector
```

Use Rector only with preview, review, and approval workflows.
