/// A language component that applies the Kleene-star operation to a language.
///
/// ```swift
/// let language = Language {
///   KleeneStar {
///     Grammar(Rule("digit") { CharacterGroup.digit })
///   }
/// }
/// ```
public struct KleeneStar: Hashable, Sendable, Language.Component {
  public let language: Language

  /// Creates a Kleene-star language from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces the language to repeat.
  public init(@LanguageBuilder _ content: () -> Language) {
    self.language = .kleeneStar(content())
  }
}
