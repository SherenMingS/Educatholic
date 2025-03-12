<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuizResult extends Model
{
    use HasFactory;

    protected $table = 'quiz_results';

    protected $fillable = [
        'user_id',        // ✅ Tambahkan kolom ini
        'quiz_id',
        'score',
        'correct_answers',
        'total_questions'
    ];
}
