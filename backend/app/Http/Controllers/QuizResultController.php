<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\QuizResult;
use Illuminate\Support\Facades\Auth;

class QuizResultController extends Controller
{
    // Endpoint untuk memeriksa apakah quiz sudah dikerjakan
 public function checkIfAttempted($quizId)
{
    $userId = Auth::id();

    $quiz = \App\Models\Quiz::find($quizId);
    if (!$quiz) {
        return response()->json(['status' => 'failed', 'message' => 'Quiz tidak ditemukan'], 404);
    }

    $latestResult = QuizResult::where('user_id', $userId)
                        ->where('quiz_id', $quizId)
                        ->latest()
                        ->first();

    $attemptCount = QuizResult::where('user_id', $userId)
                        ->where('quiz_id', $quizId)
                        ->count();

    // ✅ Kalau sudah pernah ngerjain dan nilai >= kkm, tolak retry meskipun belum max_attempts
    if ($latestResult && $latestResult->score >= $quiz->kkm) {
        return response()->json([
            'status' => 'failed',
            'message' => 'Kamu sudah mengerjakan kuis dan nilai sudah passing KKM',
            'can_retry' => false,
            'last_score' => $latestResult->score,
            'current_attempts' => $attemptCount,
            'max_attempts' => $quiz->max_attempts,
        ]);
    }

    // ✅ Kalau masih bisa retry
    return response()->json([
        'status' => 'success',
        'message' => 'Kuis bisa dikerjakan',
        'can_retry' => $attemptCount < $quiz->max_attempts,
        'last_score' => optional($latestResult)->score,
        'current_attempts' => $attemptCount,
        'max_attempts' => $quiz->max_attempts,
    ]);
}




    public function storeQuizResult(Request $request)
{
    $validated = $request->validate([
        'quiz_id' => 'required|exists:quizzes,id',
        'score' => 'required|integer',
        'correct_answers' => 'required|integer',
        'total_questions' => 'required|integer',
    ]);

    $userId = Auth::id();

    // Simpan attempt baru tanpa menghitung rata-rata
    $quizResult = QuizResult::create([
        'user_id' => $userId,
        'quiz_id' => $validated['quiz_id'],
        'score' => $validated['score'], // langsung nilai 100
        'correct_answers' => $validated['correct_answers'],
        'total_questions' => $validated['total_questions'],
    ]);

    return response()->json([
        'status' => 'success',
        'message' => 'Hasil kuis disimpan',
        'data' => $quizResult,
    ], 201);
}



// File: app/Models/QuizResult.php

public function quiz()
{
    return $this->belongsTo(\App\Models\Quiz::class);
}


}
