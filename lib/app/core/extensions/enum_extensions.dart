extension SafeEnumAccess<T extends Enum> on Iterable<T> {
  T safeGet(int? index, T defaultValue) {
    if (index == null || index < 0 || index >= length) return defaultValue;
    return elementAt(index);
  }
}
