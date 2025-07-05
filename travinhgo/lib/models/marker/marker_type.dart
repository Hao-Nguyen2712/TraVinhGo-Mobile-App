enum MarkerType {
  ocopProduct,
  buildingDestination,
  naturalDestination,
  religiousBuilding,
  naturalLandScape,
  monumentsAndMuseums,
  folkLore,
  ecology,
  eventAndFestival,
  localSpecialties;

  String getAccessPath() {
    switch (this) {
      case MarkerType.ocopProduct:
        return 'assets/markers/ocop.png';
      case MarkerType.naturalLandScape:
        return 'assets/markers/natural_landscape.png';
      case MarkerType.monumentsAndMuseums:
        return 'assets/markers/monuments_and_museums.png';
      case MarkerType.religiousBuilding:
        return 'assets/markers/religious_building.png';
      case MarkerType.folkLore:
        return 'assets/markers/folklore.png';
      case MarkerType.ecology:
        return 'assets/markers/ecology.png';
      case MarkerType.eventAndFestival:
        return 'assets/markers/eventAndFestival.png';
      case MarkerType.localSpecialties:
        return 'assets/markers/local_specialties.png';
      default:
        return 'assets/markers/default.png';
    }
  }
}
