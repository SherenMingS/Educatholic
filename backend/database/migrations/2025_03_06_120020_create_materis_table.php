<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up()
{
    Schema::create('materi', function (Blueprint $table) {
        $table->id();
        $table->string('judul');
        $table->text('deskripsi')->nullable();
        $table->string('kelas');
        $table->string('file')->nullable();
        $table->date('tanggal_tayang');
        $table->timestamps();
    });
}

public function down()
{
    Schema::dropIfExists('materi'); // Pastikan ini juga "materi", bukan "materis"
}
};