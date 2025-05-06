<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Quiz;
use App\Models\QuizQuestion;
use App\Models\QuizResult;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth; 
use App\Models\MateriRead;

class QuizController extends Controller
{
    // ✅ CREATE QUIZ
    public function createQuiz(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'kelas' => 'required|string|max:10',
            'materi_id' => 'required|exists:materi,id',
            'duration' => 'nullable|integer|min:1',
            'deadline' => 'nullable|date',
            'questions' => 'required|array|min:1',
            'questions.*.question' => 'required|string',
            'questions.*.option_1' => 'required|string',
            'questions.*.option_2' => 'required|string',
            'questions.*.option_3' => 'required|string',
            'questions.*.option_4' => 'required|string',
            'questions.*.correct_answer' => 'required|in:A,B,C,D',
        ]);

        $quiz = Quiz::create([
            'title' => $request->title,
            'kelas' => $request->kelas,
            'materi_id' => $request->materi_id,
            'created_by' => auth()->user()->id,
            'duration' => $request->duration,
            'deadline' => $request->deadline,
            'quiz_code' => Str::random(6),
        ]);

        $scorePerQuestion = round(100 / count($request->questions), 2);

        foreach ($request->questions as $q) {
            QuizQuestion::create([
                'quiz_id' => $quiz->id,
                'question' => $q['question'],
                'option_1' => $q['option_1'],
                'option_2' => $q['option_2'],
                'option_3' => $q['option_3'],
                'option_4' => $q['option_4'],
                'correct_answer' => $q['correct_answer'],
                'score' => $scorePerQuestion,
            ]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Quiz berhasil dibuat',
            'quiz' => $quiz,
        ]);
    }

    // ✅ GET ALL QUIZZES (GURU)
    public function getAllQuizzes(Request $request)
    {
        $kelasGuru = $request->query('kelas');

        $quizzes = Quiz::where('created_by', auth()->user()->id)
            ->when($kelasGuru, fn($q) => $q->where('kelas', $kelasGuru))
            ->with('questions')
            ->withCount('questions')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $quizzes,
        ]);
    }

    // ✅ GET QUIZ DETAIL
    public function getQuizDetail($id)
    {
        $quiz = Quiz::with('questions')->find($id);

        if (!$quiz) {
            return response()->json(['message' => 'Quiz tidak ditemukan'], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $quiz,
        ]);
    }

    // ✅ GET QUIZ FOR STUDENTS BY KELAS
    // public function getQuizzesForStudents(Request $request)
    // {
    //     $kelas = $request->query('kelas');

    //     $quizzes = Quiz::where('kelas', $kelas)
    //         ->withCount('questions')
    //         ->orderBy('created_at', 'desc')
    //         ->get();

    //     return response()->json([
    //         'status' => 'success',
    //         'data' => $quizzes,
    //     ]);
    // }

    public function getQuizzesForStudents(Request $request)
{
    $kelas = $request->query('kelas');
    $userId = Auth::id();

    $quizzes = Quiz::where('kelas', $kelas)
        ->withCount('questions')
        ->orderBy('created_at', 'desc')
        ->get();

    foreach ($quizzes as $quiz) {
        $quiz->is_read = false;
        if ($quiz->materi_id) {
            $quiz->is_read = MateriRead::where('user_id', $userId)
                ->where('materi_id', $quiz->materi_id)
                ->exists();
        }
    }

    return response()->json([
        'status' => 'success',
        'data' => $quizzes,
    ]);
}

    // ✅ GET QUIZ FOR STUDENT BY ID
    public function getQuizForStudent($id)
    {
        $quiz = Quiz::with('questions')->find($id);

        if (!$quiz) {
            return response()->json(['message' => 'Quiz tidak ditemukan'], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $quiz,
        ]);
    }

    // ✅ SUBMIT QUIZ
    public function submitQuiz(Request $request, $id)
    {
        $request->validate([
            'answers' => 'required|array',
            'answers.*.question_id' => 'required|exists:quiz_questions,id',
            'answers.*.selected_answer' => 'required|in:A,B,C,D',
        ]);

        $quiz = Quiz::find($id);
        if (!$quiz) {
            return response()->json(['message' => 'Quiz tidak ditemukan'], 404);
        }

        $correct = 0;
        $total = count($request->answers);

        foreach ($request->answers as $answer) {
            $question = QuizQuestion::find($answer['question_id']);
            if ($question && $question->correct_answer === $answer['selected_answer']) {
                $correct++;
            }
        }

        $score = round(($correct / $total) * 100, 2);

        QuizResult::create([
            'user_id' => auth()->id(),
            'quiz_id' => $id,
            'score' => $score,
            'correct_answers' => $correct,
            'total_questions' => $total,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Jawaban berhasil disimpan!',
            'score' => $score,
            'correct_answers' => $correct,
            'total_questions' => $total,
        ]);
    }

    // ✅ UPDATE QUIZ (TERMASUK MATERI_ID)
    public function updateQuiz(Request $request, $id)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'kelas' => 'required|string|max:10',
            'materi_id' => 'required|exists:materi,id',
            'duration' => 'nullable|integer|min:1',
            'deadline' => 'nullable|date',
        ]);

        $quiz = Quiz::where('id', $id)->where('created_by', auth()->user()->id)->first();
        if (!$quiz) {
            return response()->json(['message' => 'Quiz tidak ditemukan atau tidak memiliki akses'], 403);
        }

        $quiz->update([
            'title' => $request->title,
            'kelas' => $request->kelas,
            'materi_id' => $request->materi_id,
            'duration' => $request->duration,
            'deadline' => $request->deadline,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Quiz berhasil diperbarui',
            'quiz' => $quiz,
        ]);
    }

    // ✅ DELETE QUIZ
    public function deleteQuiz($id)
    {
        $quiz = Quiz::where('id', $id)->where('created_by', auth()->user()->id)->first();
        if (!$quiz) {
            return response()->json(['message' => 'Quiz tidak ditemukan atau tidak memiliki akses'], 403);
        }

        QuizQuestion::where('quiz_id', $quiz->id)->delete();
        $quiz->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Quiz berhasil dihapus',
        ]);
    }
}
