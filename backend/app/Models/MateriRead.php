<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MateriRead extends Model
{
    protected $fillable = ['user_id', 'materi_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function materi()
    {
        return $this->belongsTo(Materi::class);
    }

    public function getReadMateri()
{
    $userId = auth()->id();
    $readIds = \App\Models\MateriRead::where('user_id', $userId)->pluck('materi_id');

    return response()->json([
        'status' => 'success',
        'materi_ids' => $readIds,
    ]);
}

}
