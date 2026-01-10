import 'package:flutter/material.dart';
import '../models/map_style.dart';

class MapStyleNotifier {
  static final MapStyleNotifier _instance = MapStyleNotifier._internal();

  final ValueNotifier<MapStyle> _notifier = ValueNotifier(MapStyle.lightAll);

  MapStyleNotifier._internal();

  factory MapStyleNotifier() {
    return _instance;
  }

  ValueNotifier<MapStyle> get notifier => _notifier;

  void setMapStyle(MapStyle style) {
    _notifier.value = style;
  }

  MapStyle getMapStyle() {
    return _notifier.value;
  }
}
