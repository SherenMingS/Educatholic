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
                $total = $attempts->sum('score');
                $avg = $attempts->avg('score');
            @endphp
            @if ($user)
                <tr>
                    <td>{{ $user->name }}</td>
                    <td>{{ $user->kelas }}</td>
                    <td>{{ round($total, 2) }}</td>
                    <td>{{ round($avg, 2) }}</td>
                </tr>
            @endif
        @empty
            <tr>
                <td colspan="4" style="text-align:center">Tidak ada data</td>
            </tr>
        @endforelse
    </tbody>
</table>
