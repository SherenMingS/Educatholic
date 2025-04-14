<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AttendanceSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'kelas',
        'code',
        'tanggal',
        'jam_mulai',
        'jam_selesai',
    ];
}
