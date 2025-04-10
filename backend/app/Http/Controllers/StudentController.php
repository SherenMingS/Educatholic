<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;

class StudentController extends Controller
{
    public function getProfile(Request $request)
    {
        $siswa = $request->user(); // siswa yang login

        return response()->json([
            'id' => $siswa->id,
            'nama' => $siswa->name,
            'email' => $siswa->email,
            'kelas' => $siswa->kelas,
        ]);
    }
}
