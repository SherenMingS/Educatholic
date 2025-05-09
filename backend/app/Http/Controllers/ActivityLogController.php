<?php
namespace App\Http\Controllers;

use App\Models\MateriRead;
use App\Models\QuizResult;
use Illuminate\Http\Request;

class ActivityLogController extends Controller
{
    public function getActivityLogs(Request $request)
    {
        $userId = auth()->id(); // Ambil ID user yang sedang login

        // Ambil aktivitas membaca materi dan eager load relasi ke Materi
        $materiReads = MateriRead::with('materi')  // Eager load materi
        ->where('user_id', $userId)
        ->orderBy('created_at', 'desc')
        ->get()
        ->map(function ($item) {
            $item->action = 'Membaca Materi';
            // Pastikan materi tersedia untuk diakses
            $item->description = $item->materi ? "Materi " . $item->materi->judul : "Materi Tidak Ditemukan"; 
            $item->status = 'Sukses';
            return $item;
        });

        // Ambil aktivitas mengikuti kuis untuk user yang sedang login
        $quizResults = QuizResult::with('quiz') // Tambahkan eager load quiz
    ->where('user_id', $userId)
    ->orderBy('created_at', 'desc')
    ->get()
    ->map(function ($item) {
        $item->action = 'Mengikuti Kuis';
        $item->description = $item->quiz ? "Kuis " . $item->quiz->title : "Kuis Tidak Ditemukan";
        $item->status = 'Sukses';
        return $item;
    });


        // Gabungkan aktivitas membaca materi dan mengerjakan kuis
        $activityLogs = $materiReads->merge($quizResults)
            ->sortByDesc('created_at');  // Urutkan berdasarkan waktu

        return response()->json([
            'status' => 'success',
            'data' => $activityLogs
        ]);
    }
}