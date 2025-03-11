<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Materi extends Model
{
    use HasFactory;
    protected $table = 'materi'; // Pastikan ini sesuai dengan nama
    protected $fillable = [
        'judul',
        'deskripsi',
        'kelas',
        'poin_poin',
        'ayat',
        'isi_ayat',
        'file',
        'tanggal_tayang',
    ];
}

