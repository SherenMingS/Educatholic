<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;

class UserController extends Controller
{
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
}
