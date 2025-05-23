<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Quiz extends Model
{
    use HasFactory;

    protected $fillable = [
    'title',
    'kelas',
    'materi_id',
    'created_by',
    'duration',
    'deadline',
    'quiz_code',
    'kkm',              // ✅ tambahkan
    'max_attempts'      // ✅ tambahkan
];


    public function questions()
    {
        return $this->hasMany(QuizQuestion::class, 'quiz_id', 'id');
    }
    public function materi()
{
    return $this->belongsTo(Materi::class, 'materi_id');
}
}

