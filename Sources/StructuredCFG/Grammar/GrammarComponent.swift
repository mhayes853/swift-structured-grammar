/// A reusable component that contributes one or more grammar rules.
public protocol GrammarComponent {
  associatedtype Rules: Sequence<Rule>

  /// The rules represented by this component.
  @RulesBuilder
  var rules: Rules { get }
}
