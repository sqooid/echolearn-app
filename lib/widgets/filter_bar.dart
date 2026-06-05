import 'package:flutter/material.dart';
import '../models/filter_state.dart';
import '../utils/theme.dart';
import 'icons.dart';

class SegmentedOption {
  final String id;
  final String label;
  const SegmentedOption(this.id, this.label);
}

class SortOptionDef {
  final String id;
  final String label;
  final Widget Function({double size, Color? color}) icon;
  const SortOptionDef(this.id, this.label, this.icon);
}

class SegmentedControl extends StatelessWidget {
  final List<SegmentedOption> options;
  final String value;
  final ValueChanged<String> onChange;

  const SegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        children: options.map((o) {
          final active = value == o.id;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(o.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: const Cubic(0.32, 0.72, 0, 1),
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? theme.colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: active ? theme.colors.borderStrong : Colors.transparent),
                  boxShadow: active ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1))] : null,
                ),
                child: Text(o.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: active ? theme.colors.ink : theme.colors.inkSoft)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SortRow extends StatelessWidget {
  final SortOptionDef opt;
  final bool active;
  final VoidCallback onTap;

  const SortRow({super.key, required this.opt, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: const Cubic(0.32, 0.72, 0, 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? theme.colors.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? theme.colors.borderStrong : Colors.transparent),
        ),
        child: Row(
          children: [
            opt.icon(size: 17, color: active ? theme.colors.ink : theme.colors.inkFaint),
            const SizedBox(width: 11),
            Text(opt.label, style: TextStyle(fontSize: 14.5, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: theme.colors.ink)),
            if (active) ...[const Spacer(), IconCheck(size: 18, sw: 2.4, color: theme.accent)],
          ],
        ),
      ),
    );
  }
}

class Toggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChange;

  const Toggle({super.key, required this.on, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return GestureDetector(
      onTap: () => onChange(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: const Cubic(0.32, 0.72, 0, 1),
        width: 46, height: 28, padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: on ? theme.accent : theme.colors.surface3,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? Colors.transparent : theme.colors.borderStrong),
        ),
        child: Align(
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: on ? theme.onAccent : theme.colors.surface,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

class FilterLabel extends StatelessWidget {
  final String text;
  const FilterLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Text(text, style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, letterSpacing: 1.05, color: theme.colors.inkFaint));
  }
}

class FilterBar extends StatefulWidget {
  final FilterState state;
  final ValueChanged<FilterState> onChange;
  final int count;
  final bool open;
  final ValueChanged<bool> setOpen;

  const FilterBar({
    super.key,
    required this.state,
    required this.onChange,
    required this.count,
    required this.open,
    required this.setOpen,
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  static const _sortOptions = [
    SortOptionDef('newest', 'Newest first', IconArrowDown.new),
    SortOptionDef('oldest', 'Oldest first', IconArrowUp.new),
    SortOptionDef('az', 'A → Z (English)', IconArrowDown.new),
    SortOptionDef('za', 'Z → A (English)', IconArrowUp.new),
    SortOptionDef('shuffle', 'Random order', IconShuffle.new),
  ];

  static const _filterOptions = [
    SegmentedOption('active', 'Active'),
    SegmentedOption('all', 'All'),
    SegmentedOption('archived', 'Archived'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnimation = CurvedAnimation(parent: _animController, curve: const Cubic(0.32, 0.72, 0, 1), reverseCurve: const Cubic(0.32, 0.72, 0, 1));
    _searchController.text = widget.state.query;
    if (widget.open) _animController.value = 1.0;
  }

  @override
  void didUpdateWidget(FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      widget.open ? _animController.forward() : _animController.reverse();
    }
    if (widget.state.query != _searchController.text) {
      _searchController.text = widget.state.query;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _panel(LingoTheme theme, SortOptionDef cur, SegmentedOption filt) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: const Cubic(0.32, 0.72, 0, 1),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colors.border),
        boxShadow: widget.open
            ? const [BoxShadow(color: Color(0x40000000), blurRadius: 48, offset: Offset(0, 16)), BoxShadow(color: Color(0x20000000), blurRadius: 12, offset: Offset(0, 4))]
            : const [BoxShadow(color: Color(0x2A000000), blurRadius: 24, offset: Offset(0, 6)), BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              count: widget.count, curLabel: cur.label, reshuffle: widget.state.reshuffle,
              filtLabel: filt.label, open: widget.open, onTap: () => widget.setOpen(!widget.open),
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: _ExpandedContent(
                state: widget.state, onChange: widget.onChange,
                controller: _searchController, focusNode: _focusNode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    final cur = _sortOptions.firstWhere((s) => s.id == widget.state.sort);
    final filt = _filterOptions.firstWhere((f) => f.id == widget.state.filter);

    if (widget.open) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.setOpen(false),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: 12 + MediaQuery.of(context).padding.top,
            left: 16, right: 16,
            child: _panel(theme, cur, filt),
          ),
        ],
      );
    }

    return Positioned(
      top: 12 + MediaQuery.of(context).padding.top,
      left: 16, right: 16,
      child: _panel(theme, cur, filt),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final String curLabel;
  final bool reshuffle;
  final String filtLabel;
  final bool open;
  final VoidCallback onTap;

  const _Header({required this.count, required this.curLabel, required this.reshuffle, required this.filtLabel, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            IconSliders(size: 20, color: theme.colors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count ${count == 1 ? 'card' : 'cards'}', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: theme.colors.ink)),
                  const SizedBox(height: 1),
                  Text('$curLabel${reshuffle ? ' · loops' : ''} · $filtLabel', style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: theme.colors.inkSoft), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            AnimatedRotation(turns: open ? 0.5 : 0, duration: const Duration(milliseconds: 250), curve: const Cubic(0.32, 0.72, 0, 1), child: IconChevron(size: 20, color: theme.colors.inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  final FilterState state;
  final ValueChanged<FilterState> onChange;
  final TextEditingController controller;
  final FocusNode focusNode;

  const _ExpandedContent({required this.state, required this.onChange, required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchField(query: state.query, controller: controller, focusNode: focusNode, onChange: (q) => onChange(state.copyWith(query: q))),
          const SizedBox(height: 16),
          const FilterLabel(text: 'Filter'),
          const SizedBox(height: 9),
          SegmentedControl(options: _FilterBarState._filterOptions, value: state.filter, onChange: (v) => onChange(state.copyWith(filter: v))),
          const SizedBox(height: 16),
          const FilterLabel(text: 'Sort by'),
          const SizedBox(height: 9),
          ..._FilterBarState._sortOptions.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: SortRow(opt: o, active: state.sort == o.id, onTap: () => onChange(state.copyWith(sort: o.id))),
          )),
          const SizedBox(height: 14),
          _ReshuffleRow(reshuffle: state.reshuffle, onChange: (v) => onChange(state.copyWith(reshuffle: v))),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final String query;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChange;

  const _SearchField({required this.query, required this.controller, required this.focusNode, required this.onChange});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(color: theme.colors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colors.border)),
      child: Row(
        children: [
          IconSearch(size: 18, color: theme.colors.inkFaint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller, focusNode: widget.focusNode, onChanged: widget.onChange,
              style: TextStyle(fontSize: 14.5, color: theme.colors.ink),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Search cards…', hintStyle: TextStyle(color: Color(0xFF9B9BA1))),
            ),
          ),
          if (widget.query.isNotEmpty) GestureDetector(onTap: () => widget.onChange(''), child: IconClose(size: 16, color: theme.colors.inkFaint)),
        ],
      ),
    );
  }
}

class _ReshuffleRow extends StatelessWidget {
  final bool reshuffle;
  final ValueChanged<bool> onChange;

  const _ReshuffleRow({required this.reshuffle, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.colors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colors.border)),
      child: Row(
        children: [
          IconShuffle(size: 19, color: theme.colors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reshuffle at end', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colors.ink)),
                const SizedBox(height: 2),
                Text('Re-order the list when playback reaches the bottom', style: TextStyle(fontSize: 12, height: 1.35, color: theme.colors.inkSoft)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Toggle(on: reshuffle, onChange: onChange),
        ],
      ),
    );
  }
}
