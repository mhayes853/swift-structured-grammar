public protocol GrammarComponent {
  associatedtype Rules: Sequence<Rule>

  @RulesBuilder
  var rules: Rules { get }
}
