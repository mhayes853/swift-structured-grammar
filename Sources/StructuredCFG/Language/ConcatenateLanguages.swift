/// A language component that concatenates multiple child languages.
///
/// ```swift
/// let language = Language {
///   ConcatenateLanguages {
///     Grammar(Rule("digits") { OneOrMore { CharacterGroup.digit } })
///     Grammar(Rule("equals") { "=" })
///   }
/// }
/// ```
public struct ConcatenateLanguages: Hashable, Sendable, Language.Component {
  public let language: Language

  /// Creates a concatenation from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces the languages to concatenate.
  public init(@ConcatenateLanguagesBuilder _ content: () -> [Language]) {
    self.language = .concatenate(content())
  }
}
