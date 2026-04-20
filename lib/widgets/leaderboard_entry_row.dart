import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/format_score.dart';

class LeaderboardEntryRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool highlighted;

  const LeaderboardEntryRow({
    super.key,
    required this.rank,
    required this.entry,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('leaderboard-row-bg'),
      decoration: highlighted
          ? BoxDecoration(
              color: const Color(0x33D4A744),
              border: Border.all(color: const Color(0xFFD4A744)),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Color(0xFFD4A744),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.name,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatScore(entry.score),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
