<?php

    namespace App\Exports;
    use App\Models\User;
    use App\Models\QuizResult;
    use Illuminate\Contracts\View\View;
    use Maatwebsite\Excel\Concerns\FromView;

    class NilaiExport implements FromView
    {
        protected $kelas;
        protected $semester;

        public function __construct($kelas, $semester)
        {
            $this->kelas = $kelas;
            $this->semester = $semester;
        }

        public function view(): View
    {
        $results = QuizResult::with(['user', 'quiz'])
            ->whereHas('user', fn ($q) => $q->where('kelas', $this->kelas))
            ->whereHas('quiz', fn ($q) => $q->where('semester', $this->semester))
            ->get()
            ->filter(fn ($r) => $r->user && $r->quiz) // ✅ penting ini
            ->groupBy('user_id');

        return view('exports.nilai', [
            'results' => $results,
        ]);
    }

    }
