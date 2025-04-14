<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\AttendanceSession;
use Illuminate\Support\Str;

class AttendanceSessionController extends Controller
{
    public function generate(Request $request)
    {
        // Validasi input
        $request->validate([
            'kelas' => 'required|string',
            'tanggal' => 'required|date',
            'jam_mulai' => 'required',
            'jam_selesai' => 'required',
        ]);

        // Generate kode unik (misal: 8A-20250414)
        $kode = strtoupper(Str::random(5));

        // Simpan ke database
        $session = AttendanceSession::create([
            'kelas' => $request->kelas,
            'code' => $kode,
            'tanggal' => $request->tanggal,
            'jam_mulai' => $request->jam_mulai,
            'jam_selesai' => $request->jam_selesai,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Sesi absensi berhasil dibuat',
            'data' => $session
        ]);
    }
    public function index(Request $request)
{
    // Ambil kelas aktif dari query param
    $kelas = $request->query('kelas'); // contoh: /attendance-sessions?kelas=8A

    if (!$kelas) {
        return response()->json([
            'status' => 'error',
            'message' => 'Kelas harus disertakan'
        ], 400);
    }

    $sessions = AttendanceSession::where('kelas', $kelas)
                ->orderBy('created_at', 'desc')
                ->get();

    return response()->json([
        'status' => 'success',
        'data' => $sessions
    ]);
}
    

}
