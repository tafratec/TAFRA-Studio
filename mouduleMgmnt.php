<?php

declare(strict_types=1);

/**
 * TAFRA Framework - Module/Submodule Management
 *
 * Development CLI tool:
 * php tools/mouduleMgmnt.php
 */

if (PHP_SAPI !== 'cli') {
    fwrite(STDERR, 'Error: mouduleMgmnt.php can run only from the CLI.' . PHP_EOL);
    exit(1);
}

$basePath = dirname(__DIR__);
$configFile = $basePath . '/app/modules/common/sysmodules/moduleConfig.php';
$modulesRoot = $basePath . '/app/modules';
$appConfigFile = $basePath . '/app/config/config.php';
$environmentFile = $basePath . '/app/bootstrap/environment.php';

defined('BASE_PATH') || define('BASE_PATH', $basePath);

if (is_file($appConfigFile)) {
    require_once $appConfigFile;
}

if (!defined('APP_ENV') && is_file($environmentFile)) {
    require_once $environmentFile;
}

if (!defined('APP_ENV') || APP_ENV !== 'development') {
    fwrite(STDERR, 'Error: mouduleMgmnt.php can run only when APP_ENV == development.' . PHP_EOL);
    exit(1);
}

if (!is_file($configFile)) {
    fwrite(STDERR, "Error: moduleConfig.php not found at: {$configFile}" . PHP_EOL);
    exit(1);
}

$moduleConfig = require $configFile;

if (!is_array($moduleConfig)) {
    fwrite(STDERR, 'Error: moduleConfig.php must return an array.' . PHP_EOL);
    exit(1);
}

const CLI_YELLOW = "\033[33m";
const CLI_RESET = "\033[0m";

function fail(string $message): never
{
    fwrite(STDERR, 'Error: ' . $message . PHP_EOL);
    exit(1);
}

function colorize(string $text, ?string $color = null): string
{
    return $color === null ? $text : $color . $text . CLI_RESET;
}

function ask(string $label, ?string $default = null, ?string $color = null): string
{
    $defaultText = $default !== null ? " [default: {$default}]" : '';
    echo colorize("{$label}{$defaultText}: ", $color);

    $input = fgets(STDIN);

    if ($input === false) {
        fail('Unable to read CLI input.');
    }

    $value = trim($input);

    return $value !== '' ? $value : (string) $default;
}

function askBool(string $label, bool $default = true, ?string $color = null): bool
{
    $defaultText = $default ? 'yes' : 'no';

    while (true) {
        $value = strtolower(ask($label . ' yes/no', $defaultText, $color));

        if (in_array($value, ['1', 'true', 'yes', 'y'], true)) {
            return true;
        }

        if (in_array($value, ['0', 'false', 'no', 'n'], true)) {
            return false;
        }

        echo "Please answer yes or no." . PHP_EOL;
    }
}

function askOptional(string $label, ?string $color = null): ?string
{
    echo colorize("{$label}: ", $color);

    $input = fgets(STDIN);

    if ($input === false) {
        fail('Unable to read CLI input.');
    }

    $value = trim($input);

    return $value === '' ? null : $value;
}

function askConfirm(string $label, bool $default = false, ?string $color = null): bool
{
    return askBool($label, $default, $color);
}

function validName(string $name): bool
{
    return preg_match('/^[A-Za-z][A-Za-z0-9_]*$/', $name) === 1;
}

function studly(string $value): string
{
    return str_replace(' ', '', ucwords(str_replace(['-', '_'], ' ', $value)));
}

function namespaceName(string ...$parts): string
{
    return implode('\\', array_map(
        static fn(string $part): string => str_replace('\\', '', trim($part)),
        $parts
    ));
}

function ensureDir(string $path): void
{
    if (is_dir($path)) {
        return;
    }

    if (file_exists($path)) {
        fail("Path exists and is not a directory: {$path}");
    }

    if (!mkdir($path, 0775, true) && !is_dir($path)) {
        fail("Unable to create directory: {$path}");
    }
}

function writeFileIfMissing(string $path, string $content): void
{
    if (file_exists($path)) {
        return;
    }

    ensureDir(dirname($path));

    if (file_put_contents($path, $content, LOCK_EX) === false) {
        fail("Unable to write file: {$path}");
    }
}

function exportConfig(string $configFile, array $config): void
{
    $content = "<?php\n\nreturn " . var_export($config, true) . ";\n";
    $tempFile = $configFile . '.tmp';

    if (file_put_contents($tempFile, $content, LOCK_EX) === false) {
        fail("Unable to write temporary config file: {$tempFile}");
    }

    if (!rename($tempFile, $configFile)) {
        @unlink($tempFile);
        fail("Unable to replace config file: {$configFile}");
    }
}

function getModuleTemplate(array $config): array
{
    foreach ($config as $module) {
        if (is_array($module)) {
            return $module;
        }
    }

    return [
        'enabled' => true,
        'show_in_navbar' => true,
        'menu_title' => '',
        'display_order' => 1,
        'tool_tip' => '',
        'enable_tooltip' => false,
        'requires_login' => true,
        'submodules' => [],
    ];
}

function getSubmoduleTemplate(array $moduleConfig): array
{
    foreach ($moduleConfig as $module) {
        if (!empty($module['submodules']) && is_array($module['submodules'])) {
            foreach ($module['submodules'] as $submodule) {
                if (is_array($submodule)) {
                    return $submodule;
                }
            }
        }
    }

    return [
        'enabled' => true,
        'show_in_navbar' => true,
        'menu_title' => '',
        'display_order' => 1,
        'tool_tip' => '',
        'enable_tooltip' => false,
        'requires_login' => true,
    ];
}

function promptByTemplate(array $template, string $name, ?int $displayOrder = null, ?string $promptColor = null): array
{
    $data = [];

    foreach ($template as $key => $default) {
        if ($key === 'submodules') {
            $data[$key] = [];
            continue;
        }

        if ($key === 'menu_title') {
            $data[$key] = ask('Menu title', studly($name), $promptColor);
            continue;
        }

        if ($key === 'display_order') {
            $orderDefault = $displayOrder ?? (filter_var($default, FILTER_VALIDATE_INT) !== false ? (int) $default : 1);
            $value = ask('Display order', (string) $orderDefault, $promptColor);
            $data[$key] = filter_var($value, FILTER_VALIDATE_INT) !== false ? (int) $value : $orderDefault;
            continue;
        }

        if ($key === 'tool_tip') {
            $data[$key] = ask('Tool tip', (string) ($data['menu_title'] ?? studly($name)), $promptColor);
            continue;
        }

        if ($key === 'enable_tooltip') {
            $data[$key] = askBool('Enable tooltip', false, $promptColor);
            continue;
        }

        if (is_bool($default)) {
            $data[$key] = askBool($key, true, $promptColor);
            continue;
        }

        if (is_array($default)) {
            $data[$key] = $default;
            continue;
        }

        $data[$key] = ask($key, (string) $default, $promptColor);
    }

    return $data;
}

function routePathFromName(string $name): string
{
    $route = preg_replace('/([a-z])([A-Z])/', '$1-$2', $name) ?? $name;
    $route = strtolower(str_replace('_', '-', $route));

    return '/' . trim($route, '/');
}

function appendSubmoduleRoute(string $routesFile, string $moduleName, string $submoduleName): void
{
    $classBase = studly($submoduleName);
    $controllerClass = $classBase . 'Controller';
    $controllerFqn = namespaceName('Modules', $moduleName, 'submodules', $submoduleName, $controllerClass);
    $useLine = 'use ' . $controllerFqn . ';';
    $routeLine = "\$this->get('" . routePathFromName($submoduleName) . "', [{$controllerClass}::class, 'index']);";

    if (!file_exists($routesFile)) {
        writeFileIfMissing(
            $routesFile,
            "<?php\n\ndeclare(strict_types=1);\n\n// Routes for {$moduleName} module.\n// Keep routes registered even when the module/submodule is disabled;\n// BaseController blocks disabled features with the disabled-action response.\n"
        );
    }

    $content = (string) file_get_contents($routesFile);

    if (!str_contains($content, $useLine)) {
        if (preg_match('/declare\(strict_types=1\);\s*/', $content, $matches, PREG_OFFSET_CAPTURE)) {
            $insertAt = $matches[0][1] + strlen($matches[0][0]);
            $content = substr($content, 0, $insertAt) . "\n" . $useLine . "\n" . substr($content, $insertAt);
        } else {
            $content = $useLine . "\n" . $content;
        }
    }

    if (!str_contains($content, $routeLine)) {
        $content = rtrim($content) . "\n" . $routeLine . "\n";
    }

    if (file_put_contents($routesFile, $content, LOCK_EX) === false) {
        fail("Unable to update routes file: {$routesFile}");
    }
}

function removeSubmoduleRoute(string $routesFile, string $moduleName, string $submoduleName): void
{
    if (!is_file($routesFile)) {
        return;
    }

    $classBase = studly($submoduleName);
    $controllerClass = $classBase . 'Controller';
    $controllerFqn = namespaceName('Modules', $moduleName, 'submodules', $submoduleName, $controllerClass);
    $content = (string) file_get_contents($routesFile);
    $lines = preg_split('/\R/', $content);

    if (!is_array($lines)) {
        fail("Unable to parse routes file: {$routesFile}");
    }

    $filtered = [];

    foreach ($lines as $line) {
        if (str_contains($line, 'use ' . $controllerFqn . ';')) {
            continue;
        }

        if (str_contains($line, '[' . $controllerClass . '::class,')) {
            continue;
        }

        $filtered[] = $line;
    }

    $newContent = rtrim(implode(PHP_EOL, $filtered)) . PHP_EOL;

    if (file_put_contents($routesFile, $newContent, LOCK_EX) === false) {
        fail("Unable to update routes file: {$routesFile}");
    }
}

function deleteDirectoryTree(string $targetPath, string $allowedRoot): void
{
    if (!file_exists($targetPath)) {
        return;
    }

    $resolvedTarget = realpath($targetPath);
    $resolvedRoot = realpath($allowedRoot);

    if ($resolvedTarget === false || $resolvedRoot === false) {
        fail('Unable to resolve deletion paths.');
    }

    $normalizedTarget = rtrim(str_replace('\\', '/', $resolvedTarget), '/');
    $normalizedRoot = rtrim(str_replace('\\', '/', $resolvedRoot), '/');

    if ($normalizedTarget === $normalizedRoot || !str_starts_with($normalizedTarget . '/', $normalizedRoot . '/')) {
        fail("Refusing to delete path outside allowed root: {$targetPath}");
    }

    if (!is_dir($resolvedTarget)) {
        fail("Delete target is not a directory: {$targetPath}");
    }

    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($resolvedTarget, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::CHILD_FIRST
    );

    foreach ($iterator as $item) {
        $path = $item->getPathname();

        if ($item->isDir()) {
            if (!rmdir($path)) {
                fail("Unable to delete directory: {$path}");
            }
        } elseif (!unlink($path)) {
            fail("Unable to delete file: {$path}");
        }
    }

    if (!rmdir($resolvedTarget)) {
        fail("Unable to delete directory: {$resolvedTarget}");
    }
}

function deleteSubmoduleEffects(array &$moduleConfig, string $modulesRoot, string $moduleName, string $submoduleName): void
{
    unset($moduleConfig[$moduleName]['submodules'][$submoduleName]);
    removeSubmoduleRoute($modulesRoot . '/' . $moduleName . '/routes.php', $moduleName, $submoduleName);
    deleteDirectoryTree(
        $modulesRoot . '/' . $moduleName . '/submodules/' . $submoduleName,
        $modulesRoot . '/' . $moduleName . '/submodules'
    );
}

function printRemainingSubmoduleReferences(string $basePath, string $moduleName, string $submoduleName): void
{
    $references = [];
    $patterns = [
        $submoduleName,
        studly($submoduleName) . 'Controller',
        studly($submoduleName) . 'Model',
        studly($submoduleName) . 'Service',
        trim($moduleName, '/') . '/submodules/' . trim($submoduleName, '/'),
    ];

    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($basePath . '/app', FilesystemIterator::SKIP_DOTS)
    );

    foreach ($iterator as $item) {
        if (!$item->isFile() || strtolower($item->getExtension()) !== 'php') {
            continue;
        }

        $path = $item->getPathname();
        $content = (string) file_get_contents($path);

        foreach ($patterns as $pattern) {
            if ($pattern !== '' && str_contains($content, $pattern)) {
                $references[] = $path;
                break;
            }
        }
    }

    $references = array_values(array_unique($references));

    if ($references === []) {
        return;
    }

    echo PHP_EOL . 'Warning: possible remaining references found:' . PHP_EOL;

    foreach ($references as $path) {
        echo ' - ' . $path . PHP_EOL;
    }
}

function printRemainingModuleReferences(string $basePath, string $moduleName): void
{
    $references = [];
    $patterns = [
        $moduleName,
        'Modules\\' . $moduleName,
        trim($moduleName, '/') . '/submodules',
        $moduleName . '.json',
    ];

    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($basePath . '/app', FilesystemIterator::SKIP_DOTS)
    );

    foreach ($iterator as $item) {
        if (!$item->isFile() || strtolower($item->getExtension()) !== 'php') {
            continue;
        }

        $path = $item->getPathname();
        $content = (string) file_get_contents($path);

        foreach ($patterns as $pattern) {
            if ($pattern !== '' && str_contains($content, $pattern)) {
                $references[] = $path;
                break;
            }
        }
    }

    $references = array_values(array_unique($references));

    if ($references === []) {
        return;
    }

    echo PHP_EOL . 'Warning: possible remaining module references found:' . PHP_EOL;

    foreach ($references as $path) {
        echo ' - ' . $path . PHP_EOL;
    }
}

function relativePath(string $path, string $basePath): string
{
    $normalizedPath = str_replace('\\', '/', $path);
    $normalizedBase = rtrim(str_replace('\\', '/', $basePath), '/');

    if (str_starts_with($normalizedPath, $normalizedBase . '/')) {
        return substr($normalizedPath, strlen($normalizedBase) + 1);
    }

    return $normalizedPath;
}

function addNamingTarget(array &$targets, string $category, string $name, string $source): void
{
    $name = trim($name);

    if ($name === '') {
        return;
    }

    $key = strtolower($category . ':' . $name);
    $targets[$key] ??= [
        'category' => $category,
        'name' => $name,
        'source' => $source,
    ];
}

function addNamingFinding(
    array &$findings,
    string $category,
    string $file,
    int $line,
    string $found,
    string $current,
    string $source
): void {
    if ($found === $current || strtolower($found) !== strtolower($current)) {
        return;
    }

    $key = strtolower($category . '|' . $file . '|' . $line . '|' . $found . '|' . $current);
    $findings[$key] = [
        'category' => $category,
        'file' => $file,
        'line' => $line,
        'found' => $found,
        'current' => $current,
        'source' => $source,
    ];
}

function phpFilesUnder(string $path): array
{
    if (!is_dir($path)) {
        return [];
    }

    $files = [];
    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($path, FilesystemIterator::SKIP_DOTS)
    );

    foreach ($iterator as $item) {
        if ($item->isFile() && strtolower($item->getExtension()) === 'php') {
            $files[] = $item->getPathname();
        }
    }

    sort($files);

    return $files;
}

function addNamingTargetsFromPhpFiles(array &$targets, array $files, string $basePath): void
{
    foreach ($files as $file) {
        $basename = pathinfo($file, PATHINFO_FILENAME);
        addNamingTarget($targets, 'PHP file', $basename, relativePath($file, $basePath));

        if (str_ends_with(strtolower($basename), 'view')) {
            addNamingTarget($targets, 'View name', $basename, relativePath($file, $basePath));
        }

        $content = (string) file_get_contents($file);

        if (preg_match_all('/\b(class|interface|trait|enum)\s+([A-Za-z_][A-Za-z0-9_]*)\b/i', $content, $matches, PREG_SET_ORDER)) {
            foreach ($matches as $match) {
                addNamingTarget($targets, ucfirst(strtolower($match[1])) . ' name', $match[2], relativePath($file, $basePath));
            }
        }

        if (preg_match_all('/\bconst\s+([A-Za-z_][A-Za-z0-9_]*)\b/', $content, $matches)) {
            foreach ($matches[1] as $constantName) {
                addNamingTarget($targets, 'Constant name', $constantName, relativePath($file, $basePath));
            }
        }

        if (preg_match_all('/\bdefine\s*\(\s*[\'"]([A-Za-z_][A-Za-z0-9_]*)[\'"]/', $content, $matches)) {
            foreach ($matches[1] as $constantName) {
                addNamingTarget($targets, 'Constant name', $constantName, relativePath($file, $basePath));
            }
        }
    }
}

function addNamingTargetsFromRoutes(
    array &$targets,
    string $routesFile,
    string $basePath,
    ?string $submoduleName = null
): void {
    if (!is_file($routesFile)) {
        return;
    }

    $routesContent = (string) file_get_contents($routesFile);
    $controllerClass = $submoduleName !== null ? studly($submoduleName) . 'Controller' : null;

    if (preg_match_all('/\$this->(?:get|post|put|patch|delete)\s*\(\s*[\'"]([^\'"]+)[\'"]\s*,\s*\[([A-Za-z_][A-Za-z0-9_]*)::class/i', $routesContent, $matches, PREG_SET_ORDER)) {
        foreach ($matches as $match) {
            $routePath = $match[1];
            $routeController = $match[2];

            if (
                $submoduleName !== null
                && $controllerClass !== null
                && strcasecmp($routeController, $controllerClass) !== 0
                && stripos($routePath, $submoduleName) === false
            ) {
                continue;
            }

            addNamingTarget($targets, 'Route path', $routePath, relativePath($routesFile, $basePath));
        }
    }
}

function collectModuleNamingTargets(string $moduleName, string $modulePath, string $basePath): array
{
    $targets = [];
    addNamingTarget($targets, 'Module name', $moduleName, 'Selected module');

    $actualModulePath = realpath($modulePath);

    if ($actualModulePath !== false) {
        addNamingTarget($targets, 'Module folder', basename($actualModulePath), relativePath($actualModulePath, $basePath));
    }

    $submodulesPath = $modulePath . '/submodules';

    if (is_dir($submodulesPath)) {
        $submoduleIterator = new DirectoryIterator($submodulesPath);

        foreach ($submoduleIterator as $item) {
            if ($item->isDot() || !$item->isDir()) {
                continue;
            }

            addNamingTarget($targets, 'Submodule folder', $item->getBasename(), relativePath($item->getPathname(), $basePath));
        }
    }

    addNamingTargetsFromPhpFiles($targets, phpFilesUnder($modulePath), $basePath);
    addNamingTargetsFromRoutes($targets, $modulePath . '/routes.php', $basePath);

    return array_values($targets);
}

function collectSubmoduleNamingTargets(string $moduleName, string $submoduleName, string $modulePath, string $submodulePath, string $basePath): array
{
    $targets = [];
    addNamingTarget($targets, 'Module name', $moduleName, 'Selected module');
    addNamingTarget($targets, 'Submodule name', $submoduleName, 'Selected submodule');

    $actualSubmodulePath = realpath($submodulePath);

    if ($actualSubmodulePath !== false) {
        addNamingTarget($targets, 'Submodule folder', basename($actualSubmodulePath), relativePath($actualSubmodulePath, $basePath));
    }

    addNamingTargetsFromPhpFiles($targets, phpFilesUnder($submodulePath), $basePath);
    addNamingTargetsFromRoutes($targets, $modulePath . '/routes.php', $basePath, $submoduleName);

    return array_values($targets);
}

function scanPhpTokensForNamingFindings(array &$findings, array $targetsByLowerName, string $file, string $basePath): void
{
    $content = (string) file_get_contents($file);
    $tokens = token_get_all($content);

    foreach ($tokens as $token) {
        if (!is_array($token)) {
            continue;
        }

        [$id, $text, $line] = $token;

        if (!in_array($id, [T_STRING, T_NAME_QUALIFIED, T_NAME_FULLY_QUALIFIED], true)) {
            continue;
        }

        $parts = preg_split('/\\\\+/', ltrim($text, '\\')) ?: [];

        foreach ($parts as $part) {
            $target = $targetsByLowerName[strtolower($part)] ?? null;

            if ($target === null) {
                continue;
            }

            addNamingFinding(
                $findings,
                $target['category'],
                relativePath($file, $basePath),
                (int) $line,
                $part,
                $target['name'],
                $target['source']
            );
        }
    }
}

function scanTextForNamingFindings(array &$findings, array $targets, string $file, string $basePath): void
{
    $lines = file($file, FILE_IGNORE_NEW_LINES);

    if ($lines === false) {
        return;
    }

    foreach ($lines as $index => $lineText) {
        foreach ($targets as $target) {
            if (in_array($target['category'], ['Constant name', 'PHP file'], true)) {
                continue;
            }

            $name = $target['name'];
            $pattern = preg_match('/^[A-Za-z_][A-Za-z0-9_]*$/', $name) === 1
                ? '/(?<![A-Za-z0-9_])' . preg_quote($name, '/') . '(?![A-Za-z0-9_])/i'
                : '/' . preg_quote($name, '/') . '/i';

            if (!preg_match_all($pattern, $lineText, $matches)) {
                continue;
            }

            foreach ($matches[0] as $found) {
                addNamingFinding(
                    $findings,
                    $target['category'],
                    relativePath($file, $basePath),
                    $index + 1,
                    $found,
                    $name,
                    $target['source']
                );
            }
        }
    }
}

function writeNamingReport(
    string $basePath,
    string $moduleName,
    ?string $submoduleName,
    array $findings,
    DateTimeImmutable $createdAt
): string {
    $logsPath = $basePath . '/storage/logs';
    ensureDir($logsPath);

    $reportPath = $logsPath . '/CheckNaming' . $createdAt->format('Ymd_His') . '.md';
    $creator = getenv('USERNAME') ?: getenv('USER') ?: get_current_user();
    $creator = is_string($creator) && trim($creator) !== '' ? trim($creator) : 'N/A';
    $lines = [
        '# Check Naming Report',
        '',
        '- Date time: ' . $createdAt->format('Y-m-d H:i:s'),
        '- Scope: ' . ($submoduleName === null ? 'Module' : 'Submodule'),
        '- Module: ' . $moduleName,
        '- Submodule: ' . ($submoduleName ?? 'N/A'),
        '- Creator: ' . $creator,
        '- Findings: ' . count($findings),
        '',
    ];

    if ($findings === []) {
        $lines[] = 'No case-difference naming issues found.';
    } else {
        $lines[] = '| Type | Calling file | Line | Object name in call | Current object name | Current source |';
        $lines[] = '| --- | --- | ---: | --- | --- | --- |';

        foreach ($findings as $finding) {
            $lines[] = '| '
                . str_replace('|', '\\|', $finding['category']) . ' | '
                . str_replace('|', '\\|', $finding['file']) . ' | '
                . (int) $finding['line'] . ' | `'
                . str_replace('`', '\`', $finding['found']) . '` | `'
                . str_replace('`', '\`', $finding['current']) . '` | '
                . str_replace('|', '\\|', $finding['source']) . ' |';
        }
    }

    if (file_put_contents($reportPath, implode(PHP_EOL, $lines) . PHP_EOL, LOCK_EX) === false) {
        fail("Unable to write naming report: {$reportPath}");
    }

    return $reportPath;
}

function runNamingScan(array $targets, array $filesToScan, string $basePath): array
{
    $targetsByLowerName = [];

    foreach ($targets as $target) {
        if (preg_match('/^[A-Za-z_][A-Za-z0-9_]*$/', $target['name']) === 1) {
            $targetsByLowerName[strtolower($target['name'])] ??= $target;
        }
    }

    $findings = [];

    foreach (array_values(array_unique($filesToScan)) as $file) {
        scanPhpTokensForNamingFindings($findings, $targetsByLowerName, $file, $basePath);
        scanTextForNamingFindings($findings, $targets, $file, $basePath);
    }

    uasort(
        $findings,
        static fn(array $left, array $right): int => [$left['file'], $left['line'], $left['category']] <=> [$right['file'], $right['line'], $right['category']]
    );

    return array_values($findings);
}

function runCheckNamingTool(array $moduleConfig, string $modulesRoot, string $basePath): never
{
    $moduleName = selectFromList($moduleConfig, 'Choose main module for naming check', CLI_YELLOW);

    if ($moduleName === null) {
        echo PHP_EOL . 'Naming check canceled.' . PHP_EOL;
        exit(0);
    }

    if (!validName($moduleName)) {
        fail('Selected module name contains unsupported characters.');
    }

    echo PHP_EOL;
    echo colorize('Choose naming check scope', CLI_YELLOW) . PHP_EOL;
    echo colorize('1 - Whole module', CLI_YELLOW) . PHP_EOL;
    echo colorize('2 - Single submodule', CLI_YELLOW) . PHP_EOL;
    echo colorize('0 - Exit', CLI_YELLOW) . PHP_EOL;

    $scopeChoice = ask('Enter choice', '1', CLI_YELLOW);

    if ($scopeChoice === '0') {
        echo PHP_EOL . 'Naming check canceled.' . PHP_EOL;
        exit(0);
    }

    $modulePath = $modulesRoot . '/' . $moduleName;

    if (!is_dir($modulePath)) {
        fail("Module folder not found: {$modulePath}");
    }

    $submoduleName = null;

    if ($scopeChoice === '1') {
        $targets = collectModuleNamingTargets($moduleName, $modulePath, $basePath);
        $filesToScan = phpFilesUnder($modulePath);
    } elseif ($scopeChoice === '2') {
        $submodules = $moduleConfig[$moduleName]['submodules'] ?? [];

        if (!is_array($submodules) || $submodules === []) {
            echo colorize("Module '{$moduleName}' has no submodules.", CLI_YELLOW) . PHP_EOL;
            exit(0);
        }

        $submoduleName = selectFromList($submodules, "Choose submodule under '{$moduleName}' for naming check", CLI_YELLOW);

        if ($submoduleName === null) {
            echo PHP_EOL . 'Naming check canceled.' . PHP_EOL;
            exit(0);
        }

        if (!validName($submoduleName)) {
            fail('Selected submodule name contains unsupported characters.');
        }

        $submodulePath = $modulePath . '/submodules/' . $submoduleName;

        if (!is_dir($submodulePath)) {
            fail("Submodule folder not found: {$submodulePath}");
        }

        $targets = collectSubmoduleNamingTargets($moduleName, $submoduleName, $modulePath, $submodulePath, $basePath);
        $filesToScan = phpFilesUnder($submodulePath);
        $routesFile = $modulePath . '/routes.php';

        if (is_file($routesFile)) {
            $filesToScan[] = $routesFile;
        }
    } else {
        fail('Invalid naming check scope.');
    }

    $findings = runNamingScan($targets, $filesToScan, $basePath);
    $reportPath = writeNamingReport($basePath, $moduleName, $submoduleName, $findings, new DateTimeImmutable());

    echo PHP_EOL . 'Naming check completed.' . PHP_EOL;
    echo 'Report: ' . $reportPath . PHP_EOL;
    echo 'Findings: ' . count($findings) . PHP_EOL;
    exit(0);
}

function controllerStub(string $moduleName, string $submoduleName): string
{
    $classBase = studly($submoduleName);
    $namespace = namespaceName('Modules', $moduleName, 'submodules', $submoduleName);
    $viewName = $submoduleName . 'view';
    $viewPath = '/' . trim($moduleName, '/') . '/submodules/' . trim($submoduleName, '/') . '/' . $viewName;

    return <<<PHP
<?php

declare(strict_types=1);

namespace {$namespace};

use Base\BaseController;
use Core\Security\CSRF;

class {$classBase}Controller extends BaseController
{
    public function __construct(
        private ?{$classBase}Service \$service = null
    ) {
        parent::__construct();

        \$this->service ??= new {$classBase}Service(new {$classBase}Model());
    }

    public function index(): void
    {
        echo \\getView('{$viewPath}', [
            'csrfToken' => CSRF::generate(),
        ]);
    }
}
PHP;
}

function serviceStub(string $moduleName, string $submoduleName): string
{
    $classBase = studly($submoduleName);
    $namespace = namespaceName('Modules', $moduleName, 'submodules', $submoduleName);

    return <<<PHP
<?php

declare(strict_types=1);

namespace {$namespace};

class {$classBase}Service
{
    public function __construct(private readonly {$classBase}Model \$model) {}
}
PHP;
}

function modelStub(string $moduleName, string $submoduleName): string
{
    $classBase = studly($submoduleName);
    $namespace = namespaceName('Modules', $moduleName, 'submodules', $submoduleName);

    return <<<PHP
<?php

declare(strict_types=1);

namespace {$namespace};

use Base\BaseModel;

class {$classBase}Model extends BaseModel
{
}
PHP;
}

function viewStub(string $title): string
{
    $safeTitle = htmlspecialchars($title, ENT_QUOTES, 'UTF-8');

    return <<<HTML
<section class="container py-4">
    <h1>{$safeTitle}</h1>
</section>
HTML;
}

function valueToDisplay(mixed $value): string
{
    if (is_bool($value)) {
        return $value ? 'true' : 'false';
    }

    if (is_array($value)) {
        return 'array(' . count($value) . ')';
    }

    if ($value === null) {
        return 'null';
    }

    return (string) $value;
}

function castPropertyValue(string $input, mixed $currentValue): mixed
{
    if (is_bool($currentValue)) {
        $normalized = strtolower($input);

        if (in_array($normalized, ['1', 'true', 'yes', 'y'], true)) {
            return true;
        }

        if (in_array($normalized, ['0', 'false', 'no', 'n'], true)) {
            return false;
        }

        echo "Invalid boolean value. Keeping current value." . PHP_EOL;
        return $currentValue;
    }

    if (is_int($currentValue)) {
        return filter_var($input, FILTER_VALIDATE_INT) !== false ? (int) $input : $currentValue;
    }

    if (is_float($currentValue)) {
        return is_numeric($input) ? (float) $input : $currentValue;
    }

    if ($currentValue === null) {
        return strtolower($input) === 'null' ? null : $input;
    }

    return $input;
}

function selectFromList(array $items, string $title, ?string $color = null): ?string
{
    if ($items === []) {
        echo "No items found." . PHP_EOL;
        return null;
    }

    while (true) {
        echo PHP_EOL . colorize($title, $color) . PHP_EOL;

        $indexMap = [];
        $counter = 1;

        foreach ($items as $name => $_item) {
            echo colorize("{$counter} - {$name}", $color) . PHP_EOL;
            $indexMap[(string) $counter] = (string) $name;
            $counter++;
        }

        echo colorize("0 - Exit", $color) . PHP_EOL;

        $choice = ask('Enter number', '0', $color);

        if ($choice === '0') {
            return null;
        }

        if (array_key_exists($choice, $indexMap)) {
            return $indexMap[$choice];
        }

        echo "Invalid choice." . PHP_EOL;
    }
}

function editProperties(array $properties, string $title, ?string $promptColor = null): array
{
    echo PHP_EOL . colorize($title, $promptColor) . PHP_EOL;
    echo colorize("Press Enter to keep the current value for any property.", $promptColor) . PHP_EOL;

    foreach ($properties as $key => $currentValue) {
        if (is_array($currentValue)) {
            echo colorize("{$key}: " . valueToDisplay($currentValue) . " (managed separately, kept unchanged)", $promptColor) . PHP_EOL;
            continue;
        }

        $input = askOptional($key . ' [current: ' . valueToDisplay($currentValue) . '] new value', $promptColor);

        if ($input === null) {
            continue;
        }

        $properties[$key] = castPropertyValue($input, $currentValue);
    }

    return $properties;
}

function runModulePropertiesTool(array &$moduleConfig, string $configFile): never
{
    do {
        $moduleName = selectFromList($moduleConfig, 'Existing modules');

        if ($moduleName === null) {
            exportConfig($configFile, $moduleConfig);
            echo PHP_EOL . 'Module properties tool closed.' . PHP_EOL;
            exit(0);
        }

        echo PHP_EOL;
        echo "1 - Change main module properties" . PHP_EOL;
        echo "2 - Change submodule properties" . PHP_EOL;
        echo "0 - Exit" . PHP_EOL;

        $targetChoice = ask('Enter choice', '0');

        if ($targetChoice === '1') {
            $moduleConfig[$moduleName] = editProperties(
                $moduleConfig[$moduleName],
                "Main module '{$moduleName}' properties"
            );

            exportConfig($configFile, $moduleConfig);
            echo "Module '{$moduleName}' properties updated." . PHP_EOL;
        } elseif ($targetChoice === '2') {
            $submodules = $moduleConfig[$moduleName]['submodules'] ?? [];

            if (!is_array($submodules) || $submodules === []) {
                echo "Module '{$moduleName}' has no submodules." . PHP_EOL;
            } else {
                $submoduleName = selectFromList($submodules, "Submodules under '{$moduleName}'", CLI_YELLOW);

                if ($submoduleName !== null) {
                    $moduleConfig[$moduleName]['submodules'][$submoduleName] = editProperties(
                        $moduleConfig[$moduleName]['submodules'][$submoduleName],
                        "Submodule '{$moduleName}/{$submoduleName}' properties",
                        CLI_YELLOW
                    );

                    exportConfig($configFile, $moduleConfig);
                    echo "Submodule '{$moduleName}/{$submoduleName}' properties updated." . PHP_EOL;
                }
            }
        } elseif ($targetChoice === '0') {
            exportConfig($configFile, $moduleConfig);
            echo PHP_EOL . 'Module properties tool closed.' . PHP_EOL;
            exit(0);
        } else {
            echo "Invalid choice." . PHP_EOL;
        }

        echo PHP_EOL;
        $again = askBool('Do you want to choose more modules?', true);
    } while ($again);

    exportConfig($configFile, $moduleConfig);
    echo PHP_EOL . 'Module properties tool closed.' . PHP_EOL;
    exit(0);
}

function runSubmoduleDisplayOrderTool(array &$moduleConfig, string $configFile): never
{
    $moduleName = selectFromList($moduleConfig, 'Choose main module to reorder submodules', CLI_YELLOW);

    if ($moduleName === null) {
        echo PHP_EOL . 'Submodule reorder canceled.' . PHP_EOL;
        exit(0);
    }

    if (!validName($moduleName)) {
        fail('Selected module name contains unsupported characters.');
    }

    $submodules = $moduleConfig[$moduleName]['submodules'] ?? [];

    if (!is_array($submodules) || $submodules === []) {
        echo colorize("Module '{$moduleName}' has no submodules.", CLI_YELLOW) . PHP_EOL;
        exit(0);
    }

    uasort(
        $submodules,
        static fn(array $left, array $right): int => ((int) ($left['display_order'] ?? 0)) <=> ((int) ($right['display_order'] ?? 0))
    );

    echo PHP_EOL . colorize("Current submodule order for '{$moduleName}':", CLI_YELLOW) . PHP_EOL;

    foreach ($submodules as $submoduleName => $submoduleConfig) {
        $currentOrder = (int) ($submoduleConfig['display_order'] ?? 0);
        echo colorize("- {$submoduleName}: {$currentOrder}", CLI_YELLOW) . PHP_EOL;
    }

    $usedOrders = [];

    foreach (array_keys($submodules) as $submoduleName) {
        $currentOrder = (int) ($moduleConfig[$moduleName]['submodules'][$submoduleName]['display_order'] ?? 0);

        while (true) {
            $input = ask("New display order for {$submoduleName}", (string) $currentOrder, CLI_YELLOW);
            $newOrder = filter_var($input, FILTER_VALIDATE_INT);

            if ($newOrder === false || (int) $newOrder < 1) {
                echo colorize('Display order must be a positive integer.', CLI_YELLOW) . PHP_EOL;
                continue;
            }

            if (in_array((int) $newOrder, $usedOrders, true)) {
                echo colorize('Display order already used in this module. Choose another number.', CLI_YELLOW) . PHP_EOL;
                continue;
            }

            $moduleConfig[$moduleName]['submodules'][$submoduleName]['display_order'] = (int) $newOrder;
            $usedOrders[] = (int) $newOrder;
            break;
        }
    }

    uasort(
        $moduleConfig[$moduleName]['submodules'],
        static fn(array $left, array $right): int => ((int) ($left['display_order'] ?? 0)) <=> ((int) ($right['display_order'] ?? 0))
    );

    exportConfig($configFile, $moduleConfig);

    echo PHP_EOL . "Submodule display order updated for module '{$moduleName}'." . PHP_EOL;
    exit(0);
}

echo PHP_EOL;
echo "==============================" . PHP_EOL;
echo " TAFRA Module Management" . PHP_EOL;
echo "==============================" . PHP_EOL;
echo "1 - Create module" . PHP_EOL;
echo "2 - Create submodule" . PHP_EOL;
echo "3 - ModulePropertirs" . PHP_EOL;
echo "4 - Delete submodule" . PHP_EOL;
echo "5 - Rearrange submodules display order" . PHP_EOL;
echo "6 - Check naming letter case" . PHP_EOL;
echo "7 - Delete Module" . PHP_EOL;

$choice = $argv[1] ?? ask('Enter choice', '1');

if (strtolower((string) $choice) === 'modulepropertirs') {
    $choice = '3';
}

if (strtolower((string) $choice) === 'deletemodule') {
    $choice = '7';
}

if ($choice === '1') {
    $moduleName = ask('Module name');

    if (!validName($moduleName)) {
        fail('Invalid module name. Use letters, numbers, and underscores; start with a letter.');
    }

    if (array_key_exists($moduleName, $moduleConfig)) {
        fail("Module '{$moduleName}' already exists.");
    }

    $template = getModuleTemplate($moduleConfig);
    $newModule = promptByTemplate($template, $moduleName, count($moduleConfig) + 1);
    $newModule['submodules'] = [];

    $moduleConfig[$moduleName] = $newModule;
    $modulePath = $modulesRoot . '/' . $moduleName;

    ensureDir($modulePath);
    ensureDir($modulePath . '/submodules');
    ensureDir($modulePath . '/assets/css');
    ensureDir($modulePath . '/assets/js');

    writeFileIfMissing(
        $modulePath . '/routes.php',
        "<?php\n\ndeclare(strict_types=1);\n\n// Routes for {$moduleName} module.\n// Keep routes registered even when the module/submodule is disabled;\n// BaseController blocks disabled features with the disabled-action response.\n"
    );

    writeFileIfMissing(
        $modulePath . '/' . $moduleName . '.json',
        json_encode([
            'module' => $moduleName,
            'description' => 'Describe this module here.',
            'created_by' => 'TAFRA mouduleMgmnt.php',
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL
    );

    exportConfig($configFile, $moduleConfig);

    echo PHP_EOL . "Module '{$moduleName}' created successfully." . PHP_EOL;
    exit(0);
}

if ($choice === '2') {
    $moduleName = selectFromList($moduleConfig, 'Choose main module for new submodule', CLI_YELLOW);

    if ($moduleName === null) {
        echo PHP_EOL . 'Submodule creation canceled.' . PHP_EOL;
        exit(0);
    }

    if (!validName($moduleName)) {
        fail('Existing module name contains unsupported characters.');
    }

    $submoduleName = ask('Submodule name', null, CLI_YELLOW);

    if (!validName($submoduleName)) {
        fail('Invalid submodule name. Use letters, numbers, and underscores; start with a letter.');
    }

    if (!isset($moduleConfig[$moduleName]['submodules']) || !is_array($moduleConfig[$moduleName]['submodules'])) {
        $moduleConfig[$moduleName]['submodules'] = [];
    }

    if (array_key_exists($submoduleName, $moduleConfig[$moduleName]['submodules'])) {
        fail("Submodule '{$submoduleName}' already exists under '{$moduleName}'.");
    }

    $template = getSubmoduleTemplate($moduleConfig);
    $newSubmodule = promptByTemplate(
        $template,
        $submoduleName,
        count($moduleConfig[$moduleName]['submodules']) + 1,
        CLI_YELLOW
    );

    $moduleConfig[$moduleName]['submodules'][$submoduleName] = $newSubmodule;

    $submodulePath = $modulesRoot . '/' . $moduleName . '/submodules/' . $submoduleName;
    $classBase = studly($submoduleName);

    ensureDir($submodulePath);

    writeFileIfMissing($submodulePath . '/' . $classBase . 'Controller.php', controllerStub($moduleName, $submoduleName) . PHP_EOL);
    writeFileIfMissing($submodulePath . '/' . $classBase . 'Service.php', serviceStub($moduleName, $submoduleName) . PHP_EOL);
    writeFileIfMissing($submodulePath . '/' . $classBase . 'Model.php', modelStub($moduleName, $submoduleName) . PHP_EOL);
    writeFileIfMissing($submodulePath . '/' . $submoduleName . 'view.php', viewStub(studly($submoduleName)) . PHP_EOL);
    appendSubmoduleRoute($modulesRoot . '/' . $moduleName . '/routes.php', $moduleName, $submoduleName);

    exportConfig($configFile, $moduleConfig);

    echo PHP_EOL . "Submodule '{$submoduleName}' created successfully under module '{$moduleName}'." . PHP_EOL;
    exit(0);
}

if ($choice === '3') {
    runModulePropertiesTool($moduleConfig, $configFile);
}

if ($choice === '4') {
    $moduleName = selectFromList($moduleConfig, 'Choose main module for submodule deletion', CLI_YELLOW);

    if ($moduleName === null) {
        echo PHP_EOL . 'Submodule deletion canceled.' . PHP_EOL;
        exit(0);
    }

    if (!validName($moduleName)) {
        fail('Selected module name contains unsupported characters.');
    }

    $submodules = $moduleConfig[$moduleName]['submodules'] ?? [];

    if (!is_array($submodules) || $submodules === []) {
        echo colorize("Module '{$moduleName}' has no submodules.", CLI_YELLOW) . PHP_EOL;
        exit(0);
    }

    $submoduleName = selectFromList($submodules, "Choose submodule to delete from '{$moduleName}'", CLI_YELLOW);

    if ($submoduleName === null) {
        echo PHP_EOL . 'Submodule deletion canceled.' . PHP_EOL;
        exit(0);
    }

    if (!validName($submoduleName)) {
        fail('Selected submodule name contains unsupported characters.');
    }

    echo PHP_EOL;
    echo colorize("This will delete submodule '{$moduleName}/{$submoduleName}'.", CLI_YELLOW) . PHP_EOL;
    echo colorize('The operation will remove its route entries, moduleConfig entry, and folder contents.', CLI_YELLOW) . PHP_EOL;

    if (!askConfirm('Confirm deletion yes/no', false, CLI_YELLOW)) {
        echo PHP_EOL . 'Submodule deletion canceled.' . PHP_EOL;
        exit(0);
    }

    deleteSubmoduleEffects($moduleConfig, $modulesRoot, $moduleName, $submoduleName);
    exportConfig($configFile, $moduleConfig);

    echo PHP_EOL . "Submodule '{$moduleName}/{$submoduleName}' deleted successfully." . PHP_EOL;
    printRemainingSubmoduleReferences($basePath, $moduleName, $submoduleName);
    exit(0);
}

if ($choice === '5') {
    runSubmoduleDisplayOrderTool($moduleConfig, $configFile);
}

if ($choice === '6') {
    runCheckNamingTool($moduleConfig, $modulesRoot, $basePath);
}

if ($choice === '7') {
    $moduleName = selectFromList($moduleConfig, 'Choose main module for deletion', CLI_YELLOW);

    if ($moduleName === null) {
        echo PHP_EOL . 'Module deletion canceled.' . PHP_EOL;
        exit(0);
    }

    if (!validName($moduleName)) {
        fail('Selected module name contains unsupported characters.');
    }

    $modulePath = $modulesRoot . '/' . $moduleName;

    if (!is_dir($modulePath)) {
        fail("Module folder not found: {$modulePath}");
    }

    $submodules = $moduleConfig[$moduleName]['submodules'] ?? [];
    $submoduleNames = is_array($submodules) ? array_keys($submodules) : [];

    foreach ($submoduleNames as $submoduleName) {
        if (!is_string($submoduleName) || !validName($submoduleName)) {
            fail("Submodule name contains unsupported characters under '{$moduleName}'.");
        }
    }

    echo PHP_EOL;
    echo colorize("This will delete module '{$moduleName}' and all owned submodules.", CLI_YELLOW) . PHP_EOL;
    echo colorize('The operation will remove submodule route entries, moduleConfig entries, module JSON file, and all folder contents.', CLI_YELLOW) . PHP_EOL;

    if ($submoduleNames !== []) {
        echo colorize('Owned submodules to delete:', CLI_YELLOW) . PHP_EOL;

        foreach ($submoduleNames as $submoduleName) {
            echo colorize("- {$moduleName}/{$submoduleName}", CLI_YELLOW) . PHP_EOL;
        }
    }

    if (!askConfirm('Confirm deletion yes/no', false, CLI_YELLOW)) {
        echo PHP_EOL . 'Module deletion canceled.' . PHP_EOL;
        exit(0);
    }

    foreach ($submoduleNames as $submoduleName) {
        deleteSubmoduleEffects($moduleConfig, $modulesRoot, $moduleName, (string) $submoduleName);
    }

    unset($moduleConfig[$moduleName]);
    deleteDirectoryTree($modulePath, $modulesRoot);
    exportConfig($configFile, $moduleConfig);

    echo PHP_EOL . "Module '{$moduleName}' deleted successfully." . PHP_EOL;
    printRemainingModuleReferences($basePath, $moduleName);
    exit(0);
}

fail('Invalid choice.');
