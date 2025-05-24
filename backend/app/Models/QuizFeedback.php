<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuizFeedback extends Model
{
    use HasFactory;

    protected $table = 'quiz_feedback';

    protected $fillable = [
        'quiz_id',
        'user_id',
        'rating',
        'comment',
    ];

    public function quiz()
    {
        return $this->belongsTo(Quiz::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
