<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;

class UserController extends Controller
{
    // ✅ Endpoint: Ambil Profil User Login (tanpa school_name)
    public function getUserProfile(Request $request)
    {
        $user = auth()->user();

        return response()->json([
            'status' => 'success',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'kelas' => $user->kelas,
                'role' => $user->role,
                'photo' => $user->photo,
                'gender' => $user->gender // ✅ tetap tampilkan gender
            ]
        ]);
    }

    // ✅ Endpoint: Ambil semua siswa berdasarkan kelas
    public function getStudentsByClass($kelas)
    {
        $students = User::where('role', 'siswa')
                        ->where('kelas', $kelas)
                        ->select('id', 'name', 'email', 'kelas')
                        ->get();

        if ($students->isEmpty()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Tidak ada siswa di kelas ini'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $students
        ]);
    }

    // ✅ Endpoint: Update Foto Profil
    public function updatePhoto(Request $request)
    {
        $user = auth()->user();

        $request->validate([
            'photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        if ($request->hasFile('photo')) {
            $file = $request->file('photo');
            $filename = time() . '.' . $file->getClientOriginalExtension();
            $file->move(public_path('uploads/profile'), $filename);

            $user->photo = 'uploads/profile/' . $filename;
            $user->save();

            return response()->json([
                'status' => 'success',
                'message' => 'Foto profil berhasil diupdate!',
                'photo' => $user->photo
            ]);
        }

        return response()->json([
            'status' => 'error',
            'message' => 'Tidak ada file yang diupload.'
        ], 400);
    }
}
