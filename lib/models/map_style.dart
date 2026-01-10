enum MapStyle {
  lightAll,
  lightNoLabels,
  darkAll,
  darkNoLabels,
  positron,
  positronNoLabels,
  voyager,
  voyagerNoLabels,
}

extension MapStyleExtension on MapStyle {
  String get urlTemplate {
    switch (this) {
      case MapStyle.lightAll:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}{r}.png';
      case MapStyle.lightNoLabels:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/light_nolabels/{z}/{x}/{y}{r}.png';
      case MapStyle.darkAll:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png';
      case MapStyle.darkNoLabels:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_nolabels/{z}/{x}/{y}{r}.png';
      case MapStyle.positron:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
      case MapStyle.positronNoLabels:
        return 'https://{s}.basemaps.cartocdn.com/light_nolabels_all/{z}/{x}/{y}{r}.png';
      case MapStyle.voyager:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
      case MapStyle.voyagerNoLabels:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}{r}.png';
    }
  }

  String get displayName {
    switch (this) {
      case MapStyle.lightAll:
        return 'Light (z etykietami)';
      case MapStyle.lightNoLabels:
        return 'Light (bez etykiet)';
      case MapStyle.darkAll:
        return 'Ciemna (z etykietami)';
      case MapStyle.darkNoLabels:
        return 'Ciemna (bez etykiet)';
      case MapStyle.positron:
        return 'Positron (z etykietami)';
      case MapStyle.positronNoLabels:
        return 'Positron (bez etykiet)';
      case MapStyle.voyager:
        return 'Voyager (z etykietami)';
      case MapStyle.voyagerNoLabels:
        return 'Voyager (bez etykiet)';
    }
  }

  String get stringValue {
    switch (this) {
      case MapStyle.lightAll:
        return 'light_all';
      case MapStyle.lightNoLabels:
        return 'light_no_labels';
      case MapStyle.darkAll:
        return 'dark_all';
      case MapStyle.darkNoLabels:
        return 'dark_no_labels';
      case MapStyle.positron:
        return 'positron';
      case MapStyle.positronNoLabels:
        return 'positron_no_labels';
      case MapStyle.voyager:
        return 'voyager';
      case MapStyle.voyagerNoLabels:
        return 'voyager_no_labels';
    }
  }

  static MapStyle fromStringValue(String? value) {
    switch (value) {
      case 'light_no_labels':
        return MapStyle.lightNoLabels;
      case 'dark_all':
        return MapStyle.darkAll;
      case 'dark_no_labels':
        return MapStyle.darkNoLabels;
      case 'positron':
        return MapStyle.positron;
      case 'positron_no_labels':
        return MapStyle.positronNoLabels;
      case 'voyager':
        return MapStyle.voyager;
      case 'voyager_no_labels':
        return MapStyle.voyagerNoLabels;
      case 'light_all':
      default:
        return MapStyle.lightAll;
    }
  }
}
