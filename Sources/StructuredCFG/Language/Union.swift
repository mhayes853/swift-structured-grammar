/// A language component that unions multiple child languages.
///
/// ```swift
/// let language = Language {
///   Union {
///     Grammar(Rule("digits") { OneOrMore { CharacterGroup.digit } })
///     Grammar(Rule("identifier") { OneOrMore { CharacterGroup.word } })
///   }
/// }
/// ```
public struct Union: Hashable, Sendable, Language.Component {
  public let language: Language

  /// Creates a union from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces the languages to union.
  public init(@UnionBuilder _ content: () -> [Language]) {
    self.language = .union(content())
  }
}
