<?php

declare(strict_types=1);

const PASSWORD_LENGTHS = [
    1 => 4,
    2 => 6,
    3 => 8,
    4 => 10,
    5 => 12,
    6 => 16,
    7 => 20,
    8 => 24,
    9 => 28,
    10 => 32,
    11 => 64,
];

const DIGITS = '0123456789';
const LOWERCASE = 'abcdefghijklmnopqrstuvwxyz';
const UPPERCASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const SYMBOLS = '!@#$%^&*()-_=+[]{};:,.<>?';

function readInput(string $prompt): string
{
    echo $prompt;

    $input = fgets(STDIN);

    return $input === false ? '' : trim($input);
}

function showMainMenu(): void
{
    echo PHP_EOL;
    echo 'Password Generator' . PHP_EOL;
    echo '==================' . PHP_EOL;
    echo '0: Exit' . PHP_EOL;

    foreach (PASSWORD_LENGTHS as $choice => $length) {
        echo $choice . ': ' . $length . ' characters length' . PHP_EOL;
    }

    echo 'Append /c to a choice for a password without symbols.' . PHP_EOL;
}

function generatePassword(int $length, bool $includeSymbols = true): string
{
    $requiredCharacters = [
        randomCharacter(DIGITS),
        randomCharacter(LOWERCASE),
        randomCharacter(UPPERCASE),
    ];

    if ($includeSymbols) {
        $requiredCharacters[] = randomCharacter(SYMBOLS);
    }

    $allCharacters = DIGITS . LOWERCASE . UPPERCASE;

    if ($includeSymbols) {
        $allCharacters .= SYMBOLS;
    }

    while (count($requiredCharacters) < $length) {
        $requiredCharacters[] = randomCharacter($allCharacters);
    }

    shuffleSecurely($requiredCharacters);

    return implode('', $requiredCharacters);
}

function randomCharacter(string $characters): string
{
    return $characters[random_int(0, strlen($characters) - 1)];
}

function shuffleSecurely(array &$characters): void
{
    for ($index = count($characters) - 1; $index > 0; $index--) {
        $swapIndex = random_int(0, $index);

        [$characters[$index], $characters[$swapIndex]] = [$characters[$swapIndex], $characters[$index]];
    }
}

function copyToClipboard(string $text): bool
{
    $command = match (PHP_OS_FAMILY) {
        'Windows' => 'clip',
        'Darwin' => 'pbcopy',
        default => commandExists('wl-copy') ? 'wl-copy' : (commandExists('xclip') ? 'xclip -selection clipboard' : ''),
    };

    if ($command === '') {
        return false;
    }

    $process = proc_open(
        $command,
        [
            0 => ['pipe', 'r'],
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w'],
        ],
        $pipes
    );

    if (!is_resource($process)) {
        return false;
    }

    fwrite($pipes[0], $text);
    fclose($pipes[0]);
    fclose($pipes[1]);
    fclose($pipes[2]);

    return proc_close($process) === 0;
}

function commandExists(string $command): bool
{
    $checkCommand = PHP_OS_FAMILY === 'Windows'
        ? 'where ' . escapeshellarg($command)
        : 'command -v ' . escapeshellarg($command);

    exec($checkCommand, $output, $exitCode);

    return $exitCode === 0;
}

function showPasswordActions(): string
{
    echo PHP_EOL;
    echo 'What would you like to do next?' . PHP_EOL;
    echo '1: Copy password to clipboard' . PHP_EOL;
    echo '2: Regenerate password' . PHP_EOL;
    echo '3: Main menu' . PHP_EOL;
    echo '0: Exit' . PHP_EOL;

    return readInput('Select an option: ');
}

while (true) {
    showMainMenu();

    $choice = readInput('Select password length: ');

    if ($choice === '0') {
        echo 'Goodbye!' . PHP_EOL;
        exit(0);
    }

    if (!preg_match('/^(\d+)(?:\/([cC]))?$/', $choice, $matches)) {
        echo 'Invalid selection. Please choose a number from the menu.' . PHP_EOL;
        continue;
    }

    $menuNumber = (int) $matches[1];

    if (!array_key_exists($menuNumber, PASSWORD_LENGTHS)) {
        echo 'Invalid selection. Please choose a number from the menu.' . PHP_EOL;
        continue;
    }

    $length = PASSWORD_LENGTHS[$menuNumber];
    $includeSymbols = !isset($matches[2]);

    while (true) {
        $password = generatePassword($length, $includeSymbols);
        echo PHP_EOL . 'Generated password: ' . $password . PHP_EOL;

        while (true) {
            $nextAction = showPasswordActions();

            if ($nextAction === '1') {
                echo copyToClipboard($password)
                    ? 'Password copied to clipboard.' . PHP_EOL
                    : 'Unable to copy password to clipboard on this system.' . PHP_EOL;
                continue;
            }

            if ($nextAction === '2') {
                continue 2;
            }

            if ($nextAction === '3') {
                break 2;
            }

            if ($nextAction === '0') {
                echo 'Goodbye!' . PHP_EOL;
                exit(0);
            }

            echo 'Invalid selection. Please choose a number from the menu.' . PHP_EOL;
        }
    }
}
