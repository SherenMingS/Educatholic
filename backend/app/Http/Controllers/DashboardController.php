<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Models\QuizResult;
use App\Models\Badge;

class DashboardController extends Controller
{
    // Dashboard Siswa
    public function index()
    {
        $user = Auth::user();

        if ($user->role !== 'siswa') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        // Ambil rata-rata nilai kuis
        $quizAverage = QuizResult::where('user_id', $user->id)->avg('score') ?? 0;

        $badgesCount = QuizResult::where('user_id', $user->id)
        ->where('score', 100)
        ->count();

        $badgeLevel = match (true) {
            $badgesCount >= 10 => 'Dewa Kuis 🥇',
            $badgesCount >= 5 => 'Pro Player 🥈',
            $badgesCount >= 1 => 'Beginner 🥉',
            default => 'Belum Punya Badge ❌',
        };

        return response()->json([
            'name' => $user->name,
            'quiz_average' => round($quizAverage, 2),
            'badges_count' => (int) $badgesCount,
            'badge_level' => $badgeLevel, // 👈 pindahkan ke sini
            'recent_activities' => [
                'Riwayat Aktivitas Anda',
                'Rata-rata Skor Kuis ' . round($quizAverage, 2) . '%',
                'Badges Tercapai ' . (int)$badgesCount,
            ]
        ]);
        
    }
    


    // Dashboard Guru
    public function dashboardGuru(Request $request)
    {
        $user = Auth::user();

        if ($user->role !== 'guru') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return response()->json([
            'name' => $user->name,
            'attendance' => [
                ['class' => '9A', 'percentage' => 78],
                ['class' => '9B', 'percentage' => 90],
            ],
            'management_options' => [
                ['title' => 'Manage Materi', 'icon' => 'book'],
                ['title' => 'Manage Kuis', 'icon' => 'assignment'],
                ['title' => 'Manage Kelas', 'icon' => 'class'],
                ['title' => 'Manage Siswa', 'icon' => 'people'],
            ]
        ]);
    }
}
