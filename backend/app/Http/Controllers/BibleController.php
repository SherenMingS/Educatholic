<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BibleController extends Controller
{
    // API untuk list semua kitab
    public function getBooks()
    {
        $books = DB::table('books')->orderBy('book_id')->get();
        return response()->json([
            'status' => 'success',
            'data' => $books
        ]);
    }

    // API untuk ambil ayat berdasarkan book_id, chapter, dan verse
    public function getVerse(Request $request)
    {
        $bookId = $request->query('book_id');
        $chapter = $request->query('chapter');
        $verse = $request->query('verse');

        $verseData = DB::table('bible_verses')
                        ->where('book_id', $bookId)
                        ->where('chapter', $chapter)
                        ->where('verse', $verse)
                        ->first();

        if (!$verseData) {
            return response()->json([
                'status' => 'error',
                'message' => 'Ayat tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $verseData
        ]);
    }
}
