/// A language component that reverses the accepted terminal sequences of a language.
///
/// ```swift
/// let language = Language {
///   Reverse {
///     Grammar(Rule("arrow") { "->" })
///   }
/// }
/// ```
public struct Reverse: Hashable, Sendable, LanguageComponent {
  public let language: Language

  /// Creates a reversed language from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces the language to reverse.
  public init(@LanguageBuilder _ content: () -> Language) {
    self.language = .reverse(content())
  }
}
