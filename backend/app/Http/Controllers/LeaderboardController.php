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
        ->get()
        ->map(function ($siswa) {
            $jumlahKuis = QuizResult::where('user_id', $siswa->id)->count();
            $average = $jumlahKuis > 0
                ? round(QuizResult::where('user_id', $siswa->id)->avg('score'), 1)
                : null;

            return [
                'id' => $siswa->id,
                'name' => $siswa->name,
                'kelas' => $siswa->kelas,
                'total_score' => $siswa->total_score ?? 0,
                'average_score' => $average, // ✅ Tambahkan ini
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
    
       $leaderboard = User::where('role', 'siswa')
    ->where('kelas', $kelasDipilih)
    ->select('id', 'name', 'kelas')
    ->withSum('quizResults as total_score', 'score')
    ->get()
    ->map(function ($siswa) {
        $jumlahKuis = QuizResult::where('user_id', $siswa->id)->count();
        $average = $jumlahKuis > 0
            ? round(QuizResult::where('user_id', $siswa->id)->avg('score'), 1)
            : null;

        return [
            'id' => $siswa->id,
            'name' => $siswa->name,
            'kelas' => $siswa->kelas,
            'total_score' => $siswa->total_score ?? 0,
            'average_score' => $average, // ✅ Tambahan
        ];
    });
    return response()->json([
    'status' => 'success',
    'kelas_aktif' => $kelasDipilih,
    'leaderboard' => $leaderboard
]);

    }
    

}
