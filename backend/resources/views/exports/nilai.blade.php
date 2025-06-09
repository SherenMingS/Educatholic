<table>
    <thead>
        <tr>
            <th>Nama</th>
            <th>Kelas</th>
            <th>Total Nilai</th>
            <th>Rata-rata</th>
        </tr>
    </thead>
    <tbody>
        @forelse ($results as $user_id => $attempts)
            @php
                $first = $attempts->first();
                $user = $first?->user;

                $perQuiz = $attempts->groupBy('quiz_id'); // ✅ group berdasarkan quiz

                $total = 0;
                foreach ($perQuiz as $quizAttempts) {
                    $total += $quizAttempts->avg('score'); // ✅ rata-rata tiap kuis
                }

                $quizCount = $perQuiz->count();
                $avg = $quizCount > 0 ? round($total / $quizCount, 2) : 0;
            @endphp

            @if ($user)
                <tr>
                    <td>{{ $user->name }}</td>
                    <td>{{ $user->kelas }}</td>
                    <td>{{ round($total, 2) }}</td>
                    <td>{{ $avg }}</td>
                </tr>
            @endif
        @empty
            <tr>
                <td colspan="4" style="text-align: center">Tidak ada data</td>
            </tr>
        @endforelse
    </tbody>
</table>
