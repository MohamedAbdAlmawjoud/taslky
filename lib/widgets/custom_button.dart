import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy, outlined;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: outlined
        ? OutlinedButton(
            onPressed: busy ? null : onPressed,
            child: busy ? const CircularProgressIndicator() : Text(label),
          )
        : FilledButton(
            onPressed: busy ? null : onPressed,
            child: busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          ),
  );
}
