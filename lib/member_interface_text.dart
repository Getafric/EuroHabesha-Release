import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'l10n/app_ui.dart';

String memberText(
  BuildContext context,
  String french,
  String english, {
  String? catalogKey,
}) {
  if (catalogKey != null) return ui(context, catalogKey.tr(context: context));
  return ui(
    context,
    AppUi.known(french)
        ? french
        : (context.locale.languageCode == 'fr' ? french : english),
  );
}
