import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// The live edge of the day. At rest it is one quiet row; once a timer runs it
/// becomes the loudest thing on the screen, because that is the state worth
/// noticing.
class NowBar extends StatefulWidget {
  const NowBar({
    required this.running,
    required this.runningCategory,
    required this.busy,
    required this.onStart,
    required this.onStop,
    required this.onOpenRunning,
    required this.onPickCategory,
    required this.onLogRecent,
    required this.pendingCategory,
    super.key,
  });

  final TimeEntry? running;
  final Category? runningCategory;
  final bool busy;
  final Future<void> Function(String description) onStart;
  final Future<void> Function() onStop;
  final VoidCallback onOpenRunning;

  /// Composes a block for the time since whatever was logged last. Tapping the
  /// grid does the same thing faster, but this is the path a screen reader or
  /// a one-handed thumb can always find.
  final VoidCallback onLogRecent;

  /// Opens the category picker for the timer about to be started.
  final Future<void> Function() onPickCategory;
  final Category? pendingCategory;

  @override
  State<NowBar> createState() => _NowBarState();
}

class _NowBarState extends State<NowBar> {
  final TextEditingController _description = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _expanded = false;

  @override
  void dispose() {
    _description.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NowBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running != null && oldWidget.running == null) {
      _description.clear();
      setState(() => _expanded = false);
    }
  }

  void _expand() {
    setState(() => _expanded = true);
    _focus.requestFocus();
  }

  Future<void> _start() async {
    _focus.unfocus();
    // Fire and forget: the confirmation should be felt as the work starts,
    // not gate it behind a platform round trip.
    unawaited(HapticFeedback.mediumImpact());
    await widget.onStart(_description.text);
  }

  Future<void> _stop() async {
    unawaited(HapticFeedback.mediumImpact());
    await widget.onStop();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.running;
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : LuqaMotion.state,
      curve: LuqaMotion.curve,
      alignment: Alignment.topCenter,
      child: running != null
          ? _RunningBar(
              entry: running,
              category: widget.runningCategory,
              busy: widget.busy,
              onStop: _stop,
              onOpen: widget.onOpenRunning,
            )
          : _expanded
          ? _StartComposer(
              controller: _description,
              focus: _focus,
              busy: widget.busy,
              category: widget.pendingCategory,
              onPickCategory: widget.onPickCategory,
              onStart: _start,
              onCollapse: () {
                _focus.unfocus();
                setState(() => _expanded = false);
              },
            )
          : _IdleBar(onTap: _expand, onLogRecent: widget.onLogRecent),
    );
  }
}

class _IdleBar extends StatelessWidget {
  const _IdleBar({required this.onTap, required this.onLogRecent});

  final VoidCallback onTap;
  final VoidCallback onLogRecent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Start a timer',
            child: Material(
              color: palette.raised,
              borderRadius: BorderRadius.circular(LuqaRadii.control),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      const SizedBox(width: LuqaSpacing.lg),
                      Expanded(
                        child: Text(
                          'Start a timer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: LuqaSpacing.sm),
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: LuqaSpacing.sm),
        SizedBox.square(
          dimension: 52,
          child: IconButton.outlined(
            key: const ValueKey('log-recent-button'),
            tooltip: 'Log time already spent',
            onPressed: onLogRecent,
            icon: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _StartComposer extends StatelessWidget {
  const _StartComposer({
    required this.controller,
    required this.focus,
    required this.busy,
    required this.category,
    required this.onPickCategory,
    required this.onStart,
    required this.onCollapse,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool busy;
  final Category? category;
  final Future<void> Function() onPickCategory;
  final Future<void> Function() onStart;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('timer-description'),
            controller: controller,
            focusNode: focus,
            maxLength: 500,
            textInputAction: TextInputAction.go,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What are you starting?',
              counterText: '',
              isDense: true,
              prefixIcon: IconButton(
                tooltip: category == null
                    ? 'Choose category'
                    : 'Category ${category!.name}',
                onPressed: onPickCategory,
                icon: category == null
                    ? Icon(
                        Icons.label_outline_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(category!.colorValue),
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 14),
                      ),
              ),
              suffixIcon: IconButton(
                tooltip: 'Cancel',
                onPressed: onCollapse,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            onSubmitted: (_) => onStart(),
          ),
        ),
        const SizedBox(width: LuqaSpacing.sm),
        SizedBox.square(
          dimension: 48,
          child: IconButton.filled(
            key: const ValueKey('start-timer-button'),
            tooltip: 'Start timer',
            onPressed: busy ? null : onStart,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ),
      ],
    );
  }
}

class _RunningBar extends StatelessWidget {
  const _RunningBar({
    required this.entry,
    required this.category,
    required this.busy,
    required this.onStop,
    required this.onOpen,
  });

  final TimeEntry entry;
  final Category? category;
  final bool busy;
  final Future<void> Function() onStop;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final label = entry.description.trim().isEmpty
        ? 'Untitled'
        : entry.description.trim();

    return Material(
      color: accent.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.16 : 0.09,
      ),
      borderRadius: BorderRadius.circular(LuqaRadii.control),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // The elapsed time leads the second line: it is the
                        // number the owner glances at, and it keeps the title
                        // above it full width.
                        _Stopwatch(since: entry.start, color: accent),
                        if (category != null) ...[
                          Text(
                            '  ·  ',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(category!.colorValue),
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(dimension: 7),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              category!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LuqaSpacing.sm),
              FilledButton(
                key: const ValueKey('stop-timer-button'),
                onPressed: busy ? null : onStop,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Stop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Counts up once a second. Kept in its own widget so the rest of the screen
/// is not rebuilt sixty times a minute.
class _Stopwatch extends StatefulWidget {
  const _Stopwatch({required this.since, required this.color});

  final DateTime since;
  final Color color;

  @override
  State<_Stopwatch> createState() => _StopwatchState();
}

class _StopwatchState extends State<_Stopwatch> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.since);
    return Text(
      stopwatch(elapsed),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontSize: 18,
        color: widget.color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
