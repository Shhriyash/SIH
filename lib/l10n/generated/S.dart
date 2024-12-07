import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'S_en.dart';
import 'S_hi.dart';
import 'S_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/S.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta')
  ];

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcomeTo;

  /// No description provided for @dakMadad.
  ///
  /// In en, this message translates to:
  /// **'Dak Madad'**
  String get dakMadad;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocation;

  /// No description provided for @scanParcel.
  ///
  /// In en, this message translates to:
  /// **'Scan the Post / Parcel'**
  String get scanParcel;

  /// No description provided for @enterConsignment.
  ///
  /// In en, this message translates to:
  /// **'Enter a consignment no...'**
  String get enterConsignment;

  /// No description provided for @postOffice.
  ///
  /// In en, this message translates to:
  /// **'Post Office'**
  String get postOffice;

  /// No description provided for @deliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Delivery Partner'**
  String get deliveryPartner;

  /// No description provided for @trackParcel.
  ///
  /// In en, this message translates to:
  /// **'Track Parcel'**
  String get trackParcel;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @edgeDetection.
  ///
  /// In en, this message translates to:
  /// **'Edge Detection'**
  String get edgeDetection;

  /// No description provided for @maps.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get maps;

  /// No description provided for @waypointAdderQR.
  ///
  /// In en, this message translates to:
  /// **'Waypoint Adder QR'**
  String get waypointAdderQR;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by India Post\nDak Sewa - Jan Sewa'**
  String get poweredBy;

  /// No description provided for @placeholderScreenText.
  ///
  /// In en, this message translates to:
  /// **'This is the {title} screen'**
  String placeholderScreenText(Object title);

  /// No description provided for @poweredByIndiaPost.
  ///
  /// In en, this message translates to:
  /// **'Powered by India Post'**
  String get poweredByIndiaPost;

  /// No description provided for @dakSewaJanSewa.
  ///
  /// In en, this message translates to:
  /// **'Dak Sewa - Jan Sewa'**
  String get dakSewaJanSewa;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload Images'**
  String get uploadImages;

  /// No description provided for @frontImage.
  ///
  /// In en, this message translates to:
  /// **'Front Image'**
  String get frontImage;

  /// No description provided for @rearImage.
  ///
  /// In en, this message translates to:
  /// **'Rear Image'**
  String get rearImage;

  /// No description provided for @uuid.
  ///
  /// In en, this message translates to:
  /// **'UUID:'**
  String get uuid;

  /// No description provided for @errorUploadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Error uploading photos:'**
  String get errorUploadingPhotos;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return SEn();
    case 'hi': return SHi();
    case 'ta': return STa();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
