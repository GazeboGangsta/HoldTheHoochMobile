# Leaderboard Scene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Leaderboard scene accessible from the menu that shows the top 50 scores from `gurgles.beer/api/scores/top`, with proper loading / error / empty states and current-player highlighting.

**Architecture:** Pure-Flutter scene (not Flame) — leaderboard is static data rendering, no game loop required. `ApiClient.fetchTop()` already exists and is battle-tested. Pull the player's name from `LocalStore.getName()` so we can highlight their rows. Menu gets a secondary button that pushes the new scene via the existing `fadeRoute` helper.

**Tech Stack:** Flutter widgets (`ListView.separated`, `FutureBuilder`, `RefreshIndicator`), existing `ApiClient`, existing `LocalStore`, no new dependencies.

---

## File structure

| Path | Role | Action |
|------|------|--------|
| `lib/scenes/leaderboard_screen.dart` | Full Flutter scene, owns fetch + render + state | Create |
| `lib/widgets/leaderboard_entry_row.dart` | Stateless widget — one row with rank, name, score | Create |
| `lib/scenes/menu_screen.dart` | Add "Leaderboard" button below "Start" | Modify |
| `test/leaderboard_entry_row_test.dart` | Widget tests for the row — highlight, score formatting | Create |
| `test/leaderboard_utils_test.dart` | Unit tests for the score-formatting helper | Create |
| `lib/utils/format_score.dart` | Pure formatter `formatScore(int)` → `"1,234"` | Create |

## Scope check

Single subsystem (one scene + dependencies). No sub-project breakout needed.

## Decomposition notes

- **Fetch happens on mount, not on build.** Use a `Future<List<LeaderboardEntry>>` stored in state, created in `initState`, consumed by a `FutureBuilder`. This keeps the fetch from re-firing on every rebuild and gives us clean loading/error handling.
- **Highlighting.** Compare each entry's `name` to the current player's name from `LocalStore` (case-insensitive, trimmed). Highlighted rows get a brass-gold background tint.
- **Empty state.** `ApiClient.fetchTop` swallows errors and returns `[]` — we can't distinguish "server returned zero" from "network failed". Fix the API client to throw on failure so the scene can show a retry UI. Task 5 handles this.
- **Pull-to-refresh.** Cheap win: wrap the list in `RefreshIndicator` so the user can refresh without going back to menu.
- **Number formatting.** `1234567` → `"1,234,567"`. Use `NumberFormat` from `package:intl`? **No** — adds a dep. Write a 6-line formatter with `replaceAllMapped` using a regex. Pure function, testable.
- **"Back" navigation.** Standard `Scaffold.appBar` with back arrow. No custom route needed.

## Out of scope

- Player profiles / avatars.
- Time-filtered leaderboards (weekly / all-time).
- Pagination beyond top 50.
- Share-to-social buttons.

---

### Task 1: Score formatter helper

**Files:**
- Create: `lib/utils/format_score.dart`
- Test: `test/leaderboard_utils_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/leaderboard_utils_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/utils/format_score.dart';

void main() {
  group('formatScore', () {
    test('formats zero as "0"', () {
      expect(formatScore(0), '0');
    });

    test('formats sub-thousand values with no separators', () {
      expect(formatScore(7), '7');
      expect(formatScore(42), '42');
      expect(formatScore(999), '999');
    });

    test('inserts commas every three digits', () {
      expect(formatScore(1000), '1,000');
      expect(formatScore(12345), '12,345');
      expect(formatScore(1234567), '1,234,567');
    });

    test('handles negative values by preserving the sign', () {
      expect(formatScore(-1234), '-1,234');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/leaderboard_utils_test.dart`
Expected: FAIL — `format_score.dart` doesn't exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/utils/format_score.dart`:

```dart
/// Formats an integer score with comma thousands separators.
/// Examples: 0 -> "0", 1234 -> "1,234", -1234567 -> "-1,234,567".
String formatScore(int score) {
  final s = score.abs().toString();
  final withCommas = s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m.group(1)},',
  );
  return score < 0 ? '-$withCommas' : withCommas;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/leaderboard_utils_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/utils/format_score.dart test/leaderboard_utils_test.dart
git commit -m "Leaderboard task 1: formatScore helper"
```

---

### Task 2: LeaderboardEntryRow widget

**Files:**
- Create: `lib/widgets/leaderboard_entry_row.dart`
- Test: `test/leaderboard_entry_row_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/leaderboard_entry_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/services/api_client.dart';
import 'package:hold_the_hooch/widgets/leaderboard_entry_row.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LeaderboardEntryRow', () {
    testWidgets('shows rank, name and formatted score', (tester) async {
      await tester.pumpWidget(_wrap(LeaderboardEntryRow(
        rank: 1,
        entry: LeaderboardEntry(name: 'Gurgles', score: 12345),
        highlighted: false,
      )));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('Gurgles'), findsOneWidget);
      expect(find.text('12,345'), findsOneWidget);
    });

    testWidgets('highlighted rows have a non-null background decoration',
        (tester) async {
      await tester.pumpWidget(_wrap(LeaderboardEntryRow(
        rank: 3,
        entry: LeaderboardEntry(name: 'Me', score: 100),
        highlighted: true,
      )));

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('leaderboard-row-bg')),
      );
      expect(container.decoration, isNotNull);
    });

    testWidgets('non-highlighted rows have no background decoration',
        (tester) async {
      await tester.pumpWidget(_wrap(LeaderboardEntryRow(
        rank: 3,
        entry: LeaderboardEntry(name: 'Other', score: 100),
        highlighted: false,
      )));

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('leaderboard-row-bg')),
      );
      expect(container.decoration, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/leaderboard_entry_row_test.dart`
Expected: FAIL — `leaderboard_entry_row.dart` doesn't exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/widgets/leaderboard_entry_row.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/leaderboard_entry_row_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/leaderboard_entry_row.dart test/leaderboard_entry_row_test.dart
git commit -m "Leaderboard task 2: LeaderboardEntryRow widget"
```

---

### Task 3: Distinguish network errors from empty lists in ApiClient.fetchTop

**Files:**
- Modify: `lib/services/api_client.dart`

Currently `fetchTop` swallows all exceptions and returns `[]`, so the scene can't tell "server returned no scores yet" from "network failed". Replace with an exception so the scene can show a retry path.

- [ ] **Step 1: Change the signature to throw on failure**

In `lib/services/api_client.dart`, replace `fetchTop`:

```dart
  Future<List<LeaderboardEntry>> fetchTop({int limit = 50}) async {
    final res = await http.get(
      Uri.parse('${GameConfig.apiBaseUrl}/api/scores/top?limit=$limit'),
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Leaderboard request failed: HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['scores'] as List? ?? []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList();
  }
```

- [ ] **Step 2: Check for any callers that depend on the old swallow behavior**

Run: `grep -rn "fetchTop" lib/ test/`

Expected: only the leaderboard scene (not yet created) should call this. If any other caller exists that depends on `[]`-on-error, add a try/catch around the call site in that file. As of this plan there is no existing caller.

- [ ] **Step 3: Run the existing test suite — nothing should regress**

Run: `flutter analyze && flutter test`
Expected: 24 tests pass, no analyzer issues.

- [ ] **Step 4: Commit**

```bash
git add lib/services/api_client.dart
git commit -m "Leaderboard task 3: fetchTop throws on failure (was silently []→empty)"
```

---

### Task 4: LeaderboardScreen scene

**Files:**
- Create: `lib/scenes/leaderboard_screen.dart`

This is the main visible work. Built as a `StatefulWidget` with an initState fetch. The `FutureBuilder` renders three states: loading / error / success.

- [ ] **Step 1: Create the scene file**

Create `lib/scenes/leaderboard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';
import '../widgets/leaderboard_entry_row.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _api = ApiClient();
  final _store = LocalStore();
  late Future<List<LeaderboardEntry>> _future;
  String? _playerName;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchTop(limit: 50);
    _store.getName().then((n) {
      if (mounted) setState(() => _playerName = n?.trim().toLowerCase());
    });
  }

  Future<void> _refresh() async {
    final f = _api.fetchTop(limit: 50);
    setState(() => _future = f);
    await f;
  }

  bool _isPlayerRow(LeaderboardEntry e) {
    final pn = _playerName;
    if (pn == null || pn.isEmpty) return false;
    return e.name.trim().toLowerCase() == pn;
  }

  Widget _buildList(List<LeaderboardEntry> scores) {
    if (scores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No scores yet — be the first!',
            style: TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFFD4A744),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: scores.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (ctx, i) {
          final e = scores[i];
          return LeaderboardEntryRow(
            rank: i + 1,
            entry: e,
            highlighted: _isPlayerRow(e),
          );
        },
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Could not load leaderboard.',
              style: TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A744),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A1A),
        foregroundColor: const Color(0xFFD4A744),
        title: const Text('Leaderboard'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<LeaderboardEntry>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD4A744),
                ),
              );
            }
            if (snap.hasError) return _buildError(snap.error!);
            return _buildList(snap.data ?? const []);
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/scenes/leaderboard_screen.dart
git commit -m "Leaderboard task 4: LeaderboardScreen with loading/error/empty states"
```

---

### Task 5: Menu button that pushes LeaderboardScreen

**Files:**
- Modify: `lib/scenes/menu_screen.dart`

- [ ] **Step 1: Add imports + button**

In `lib/scenes/menu_screen.dart`, add import at the top:

```dart
import 'leaderboard_screen.dart';
```

Replace the existing `ElevatedButton` block (currently only the Start button) with:

```dart
              ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 64, vertical: 18),
                  backgroundColor: const Color(0xFFD4A744),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Start', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  fadeRoute(const LeaderboardScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 14),
                  side: const BorderSide(color: Color(0xFFD4A744)),
                  foregroundColor: const Color(0xFFD4A744),
                ),
                child: const Text('Leaderboard', style: TextStyle(fontSize: 18)),
              ),
```

- [ ] **Step 2: Run analyze + tests**

Run: `flutter analyze && flutter test`
Expected: no issues; tests still pass (the new scene is lightly tested — integration is covered by on-device verification in Task 7).

- [ ] **Step 3: Commit**

```bash
git add lib/scenes/menu_screen.dart
git commit -m "Leaderboard task 5: menu 'Leaderboard' button pushes the new scene"
```

---

### Task 6: Documentation sync

**Files:**
- Modify: `docs/STATUS.md`
- Modify: `docs/ROADMAP.md`

- [ ] **Step 1: Update ROADMAP.md**

In `docs/ROADMAP.md`, find under M5c:

```markdown
- [ ] **Leaderboard scene** — `GET /api/scores/top`, list top 50. Add Leaderboard button on menu.
```

Change to:

```markdown
- [x] **Leaderboard scene** — `GET /api/scores/top`, list top 50. Menu button pushes a new scene with loading / error / empty states and current-player highlighting.
```

- [ ] **Step 2: Update STATUS.md**

In `docs/STATUS.md` "What's playable today" section, at the end of the bullet list add:

```markdown
- **Leaderboard** — menu button → scrollable top-50 list from `gurgles.beer`, pull-to-refresh, current player rows highlighted.
```

Also add a new line to the Gotchas section:

```markdown
- **`ApiClient.fetchTop` now throws on failure** (used to silently return `[]`). Callers must catch or wrap in a `FutureBuilder` with error handling.
```

- [ ] **Step 3: Commit**

```bash
git add docs/STATUS.md docs/ROADMAP.md
git commit -m "Leaderboard task 6: docs sync"
```

---

### Task 7: On-device verification

- [ ] **Step 1: Build + install**

```bash
flutter build apk --debug
flutter install -d 192.168.4.25:38097 --debug
```

- [ ] **Step 2: Verify all three UI states on device**

1. **Loading:** relaunch the app, tap "Leaderboard" from the menu. A centered brass-colored spinner should appear briefly.
2. **Success:** after the spinner, the top-50 list should render. Each row shows rank, name, formatted score with commas. If the player's name ever submitted a score, at least one row should be visually highlighted (brass tint + border).
3. **Pull-to-refresh:** drag down on the list. The spinner should reappear briefly, the list should refresh.
4. **Empty state** (hard to trigger without resetting the server — acceptable to skip if the production leaderboard has entries). Informational only.
5. **Error state:** toggle airplane mode on the phone, relaunch the scene. The "Could not load leaderboard" message with a Retry button should appear. Turn airplane mode off and tap Retry — list should load.

- [ ] **Step 3: Final empty commit for the milestone**

```bash
git commit --allow-empty -m "Leaderboard verified on device (Samsung S26 Ultra)"
```

---

## Self-review checklist

- **Spec coverage:**
  - New scene pushed from menu → Task 4 + Task 5 ✓
  - Fetch top 50 from existing API → Task 4 (uses `ApiClient.fetchTop`) ✓
  - Loading / success / error / empty states → Task 4 (all four) ✓
  - Current player highlighting → Task 4 (`_isPlayerRow` + Task 2 `highlighted` prop) ✓
  - Score formatting with commas → Task 1 ✓
  - Pull-to-refresh → Task 4 (RefreshIndicator) ✓
  - Back navigation → Task 4 (default AppBar back arrow) ✓
  - Error-distinguishable-from-empty → Task 3 (fetchTop now throws) ✓
  - Docs sync → Task 6 ✓
  - Device verification → Task 7 ✓
- **Placeholder scan:** no TBD, no "add validation", no "similar to task N". All code blocks are complete and copy-pasteable.
- **Type consistency:** `LeaderboardEntry` import path consistent across all files. `formatScore(int)` signature matches in all three consumers. `_isPlayerRow` returns bool, matches `LeaderboardEntryRow.highlighted` type. `Future<List<LeaderboardEntry>>` return type matches between `ApiClient.fetchTop` and scene's `_future` field.
- **Dependencies:** Task 3 is load-bearing for Task 4's error state. Task 2 depends on Task 1. Task 4 depends on Tasks 1, 2, 3. Task 5 depends on Task 4. Task 6 can run in parallel with Task 5 if we wanted but sequence it after for clarity. Task 7 is verification — runs last.
