<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    echo json_encode([
        'success' => false,
        'error_code' => 'CLI_ONLY',
        'message' => 'Module management can run only from PHP CLI.',
    ], JSON_UNESCAPED_SLASHES) . PHP_EOL;
    exit(1);
}

function respond(bool $success, string $message, string $errorCode = '', array $extra = []): never
{
    echo json_encode(array_merge([
        'success' => $success,
        'error_code' => $errorCode,
        'message' => $message,
    ], $extra), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL;

    exit($success ? 0 : 1);
}

function optionValue(array $options, string $name, string $default = ''): string
{
    return trim((string) ($options[$name] ?? $default));
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

function routePathFromName(string $name): string
{
    $route = preg_replace('/([a-z])([A-Z])/', '$1-$2', $name) ?? $name;
    $route = strtolower(str_replace('_', '-', $route));

    return '/' . trim($route, '/');
}

function ensureDir(string $path): void
{
    if (is_dir($path)) {
        return;
    }

    if (file_exists($path)) {
        respond(false, "Path exists and is not a directory: {$path}", 'PATH_CONFLICT');
    }

    if (!mkdir($path, 0775, true) && !is_dir($path)) {
        respond(false, "Unable to create directory: {$path}", 'DIRECTORY_CREATE_FAILED');
    }
}

function writeFileIfMissing(string $path, string $content): void
{
    if (file_exists($path)) {
        return;
    }

    ensureDir(dirname($path));

    if (file_put_contents($path, $content, LOCK_EX) === false) {
        respond(false, "Unable to write file: {$path}", 'FILE_WRITE_FAILED');
    }
}

function exportConfig(string $configFile, array $config): void
{
    $content = "<?php\n\nreturn " . var_export($config, true) . ";\n";
    $tempFile = $configFile . '.tmp';

    if (file_put_contents($tempFile, $content, LOCK_EX) === false) {
        respond(false, "Unable to write temporary config file: {$tempFile}", 'CONFIG_WRITE_FAILED');
    }

    if (!rename($tempFile, $configFile)) {
        @unlink($tempFile);
        respond(false, "Unable to replace config file: {$configFile}", 'CONFIG_REPLACE_FAILED');
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

function defaultsFromTemplate(array $template, string $name, int $displayOrder): array
{
    $data = [];

    foreach ($template as $key => $default) {
        if ($key === 'submodules') {
            $data[$key] = [];
        } elseif ($key === 'menu_title') {
            $data[$key] = studly($name);
        } elseif ($key === 'display_order') {
            $data[$key] = $displayOrder;
        } elseif ($key === 'tool_tip') {
            $data[$key] = studly($name);
        } elseif ($key === 'enable_tooltip') {
            $data[$key] = false;
        } elseif (is_bool($default)) {
            $data[$key] = $default;
        } elseif (is_array($default)) {
            $data[$key] = $default;
        } else {
            $data[$key] = $default;
        }
    }

    return $data;
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
            "<?php\n\ndeclare(strict_types=1);\n\n// Routes for {$moduleName} module.\n"
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
        respond(false, "Unable to update routes file: {$routesFile}", 'ROUTES_WRITE_FAILED');
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
        respond(false, "Unable to parse routes file: {$routesFile}", 'ROUTES_PARSE_FAILED');
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

    if (file_put_contents($routesFile, rtrim(implode(PHP_EOL, $filtered)) . PHP_EOL, LOCK_EX) === false) {
        respond(false, "Unable to update routes file: {$routesFile}", 'ROUTES_WRITE_FAILED');
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
        respond(false, 'Unable to resolve deletion paths.', 'PATH_RESOLVE_FAILED');
    }

    $normalizedTarget = rtrim(str_replace('\\', '/', $resolvedTarget), '/');
    $normalizedRoot = rtrim(str_replace('\\', '/', $resolvedRoot), '/');

    if ($normalizedTarget === $normalizedRoot || !str_starts_with($normalizedTarget . '/', $normalizedRoot . '/')) {
        respond(false, "Refusing to delete path outside allowed root: {$targetPath}", 'UNSAFE_DELETE_TARGET');
    }

    if (!is_dir($resolvedTarget)) {
        respond(false, "Delete target is not a directory: {$targetPath}", 'DELETE_TARGET_NOT_DIRECTORY');
    }

    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($resolvedTarget, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::CHILD_FIRST
    );

    foreach ($iterator as $item) {
        $path = $item->getPathname();

        if ($item->isDir()) {
            if (!rmdir($path)) {
                respond(false, "Unable to delete directory: {$path}", 'DIRECTORY_DELETE_FAILED');
            }
        } elseif (!unlink($path)) {
            respond(false, "Unable to delete file: {$path}", 'FILE_DELETE_FAILED');
        }
    }

    if (!rmdir($resolvedTarget)) {
        respond(false, "Unable to delete directory: {$resolvedTarget}", 'DIRECTORY_DELETE_FAILED');
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

function createModule(array &$moduleConfig, string $configFile, string $modulesRoot, string $moduleName): void
{
    if (!validName($moduleName)) {
        respond(false, 'Invalid module name. Use letters, numbers, and underscores; start with a letter.', 'INVALID_MODULE_NAME');
    }

    if (array_key_exists($moduleName, $moduleConfig)) {
        respond(false, "Module '{$moduleName}' already exists.", 'MODULE_EXISTS');
    }

    $newModule = defaultsFromTemplate(getModuleTemplate($moduleConfig), $moduleName, count($moduleConfig) + 1);
    $newModule['submodules'] = [];
    $moduleConfig[$moduleName] = $newModule;

    $modulePath = $modulesRoot . '/' . $moduleName;
    ensureDir($modulePath);
    ensureDir($modulePath . '/submodules');
    ensureDir($modulePath . '/assets/css');
    ensureDir($modulePath . '/assets/js');

    writeFileIfMissing(
        $modulePath . '/routes.php',
        "<?php\n\ndeclare(strict_types=1);\n\n// Routes for {$moduleName} module.\n"
    );

    writeFileIfMissing(
        $modulePath . '/' . $moduleName . '.json',
        json_encode([
            'module' => $moduleName,
            'description' => 'Describe this module here.',
            'created_by' => 'TAFRA Studio',
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL
    );

    exportConfig($configFile, $moduleConfig);
    respond(true, "Module '{$moduleName}' created successfully.");
}

function createSubmodule(array &$moduleConfig, string $configFile, string $modulesRoot, string $moduleName, string $submoduleName): void
{
    if (!validName($moduleName) || !array_key_exists($moduleName, $moduleConfig)) {
        respond(false, "Module '{$moduleName}' was not found.", 'MODULE_NOT_FOUND');
    }

    if (!validName($submoduleName)) {
        respond(false, 'Invalid submodule name. Use letters, numbers, and underscores; start with a letter.', 'INVALID_SUBMODULE_NAME');
    }

    if (!isset($moduleConfig[$moduleName]['submodules']) || !is_array($moduleConfig[$moduleName]['submodules'])) {
        $moduleConfig[$moduleName]['submodules'] = [];
    }

    if (array_key_exists($submoduleName, $moduleConfig[$moduleName]['submodules'])) {
        respond(false, "Submodule '{$submoduleName}' already exists under '{$moduleName}'.", 'SUBMODULE_EXISTS');
    }

    $moduleConfig[$moduleName]['submodules'][$submoduleName] = defaultsFromTemplate(
        getSubmoduleTemplate($moduleConfig),
        $submoduleName,
        count($moduleConfig[$moduleName]['submodules']) + 1
    );

    $submodulePath = $modulesRoot . '/' . $moduleName . '/submodules/' . $submoduleName;
    $classBase = studly($submoduleName);

    ensureDir($submodulePath);
    writeFileIfMissing($submodulePath . '/' . $classBase . 'Controller.php', controllerStub($moduleName, $submoduleName) . PHP_EOL);
    writeFileIfMissing($submodulePath . '/' . $classBase . 'Service.php', serviceStub($moduleName, $submoduleName) . PHP_EOL);
    writeFileIfMissing($submodulePath . '/' . $classBase . 'Model.php', modelStub($moduleName, $submoduleName) . PHP_EOL);
    writeFileIfMissing($submodulePath . '/' . $submoduleName . 'view.php', viewStub(studly($submoduleName)) . PHP_EOL);
    appendSubmoduleRoute($modulesRoot . '/' . $moduleName . '/routes.php', $moduleName, $submoduleName);

    exportConfig($configFile, $moduleConfig);
    respond(true, "Submodule '{$moduleName}/{$submoduleName}' created successfully.");
}

function deleteSubmodule(array &$moduleConfig, string $configFile, string $modulesRoot, string $moduleName, string $submoduleName): void
{
    if (!isset($moduleConfig[$moduleName]['submodules'][$submoduleName])) {
        respond(false, "Submodule '{$moduleName}/{$submoduleName}' was not found.", 'SUBMODULE_NOT_FOUND');
    }

    deleteSubmoduleEffects($moduleConfig, $modulesRoot, $moduleName, $submoduleName);
    exportConfig($configFile, $moduleConfig);
    respond(true, "Submodule '{$moduleName}/{$submoduleName}' deleted successfully.");
}

function deleteModule(array &$moduleConfig, string $configFile, string $modulesRoot, string $moduleName): void
{
    if (!array_key_exists($moduleName, $moduleConfig)) {
        respond(false, "Module '{$moduleName}' was not found.", 'MODULE_NOT_FOUND');
    }

    $submodules = $moduleConfig[$moduleName]['submodules'] ?? [];

    if (is_array($submodules)) {
        foreach (array_keys($submodules) as $submoduleName) {
            deleteSubmoduleEffects($moduleConfig, $modulesRoot, $moduleName, (string) $submoduleName);
        }
    }

    unset($moduleConfig[$moduleName]);
    deleteDirectoryTree($modulesRoot . '/' . $moduleName, $modulesRoot);
    exportConfig($configFile, $moduleConfig);
    respond(true, "Module '{$moduleName}' deleted successfully.");
}

$options = getopt('', ['project:', 'action:', 'module::', 'submodule::']);
$projectRoot = optionValue($options, 'project');
$action = optionValue($options, 'action');
$moduleName = optionValue($options, 'module');
$submoduleName = optionValue($options, 'submodule');

if ($projectRoot === '' || $action === '') {
    respond(false, 'Required arguments: --project and --action.', 'ARGUMENTS_MISSING');
}

$basePath = realpath($projectRoot);

if ($basePath === false || !is_dir($basePath)) {
    respond(false, "Project path was not found: {$projectRoot}", 'PROJECT_NOT_FOUND');
}

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
    respond(false, 'Module management can run only when APP_ENV == development.', 'INVALID_APP_ENV');
}

if (!is_file($configFile)) {
    respond(false, "moduleConfig.php not found at: {$configFile}", 'MODULE_CONFIG_NOT_FOUND');
}

$moduleConfig = require $configFile;

if (!is_array($moduleConfig)) {
    respond(false, 'moduleConfig.php must return an array.', 'INVALID_MODULE_CONFIG');
}

match ($action) {
    'create-module' => createModule($moduleConfig, $configFile, $modulesRoot, $moduleName),
    'create-submodule' => createSubmodule($moduleConfig, $configFile, $modulesRoot, $moduleName, $submoduleName),
    'delete-submodule' => deleteSubmodule($moduleConfig, $configFile, $modulesRoot, $moduleName, $submoduleName),
    'delete-module' => deleteModule($moduleConfig, $configFile, $modulesRoot, $moduleName),
    default => respond(false, "Action '{$action}' is not implemented by the JSON backend yet.", 'UNSUPPORTED_ACTION'),
};
