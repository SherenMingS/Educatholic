<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::table('materi', function (Blueprint $table) {
            $table->text('poin_poin')->nullable()->after('kelas');
            $table->string('ayat')->nullable()->after('poin_poin');
            $table->text('isi_ayat')->nullable()->after('ayat');
        });
    }

    public function down()
    {
        Schema::table('materi', function (Blueprint $table) {
            $table->dropColumn(['poin_poin', 'ayat', 'isi_ayat']);
        });
    }
};
