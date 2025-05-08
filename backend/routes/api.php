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
use App\Http\Controllers\MateriReadController;


Route::middleware('auth:sanctum')->group(function () {
    Route::get('/materi', [MateriController::class, 'index']);
    Route::get('/materi/{id}', [MateriController::class, 'show']);

    Route::post('/materi/read/{id}', [MateriReadController::class, 'markAsRead']);

    Route::post('/materi', [MateriController::class, 'store'])->middleware('role:guru');
    Route::put('/materi/{id}', [MateriController::class, 'update'])->middleware('role:guru');
    Route::post('/materi/update-file/{id}', [MateriController::class, 'updateWithFile'])->middleware('role:guru');
    Route::delete('/materi/{id}', [MateriController::class, 'destroy'])->middleware('role:guru');
});

Route::get('/materi/read/list', [MateriReadController::class, 'getReadMateri'])->middleware('auth:sanctum');


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

Route::middleware(['auth:sanctum', 'role:guru'])->get('/leaderboard/teacher', [LeaderboardController::class, 'getTeacherLeaderboard']);

use App\Http\Controllers\StudentController;

Route::middleware(['auth:sanctum', 'role:siswa'])->get('/student/profile', [StudentController::class, 'getProfile']);
Route::middleware('auth:sanctum')->post('/user/update-photo', [UserController::class, 'updatePhoto']);


use App\Http\Controllers\BibleController;

Route::prefix('bible')->group(function () {
    Route::get('/books', [BibleController::class, 'books']);
    Route::get('/chapters', [BibleController::class, 'chapters']);
    Route::get('/verses', [BibleController::class, 'verses']);
    Route::get('/lookup', [BibleController::class, 'lookup']);
});



use App\Http\Controllers\AttendanceSessionController;

Route::post('/attendance-sessions', [AttendanceSessionController::class, 'generate']);

use App\Http\Controllers\AttendanceRecordController;

// Menampilkan daftar absensi berdasarkan sesi
Route::middleware('auth:sanctum')->get('/attendance-sessions/{session_id}/records', [AttendanceRecordController::class, 'getRecordsBySession']);

// Mengupdate status absensi siswa (izin / sakit)
// Route::middleware('auth:sanctum')->put('/attendance-records/{id}', [AttendanceRecordController::class, 'updateStatus']);
Route::put('/attendance-records/{siswaId}', [AttendanceRecordController::class, 'updateOrCreateAbsensi']);

Route::middleware('auth:sanctum')->get('/attendance-sessions', [AttendanceSessionController::class, 'index']);

Route::get('/attendance-records/{sessionId}', [AttendanceRecordController::class, 'getBySession']);
Route::get('/students-by-class/{kelas}', [StudentController::class, 'getByClass']);
Route::get('/attendance-records/session/{sessionId}', [AttendanceRecordController::class, 'getAbsensiBySession']);
Route::post('/attendance/check-code', [AttendanceRecordController::class, 'checkKode']);
Route::middleware(['auth:sanctum', 'role:siswa'])->post('/attendance-records/absen', [AttendanceRecordController::class, 'submitAbsen']);

use App\Http\Controllers\TeacherController;

Route::middleware(['auth:sanctum', 'role:guru'])->get('/teacher/profile', [TeacherController::class, 'profile']);

Route::middleware(['auth:sanctum', 'role:guru'])->group(function () {
    Route::post('/teacher/update-photo', [TeacherController::class, 'updatePhoto']);
});

use Illuminate\Support\Facades\Password;

use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use App\Mail\ResetOtpMail;
use App\Models\User;

Route::post('/forgot-password', function (Request $request) {
    $request->validate(['email' => 'required|email']);

    $user = \App\Models\User::where('email', $request->email)->first();

    if (!$user) {
        return response()->json(['status' => 'error', 'message' => 'Email tidak ditemukan.']);
    }

    $otp = random_int(100000, 999999); // 👈 OTP 6 digit

    $user->update([
        'reset_otp' => $otp,
        'reset_otp_expires_at' => now()->addMinutes(10),
    ]);

    \Mail::to($user->email)->send(new \App\Mail\ResetOtpMail($otp));

    return response()->json([
        'status' => 'success',
        'message' => 'Kode OTP berhasil dikirim ke email kamu.'
    ]);
});






use Illuminate\Support\Facades\Hash;
use Illuminate\Auth\Events\PasswordReset;

Route::post('/reset-password', function (Request $request) {
    $request->validate([
        'email' => 'required|email',
        'otp' => 'required',
        'password' => 'required|min:8|confirmed',
    ]);

    $user = \App\Models\User::where('email', $request->email)->first();

    if (!$user || $user->reset_otp !== $request->otp) {
        return response()->json([
            'status' => 'error',
            'message' => 'OTP salah atau tidak valid.'
        ], 400);
    }

    if ($user->reset_otp_expires_at < now()) {
        return response()->json([
            'status' => 'error',
            'message' => 'OTP sudah kadaluarsa.'
        ], 400);
    }

    $user->update([
        'password' => Hash::make($request->password),
        'reset_otp' => null,
        'reset_otp_expires_at' => null,
    ]);

    return response()->json([
        'status' => 'success',
        'message' => 'Password berhasil direset.'
    ]);
});

use App\Http\Controllers\ActivityLogController;

Route::middleware('auth:sanctum')->get('/activity-logs', [ActivityLogController::class, 'getActivityLogs']);

use App\Http\Controllers\QuizResultController;

Route::middleware('auth:sanctum')->get('/check-quiz-attempted/{quizId}', [QuizResultController::class, 'checkIfAttempted']);

Route::get('/attendance-sessions/last', [AttendanceSessionController::class, 'getLastSessionByKelas']);
