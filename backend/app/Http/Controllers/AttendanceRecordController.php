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
    
}
