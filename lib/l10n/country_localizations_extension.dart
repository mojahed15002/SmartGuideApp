import 'gen/app_localizations.dart';

// ✅ توسيع AppLocalizations لإضافة أسماء الدول باللغتين
extension CountryNames on AppLocalizations {
  String getCountryName(String key) {
    switch (key) {
      case 'saudi': return countrySaudi;
      case 'uae': return countryUAE;
      case 'egypt': return countryEgypt;
      case 'jordan': return countryJordan;
      case 'kuwait': return countryKuwait;
      case 'qatar': return countryQatar;
      case 'oman': return countryOman;
      case 'bahrain': return countryBahrain;
      case 'lebanon': return countryLebanon;
      case 'iraq': return countryIraq;
      case 'palestine': return countryPalestine;
      case 'syria': return countrySyria;
      case 'yemen': return countryYemen;
      case 'algeria': return countryAlgeria;
      case 'morocco': return countryMorocco;
      case 'tunisia': return countryTunisia;
      case 'libya': return countryLibya;
      case 'sudan': return countrySudan;
      case 'mauritania': return countryMauritania;
      case 'turkey': return countryTurkey;
      case 'usa': return countryUSA;
      case 'canada': return countryCanada;
      case 'uk': return countryUK;
      case 'france': return countryFrance;
      case 'germany': return countryGermany;
      case 'spain': return countrySpain;
      case 'italy': return countryItaly;
      case 'india': return countryIndia;
      default: return key;
    }
  }
}
