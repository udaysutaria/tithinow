import 'app_pill_button.dart';

/// Atomic widget representing the "Get Started" Pill Button.
///
/// Extends [AppPillButton] with default text 'Get Started'.
class ButtonGetStarted extends AppPillButton {
  const ButtonGetStarted({
    super.key,
    super.onPressed,
    super.isEnabled = true,
    super.text = 'Get Started',
    super.width = 364,
  });
}
