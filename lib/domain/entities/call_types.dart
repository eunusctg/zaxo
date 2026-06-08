/// Call type — whether the call is audio or video.
enum CallType {
  audio,
  video,
}

/// Call filter for the history screen.
enum CallFilter {
  all,
  missed,
  outgoing,
  incoming,
}

/// Call status lifecycle.
enum CallStatus {
  ringing,
  ongoing,
  ended,
  missed,
  rejected,
}
