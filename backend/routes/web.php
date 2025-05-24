<?php
use Illuminate\Http\Request; // ✅ Bukan Facade
use App\Exports\NilaiExport;
use Maatwebsite\Excel\Facades\Excel;

Route::get('/export-nilai', function (Request $request) {
    try {
        $kelas = $request->get('kelas');
        $semester = $request->get('semester');

        return Excel::download(
            new \App\Exports\NilaiExport($kelas, $semester),
            "nilai_{$kelas}_semester_{$semester}.xlsx"
        );
    } catch (\Throwable $e) {
        return response()->json([
            'message' => 'Export error',
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ], 500);
    }
});



Route::get('/', function () {
    return view('welcome');
});


Route::get('/reset-password/{token}', function ($token) {
    return response()->json([
        'message' => 'Halaman reset password dummy',
        'token' => $token
    ]);
})->name('password.reset');
