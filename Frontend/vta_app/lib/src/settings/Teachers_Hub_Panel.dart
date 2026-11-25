import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

const Color _hubTextColor = Color(0xFF757575);
const Color _hubAccentColor = Color(0xFFFEC377);
const Color _hubErrorColor = Color(0xFFC2185B);
const Color _hubKeyColor = Color(0xFFE9E4DF);

class TeachersHubPanel extends StatefulWidget {
  const TeachersHubPanel({
    super.key,
    required this.isOpen,
    required this.onBoards,
    required this.onSettings,
    required this.onLogout,
    this.onImages,
    this.onPersonalization,
    this.borderRadius = BorderRadius.zero,
  });

  final bool isOpen;
  final VoidCallback onBoards;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final VoidCallback? onImages; // TODO: wire up when the screen exists
  final VoidCallback? onPersonalization; // TODO: wire up when the screen exists
  final BorderRadius borderRadius;

  @override
  State<TeachersHubPanel> createState() => _TeachersHubPanelState();
}

class _TeachersHubPanelState extends State<TeachersHubPanel> {
  static const int _maxOperand = 10;

  final Random _rng = Random();
  int _a = 0;
  int _b = 0;
  int _answer = 0;
  bool _isPlus = true;

  String _input = '';
  bool _unlocked = false;
  bool _wrong = false;
  Timer? _wrongTimer;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  @override
  void didUpdateWidget(TeachersHubPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Lock the gate again every time the panel is opened
    if (!oldWidget.isOpen && widget.isOpen) {
      _reset();
    }
  }

  @override
  void dispose() {
    _wrongTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    _wrongTimer?.cancel();
    _unlocked = false;
    _wrong = false;
    _input = '';
    _newQuestion();
  }

  void _newQuestion() {
    _isPlus = _rng.nextBool();
    if (_isPlus) {
      _a = 1 + _rng.nextInt(_maxOperand); // 1..max
      _b = 1 + _rng.nextInt(_maxOperand); // 1..max
      _answer = _a + _b;
    } else {
      _a = 2 + _rng.nextInt(_maxOperand - 1); // 2..max
      _b = 1 + _rng.nextInt(_a - 1); // 1..a-1, so the answer is always >= 1
      _answer = _a - _b;
    }
  }

  void _onDigit(int digit) {
    if (_wrong) return;
    final answerLength = _answer.toString().length;
    if (_input.length >= answerLength) return;

    setState(() => _input += digit.toString());

    if (_input.length == answerLength) {
      _check();
    }
  }

  void _onBackspace() {
    if (_wrong || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _check() {
    if (int.parse(_input) == _answer) {
      setState(() => _unlocked = true);
    } else {
      setState(() => _wrong = true);
      _wrongTimer?.cancel();
      _wrongTimer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _wrong = false;
          _input = '';
          _newQuestion();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 600;

    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, wide ? 28 : 22, 16, 16),
        child: Column(
          children: [
            // Title with orange underline
            Container(
              padding: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _hubAccentColor, width: 1),
                ),
              ),
              child: Text(
                'Lærer Hub',
                style: TextStyle(
                  fontSize: wide ? 24 : 20,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: wide ? 36 : 28),
            Expanded(
              child: _unlocked ? _buildMenu(wide) : _buildGate(wide),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(bool wide) {
    final itemFontSize = wide ? 18.0 : 15.0;

    return Column(
      children: [
        _MenuItem('Boards', widget.onBoards, itemFontSize),
        _MenuItem('Billeder', widget.onImages, itemFontSize),
        _MenuItem('Indstillinger', widget.onSettings, itemFontSize),
        _MenuItem(
            'Personlig Tilpasning', widget.onPersonalization, itemFontSize),
        const Spacer(),
        TextButton(
          onPressed: widget.onLogout,
          child: Text(
            'Log Ud',
            style: TextStyle(
              fontSize: itemFontSize,
              color: _hubErrorColor,
            ),
          ),
        ),
      ],
    );
  }

    Widget _buildGate(bool wide) {
    final keyHeight = wide ? 52.0 : 44.0;
    final questionSize = wide ? 26.0 : 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            // Fill the panel's height so the spacing can spread out
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Løs regnestykket for at få adgang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: wide ? 20 : 15,
                      color: _hubTextColor,
                    ),
                  ),

                  // Question + answer box
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_a ${_isPlus ? '+' : '−'} $_b =',
                          style: TextStyle(
                            fontSize: questionSize,
                            color: _hubTextColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: wide ? 64 : 52,
                          height: keyHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _wrong ? _hubErrorColor : _hubAccentColor,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _input,
                            style: TextStyle(
                              fontSize: questionSize,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Numpad
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _keyRow([
                        _digitKey(1, keyHeight),
                        _digitKey(2, keyHeight),
                        _digitKey(3, keyHeight),
                      ]),
                      _keyRow([
                        _digitKey(4, keyHeight),
                        _digitKey(5, keyHeight),
                        _digitKey(6, keyHeight),
                      ]),
                      _keyRow([
                        _digitKey(7, keyHeight),
                        _digitKey(8, keyHeight),
                        _digitKey(9, keyHeight),
                      ]),
                      _keyRow([
                        const SizedBox.shrink(),
                        _digitKey(0, keyHeight),
                        _NumKey(
                          icon: Icons.backspace_outlined,
                          height: keyHeight,
                          onTap: _onBackspace,
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _digitKey(int digit, double height) {
    return _NumKey(
      label: '$digit',
      height: height,
      onTap: () => _onDigit(digit),
    );
  }

  Widget _keyRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (final child in children)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: child,
              ),
            ),
        ],
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({
    this.label,
    this.icon,
    required this.height,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _hubKeyColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: icon != null
                ? Icon(icon, color: _hubTextColor, size: 22)
                : Text(
                    label ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      color: _hubTextColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.label, this.onTap, this.fontSize);

  final String label;
  final VoidCallback? onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            color: _hubTextColor,
          ),
        ),
      ),
    );
  }
}