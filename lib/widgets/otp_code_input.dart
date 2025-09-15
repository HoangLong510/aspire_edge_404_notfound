import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpCodeInput extends StatefulWidget {
  final int length;
  final double boxSize;
  final ValueChanged<String> onCompleted;
  final bool disabled;

  const OtpCodeInput({
    super.key,
    this.length = 6,
    this.boxSize = 52,
    required this.onCompleted,
    this.disabled = false,
  });

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (widget.disabled) return;

    if (value.length == 1 && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }

    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted(code);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: widget.boxSize,
          height: widget.boxSize,
          child: TextField(
            enabled: !widget.disabled,
            controller: _controllers[i],
            focusNode: _nodes[i],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
            ),
            onChanged: (v) => _onChanged(i, v),
          ),
        );
      }),
    );
  }
}
