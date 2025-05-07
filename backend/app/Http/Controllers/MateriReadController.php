<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\MateriRead;
use App\Models\Materi;  // Menambahkan model Materi untuk validasi materi_id

class MateriReadController extends Controller
{
    // ✅ Fungsi untuk menandai materi sebagai sudah dibaca
    public function markAsRead($id)
    {
        $userId = auth()->id();
    
        // Cek apakah materi dengan ID yang diberikan ada
        $materi = Materi::find($id);
        if (!$materi) {
            return response()->json([
                'status' => 'error',
                'message' => 'Materi tidak ditemukan.'
            ], 404);
        }
    
        // Cek apakah materi sudah tercatat sebelumnya
        $already = MateriRead::where('user_id', $userId)
                             ->where('materi_id', $id)
                             ->first();
    
        if ($already) {
            return response()->json([
                'status' => 'already_read',
                'message' => 'Materi sudah dibaca sebelumnya.',
                'materi' => $materi->judul // Menambahkan nama materi
            ]);
        }
    
        // Simpan ke database
        try {
            MateriRead::create([
                'user_id' => $userId,
                'materi_id' => $id,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Terjadi kesalahan saat menyimpan data.',
                'error' => $e->getMessage(),
            ], 500);
        }
    
        return response()->json([
            'status' => 'success',
            'message' => 'Berhasil menandai sebagai sudah dibaca.',
            'materi' => $materi->judul // Mengembalikan nama materi
        ]);
    }
    public function materi()
{
    return $this->belongsTo(Materi::class, 'materi_id');
}
    
}
