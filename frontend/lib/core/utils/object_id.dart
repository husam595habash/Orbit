/// A Mongo ObjectId's first 4 bytes (8 hex chars) encode its creation time
/// as a Unix timestamp — useful for entities like chat messages that don't
/// store their own `createdAt`.
DateTime dateTimeFromObjectId(String objectId) {
  final seconds = int.parse(objectId.substring(0, 8), radix: 16);
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}
