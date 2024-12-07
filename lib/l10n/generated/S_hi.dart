import 'S.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class SHi extends S {
  SHi([String locale = 'hi']) : super(locale);

  @override
  String get welcomeTo => 'डाक मदद';

  @override
  String get dakMadad => 'में आपका स्वागत है';

  @override
  String get yourLocation => 'आपका स्थान';

  @override
  String get scanParcel => 'पोस्ट/पार्सल स्कैन करें';

  @override
  String get enterConsignment => 'कंसाइनमेंट नंबर दर्ज करें...';

  @override
  String get postOffice => 'डाकघर';

  @override
  String get deliveryPartner => 'डिलीवरी पार्टनर';

  @override
  String get trackParcel => 'पार्सल ट्रैक करें';

  @override
  String get support => 'सहायता';

  @override
  String get edgeDetection => 'एज डिटेक्शन';

  @override
  String get maps => 'नक्शे';

  @override
  String get waypointAdderQR => 'वेपॉइंट ऐडर क्यूआर';

  @override
  String get poweredBy => 'इंडिया पोस्ट द्वारा संचालित\nडाक सेवा - जन सेवा';

  @override
  String placeholderScreenText(Object title) {
    return 'यह $title स्क्रीन है';
  }

  @override
  String get poweredByIndiaPost => 'इंडिया पोस्ट द्वारा संचालित';

  @override
  String get dakSewaJanSewa => 'डाक सेवा - जन सेवा';

  @override
  String get uploadImages => 'छवियाँ अपलोड करें';

  @override
  String get frontImage => 'सामने की छवि';

  @override
  String get rearImage => 'पीछे की छवि';

  @override
  String get uuid => 'यूयूआईडी:';

  @override
  String get errorUploadingPhotos => 'फ़ोटो अपलोड करने में त्रुटि:';
}
