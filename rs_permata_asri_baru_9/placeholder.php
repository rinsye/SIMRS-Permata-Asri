<?php
require_once __DIR__ . '/includes/functions.php';
$user = require_login();
redirect('dashboard.php');
