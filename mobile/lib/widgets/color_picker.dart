import 'package:adair_flutter_lib/res/anim.dart';
import 'package:flutter/material.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/target_color.dart';

import 'package:mobile/utils/style.dart';

import '../managers/audio_manager.dart';

class ColorPicker extends StatelessWidget {
  static const _colorSize = 30.0;
  static const _colorSpacing = 5.0;
  static const _selectedBorderSize = 2.0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: PreferenceManager.get.stream,
      builder: (context, _) {
        var isEnabled = PreferenceManager.get.difficulty.canChooseColor;
        var index = PreferenceManager.get.colorIndex;
        var selectedColor =
            index == null ? null : TargetColor.from(index: index);

        return AnimatedOpacity(
          opacity: isEnabled ? 1.0 : opacityDisabled,
          duration: animDurationDefault,
          child: Wrap(
            runSpacing: _colorSpacing,
            spacing: _colorSpacing,
            children: Difficulty.veryEasy.colors().map((e) {
              return _buildColor(
                context,
                e,
                isSelected: e == selectedColor,
                isEnabled: isEnabled,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildColor(
    BuildContext context,
    TargetColor color, {
    required bool isSelected,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled
          ? AudioManager.get.onButtonPressed(() => PreferenceManager
              .get.colorIndex = isSelected ? null : color.index)
          : null,
      child: Container(
        width: _colorSize,
        height: _colorSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: _selectedBorderSize,
          ),
        ),
        child: Image.asset(color.path),
      ),
    );
  }
}
