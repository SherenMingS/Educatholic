<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuizAnswer extends Model
{
    use HasFactory;

    protected $table = 'quiz_answers';

    protected $fillable = [
        'user_id',
        'quiz_id',
        'question_id',
        'selected_answer',
        'is_correct',
    ];

    // Relasi ke soal (QuizQuestion)
    public function question()
    {
        return $this->belongsTo(QuizQuestion::class, 'question_id');
    }

    // Relasi ke quiz (opsional, jika kamu butuh)
    public function quiz()
    {
        return $this->belongsTo(Quiz::class, 'quiz_id');
    }

    // Relasi ke user (opsional)
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
