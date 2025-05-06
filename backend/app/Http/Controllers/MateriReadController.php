<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\MateriRead;

class MateriReadController extends Controller
{
    // ✅ Fungsi untuk menandai materi sebagai sudah dibaca
    public function markAsRead($id)
    {
        $userId = auth()->id();

        // Cek apakah sudah tercatat sebelumnya
        $already = MateriRead::where('user_id', $userId)
                             ->where('materi_id', $id)
                             ->first();

        if ($already) {
            return response()->json([
                'status' => 'already_read',
                'message' => 'Materi sudah dibaca sebelumnya.'
            ]);
        }

        // Simpan ke database
        MateriRead::create([
            'user_id' => $userId,
            'materi_id' => $id,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Berhasil menandai sebagai sudah dibaca.'
        ]);
    }
}
