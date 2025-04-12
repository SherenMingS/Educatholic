<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;

class UserController extends Controller
{
    public function getUserProfile(Request $request)
    {
        return response()->json([
            'id' => auth()->user()->id,
            'name' => auth()->user()->name,
            'email' => auth()->user()->email,
            'kelas' => auth()->user()->kelas, // Kirim kelas user yang login
            'role' => auth()->user()->role,
            'photo' => auth()->user()->photo,
        ]);
    }



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

        return response()->json(['message' => 'Foto profil berhasil diupdate!', 'photo' => $user->photo]);
    }

    return response()->json(['message' => 'Tidak ada file yang diupload.'], 400);
}

}
