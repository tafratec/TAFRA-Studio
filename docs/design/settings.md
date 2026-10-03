Yes — adding a dedicated “Settings” part is the right next step, but I recommend doing it as a small infrastructure feature first, not as a broad preferences system.

The important point: do not make one generic “PHP path” setting. TAFRA Studio architecture requires runtime separation.

Recommended Settings scope now:

```text
Settings
├── PHP Runtime
│   ├── Studio PHP CLI
│   └── Project PHP CLI
└── Composer
    ├── Composer executable / composer.phar
    └── Composer PHP runtime source
```

The current application has `TAppPaths.PHPExecutablePath`, which always resolves to:

```text
runtime/php/php.exe
```

That is good as a default, but it is too rigid once the user needs to configure runtime paths from the UI.

Recommended design:

1. Add Settings UI

Add a new main menu item:

```text
Settings
└── Application Settings
```

Settings should open a Lazarus form/dialog with fields for:

- Studio PHP executable path
- Project PHP executable path
- Composer executable path or composer.phar path
- Composer execution mode

For each executable, provide:

- Browse button
- Test button
- Status/result message

2. Separate Studio PHP from Project PHP

This is the key architectural rule.

Studio PHP CLI:

```text
Used by TAFRA Studio internal PHP tools:
- health-check.php
- module-management.php
- future PHP analyzers
- Studio-owned Composer libraries
```

Default:

```text
runtime/php/php.exe
```

Project PHP CLI:

```text
Used when running commands against the opened TAFRA project:
- project validation
- project Composer commands
- future project PHP checks
```

Default recommendation:

```text
Auto / not configured
```

If not configured, later the app may detect from project, PATH, or ask the user.

Do not assume Studio PHP and Project PHP are the same.

3. Composer setting should also be separated

Composer can exist in more than one form:

```text
composer.bat
composer.exe
composer.phar
bundled composer.phar
```

Recommended settings:

```text
Composer path:
  C:\path\to\composer.bat
  or
  C:\path\to\composer.phar

Composer runtime:
  Use Project PHP
  Use Studio PHP
  Custom PHP
```

Recommended default:

```text
Composer for opened projects should use Project PHP.
Composer for Studio internal tools should use Studio PHP.
```

This avoids corrupt assumptions where Studio’s bundled PHP controls the user’s target project dependencies.

4. Add a settings service, not direct form logic

Recommended new pieces:

```text
src/models/uStudioSettings.pas
src/services/uSettingsService.pas
src/services/uComposerRunner.pas
src/forms/uSettingsForm.pas
```

Responsibilities:

```text
TStudioSettings
  stores configured paths and options

TSettingsService
  loads/saves settings

TPHPToolRunner
  uses configured Studio PHP path

TComposerRunner
  uses TProcessRunner and configured Composer/PHP paths

TSettingsForm
  only edits settings and runs tests through services
```

Avoid calling `php.exe` or `composer` directly from the settings form.

5. Settings persistence

For now, a JSON file is enough.

Recommended file:

```text
config/studio-settings.json
```

Possible structure:

```json
{
  "php": {
    "studio_php": "runtime/php/php.exe",
    "project_php": "",
    "project_php_mode": "auto"
  },
  "composer": {
    "composer_path": "",
    "runtime_mode": "project_php"
  }
}
```

Later, for installed Windows builds, this should move to user-writable storage such as AppData, but for the current development phase, `config/studio-settings.json` is acceptable.

6. Validation actions needed

The Settings dialog should provide:

```text
Test Studio PHP
```

Runs:

```text
tools/php/health-check.php
```

through `TPHPToolRunner`.

```text
Test Project PHP
```

Runs:

```text
php -v
```

through `TProcessRunner`.

```text
Test Composer
```

Runs:

```text
composer --version
```

or:

```text
php composer.phar --version
```

depending on selected Composer mode.

7. Recommended implementation order

I would implement in this order:

1. Create `TStudioSettings` model.
2. Create `TSettingsService` JSON load/save.
3. Modify `TAppPaths` or add a resolver so defaults still work.
4. Modify `TPHPToolRunner` to use configured Studio PHP path instead of hard-coded `runtime/php/php.exe`.
5. Add `TComposerRunner`.
6. Add Settings menu and Settings form.
7. Add test buttons.
8. Update manuals.

8. What not to do

Do not:

- replace `runtime/php/php.exe` concept;
- use one PHP path for everything;
- call Composer directly from UI forms;
- require global Composer;
- require XAMPP or a web server;
- mix project Composer dependencies with Studio Composer dependencies;
- add Composer package-management UI yet.

Final recommendation: implement Settings now as a foundation feature, limited to runtime path configuration and validation. It aligns strongly with Phase 1 architecture and prepares Composer/PHP tooling without prematurely building package management.