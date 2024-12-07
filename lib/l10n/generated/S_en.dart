import 'S.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTo => 'Welcome to';

  @override
  String get dakMadad => 'Dak Madad';

  @override
  String get yourLocation => 'Your Location';

  @override
  String get scanParcel => 'Scan the Post / Parcel';

  @override
  String get enterConsignment => 'Enter a consignment no...';

  @override
  String get postOffice => 'Post Office';

  @override
  String get deliveryPartner => 'Delivery Partner';

  @override
  String get trackParcel => 'Track Parcel';

  @override
  String get support => 'Support';

  @override
  String get edgeDetection => 'Edge Detection';

  @override
  String get maps => 'Maps';

  @override
  String get waypointAdderQR => 'Waypoint Adder QR';

  @override
  String get poweredBy => 'Powered by India Post\nDak Sewa - Jan Sewa';

  @override
  String placeholderScreenText(Object title) {
    return 'This is the $title screen';
  }

  @override
  String get poweredByIndiaPost => 'Powered by India Post';

  @override
  String get dakSewaJanSewa => 'Dak Sewa - Jan Sewa';

  @override
  String get uploadImages => 'Upload Images';

  @override
  String get frontImage => 'Front Image';

  @override
  String get rearImage => 'Rear Image';

  @override
  String get uuid => 'UUID:';

  @override
  String get errorUploadingPhotos => 'Error uploading photos:';
}
