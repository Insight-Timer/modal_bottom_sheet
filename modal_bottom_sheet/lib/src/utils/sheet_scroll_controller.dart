import 'package:flutter/widgets.dart';

/// Receives the drags a [SheetScrollController] hands to its sheet.
abstract class SheetDragTarget {
  bool get canDragSheet;

  /// True while the sheet sits below its fully open position.
  bool get isSheetDisplaced;

  bool get isDraggingSheet;

  void dragSheet(double delta);

  void releaseSheet(double velocity);
}

/// Moves the sheet before the content scrolls: a drag down at the top pulls
/// the sheet down, and a drag up while it is pulled down lifts it back first.
class SheetScrollController extends ScrollController {
  SheetDragTarget? sheet;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SheetScrollPosition(
      controller: this,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _SheetScrollPosition extends ScrollPositionWithSingleContext {
  _SheetScrollPosition({
    required this.controller,
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  final SheetScrollController controller;

  SheetDragTarget? get _sheet {
    final sheet = controller.sheet;
    if (sheet == null || !sheet.canDragSheet) return null;
    if (axisDirection != AxisDirection.down) return null;
    return sheet;
  }

  @override
  void applyUserOffset(double delta) {
    final sheet = _sheet;
    final pullsDownAtTop = delta > 0 && pixels <= minScrollExtent;
    final liftsDisplacedSheet = delta < 0 && (sheet?.isSheetDisplaced ?? false);
    if (sheet != null && (pullsDownAtTop || liftsDisplacedSheet)) {
      sheet.dragSheet(delta);
      return;
    }
    super.applyUserOffset(delta);
  }

  @override
  void goBallistic(double velocity) {
    final sheet = _sheet;
    if (sheet != null && sheet.isDraggingSheet) {
      // Scroll velocity is positive towards the end; the sheet's is positive downwards.
      sheet.releaseSheet(-velocity);
      super.goBallistic(0);
      return;
    }
    super.goBallistic(velocity);
  }
}
