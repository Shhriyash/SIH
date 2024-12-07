import 'S.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class STa extends S {
  STa([String locale = 'ta']) : super(locale);

  @override
  String get welcomeTo => 'வரவேற்கிறது';

  @override
  String get dakMadad => 'டாக் மடாத்';

  @override
  String get yourLocation => 'உங்கள் இடம்';

  @override
  String get scanParcel => 'அஞ்சல்/பார்சலை ஸ்கேன் செய்யவும்';

  @override
  String get enterConsignment => 'அனுப்பும் எண் உள்ளிடவும்...';

  @override
  String get postOffice => 'அஞ்சலகம்';

  @override
  String get deliveryPartner => 'டெலிவரி பார்ட்னர்';

  @override
  String get trackParcel => 'பார்சலை கண்காணிக்கவும்';

  @override
  String get support => 'ஆதரவு';

  @override
  String get edgeDetection => 'எட்ஜ் டெடெக்ஷன்';

  @override
  String get maps => 'வரைபடங்கள்';

  @override
  String get waypointAdderQR => 'வாய்பாயிண்ட் ஆட்டர் QR';

  @override
  String get poweredBy => 'இந்தியா போஸ்ட் மூலம் இயங்குகிறது\nஅஞ்சல் சேவை - பொதுச் சேவை';

  @override
  String placeholderScreenText(Object title) {
    return 'இது $title திரை';
  }

  @override
  String get poweredByIndiaPost => 'இந்தியா போஸ்ட் மூலம் இயங்குகிறது';

  @override
  String get dakSewaJanSewa => 'அஞ்சல் சேவை - பொதுச் சேவை';

  @override
  String get uploadImages => 'படங்களை பதிவேற்றவும்';

  @override
  String get frontImage => 'முன் படம்';

  @override
  String get rearImage => 'பின்புற படம்';

  @override
  String get uuid => 'UUID:';

  @override
  String get errorUploadingPhotos => 'படங்களை பதிவேற்றுவதில் பிழை:';
}
