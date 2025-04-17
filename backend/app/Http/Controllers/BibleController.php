<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\BibleVerse;
use App\Http\Controllers\Controller; // ✅ Tambahkan baris ini

class BibleController extends Controller
{
    public function books()
    {
        return response()->json(
            BibleVerse::select('book')->distinct()->orderBy('book')->pluck('book')
        );
    }

    public function chapters(Request $request)
    {
        $request->validate(['book' => 'required']);
        return response()->json(
            BibleVerse::where('book', $request->book)
                ->select('chapter')->distinct()->orderBy('chapter')->pluck('chapter')
        );
    }

    public function verses(Request $request)
    {
        $request->validate(['book' => 'required', 'chapter' => 'required']);
        return response()->json(
            BibleVerse::where('book', $request->book)
                ->where('chapter', $request->chapter)
                ->select('verse')->orderBy('verse')->pluck('verse')
        );
    }

    public function lookup(Request $request)
    {
        $request->validate([
            'book' => 'required',
            'chapter' => 'required',
            'verse' => 'required',
        ]);

        $verse = BibleVerse::where('book', $request->book)
            ->where('chapter', $request->chapter)
            ->where('verse', $request->verse)
            ->first();

        if (!$verse) {
            return response()->json(['message' => 'Ayat tidak ditemukan'], 404);
        }

        return response()->json([
            'ayat' => "{$verse->book} {$verse->chapter}:{$verse->verse}",
            'isi_ayat' => $verse->text
        ]);
    }
}
