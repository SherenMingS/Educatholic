<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Materi;

class MateriController extends Controller
{
    public function index(Request $request)
    {
        $kelas = $request->query('kelas');
        $today = now()->toDateString();
    
        $query = Materi::query();
        if ($kelas) {
            $query->where('kelas', $kelas);
        }
    
        $materi = $query->orderBy('tanggal_tayang', 'desc')->get();
    
        // Tambahkan status tayang
        $materi->map(function ($item) use ($today) {
            $item->status = $item->tanggal_tayang <= $today ? 'tayang' : 'belum_tayang';
            return $item;
        });
    
        return response()->json(['materi' => $materi], 200);
    }
    
    public function store(Request $request)
    {
        try {
            // Validasi
            $request->validate([
                'judul' => 'required|string|max:255',
                'deskripsi' => 'nullable|string',
                'kelas' => 'required|string|max:10',
                'poin_poin' => 'nullable|string',
                'ayat' => 'nullable|string',
                'isi_ayat' => 'nullable|string',
                'file' => 'nullable|file|mimes:png,pdf,doc,docx|max:2048',
                'tanggal_tayang' => 'required|date',
            ]);

            // Simpan file jika ada
            $filePath = null;
            if ($request->hasFile('file')) {
                $filePath = $request->file('file')->store('materi_files', 'public');
            }

            // Simpan ke database
            $materi = Materi::create([
                'judul' => $request->judul,
                'deskripsi' => $request->deskripsi,
                'kelas' => $request->kelas,
                'poin_poin' => $request->poin_poin,
                'ayat' => $request->ayat,
                'isi_ayat' => $request->isi_ayat,
                'file' => $filePath,
                'tanggal_tayang' => $request->tanggal_tayang,
            ]);

            return response()->json([
                'message' => 'Materi berhasil diunggah!',
                'materi' => $materi
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Terjadi kesalahan!',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $materi = Materi::find($id);
            if (!$materi) {
                return response()->json(['message' => 'Materi tidak ditemukan'], 404);
            }

            // Update hanya field yang dikirim dalam request
            if ($request->has('judul')) {
                $materi->judul = $request->judul;
            }
            if ($request->has('deskripsi')) {
                $materi->deskripsi = $request->deskripsi;
            }
            if ($request->has('kelas')) {
                $materi->kelas = $request->kelas;
            }
            if ($request->has('poin_poin')) {
                $materi->poin_poin = $request->poin_poin;
            }
            if ($request->has('ayat')) {
                $materi->ayat = $request->ayat;
            }
            if ($request->has('isi_ayat')) {
                $materi->isi_ayat = $request->isi_ayat;
            }
            if ($request->has('tanggal_tayang')) {
                $materi->tanggal_tayang = $request->tanggal_tayang;
            }

            if ($request->hasFile('file')) {
                $filePath = $request->file('file')->store('materi_files', 'public');
                $materi->file = $filePath;
            }

            $materi->save();

            return response()->json([
                'message' => 'Materi berhasil diperbarui!',
                'materi' => $materi
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Terjadi kesalahan!',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function updateWithFile(Request $request, $id)
{
    try {
        $materi = Materi::find($id);
        if (!$materi) {
            return response()->json(['message' => 'Materi tidak ditemukan'], 404);
        }

        $request->validate([
            'judul' => 'required|string|max:255',
            'deskripsi' => 'nullable|string',
            'kelas' => 'required|string|max:10',
            'poin_poin' => 'nullable|string',
            'ayat' => 'nullable|string',
            'isi_ayat' => 'nullable|string',
            'tanggal_tayang' => 'required|date',
            'file' => 'nullable|file|mimes:pdf,doc,docx,png|max:2048',
        ]);

        $materi->judul = $request->judul;
        $materi->deskripsi = $request->deskripsi;
        $materi->kelas = $request->kelas;
        $materi->poin_poin = $request->poin_poin;
        $materi->ayat = $request->ayat;
        $materi->isi_ayat = $request->isi_ayat;
        $materi->tanggal_tayang = $request->tanggal_tayang;

        if ($request->hasFile('file') && $request->file('file')->isValid()) {
            $filePath = $request->file('file')->store('materi_files', 'public');
            $materi->file = $filePath;
        }

        $materi->save();

        return response()->json([
            'message' => 'Materi berhasil diperbarui (dengan file)',
            'materi' => $materi
        ]);
    } catch (\Exception $e) {
        return response()->json(['message' => 'Gagal update', 'error' => $e->getMessage()], 500);
    }
}

    public function destroy($id)
    {
        try {
            $materi = Materi::find($id);
            if (!$materi) {
                return response()->json(['message' => 'Materi tidak ditemukan'], 404);
            }

            $materi->delete();

            return response()->json([
                'message' => 'Materi berhasil dihapus!'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Terjadi kesalahan saat menghapus!',
                'error' => $e->getMessage()
            ], 500);
        }
}


//STUDENT
public function show($id)
{
    $materi = Materi::find($id);

    if (!$materi) {
        return response()->json(['message' => 'Materi tidak ditemukan'], 404);
    }

    // Jika `poin_poin` masih berbentuk String, ubah ke Array (List)
    if (is_string($materi->poin_poin)) {
        $materi->poin_poin = explode(',', $materi->poin_poin); // Ubah jadi List
    }

    return response()->json($materi, 200);
}



}