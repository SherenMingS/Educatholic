<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    */

    'paths' => [
        'api/*',              // Semua API route
        'sanctum/csrf-cookie', // Untuk Sanctum auth
        'uploads/*',           // 🔥 Untuk akses gambar di folder uploads/
    ],

    'allowed_methods' => ['*'], // 🔥 Bolehkan semua HTTP methods (GET, POST, PUT, DELETE, dll)

    'allowed_origins' => ['*'], // 🔥 Izinkan semua asal domain (localhost, IP, dll)

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'], // 🔥 Izinkan semua headers (Authorization, Content-Type, dll)

    'exposed_headers' => [],    // Biasanya kosong, kecuali perlu expose header tertentu

    'max_age' => 0,             // Cache preflight request (OPTIONS)

    'supports_credentials' => false, // 🔥 Kalau butuh kirim cookie/session, set true, kalau token aja cukup false
];
