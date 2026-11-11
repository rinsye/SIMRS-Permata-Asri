<?php

declare(strict_types=1);

// Konfigurasi koneksi di .env server / environment MAMP. Jangan menyimpan password produksi dalam source.
function db_setting(string $name, string $default): string { $value=getenv($name); return $value===false ? $default : $value; }

function db(): PDO
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $dsn = 'mysql:host=' . db_setting('SIMRS_DB_HOST','127.0.0.1') . ';port=' . db_setting('SIMRS_DB_PORT','8889') . ';dbname=' . db_setting('SIMRS_DB_NAME','simrs_permata_asri') . ';charset=utf8mb4';

    $pdo = new PDO($dsn, db_setting('SIMRS_DB_USER','root'), db_setting('SIMRS_DB_PASS','root'), [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);

    return $pdo;
}
