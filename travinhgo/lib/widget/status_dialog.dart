import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusDialog extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final VoidCallback onOkPressed;

  const StatusDialog({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.onOkPressed,
  });

  @override
  State<StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<StatusDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _iconScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 40.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final successColor = const Color(0xFF158247); // Match app primary color
    final errorColor = const Color(0xFFE93C3C);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (widget.isSuccess ? successColor : errorColor)
                    .withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 5,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status icon with animation
              ScaleTransition(
                scale: _iconScaleAnimation,
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: widget.isSuccess ? successColor : errorColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isSuccess ? successColor : errorColor)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isSuccess ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                widget.title,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),

              // OK button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: widget.onOkPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        widget.isSuccess ? successColor : errorColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: (widget.isSuccess ? successColor : errorColor)
                        .withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper methods to show the dialogs
class StatusDialogs {
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String message,
    required VoidCallback onOkPressed,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatusDialog(
        isSuccess: true,
        title: 'Success',
        message: message,
        onOkPressed: onOkPressed,
      ),
    );
  }

  static Future<void> showErrorDialog({
    required BuildContext context,
    required String message,
    required VoidCallback onOkPressed,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatusDialog(
        isSuccess: false,
        title: 'Error',
        message: message,
        onOkPressed: onOkPressed,
      ),
    );
  }
}
