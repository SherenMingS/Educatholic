<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\MateriController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Endpoint untuk mendapatkan data user yang sedang login
Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return response()->json([
        'user' => $request->user()
    ], 200);
});

// Endpoint test API
Route::get('/hello', function () {
    return response()->json(['message' => 'Hello, Flutter from sheren!'], 200);
});

// **Auth Routes**
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

// **Dashboard Routes** (Harus login)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/dashboard-siswa', [DashboardController::class, 'index'])->middleware('role:siswa');
    Route::get('/dashboard-guru', [DashboardController::class, 'dashboardGuru'])->middleware('role:guru');
    
});

use App\Http\Controllers\UserController;

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/students/{kelas}', [UserController::class, 'getStudentsByClass'])->middleware('role:guru');
});

Route::middleware(['auth:sanctum'])->get('/user/profile', [UserController::class, 'getUserProfile']);


// **Materi Routes** (Hanya guru yang bisa menambah, mengedit, atau menghapus materi)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/materi', [MateriController::class, 'index']);
    Route::get('/materi/{id}', [MateriController::class, 'show']); // Ambil detail materi
    Route::post('/materi', [MateriController::class, 'store'])->middleware('role:guru');
    Route::put('/materi/{id}', [MateriController::class, 'update'])->middleware('role:guru');
    Route::delete('/materi/{id}', [MateriController::class, 'destroy'])->middleware('role:guru');
});

use App\Http\Controllers\QuizController;

Route::middleware(['auth:sanctum', 'role:siswa'])->group(function () {
    Route::get('/quizzes/student', [QuizController::class, 'getQuizzesForStudents']);
    Route::get('/quizzes/{id}/student', [QuizController::class, 'getQuizForStudent']);
    Route::post('/quizzes/{id}/submit', [QuizController::class, 'submitQuiz']); // ✅ Perbaikan
});

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/quizzes', [QuizController::class, 'createQuiz'])->middleware('role:guru');
    Route::get('/quizzes', [QuizController::class, 'getAllQuizzes'])->middleware('role:guru');
    Route::get('/quizzes/{id}', [QuizController::class, 'getQuizDetail'])->middleware('role:guru'); // Ambil detail quiz
    Route::put('/quizzes/{id}', [QuizController::class, 'updateQuiz'])->middleware('role:guru');
    Route::delete('/quizzes/{id}', [QuizController::class, 'deleteQuiz'])->middleware('role:guru'); // Hapus quiz
});


use App\Http\Controllers\LeaderboardController;


Route::middleware(['auth:sanctum'])->get('/leaderboard/students', [LeaderboardController::class, 'getStudentLeaderboard']);




