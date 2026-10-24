import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../res/colors/app_color.dart';

double _w(num val) {
  try {
    return val.w;
  } catch (_) {
    return val.toDouble();
  }
}

double _h(num val) {
  try {
    return val.h;
  } catch (_) {
    return val.toDouble();
  }
}

double _r(num val) {
  try {
    return val.r;
  } catch (_) {
    return val.toDouble();
  }
}

double _sp(num val) {
  try {
    return val.sp;
  } catch (_) {
    return val.toDouble();
  }
}

OverlayEntry? _activeSnackbarEntry;
Timer? _dismissTimer;

class _CustomSnackbarOverlay extends StatefulWidget {
  final String title;
  final String message;
  final Color textColor;
  final bool isSuccess;
  final Duration duration;
  final VoidCallback onDismiss;

  const _CustomSnackbarOverlay({
    required this.title,
    required this.message,
    required this.textColor,
    required this.isSuccess,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_CustomSnackbarOverlay> createState() => _CustomSnackbarOverlayState();
}

class _CustomSnackbarOverlayState extends State<_CustomSnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _timer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: SlideTransition(
              position: _offsetAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: EdgeInsets.all(_w(16)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _w(16),
                      vertical: _h(12),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isSuccess
                            ? [
                                AppColor.defaultColor,
                                AppColor.defaultColor.withValues(alpha: 0.8),
                              ]
                            : [
                                AppColor.redColor,
                                AppColor.redAlphaColor,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(_r(12)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.black20Color,
                          blurRadius: _r(8),
                          offset: Offset(0, _h(4)),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: _w(12)),
                          child: Icon(
                            widget.isSuccess
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: widget.textColor,
                            size: _w(20),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: _sp(16),
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: _h(4)),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: widget.textColor.withValues(alpha: 0.9),
                                  fontSize: _sp(14),
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showCustomSnackBar({
  required String title,
  required String message,
  Color backgroundColor = AppColor.defaultColor,
  Color textColor = AppColor.textWhiteColor,
  Duration duration = const Duration(seconds: 2),
  bool isSuccess = true,
}) {
  debugPrint("showCustomSnackBar: [$title] $message");

  // Dismiss any active custom snackbar
  _dismissTimer?.cancel();
  _dismissTimer = null;
  if (_activeSnackbarEntry != null) {
    try {
      _activeSnackbarEntry?.remove();
    } catch (_) {}
    _activeSnackbarEntry = null;
  }

  // Get overlay state directly from navigator state, bypassing GetX's broken _Theater lookup
  OverlayState? overlayState;
  try {
    overlayState = Get.key.currentState?.overlay;
  } catch (_) {}

  if (overlayState == null && Get.context != null) {
    try {
      overlayState = Overlay.maybeOf(Get.context!, rootOverlay: true);
    } catch (_) {}
  }

  if (overlayState == null) {
    // Fallback to ScaffoldMessenger if available
    try {
      final context = Get.context;
      if (context != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('$title: $message'),
            backgroundColor:
                isSuccess ? AppColor.defaultColor : AppColor.redColor,
            duration: duration,
          ),
        );
      }
    } catch (_) {}
    return;
  }

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _CustomSnackbarOverlay(
      title: title,
      message: message,
      textColor: textColor,
      isSuccess: isSuccess,
      duration: duration,
      onDismiss: () {
        if (_activeSnackbarEntry == entry) {
          try {
            entry.remove();
          } catch (_) {}
          _activeSnackbarEntry = null;
        }
      },
    ),
  );

  _activeSnackbarEntry = entry;
  overlayState.insert(entry);
}
