<?php

function respond(array $payload): void
{
    echo json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
}

function fail(string $code, string $message): void
{
    respond([
        'success' => false,
        'error_code' => $code,
        'message' => $message,
    ]);
    exit(1);
}

function arg_value(array $argv, string $name): string
{
    $index = array_search($name, $argv, true);
    if ($index === false || !isset($argv[$index + 1])) {
        return '';
    }

    return (string) $argv[$index + 1];
}

function token_text($token): string
{
    return is_array($token) ? (string) $token[1] : (string) $token;
}

function token_name_text($token): string
{
    return is_array($token) ? token_name((int) $token[0]) : (string) $token;
}

function token_line($token): int
{
    return is_array($token) ? (int) $token[2] : 0;
}

function next_named_token(array $tokens, int $index): string
{
    for ($i = $index + 1, $count = count($tokens); $i < $count; $i++) {
        if (!is_array($tokens[$i])) {
            continue;
        }

        if ($tokens[$i][0] === T_STRING) {
            return (string) $tokens[$i][1];
        }
    }

    return '';
}

function find_methods(array $tokens): array
{
    $methods = [];
    $currentClass = '';
    $pendingClass = '';
    $braceDepth = 0;
    $classDepth = -1;
    $count = count($tokens);

    for ($i = 0; $i < $count; $i++) {
        $token = $tokens[$i];
        $text = token_text($token);

        if (is_array($token) && in_array($token[0], [T_CLASS, T_TRAIT, T_INTERFACE], true)) {
            $pendingClass = next_named_token($tokens, $i);
        }

        if ($text === '{') {
            $braceDepth++;
            if ($pendingClass !== '') {
                $currentClass = $pendingClass;
                $classDepth = $braceDepth;
                $pendingClass = '';
            }
        } elseif ($text === '}') {
            if ($classDepth === $braceDepth) {
                $currentClass = '';
                $classDepth = -1;
            }
            $braceDepth--;
        }

        if (!is_array($token) || $token[0] !== T_FUNCTION) {
            continue;
        }

        $name = next_named_token($tokens, $i);
        if ($name === '') {
            continue;
        }

        $bodyStart = -1;
        for ($j = $i + 1; $j < $count; $j++) {
            if (token_text($tokens[$j]) === '{') {
                $bodyStart = $j;
                break;
            }
            if (token_text($tokens[$j]) === ';') {
                break;
            }
        }

        if ($bodyStart < 0) {
            continue;
        }

        $depth = 1;
        $bodyEnd = $bodyStart;
        for ($j = $bodyStart + 1; $j < $count; $j++) {
            $bodyText = token_text($tokens[$j]);
            if ($bodyText === '{') {
                $depth++;
            } elseif ($bodyText === '}') {
                $depth--;
                if ($depth === 0) {
                    $bodyEnd = $j;
                    break;
                }
            }
        }

        $displayName = $currentClass !== '' ? $currentClass . '::' . $name : $name;
        $methods[] = [
            'name' => $displayName,
            'short_name' => $name,
            'class_name' => $currentClass,
            'line' => token_line($token),
            'start' => $bodyStart,
            'end' => $bodyEnd,
        ];
    }

    return $methods;
}

function compact_label(string $text): string
{
    $text = trim(preg_replace('/\s+/', ' ', $text) ?? '');
    if (strlen($text) > 70) {
        $text = substr($text, 0, 67) . '...';
    }
    return $text;
}

function build_flow(array $tokens, array $method): array
{
    $nodes = [
        ['id' => 'start', 'type' => 'start', 'label' => 'Start'],
    ];
    $edges = [];
    $last = 'start';
    $sequence = 1;
    $count = (int) $method['end'];
    $statement = '';

    for ($i = (int) $method['start'] + 1; $i < $count; $i++) {
        $token = $tokens[$i];
        $text = token_text($token);
        $tokenName = token_name_text($token);
        $nodeType = '';
        $label = '';

        if (is_array($token)) {
            if (in_array($token[0], [T_IF, T_ELSEIF], true)) {
                $nodeType = 'decision';
                $label = trim($text) === 'elseif' ? 'Else if condition' : 'If condition';
            } elseif ($token[0] === T_ELSE) {
                $nodeType = 'statement';
                $label = 'Else branch';
            } elseif (in_array($token[0], [T_FOR, T_FOREACH, T_WHILE, T_DO], true)) {
                $nodeType = 'loop';
                $label = ucfirst(strtolower(str_replace('T_', '', $tokenName))) . ' loop';
            } elseif ($token[0] === T_SWITCH) {
                $nodeType = 'decision';
                $label = 'Switch';
            } elseif (in_array($token[0], [T_RETURN, T_THROW], true)) {
                $nodeType = 'return';
                $label = ucfirst(strtolower($text));
            } elseif ($token[0] === T_TRY) {
                $nodeType = 'statement';
                $label = 'Try';
            } elseif (in_array($token[0], [T_CATCH, T_FINALLY], true)) {
                $nodeType = 'statement';
                $label = ucfirst(strtolower($text));
            }
        }

        if ($nodeType !== '') {
            $id = 'n' . $sequence++;
            $nodes[] = ['id' => $id, 'type' => $nodeType, 'label' => $label];
            $edges[] = ['from' => $last, 'to' => $id, 'label' => ''];
            $last = $id;
            $statement = '';
            continue;
        }

        if (trim($text) !== '') {
            $statement .= $text;
        }

        if ($text === ';') {
            $label = compact_label($statement);
            if ($label !== '' && $label !== ';') {
                $id = 'n' . $sequence++;
                $nodes[] = ['id' => $id, 'type' => 'statement', 'label' => $label];
                $edges[] = ['from' => $last, 'to' => $id, 'label' => ''];
                $last = $id;
            }
            $statement = '';
        }
    }

    $nodes[] = ['id' => 'end', 'type' => 'end', 'label' => 'End'];
    $edges[] = ['from' => $last, 'to' => 'end', 'label' => ''];

    return [
        'success' => true,
        'message' => 'Flowchart model generated.',
        'method' => $method['name'],
        'nodes' => $nodes,
        'edges' => $edges,
    ];
}

$file = arg_value($argv, '--file');
$methodName = arg_value($argv, '--method');
$listOnly = in_array('--list', $argv, true);

if ($file === '') {
    fail('FLOWCHART_FILE_MISSING', 'No PHP file was supplied.');
}

if (!is_file($file)) {
    fail('FLOWCHART_FILE_NOT_FOUND', 'PHP file not found: ' . $file);
}

$source = file_get_contents($file);
if ($source === false) {
    fail('FLOWCHART_FILE_READ_ERROR', 'Unable to read PHP file.');
}

$tokens = token_get_all($source);
$methods = find_methods($tokens);

if ($listOnly) {
    respond([
        'success' => true,
        'message' => 'Methods detected.',
        'methods' => array_map(static function (array $method): array {
            return [
                'name' => $method['name'],
                'line' => $method['line'],
            ];
        }, $methods),
    ]);
    exit(0);
}

if ($methodName === '' && count($methods) > 0) {
    $methodName = (string) $methods[0]['name'];
}

foreach ($methods as $method) {
    if ($method['name'] === $methodName || $method['short_name'] === $methodName) {
        respond(build_flow($tokens, $method));
        exit(0);
    }
}

fail('FLOWCHART_METHOD_NOT_FOUND', 'Requested function/method was not found.');
