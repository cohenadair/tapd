import 'package:material_ui/material_ui.dart';

import '../managers/audio_manager.dart';

class AudioCloseButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AudioCloseButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return CloseButton(
      onPressed: AudioManager.get.onButtonPressed(() {
        onTap?.call();
        Navigator.of(context).pop();
      }),
    );
  }
}
