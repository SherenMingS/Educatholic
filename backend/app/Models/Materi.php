<?php
// app/Models/Materi.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Materi extends Model
{
    use HasFactory;

    protected $table = 'materi'; // Pastikan ini sesuai dengan nama tabel
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

    // Relasi dengan MateriRead
    public function materiReads()
    {
        return $this->hasMany(MateriRead::class, 'materi_id');
    }
}
