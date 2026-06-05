import 'package:flutter/material.dart';

class VirtualList extends StatefulWidget {
  final List<dynamic> items;
  final String Function(dynamic) getKey;
  final Widget Function(dynamic item, int index) renderItem;
  final double estimate;
  final double gap;
  final int overscan;
  final double padTop;
  final double padBottom;
  final ScrollController? scrollController;

  const VirtualList({
    super.key,
    required this.items,
    required this.getKey,
    required this.renderItem,
    this.estimate = 132,
    this.gap = 12,
    this.overscan = 6,
    this.padTop = 0,
    this.padBottom = 0,
    this.scrollController,
  });

  @override
  VirtualListState createState() => VirtualListState();
}

class VirtualListState extends State<VirtualList> {
  final Map<String, double> _heights = {};
  late ScrollController _scrollController;
  double _viewport = 0;
  double _scrollTop = 0;

  final List<double> _offsets = [];
  double _totalHeight = 0;
  int _start = 0;
  int _end = 0;

  ScrollController? _outerScrollController;

  void _recompute() {
    _offsets.clear();
    double acc = widget.padTop;
    for (int i = 0; i < widget.items.length; i++) {
      _offsets.add(acc);
      final h = _heights[widget.getKey(widget.items[i])] ?? widget.estimate;
      acc += h + widget.gap;
    }
    _totalHeight = acc - (widget.items.isNotEmpty ? widget.gap : 0) + widget.padBottom;
  }

  void _computeRange() {
    int start = 0;
    while (start < widget.items.length &&
        _offsets[start] + (_heights[widget.getKey(widget.items[start])] ?? widget.estimate) < _scrollTop) {
      start++;
    }
    start = (start - widget.overscan).clamp(0, widget.items.length);
    int end = start;
    final limit = _scrollTop + _viewport;
    while (end < widget.items.length && _offsets[end] < limit) {
      end++;
    }
    end = (end + widget.overscan).clamp(0, widget.items.length);
    _start = start;
    _end = end;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _outerScrollController = widget.scrollController;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewport = context.size?.height ?? 600;
      _recompute();
      _computeRange();
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(VirtualList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != _outerScrollController) {
      _scrollController.removeListener(_onScroll);
      _scrollController = widget.scrollController ?? ScrollController();
      _outerScrollController = widget.scrollController;
      _scrollController.addListener(_onScroll);
    }
    _recompute();
    _computeRange();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    final st = _scrollController.position.pixels;
    if ((st - _scrollTop).abs() > 1) {
      _scrollTop = st;
      _computeRange();
      setState(() {});
    }
  }

  void scrollToIndex(int index, {String align = 'start', bool smooth = true, double margin = 16}) {
    if (index < 0 || index >= widget.items.length) return;
    double top = _offsets[index] - margin;
    if (align == 'center') {
      final h = _heights[widget.getKey(widget.items[index])] ?? widget.estimate;
      top = _offsets[index] - (_viewport - h) / 2;
    }
    _scrollController.animateTo(
      top.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: smooth ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    _recompute();
    _computeRange();

    final visibleItems = <Widget>[];
    for (int i = _start; i < _end && i < widget.items.length; i++) {
      final item = widget.items[i];
      final key = widget.getKey(item);
      visibleItems.add(
        Positioned(
          top: _offsets[i],
          left: 0,
          right: 0,
          child: _MeasuredItem(
            mkey: key,
            heights: _heights,
            onResize: () {
              if (mounted) setState(() {});
            },
            child: widget.renderItem(item, i),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SizedBox(
          height: _totalHeight,
          child: Stack(
            children: visibleItems,
          ),
        ),
      ),
    );
  }
}

class _MeasuredItem extends StatefulWidget {
  final String mkey;
  final Map<String, double> heights;
  final VoidCallback onResize;
  final Widget child;

  const _MeasuredItem({
    required this.mkey,
    required this.heights,
    required this.onResize,
    required this.child,
  });

  @override
  State<_MeasuredItem> createState() => _MeasuredItemState();
}

class _MeasuredItemState extends State<_MeasuredItem> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final h = renderBox.size.height;
      if (widget.heights[widget.mkey] != h) {
        widget.heights[widget.mkey] = h;
        widget.onResize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
