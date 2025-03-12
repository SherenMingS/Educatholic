<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Badge extends Model
{
    use HasFactory;

    protected $table = 'badges'; // Nama tabel di database
    protected $fillable = ['user_id', 'jumlah', 'badge_level']; // Pastikan atribut ini bisa diisi massal
}
