<?php
$root = __DIR__ . '/build/web';
$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
if ($uri === '/flutter_service_worker.js') {
    header('Content-Type: application/javascript; charset=utf-8');
    header('Cache-Control: no-store');
    echo "self.addEventListener('install',()=>self.skipWaiting());self.addEventListener('activate',()=>self.clients.claim());";
    exit;
}
$path = realpath($root . $uri);
if ($path === false || !str_starts_with($path, realpath($root)) || is_dir($path)) {
    $path = $root . '/index.html';
}
$ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
$types = [
    'html' => 'text/html; charset=utf-8',
    'js'   => 'application/javascript; charset=utf-8',
    'mjs'  => 'application/javascript; charset=utf-8',
    'css'  => 'text/css; charset=utf-8',
    'json' => 'application/json; charset=utf-8',
    'png'  => 'image/png',
    'svg'  => 'image/svg+xml',
    'ico'  => 'image/x-icon',
    'wasm' => 'application/wasm',
    'ttf'  => 'font/ttf',
    'otf'  => 'font/otf',
    'woff2'=> 'font/woff2',
];
header('Content-Type: ' . ($types[$ext] ?? 'application/octet-stream'));
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
readfile($path);
