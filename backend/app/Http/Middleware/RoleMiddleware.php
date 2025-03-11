<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Log;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, $role): Response
    {
        if (!auth()->check()) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $userRole = auth()->user()->role; // Ambil role dari user

        // 🔹 DEBUG: Log role yang terbaca dan yang diminta
        Log::info('Middleware Role Check - Expected: ' . $role . ' | Actual: ' . $userRole);

        if (strtolower($userRole) !== strtolower($role)) {
            return response()->json([
                'message' => 'Akses ditolak (Role mismatch)',
                'expected_role' => $role,
                'actual_role' => $userRole
            ], 403);
        }

        return $next($request);
    }
}
