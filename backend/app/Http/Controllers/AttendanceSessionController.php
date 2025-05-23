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

public function getLastSessionByKelas(Request $request)
{
    $kelas = $request->query('kelas');

    if (!$kelas) {
        return response()->json([
            'status' => 'error',
            'message' => 'Kelas harus disertakan'
        ], 400);
    }

    $session = AttendanceSession::where('kelas', $kelas)
                ->orderBy('created_at', 'desc')
                ->first();

    if (!$session) {
        return response()->json([
            'status' => 'empty',
            'message' => 'Belum ada sesi absensi untuk kelas ini'
        ]);
    }

    $hadir = \App\Models\AttendanceRecord::where('session_id', $session->id)
        ->where('status', 'hadir')
        ->count();

    $total = \App\Models\User::where('kelas', $kelas)
        ->where('role', 'siswa')
        ->count();

    return response()->json([
        'status' => 'success',
        'data' => [
            'kelas' => $session->kelas,
            'kode' => $session->code,
            'tanggal' => $session->tanggal,
            'jam_mulai' => $session->jam_mulai,
            'jam_selesai' => $session->jam_selesai,
            'hadir' => $hadir,
            'total_siswa' => $total
        ]
    ]);
}

public function getStatusHariIni(Request $request)
{
    $user = $request->user(); // Siswa yang login
    $tanggalHariIni = now()->toDateString();

    // Cek sesi absensi untuk kelas user pada hari ini
    $session = AttendanceSession::where('kelas', $user->kelas)
                ->whereDate('tanggal', $tanggalHariIni)
                ->first();

    if (!$session) {
        return response()->json([
            'status' => 'not_available',
            'message' => 'Guru belum membuka sesi absensi hari ini'
        ]);
    }

    // Cek apakah siswa sudah absen
    $record = AttendanceRecord::where('user_id', $user->id)
                ->where('session_id', $session->id)
                ->first();

    if ($record && $record->status === 'hadir') {
        return response()->json([
            'status' => 'hadir',
            'message' => 'Kamu sudah absen hari ini'
        ]);
    }

    return response()->json([
        'status' => 'belum',
        'message' => 'Kamu belum absen hari ini'
    ]);
}


    

}
