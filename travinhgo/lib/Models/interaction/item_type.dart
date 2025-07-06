enum ItemType {
  Destination,
  OcopProduct,
  LocalSpecialties;

  String toShortString() {
    return toString().split('.').last;
  }
}