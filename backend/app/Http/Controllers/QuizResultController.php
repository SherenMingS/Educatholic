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
    $userId = Auth::id(); // Ambil user_id dari Auth

    // Cek apakah sudah ada record di quiz_results untuk user dan quiz tertentu
    $existingResult = QuizResult::where('user_id', $userId)
                                ->where('quiz_id', $quizId)
                                ->first();

    if ($existingResult) {
        // Jika sudah ada, berarti kuis sudah dikerjakan
        return response()->json(['status' => 'failed', 'message' => 'Anda sudah mengerjakan kuis ini'], 400);
    }

    // Jika belum ada, kuis bisa dikerjakan
    return response()->json(['status' => 'success', 'message' => 'Kuis bisa dikerjakan'], 200);
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

    // Simpan hasil kuis
    $quizResult = QuizResult::create([
        'user_id' => $userId,
        'quiz_id' => $validated['quiz_id'],
        'score' => $validated['score'],
        'correct_answers' => $validated['correct_answers'],
        'total_questions' => $validated['total_questions'],
    ]);

    return response()->json(['status' => 'success', 'message' => 'Hasil kuis disimpan', 'data' => $quizResult], 201);
}

// File: app/Models/QuizResult.php

public function quiz()
{
    return $this->belongsTo(\App\Models\Quiz::class);
}


}
