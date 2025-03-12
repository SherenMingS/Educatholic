<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Quiz;
use App\Models\QuizQuestion;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;


use App\Models\Badge;
use App\Models\QuizResult;

class QuizController extends Controller
{
    public function createQuiz(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'kelas' => 'required|string|max:10',
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
            'created_by' => auth()->user()->id,
            'duration' => $request->duration,
            'deadline' => $request->deadline,
            'quiz_code' => Str::random(6),
        ]);

        $totalQuestions = count($request->questions);
        $scorePerQuestion = $totalQuestions > 0 ? round(100 / $totalQuestions, 2) : 0;

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
            'score_per_question' => $scorePerQuestion,
        ]);
    }

    public function getAllQuizzes(Request $request)
    {
        $kelasGuru = $request->query('kelas');

        $quizzes = Quiz::where('created_by', auth()->user()->id)
                        ->when($kelasGuru, function ($query) use ($kelasGuru) {
                            return $query->where('kelas', $kelasGuru);
                        })
                        ->with('questions')
                        ->withCount('questions')
                        ->orderBy('created_at', 'desc')
                        ->get();

        return response()->json([
            'status' => 'success',
            'data' => $quizzes
        ]);
    }

    public function getQuizDetail($id)
    {
        $quiz = Quiz::with('questions')->where('id', $id)->first();

        if (!$quiz) {
            return response()->json(['message' => 'Quiz tidak ditemukan'], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $quiz
        ]);
    }

    public function updateQuiz(Request $request, $id)
{
    $request->validate([
        'title' => 'required|string|max:255',
        'kelas' => 'required|string|max:10',
        'duration' => 'nullable|integer|min:1',
        'deadline' => 'nullable|date',
        'questions' => 'nullable|array|min:1',
    ]);

    $quiz = Quiz::where('id', $id)->where('created_by', auth()->user()->id)->first();
    if (!$quiz) {
        return response()->json(['message' => 'Quiz tidak ditemukan atau tidak memiliki akses'], 403);
    }

    // 🔥 Update data kuis yang sudah ada
    $quiz->update([
        'title' => $request->title,
        'kelas' => $request->kelas,
        'duration' => $request->duration,
        'deadline' => $request->deadline,
    ]);

    if ($request->has('questions')) {
        $existingQuestionIds = QuizQuestion::where('quiz_id', $quiz->id)->pluck('id')->toArray();
        $updatedQuestionIds = [];

        foreach ($request->questions as $q) {
            if (isset($q['id']) && in_array($q['id'], $existingQuestionIds)) {
                // 🔥 Update soal yang sudah ada
                $question = QuizQuestion::find($q['id']);
                $question->update([
                    'question' => $q['question'],
                    'option_1' => $q['option_1'],
                    'option_2' => $q['option_2'],
                    'option_3' => $q['option_3'],
                    'option_4' => $q['option_4'],
                    'correct_answer' => $q['correct_answer'],
                ]);
                $updatedQuestionIds[] = $q['id'];
            } else {
                // 🔥 Buat soal baru jika belum ada
                $newQuestion = QuizQuestion::create([
                    'quiz_id' => $quiz->id,
                    'question' => $q['question'],
                    'option_1' => $q['option_1'],
                    'option_2' => $q['option_2'],
                    'option_3' => $q['option_3'],
                    'option_4' => $q['option_4'],
                    'correct_answer' => $q['correct_answer'],
                ]);
                $updatedQuestionIds[] = $newQuestion->id;
            }
        }

        // 🔥 Hapus soal yang tidak dikirim dari frontend
        $questionsToDelete = array_diff($existingQuestionIds, $updatedQuestionIds);
        QuizQuestion::whereIn('id', $questionsToDelete)->delete();

        // 🔥 **Hitung ulang skor setelah update**
        $totalQuestions = QuizQuestion::where('quiz_id', $quiz->id)->count();
        $scorePerQuestion = $totalQuestions > 0 ? round(100 / $totalQuestions, 2) : 0;

        QuizQuestion::where('quiz_id', $quiz->id)->update(['score' => $scorePerQuestion]);
    }

    return response()->json([
        'status' => 'success',
        'message' => 'Quiz berhasil diperbarui',
        'quiz' => $quiz
    ]);
}


public function deleteQuiz($id)
{
    $quiz = Quiz::where('id', $id)->where('created_by', auth()->user()->id)->first();

    if (!$quiz) {
        return response()->json(['message' => 'Quiz tidak ditemukan atau tidak memiliki akses'], 403);
    }

    // Hapus semua soal yang terkait dengan kuis ini
    QuizQuestion::where('quiz_id', $quiz->id)->delete();

    // Hapus kuisnya
    $quiz->delete();

    return response()->json([
        'status' => 'success',
        'message' => 'Quiz berhasil dihapus'
    ]);
}

// student yaa
public function getQuizzesForStudents(Request $request)
{
    $kelas = $request->query('kelas'); // Ambil kelas dari request

    $quizzes = Quiz::where('kelas', $kelas) // Filter kuis berdasarkan kelas siswa
                   ->withCount('questions')
                   ->orderBy('created_at', 'desc')
                   ->get();

    return response()->json([
        'status' => 'success',
        'data' => $quizzes
    ]);
}



public function getQuizForStudent($id)
{
    $quiz = Quiz::with('questions')->where('id', $id)->first();

    if (!$quiz) {
        return response()->json(['message' => 'Quiz tidak ditemukan'], 404);
    }

    return response()->json([
        'status' => 'success',
        'data' => $quiz
    ]);
}



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

    $correctAnswers = 0;
    $totalQuestions = count($request->answers);

    foreach ($request->answers as $answer) {
        $question = QuizQuestion::find($answer['question_id']);
        if ($question->correct_answer === $answer['selected_answer']) {
            $correctAnswers++;
        }
    }

    $score = round(($correctAnswers / $totalQuestions) * 100, 2);

    // 🔥 **Jika skor 100, update badge**
    if ($score == 100) {
        $badge = Badge::where('user_id', auth()->id())->first();
        if ($badge) {
            $badge->increment('jumlah'); // Tambah jumlah badge
        } else {
            Badge::create([
                'user_id' => auth()->id(),
                'jumlah' => 1,
                'badge_level' => 'Gold'
            ]);
        }
    }

    return response()->json([
        'status' => 'success',
        'message' => 'Jawaban berhasil disimpan!',
        'score' => $score,
        'correct_answers' => $correctAnswers,
        'total_questions' => $totalQuestions
    ]);
}





}
