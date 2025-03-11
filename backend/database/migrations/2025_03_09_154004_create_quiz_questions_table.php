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
    Schema::create('quiz_questions', function (Blueprint $table) {
        $table->id();
        $table->foreignId('quiz_id')->constrained('quizzes')->onDelete('cascade');
        $table->text('question'); // Pertanyaan
        $table->string('option_1');
        $table->string('option_2');
        $table->string('option_3');
        $table->string('option_4');
        $table->enum('correct_answer', ['A', 'B', 'C', 'D']); // Jawaban benar
        $table->decimal('score', 5, 2)->default(1.0); // Skor per soal
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('quiz_questions');
    }
};
