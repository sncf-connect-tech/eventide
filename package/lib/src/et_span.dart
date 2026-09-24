/// The scope of a delete or update operation on a recurring event instance.
enum ETSpan {
  /// Affects only this specific occurrence.
  thisEvent,

  /// Affects this occurrence and all future occurrences in the series.
  thisAndFuture,

  /// Affects every occurrence in the series (modifies the master event).
  allEvents,
}
