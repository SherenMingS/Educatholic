<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'password_confirmation',
        'remember_token',
        'role',
        'kelas', // Tambahkan ini supaya bisa disimpan
        'photo',
        'reset_otp',               // 👈 ini
        'reset_otp_expires_at', 
        'gender', 
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed', // Auto hash password
    ];



    ///
    public function quizResults()
{
    return $this->hasMany(QuizResult::class, 'user_id');
}

}

