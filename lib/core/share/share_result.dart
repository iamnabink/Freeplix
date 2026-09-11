/// How a share request was ultimately handled.
///
/// Kept in its own file so the platform implementations can name it without
/// importing the conditional-import entrypoint back (which would be a cycle).
enum ShareResult {
  /// The platform's native share sheet took over.
  shared,

  /// No share sheet was available, so the link was copied to the clipboard.
  copied,
}
