<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\AttendanceRecord;
use App\Models\AttendanceSession;
use App\Models\User;

class AttendanceRecordController extends Controller
{
    public function getRecordsBySession($sessionId)
    {
        $session = AttendanceSession::find($sessionId);

        if (!$session) {
            return response()->json([
                'status' => 'error',
                'message' => 'Sesi absensi tidak ditemukan'
            ], 404);
        }

        $students = User::where('kelas', $session->kelas)->get();
        $records = AttendanceRecord::where('session_id', $sessionId)->get();

        $data = $students->map(function ($student) use ($records) {
            $record = $records->where('user_id', $student->id)->first();
            return [
                'id' => $record ? $record->id : null,
                'nama' => $student->name,
                'status' => $record ? $record->status : 'alfa',
                'waktu_absen' => $record?->waktu_absen,
            ];
        });

        return response()->json([
            'status' => 'success',
            'data' => $data
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:hadir,alfa,izin,sakit'
        ]);

        $record = AttendanceRecord::find($id);

        if (!$record) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data absensi tidak ditemukan'
            ], 404);
        }

        $record->status = $request->status;
        $record->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Status absensi berhasil diubah'
        ]);
    }

    public function getBySession($sessionId)
    {
        $records = \App\Models\AttendanceRecord::where('session_id', $sessionId)->get(); // <--- Ganti ke session_id
    
        return response()->json([
            'status' => 'success',
            'data' => $records
        ]);
    }
    
    public function getAbsensiBySession($sessionId)
    {
        // Ambil sesi
        $session = \App\Models\AttendanceSession::find($sessionId);
    
        if (!$session) {
            return response()->json([
                'status' => 'error',
                'message' => 'Sesi tidak ditemukan'
            ], 404);
        }
    
        // Ambil semua siswa dari kelas yang sama
        $students = \App\Models\User::where('kelas', $session->kelas)
            ->where('role', 'siswa')
            ->get();
    
        // Ambil semua record absensi yang sudah ada untuk sesi ini
        $attendanceRecords = \App\Models\AttendanceRecord::where('session_id', $sessionId)
            ->get()
            ->keyBy('user_id'); // Key by user_id biar gampang lookup
    
        // Gabungkan
        $result = [];
    
        foreach ($students as $student) {
            $record = $attendanceRecords->get($student->id);
    
            $result[] = [
                'id' => $record ? $record->id : null,
                'user_id' => $student->id,
                'nama' => $student->name,
                'status' => $record ? $record->status : 'alfa', // Kalau belum absen, status = alfa
                'waktu_absen' => $record ? $record->waktu_absen : null,
            ];
        }
    
        return response()->json([
            'status' => 'success',
            'data' => $result,
        ]);
    }

    public function updateOrCreateAbsensi(Request $request, $siswaId)
{
    $validated = $request->validate([
        'session_id' => 'required|integer',
        'status' => 'required|string|in:hadir,izin,sakit,alfa',
    ]);

    $sessionId = $validated['session_id'];
    $status = $validated['status'];

    // Cari apakah sudah ada record untuk siswa ini di sesi ini
    $record = AttendanceRecord::where('session_id', $sessionId)
    ->where('user_id', $siswaId)
    ->first();

    if ($record) {
        // Kalau ada, update status
        $record->status = $status;
        $record->waktu_absen = now(); // Update waktu absen ke waktu sekarang
        $record->save();
    } else {
        // Kalau belum ada, buat baru
        AttendanceRecord::create([
            'session_id' => $sessionId,
            'user_id' => $siswaId,
            'status' => $status,
            'waktu_absen' => now(), // Set waktu absen sekarang
        ]);
    }

    return response()->json([
        'status' => 'success',
        'message' => 'Absensi berhasil disimpan.'
    ]);
}

public function checkKode(Request $request)
{
    $request->validate([
        'code' => 'required|string',
        'user_id' => 'required|integer',
    ]);

    $kode = $request->code;
    $userId = $request->user_id;

    // Ambil sesi berdasarkan kode
    $session = AttendanceSession::where('code', $kode)->first();

    if (!$session) {
        return response()->json([
            'status' => 'invalid',
            'message' => 'Kode absensi tidak ditemukan.'
        ], 404);
    }

    // Cek tanggal = hari ini
    if ($session->tanggal !== now()->toDateString()) {
        return response()->json([
            'status' => 'invalid_date',
            'message' => 'Kode absensi bukan untuk hari ini.'
        ], 403);
    }

    // Cek waktu sekarang dalam range
    $now = now()->format('H:i:s');
    if ($now < $session->jam_mulai || $now > $session->jam_selesai) {
        return response()->json([
            'status' => 'invalid_time',
            'message' => 'Waktu absen belum dibuka atau sudah ditutup.',
            'debug_now' => $now,
            'debug_mulai' => $session->jam_mulai,
            'debug_selesai' => $session->jam_selesai,
        ]);
    }

    // Cek apakah siswa sudah absen
    $sudahAbsen = AttendanceRecord::where('session_id', $session->id)
        ->where('user_id', $userId)
        ->exists();

    if ($sudahAbsen) {
        return response()->json([
            'status' => 'already_absent',
            'message' => 'Kamu sudah absen untuk sesi ini.'
        ], 409);
    }

    // Kalau semua valid
    return response()->json([
        'status' => 'valid',
        'message' => 'Kode valid dan sesi aktif.',
        'session_id' => $session->id,
        'kelas' => $session->kelas,
        'jam_mulai' => $session->jam_mulai,
        'jam_selesai' => $session->jam_selesai,
    ]);
}
public function submitAbsen(Request $request)
{
    $request->validate([
        'session_id' => 'required|integer',
        'user_id' => 'required|integer',
        // status tidak perlu dikirim dari frontend
    ]);

    // Cek apakah sudah absen
    $existing = AttendanceRecord::where('session_id', $request->session_id)
        ->where('user_id', $request->user_id)
        ->first();

    if ($existing) {
        return response()->json([
            'status' => 'already_absent',
            'message' => 'Kamu sudah absen sebelumnya.'
        ], 409);
    }

    // Simpan dengan status otomatis "hadir"
    $record = AttendanceRecord::create([
        'session_id' => $request->session_id,
        'user_id' => $request->user_id,
        'status' => 'hadir', // <--- langsung hardcoded di backend
        'waktu_absen' => now(),
    ]);

    return response()->json([
        'status' => 'success',
        'message' => 'Absensi berhasil dicatat.',
        'data' => $record
    ]);
}

public function getStatusHariIni(Request $request)
{
    $user = $request->user(); // siswa login
    $today = now()->toDateString();

    // 1. Cek sesi absensi hari ini untuk kelas user
    $session = AttendanceSession::where('kelas', $user->kelas)
        ->whereDate('tanggal', $today)
        ->first();

    if (!$session) {
        return response()->json([
            'status' => 'not_available',
            'message' => 'Belum ada sesi absensi untuk hari ini'
        ]);
    }

    // 2. Cek apakah siswa sudah absen
    $record = AttendanceRecord::where('session_id', $session->id)
        ->where('user_id', $user->id)
        ->first();

    if (!$record) {
        return response()->json([
            'status' => 'belum',
            'message' => 'Kamu belum absen hari ini'
        ]);
    }

    return response()->json([
        'status' => $record->status, // 'hadir', 'izin', 'sakit', 'alfa'
        'waktu_absen' => $record->waktu_absen,
    ]);
}




    
}