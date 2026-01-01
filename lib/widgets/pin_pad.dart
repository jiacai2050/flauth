import 'package:flutter/material.dart';

class PinPad extends StatefulWidget {
  final int pinLength;
  final Function(String) onSubmit;
  final bool showBiometricButton;
  final VoidCallback? onBiometricPressed;

  const PinPad({
    super.key,
    this.pinLength = 4,
    required this.onSubmit,
    this.showBiometricButton = false,
    this.onBiometricPressed,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _input = '';

  void _onKeyPress(String val) {
    if (_input.length < widget.pinLength) {
      setState(() {
        _input += val;
      });
      if (_input.length == widget.pinLength) {
        // Delay slightly to show the last dot
        Future.delayed(const Duration(milliseconds: 100), () {
          widget.onSubmit(_input);
          setState(() {
            _input = '';
          });
        });
      }
    }
  }

  void _onDelete() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
    }
  }

  Widget _buildKey(String val) {
    return Expanded(
      child: InkWell(
        onTap: () => _onKeyPress(val),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            val,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pinLength, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _input.length
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            );
          }),
        ),
        const SizedBox(height: 40),

        // Keypad
        SizedBox(
          height: 320, // adjust as needed
          child: Column(
            children: [
              Expanded(
                child: Row(children: ['1', '2', '3'].map(_buildKey).toList()),
              ),
              Expanded(
                child: Row(children: ['4', '5', '6'].map(_buildKey).toList()),
              ),
              Expanded(
                child: Row(children: ['7', '8', '9'].map(_buildKey).toList()),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Bottom Left: Biometric Button (if enabled)
                    Expanded(
                      child: widget.showBiometricButton
                          ? IconButton(
                              icon: const Icon(Icons.fingerprint, size: 32),
                              onPressed: widget.onBiometricPressed,
                            )
                          : const SizedBox(),
                    ),
                    // Bottom Center: 0
                    _buildKey('0'),
                    // Bottom Right: Backspace
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: _onDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
