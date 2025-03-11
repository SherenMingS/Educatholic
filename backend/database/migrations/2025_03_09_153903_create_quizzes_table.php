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
    Schema::create('quizzes', function (Blueprint $table) {
        $table->id();
        $table->string('title'); // Judul kuis
        $table->string('kelas'); // Kelas mana yang bisa ikut
        $table->foreignId('created_by')->constrained('users')->onDelete('cascade'); // Guru pembuat kuis
        $table->integer('duration')->nullable(); // Waktu dalam menit (opsional)
        $table->dateTime('deadline')->nullable(); // Batas waktu pengerjaan kuis
        $table->string('quiz_code')->unique(); // Kode unik untuk akses kuis
        $table->timestamps();
    });
}


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('quizzes');
    }
};
