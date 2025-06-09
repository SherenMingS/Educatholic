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

    $siswaList = User::where('role', 'siswa')
        ->where('kelas', $kelas)
        ->select('id', 'name', 'kelas')
        ->get();

    $leaderboard = $siswaList->map(function ($siswa) {
        // Ambil semua hasil kuis, lalu group by quiz_id
        $results = QuizResult::where('user_id', $siswa->id)
            ->get()
            ->groupBy('quiz_id');

        $totalScore = 0;

        foreach ($results as $quizAttempts) {
            $averagePerQuiz = $quizAttempts->avg('score'); // rata-rata attempt per quiz
            $totalScore += $averagePerQuiz;
        }

        $quizCount = $results->count();
        $averageScore = $quizCount > 0 ? round($totalScore / $quizCount, 1) : 0;

        return [
            'id' => $siswa->id,
            'name' => $siswa->name,
            'kelas' => $siswa->kelas,
            'total_score' => round($totalScore, 1), // total poin leaderboard
            'average_score' => $averageScore,
            'quiz_count' => $quizCount,
        ];
    });

    return response()->json([
        'status' => 'success',
        'leaderboard' => $leaderboard,
    ]);
}



 public function getTeacherLeaderboard(Request $request)
{
    $teacher = auth()->user();
    $kelasGuru = json_decode($teacher->kelas, true); // Pastikan dalam bentuk array

    if (!$kelasGuru || !is_array($kelasGuru)) {
        return response()->json(['message' => 'Anda tidak memiliki kelas yang dikelola'], 403);
    }

    $kelasDipilih = $request->query('kelas'); // Guru memilih kelas yang akan dilihat

    if (!$kelasDipilih || !in_array($kelasDipilih, $kelasGuru)) {
        return response()->json(['message' => 'Anda tidak memiliki akses ke kelas ini'], 403);
    }

    $siswaList = User::where('role', 'siswa')
        ->where('kelas', $kelasDipilih)
        ->select('id', 'name', 'kelas')
        ->get();

    $leaderboard = $siswaList->map(function ($siswa) {
        // Group hasil kuis berdasarkan quiz_id
        $results = QuizResult::where('user_id', $siswa->id)
            ->get()
            ->groupBy('quiz_id');

        $totalScore = 0;

        foreach ($results as $quizAttempts) {
            $averagePerQuiz = $quizAttempts->avg('score'); // rata-rata attempt per kuis
            $totalScore += $averagePerQuiz;
        }

        $quizCount = $results->count();
        $averageScore = $quizCount > 0 ? round($totalScore / $quizCount, 1) : 0;

        return [
            'id' => $siswa->id,
            'name' => $siswa->name,
            'kelas' => $siswa->kelas,
            'total_score' => round($totalScore, 1), // total poin leaderboard
            'average_score' => $averageScore,
            'quiz_count' => $quizCount,
        ];
    });

    return response()->json([
        'status' => 'success',
        'kelas_aktif' => $kelasDipilih,
        'leaderboard' => $leaderboard
    ]);
}

    

}
