<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TeacherController extends Controller
{
    public function profile(Request $request)
    {
        $user = Auth::user();

        return response()->json([
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'photo' => $user->photo,
        ]);
    }

    public function updatePhoto(Request $request)
{
    $user = auth()->user();

    $request->validate([
        'photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
    ]);

    if ($request->hasFile('photo')) {
        $file = $request->file('photo');
        $filename = time() . '.' . $file->getClientOriginalExtension();

        // Simpan file ke public/uploads/profile
        $file->move(public_path('uploads/profile'), $filename);

        // Update path foto ke database
        $user->photo = 'uploads/profile/' . $filename;
        $user->save();

        return response()->json([
            'message' => 'Foto profil berhasil diupdate!',
            'photo' => $user->photo
        ]);
    }

    return response()->json([
        'message' => 'Tidak ada file yang diupload.'
    ], 400);
}


}
