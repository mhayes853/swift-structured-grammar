/// A reusable component that can be converted into a ``Language``.
public protocol LanguageComponent {
  /// The language represented by this component.
  @LanguageBuilder
  var language: Language { get }
}
