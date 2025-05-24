<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuizResult extends Model
{
    use HasFactory;

    protected $table = 'quiz_results';

    protected $fillable = [
        'user_id',
        'quiz_id',
        'score',
        'correct_answers',
        'total_questions'
    ];

    // Relasi ke model Quiz
    public function quiz()
    {
        return $this->belongsTo(Quiz::class, 'quiz_id');  // Menghubungkan dengan tabel 'quiz' melalui 'quiz_id'
    }

public function user()
{
    return $this->belongsTo(\App\Models\User::class, 'user_id');
}

    
}
