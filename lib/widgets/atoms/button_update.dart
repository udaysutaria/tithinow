import 'app_pill_button.dart';

/// Atomic widget representing the "Update" action button.
///
/// Extends [AppPillButton] with default text 'Update'.
class ButtonUpdate extends AppPillButton {
  const ButtonUpdate({
    super.key,
    super.onPressed,
    super.isEnabled = true,
    super.text = 'Update',
    super.width = 364,
  });
}
