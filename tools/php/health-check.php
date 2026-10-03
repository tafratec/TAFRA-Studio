<?php
declare(strict_types=1);

header('Content-Type: application/json');

echo json_encode([
    'success' => true,
    'php_version' => PHP_VERSION,
    'message' => 'TAFRA PHP runtime available',
], JSON_UNESCAPED_SLASHES);
