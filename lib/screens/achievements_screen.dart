import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

enum _Filter { all, unlocked, locked }

enum _Sort { stars, date }

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late List<Achievement> _all;
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.stars;

  @override
  void initState() {
    super.initState();
    _load();
    DatabaseService.dataVersion.addListener(_load);
  }

  @override
  void dispose() {
    DatabaseService.dataVersion.removeListener(_load);
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    setState(() => _all = DatabaseService.getAllAchievements());
  }

  List<Achievement> get _filtered {
    List<Achievement> list;
    switch (_filter) {
      case _Filter.unlocked:
        list = _all.where((a) => a.unlocked).toList();
        break;
      case _Filter.locked:
        list = _all.where((a) => !a.unlocked).toList();
        break;
      case _Filter.all:
        list = List.from(_all);
    }

    switch (_sort) {
      case _Sort.stars:
        list.sort((a, b) {
          // Desbloqueadas sempre antes das bloqueadas
          if (a.unlocked && !b.unlocked) return -1;
          if (!a.unlocked && b.unlocked) return 1;
          // Dentro do mesmo grupo: mais estrelas primeiro
          return b.stars.compareTo(a.stars);
        });
        break;
      case _Sort.date:
        list.sort((a, b) {
          if (a.unlockedAt == null && b.unlockedAt == null) {
            return b.stars.compareTo(a.stars);
          }
          if (a.unlockedAt == null) return 1;
          if (b.unlockedAt == null) return -1;
          return b.unlockedAt!.compareTo(a.unlockedAt!);
        });
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final total = _all.length;
    final unlocked = _all.where((a) => a.unlocked).length;
    final pct = total == 0 ? 0.0 : unlocked / total;

    final starCounts = <int, int>{};
    for (final a in _all.where((a) => a.unlocked)) {
      starCounts[a.stars] = (starCounts[a.stars] ?? 0) + 1;
    }

    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Conquistas')),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.kCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$unlocked / $total Desbloqueadas',
                      style: TextStyle(
                        color: context.kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: context.kCardBorder,
                    color: AppColors.accent,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int s = 1; s <= 5; s++)
                      _StarCount(
                          stars: s, count: starCounts[s] ?? 0),
                  ],
                ),
              ],
            ),
          ),

          // ── Filtros ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Todas',
                          selected: _filter == _Filter.all,
                          onTap: () => setState(() => _filter = _Filter.all),
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: '✓ Desbloqueadas',
                          selected: _filter == _Filter.unlocked,
                          onTap: () =>
                              setState(() => _filter = _Filter.unlocked),
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: '🔒 Bloqueadas',
                          selected: _filter == _Filter.locked,
                          onTap: () =>
                              setState(() => _filter = _Filter.locked),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _sort = _sort == _Sort.stars ? _Sort.date : _Sort.stars;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.kCardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _sort == _Sort.stars
                              ? Icons.star_outlined
                              : Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _sort == _Sort.stars ? 'Estrelas' : 'Data',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista ──────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('Nenhuma conquista aqui.',
                        style: TextStyle(color: context.kTextSecondary)),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      return _AchievementCard(
                          achievement: filtered[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StarCount extends StatelessWidget {
  final int stars;
  final int count;
  const _StarCount({required this.stars, required this.count});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            '⭐' * stars,
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: count > 0
                  ? context.kTextPrimary
                  : context.kTextSecondary,
              fontWeight:
                  count > 0 ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
            ),
          ),
        ],
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.18)
                : context.kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.accent : context.kCardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? AppColors.accent : context.kTextSecondary,
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final isLocked = !a.unlocked;
    final isHighStarLocked = isLocked && a.stars >= 4;
    final stars = '⭐' * a.stars;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: a.unlocked
              ? AppColors.accent.withValues(alpha: 0.4)
              : context.kCardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone / emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: a.unlocked
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : context.kCardBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                a.unlocked ? '🏆' : '🔒',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isHighStarLocked ? '???' : a.title,
                        style: TextStyle(
                          color: a.unlocked
                              ? context.kTextPrimary
                              : context.kTextSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(stars,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isHighStarLocked
                      ? 'Desbloqueie para revelar'
                      : a.description,
                  style: TextStyle(
                    color: context.kTextSecondary,
                    fontSize: 12,
                  ),
                ),
                if (a.unlocked && a.unlockedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '🗓 ${_formatDate(a.unlockedAt!)}',
                    style: const TextStyle(
                      color: AppColors.income,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (isLocked &&
                    !isHighStarLocked &&
                    a.goal != null &&
                    a.progress != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (a.progress! / a.goal!)
                                .clamp(0.0, 1.0),
                            backgroundColor:
                                context.kCardBorder,
                            color: AppColors.accent,
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${a.progress} / ${a.goal}',
                        style: TextStyle(
                          color: context.kTextSecondary,
                          fontSize: 11,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }
}
