<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BibleVerse extends Model
{
    protected $fillable = ['book', 'chapter', 'verse', 'text'];
}
