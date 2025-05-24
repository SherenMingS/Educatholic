<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Exports\NilaiExport;
use Maatwebsite\Excel\Facades\Excel;

class ExportController extends Controller
{
    public function exportByKelasSemester(Request $request)
    {
        $kelas = $request->query('kelas');
        $semester = $request->query('semester');

        $filename = "Nilai_Kelas_{$kelas}_Semester_{$semester}.xlsx";
        return Excel::download(new NilaiExport($kelas, $semester), $filename);
    }
}
