<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\QuizResult;

class LeaderboardController extends Controller
{
    public function getStudentLeaderboard(Request $request)
    {
        $kelas = $request->query('kelas');

        if (!$kelas) {
            return response()->json(['message' => 'Kelas harus disertakan'], 400);
        }

        $leaderboard = User::where('role', 'siswa')
            ->where('kelas', $kelas)
            ->select('id', 'name', 'kelas')
            ->withSum('quizResults as total_score', 'score')
            ->orderByDesc('total_score')
            ->get();

        return response()->json([
            'status' => 'success',
            'leaderboard' => $leaderboard
        ]);
    }
}
