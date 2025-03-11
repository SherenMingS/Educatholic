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

        // Ambil total jumlah badges berdasarkan kolom 'jumlah'
        $badgesCount = Badge::where('user_id', $user->id)->sum('jumlah'); 

        // Ambil daftar badges dari tabel
        $badges = Badge::where('user_id', $user->id)->get(['jumlah', 'badge_level']);

        return response()->json([
            'name' => $user->name,
            'quiz_average' => round($quizAverage, 2),
            'badges_count' => (int) $badgesCount, // Sekarang ini mengambil total jumlah badge dari kolom 'jumlah'
            'badges' => $badges, // Kirim detail badge sebagai array
            'recent_activities' => [
                'Riwayat Aktivitas Anda',
                'Rata-rata Skor Kuis ' . round($quizAverage, 2) . '%',
                'Badges Tercapai ' . (int)$badgesCount
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
