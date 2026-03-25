// MARK: - Grammar

/// A concrete context-free grammar made up of named production rules.
///
/// Use ``Grammar`` when you want to define rules directly, edit them imperatively, or
/// format them into a textual BNF or EBNF dialect.
///
/// ```swift
/// let grammar = Grammar(startingSymbol: "expression") {
///   Rule("expression") {
///     Ref("term")
///     ZeroOrMore {
///       Choice {
///         "+"
///         "-"
///       }
///       Ref("term")
///     }
///   }
///
///   Rule("term") {
///     OneOrMore {
///       CharacterGroup.digit
///     }
///   }
/// }
///
/// let gbnf = try grammar.formatted(with: .gbnf)
/// ```
public struct Grammar: Hashable, Sendable, LanguageComponent, Grammar.Component {
  /// A top-level statement in a grammar.
  @nonexhaustive
  public enum Statement: Sendable {
    /// A named production rule.
    case rule(Rule)

    /// A formatter-emitted comment.
    case comment(Comment)

    /// A custom statement understood by a formatter-specific extension.
    case custom(any Hashable & Sendable)
  }

  /// The symbol used as the grammar's entry point.
  public var startingSymbol: Symbol {
    didSet {
      self.updateStartingSymbol(from: oldValue)
    }
  }

  private var orderedStatements: [Statement]
  private var orderedSymbols: [Symbol]
  private var rulesBySymbol: [Symbol: Rule]

  /// The grammar's statements in stable iteration order.
  public var statements: Statements {
    Statements(orderedStatements: self.orderedStatements)
  }

  /// The grammar's ``Rules`` in stable iteration order.
  public var rules: Rules {
    Rules(
      orderedSymbols: self.orderedSymbols,
      rulesBySymbol: self.rulesBySymbol
    )
  }

  public var language: Language {
    Language(self)
  }

  public typealias Statements = StatementCollection

  /// Creates an empty grammar rooted at ``Symbol/root``.
  public init() {
    self.init(Rule(.root) { Epsilon() })
  }

  /// Creates a grammar containing a single ``Rule``.
  ///
  /// - Parameter rule: The initial ``Rule`` to store.
  public init(_ rule: Rule) {
    self.init(startingSymbol: rule.symbol, CollectionOfOne(rule))
  }

  /// Creates a grammar from a starting ``Symbol`` and rule sequence.
  ///
  /// If the starting symbol does not appear in `rules`, an epsilon rule is synthesized
  /// for it.
  ///
  /// - Parameters:
  ///   - startingSymbol: The grammar entry ``Symbol``.
  ///   - statements: The top-level statements to include.
  public init(startingSymbol: Symbol, _ statements: some Sequence<Statement>) {
    self.startingSymbol = startingSymbol
    self.orderedStatements = [Statement]()
    self.orderedSymbols = [startingSymbol]
    self.rulesBySymbol = [startingSymbol: Rule(startingSymbol) { Epsilon() }]
    for statement in statements {
      self.append(statement)
    }
    self.ensureStartingRuleStatement()
    self.moveStartingRuleToFirstRuleSlot()
  }

  /// Creates a grammar from a starting ``Symbol`` and rule sequence.
  ///
  /// - Parameters:
  ///   - startingSymbol: The grammar entry ``Symbol``.
  ///   - rules: The ``Rule`` values to include.
  public init(startingSymbol: Symbol, _ rules: some Sequence<Rule>) {
    self.init(startingSymbol: startingSymbol, rules.map(Statement.rule))
  }

  /// Creates a grammar from a starting ``Symbol`` and result-builder closure.
  ///
  /// - Parameters:
  ///   - startingSymbol: The grammar entry `Symbol`.
  ///   - content: A builder that produces the grammar's top-level statements.
  public init(startingSymbol: Symbol, @StatementsBuilder _ content: () -> [Statement]) {
    self.init(startingSymbol: startingSymbol, content())
  }

  private init(
    startingSymbol: Symbol,
    orderedStatements: [Statement],
    orderedSymbols: [Symbol],
    rulesBySymbol: [Symbol: Rule]
  ) {
    self.startingSymbol = startingSymbol
    self.orderedStatements = orderedStatements
    self.orderedSymbols = orderedSymbols
    self.rulesBySymbol = rulesBySymbol
  }

  /// Returns the ``Rule`` for the supplied symbol.
  ///
  /// - Parameter symbol: The ``Symbol`` to look up.
  /// - Returns: The matching `Rule`, or `nil` if no rule exists.
  public func rule(for symbol: Symbol) -> Rule? {
    self.rulesBySymbol[symbol]
  }

  /// Returns whether the grammar contains a rule for a symbol.
  ///
  /// - Parameter symbol: The ``Symbol`` to test.
  public func containsRule(for symbol: Symbol) -> Bool {
    self.rulesBySymbol[symbol] != nil
  }

  /// Accesses a rule by symbol.
  public subscript(_ symbol: Symbol) -> Rule? {
    self.rulesBySymbol[symbol]
  }

  /// Accesses a rule by its ordered position.
  public subscript(index: Int) -> Rule {
    self.rules[index]
  }

  /// Appends a top-level statement to the grammar.
  ///
  /// - Parameter statement: The ``Statement`` to append.
  public mutating func append(_ statement: Statement) {
    switch statement {
    case .rule(let rule):
      self.replaceRuleStatement(for: rule.symbol, with: rule)
    case .comment, .custom:
      self.orderedStatements.append(statement)
    }
  }

  /// Appends a sequence of top-level statements.
  ///
  /// - Parameter statements: The ``Statement`` values to append.
  public mutating func append(contentsOf statements: some Sequence<Statement>) {
    for statement in statements {
      self.append(statement)
    }
  }

  /// Inserts or replaces a ``Rule`` in the grammar.
  ///
  /// - Parameter rule: The ``Rule`` to append.
  public mutating func append(_ rule: Rule) {
    self.append(.rule(rule))
  }

  /// Inserts or replaces a sequence of rules.
  ///
  /// - Parameter rules: The `Rule` values to append.
  public mutating func append(contentsOf rules: some Sequence<Rule>) {
    for rule in rules {
      self.append(rule)
    }
  }

  /// Returns a copy of the grammar with an additional rule appended.
  ///
  /// - Parameter rule: The ``Rule`` to append.
  /// - Returns: A ``Grammar`` containing `rule`.
  public func appending(_ rule: Rule) -> Self {
    var grammar = self
    grammar.append(rule)
    return grammar
  }

  /// Returns a copy of the grammar with an additional statement appended.
  ///
  /// - Parameter statement: The ``Statement`` to append.
  /// - Returns: A ``Grammar`` containing `statement`.
  public func appending(_ statement: Statement) -> Self {
    var grammar = self
    grammar.append(statement)
    return grammar
  }

  /// Returns a copy of the grammar with additional statements appended.
  ///
  /// - Parameter statements: The ``Statement`` values to append.
  /// - Returns: A ``Grammar`` containing `statements`.
  public func appending(contentsOf statements: some Sequence<Statement>) -> Self {
    var grammar = self
    grammar.append(contentsOf: statements)
    return grammar
  }

  /// Returns a copy of the grammar with additional rules appended.
  ///
  /// - Parameter rules: The `Rule` values to append.
  /// - Returns: A ``Grammar`` containing `rules`.
  public func appending(contentsOf rules: some Sequence<Rule>) -> Self {
    var grammar = self
    grammar.append(contentsOf: rules)
    return grammar
  }

  /// Removes the rule for a symbol.
  ///
  /// Removing the starting symbol resets it to an epsilon production instead of deleting
  /// it entirely.
  ///
  /// - Parameter symbol: The ``Symbol`` whose rule should be removed.
  public mutating func removeRule(for symbol: Symbol) {
    if symbol == self.startingSymbol {
      let placeholder = Rule(symbol) { Epsilon() }
      self.rulesBySymbol[symbol] = placeholder
      self.replaceOrInsertStartingRuleStatement(with: placeholder)
      return
    }
    self.orderedSymbols.removeAll { $0 == symbol }
    self.rulesBySymbol[symbol] = nil
    self.removeRuleStatement(for: symbol)
  }

  /// Removes every rule from the grammar except for the starting symbol placeholder.
  public mutating func removeAll() {
    self.orderedStatements = [Statement]()
    self.orderedSymbols = [self.startingSymbol]
    self.rulesBySymbol = [
      self.startingSymbol: Rule(self.startingSymbol) { Epsilon() }
    ]
    self.ensureStartingRuleStatement()
  }

  /// Removes every rule that matches a predicate.
  ///
  /// If the starting symbol is removed, it is restored as an epsilon production.
  ///
  /// - Parameter shouldBeRemoved: A predicate that decides whether a ``Rule`` is removed.
  public mutating func removeAll(where shouldBeRemoved: (Rule) -> Bool) {
    let removedSymbols = Set<Symbol>(
      self.orderedSymbols.compactMap { symbol in
        guard let rule = self.rulesBySymbol[symbol] else { return nil }
        return shouldBeRemoved(rule) ? symbol : nil
      }
    )

    self.orderedSymbols.removeAll { removedSymbols.contains($0) }
    self.rulesBySymbol = self.rulesBySymbol.filter { !removedSymbols.contains($0.key) }
    self.orderedStatements.removeAll { statement in
      if case .rule(let rule) = statement {
        removedSymbols.contains(rule.symbol)
      } else {
        false
      }
    }
    if removedSymbols.contains(self.startingSymbol) {
      let placeholder = Rule(self.startingSymbol) { Epsilon() }
      self.rulesBySymbol[self.startingSymbol] = placeholder
      if !self.orderedSymbols.contains(self.startingSymbol) {
        self.orderedSymbols.insert(self.startingSymbol, at: 0)
      }
      self.replaceOrInsertStartingRuleStatement(with: placeholder)
    }
  }

  /// Removes every statement that matches a predicate.
  ///
  /// - Parameter shouldBeRemoved: A predicate that decides whether a ``Statement`` is removed.
  public mutating func removeAllStatements(where shouldBeRemoved: (Statement) -> Bool) {
    let removedRuleSymbols = Set(
      self.orderedStatements.compactMap { statement -> Symbol? in
        guard shouldBeRemoved(statement) else { return nil }
        if case .rule(let rule) = statement {
          return rule.symbol
        }
        return nil
      }
    )
    self.orderedStatements.removeAll(where: shouldBeRemoved)
    self.orderedSymbols.removeAll { removedRuleSymbols.contains($0) }
    self.rulesBySymbol = self.rulesBySymbol.filter { !removedRuleSymbols.contains($0.key) }
    if self.rulesBySymbol[self.startingSymbol] == nil {
      let placeholder = Rule(self.startingSymbol) { Epsilon() }
      self.rulesBySymbol[self.startingSymbol] = placeholder
      self.orderedSymbols.insert(self.startingSymbol, at: 0)
      self.replaceOrInsertStartingRuleStatement(with: placeholder)
    }
  }

  /// Replaces the rule for a symbol with a new expression component.
  ///
  /// - Parameters:
  ///   - symbol: The ``Symbol`` to replace.
  ///   - expression: The new ``ExpressionComponent`` for the rule body.
  public mutating func replaceRule(
    for symbol: Symbol,
    with expression: some ExpressionComponent
  ) {
    self.replaceRule(for: symbol, with: Rule(symbol, expression))
  }

  /// Replaces the rule for a symbol with a string terminal.
  ///
  /// - Parameters:
  ///   - symbol: The ``Symbol`` to replace.
  ///   - string: The `String` terminal value to use for the new rule body.
  public mutating func replaceRule(
    for symbol: Symbol,
    with string: String
  ) {
    self.replaceRule(for: symbol, with: Terminal(string))
  }

  /// Replaces the rule for a symbol with an expression builder.
  ///
  /// - Parameters:
  ///   - symbol: The ``Symbol`` to replace.
  ///   - expression: A builder that produces the new ``Expression``.
  public mutating func replaceRule(
    for symbol: Symbol,
    @ExpressionBuilder _ expression: () -> Expression
  ) {
    self.replaceRule(for: symbol, with: expression())
  }

  /// Returns a copy of the grammar with a replaced rule.
  ///
  /// - Parameters:
  ///   - symbol: The ``Symbol`` to replace.
  ///   - expression: The new ``ExpressionComponent`` for the rule body.
  /// - Returns: A ``Grammar`` with the updated rule.
  public func replacingRule(
    for symbol: Symbol,
    with expression: some ExpressionComponent
  ) -> Self {
    var grammar = self
    grammar.replaceRule(for: symbol, with: expression)
    return grammar
  }

  /// Returns a copy of the grammar with a replaced rule that uses a terminal string.
  ///
  /// - Parameters:
  ///   - symbol: The ``Symbol`` to replace.
  ///   - string: The `String` terminal value to use for the new rule body.
  /// - Returns: A ``Grammar`` with the updated rule.
  public func replacingRule(
    for symbol: Symbol,
    with string: String
  ) -> Self {
    var grammar = self
    grammar.replaceRule(for: symbol, with: string)
    return grammar
  }

  /// Returns a copy of the grammar with a replaced rule from a builder closure.
  ///
  /// - Parameters:
  ///   - symbol: The ``Symbol`` to replace.
  ///   - expression: A builder that produces the new ``Expression``.
  /// - Returns: A ``Grammar`` with the updated rule.
  public func replacingRule(
    for symbol: Symbol,
    @ExpressionBuilder _ expression: () -> Expression
  ) -> Self {
    var grammar = self
    grammar.replaceRule(for: symbol, with: expression())
    return grammar
  }

  private mutating func replaceRule(for symbol: Symbol, with rule: Rule) {
    self.replaceRuleStatement(for: symbol, with: rule)
  }

  /// Merges another grammar into this one, replacing rules that share the same symbol.
  ///
  /// - Parameter grammar: The ``Grammar`` to merge into this grammar.
  public mutating func merge(_ grammar: Grammar) {
    for rule in grammar.rules {
      self.replaceRule(for: rule.symbol, with: rule)
    }
  }

  /// Returns a copy of the grammar merged with another grammar.
  ///
  /// - Parameter grammar: The ``Grammar`` to merge into this grammar.
  /// - Returns: A merged ``Grammar``.
  public func merging(_ grammar: Grammar) -> Self {
    var merged = self
    merged.merge(grammar)
    return merged
  }

  private mutating func appendSymbolIfNeeded(_ symbol: Symbol) {
    guard !self.orderedSymbols.contains(symbol) else { return }
    if symbol == self.startingSymbol {
      self.orderedSymbols.insert(symbol, at: 0)
    } else {
      self.orderedSymbols.append(symbol)
    }
  }

  private mutating func updateStartingSymbol(from oldValue: Symbol) {
    guard self.startingSymbol != oldValue else { return }
    if self.rulesBySymbol[self.startingSymbol] == nil {
      let placeholder = Rule(self.startingSymbol) { Epsilon() }
      self.rulesBySymbol[self.startingSymbol] = placeholder
      self.replaceOrInsertStartingRuleStatement(with: placeholder)
    }
    self.orderedSymbols.removeAll { $0 == self.startingSymbol }
    self.orderedSymbols.insert(self.startingSymbol, at: 0)
    self.moveStartingRuleToFirstRuleSlot()
  }

  private mutating func replaceRuleStatement(for symbol: Symbol, with rule: Rule) {
    if self.rulesBySymbol[symbol] == nil {
      self.appendSymbolIfNeeded(symbol)
    }
    self.rulesBySymbol[symbol] = rule

    if let index = self.ruleStatementIndex(for: symbol) {
      self.orderedStatements[index] = .rule(rule)
    } else {
      self.orderedStatements.append(.rule(rule))
    }

    if symbol == self.startingSymbol {
      self.moveStartingRuleToFirstRuleSlot()
    }
  }

  private mutating func removeRuleStatement(for symbol: Symbol) {
    if let index = self.ruleStatementIndex(for: symbol) {
      self.orderedStatements.remove(at: index)
    }
  }

  private func ruleStatementIndex(for symbol: Symbol) -> Int? {
    self.orderedStatements.firstIndex { statement in
      if case .rule(let rule) = statement {
        rule.symbol == symbol
      } else {
        false
      }
    }
  }

  private func firstRuleStatementIndex() -> Int {
    self.orderedStatements.firstIndex { statement in
      if case .rule = statement {
        true
      } else {
        false
      }
    } ?? self.orderedStatements.endIndex
  }

  private mutating func ensureStartingRuleStatement() {
    guard self.ruleStatementIndex(for: self.startingSymbol) == nil else { return }
    let insertIndex = self.firstRuleStatementIndex()
    let placeholder =
      self.rulesBySymbol[self.startingSymbol] ?? Rule(self.startingSymbol) { Epsilon() }
    self.orderedStatements.insert(.rule(placeholder), at: insertIndex)
  }

  private mutating func replaceOrInsertStartingRuleStatement(with rule: Rule) {
    if let index = self.ruleStatementIndex(for: rule.symbol) {
      self.orderedStatements[index] = .rule(rule)
    } else {
      let insertIndex = self.firstRuleStatementIndex()
      self.orderedStatements.insert(.rule(rule), at: insertIndex)
    }
    self.moveStartingRuleToFirstRuleSlot()
  }

  private mutating func moveStartingRuleToFirstRuleSlot() {
    guard let currentIndex = self.ruleStatementIndex(for: self.startingSymbol) else { return }
    let targetIndex = self.firstRuleStatementIndex()
    guard currentIndex != targetIndex else { return }
    let statement = self.orderedStatements.remove(at: currentIndex)
    self.orderedStatements.insert(statement, at: targetIndex)
  }
}

extension Grammar.Statement: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.rule(let lhsRule), .rule(let rhsRule)):
      lhsRule == rhsRule
    case (.comment(let lhsComment), .comment(let rhsComment)):
      lhsComment == rhsComment
    case (.custom(let lhsValue), .custom(let rhsValue)):
      equals(lhsValue, rhsValue)
    default:
      false
    }
  }
}

extension Grammar.Statement: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .rule(let rule):
      hasher.combine(0)
      hasher.combine(rule)
    case .comment(let comment):
      hasher.combine(1)
      hasher.combine(comment)
    case .custom(let value):
      hasher.combine(2)
      value.hash(into: &hasher)
    }
  }
}

// MARK: - Homomorphism

extension Grammar {
  /// Applies a terminal-to-terminal transform across every rule in the grammar.
  ///
  /// Returning `nil` leaves the original terminal unchanged.
  ///
  /// ```swift
  /// var grammar = Grammar(Rule("boolean") {
  ///   Choice {
  ///     "true"
  ///     "false"
  ///   }
  /// })
  ///
  /// grammar.homomorphMap { terminal in
  ///   switch terminal.string {
  ///   case "true": Terminal("1")
  ///   case "false": Terminal("0")
  ///   default: nil
  ///   }
  /// }
  /// ```
  public mutating func homomorphMap(_ transform: (Terminal) -> Terminal?) {
    self.orderedStatements = self.orderedStatements.map { statement in
      switch statement {
      case .rule(let rule):
        let updatedRule = Rule(
          rule.symbol,
          self.homomorphed(expression: rule.expression, transform: transform)
        )
        self.rulesBySymbol[rule.symbol] = updatedRule
        return .rule(updatedRule)
      case .comment, .custom:
        return statement
      }
    }
  }

  /// Returns a copy of the grammar after applying a terminal transform.
  ///
  /// - Parameter transform: A transform applied to each ``Terminal``.
  /// - Returns: A transformed ``Grammar``.
  public func homomorphMapped(_ transform: (Terminal) -> Terminal?) -> Self {
    var grammar = self
    grammar.homomorphMap(transform)
    return grammar
  }

  /// Replaces every matching terminal with a new terminal.
  ///
  /// - Parameters:
  ///   - terminal: The ``Terminal`` to replace.
  ///   - replacement: The replacement `Terminal`.
  public mutating func homomorph(_ terminal: Terminal, to replacement: Terminal) {
    self.homomorphMap { candidate in
      candidate == terminal ? replacement : nil
    }
  }

  /// Returns a copy of the grammar with every matching terminal replaced.
  ///
  /// - Parameters:
  ///   - terminal: The ``Terminal`` to replace.
  ///   - replacement: The replacement `Terminal`.
  /// - Returns: A transformed ``Grammar``.
  public func homomorphed(_ terminal: Terminal, to replacement: Terminal) -> Self {
    self.homomorphMapped { candidate in
      candidate == terminal ? replacement : nil
    }
  }

  private func homomorphed(expression: Expression, transform: (Terminal) -> Terminal?) -> Expression
  {
    switch expression {
    case .epsilon:
      return .epsilon
    case .concat(let expressions):
      return .concat(expressions.map { self.homomorphed(expression: $0, transform: transform) })
    case .choice(let expressions):
      return .choice(expressions.map { self.homomorphed(expression: $0, transform: transform) })
    case .optional(let expression):
      return .optional(self.homomorphed(expression: expression, transform: transform))
    case .`repeat`(let repeatExpr):
      let newRepeat = Repeat(
        min: repeatExpr.min,
        max: repeatExpr.max,
        self.homomorphed(expression: repeatExpr.innerExpression, transform: transform)
      )
      return .`repeat`(newRepeat)
    case .group(let expression):
      return .group(self.homomorphed(expression: expression, transform: transform))
    case .characterGroup(let characterGroup):
      return .characterGroup(characterGroup)
    case .ref(let ref):
      return .ref(ref)
    case .special(let special):
      return .special(special)
    case .terminal(let terminal):
      return transform(terminal).map(Expression.terminal) ?? .terminal(terminal)
    case .custom(let value):
      return .custom(value)
    }
  }
}

// MARK: - Reverse

extension Grammar {
  /// Reverses the order of every reachable terminal sequence in the grammar.
  public mutating func reverse() {
    self = self.reversed()
  }

  /// Returns a grammar that matches the reverse of every string accepted by this grammar.
  ///
  /// - Returns: A reversed ``Grammar``.
  public func reversed() -> Self {
    let reachableSymbols = self.reachableSymbols()
    let statements = self.statements.compactMap { statement -> Statement? in
      switch statement {
      case .rule(let rule):
        guard reachableSymbols.contains(rule.symbol) else { return nil }
        return .rule(Rule(rule.symbol, self.reversed(expression: rule.expression)))
      case .comment, .custom:
        return statement
      }
    }
    return Grammar(startingSymbol: self.startingSymbol, statements)
  }

  private func reachableSymbols() -> Set<Symbol> {
    var visited = Set<Symbol>()
    var stack = [self.startingSymbol]

    while let symbol = stack.popLast() {
      guard visited.insert(symbol).inserted else { continue }
      guard let rule = self.rulesBySymbol[symbol] else { continue }
      stack.append(contentsOf: self.referencedSymbols(in: rule.expression))
    }

    return visited
  }

  private func referencedSymbols(in expression: Expression) -> [Symbol] {
    switch expression {
    case .epsilon:
      []
    case .concat(let expressions), .choice(let expressions):
      expressions.flatMap { self.referencedSymbols(in: $0) }
    case .optional(let expr), .group(let expr):
      self.referencedSymbols(in: expr)
    case .`repeat`(let repeatExpr):
      self.referencedSymbols(in: repeatExpr.innerExpression)
    case .characterGroup:
      []
    case .ref(let ref):
      [ref.symbol]
    case .special:
      []
    case .terminal:
      []
    case .custom:
      []
    }
  }

  private func reversed(expression: Expression) -> Expression {
    switch expression {
    case .epsilon:
      return .epsilon
    case .concat(let expressions):
      return .concat(expressions.reversed().map { self.reversed(expression: $0) })
    case .choice(let expressions):
      return .choice(expressions.map { self.reversed(expression: $0) })
    case .optional(let expr):
      return .optional(self.reversed(expression: expr))
    case .`repeat`(let repeatExpr):
      let newRepeat = Repeat(
        min: repeatExpr.min,
        max: repeatExpr.max,
        self.reversed(expression: repeatExpr.innerExpression)
      )
      return .`repeat`(newRepeat)
    case .group(let expr):
      return .group(self.reversed(expression: expr))
    case .characterGroup(let characterGroup):
      return .characterGroup(characterGroup)
    case .ref(let ref):
      return .ref(ref)
    case .special(let special):
      return .special(special)
    case .terminal(let terminal):
      return .terminal(terminal)
    case .custom(let value):
      return .custom(value)
    }
  }
}

// MARK: - Rules

extension Grammar {
  /// An ordered view over a grammar's statements.
  public struct StatementCollection: RandomAccessCollection, Sendable {
    public typealias Element = Statement
    public typealias Index = Int

    private let orderedStatements: [Statement]

    init(orderedStatements: [Statement]) {
      self.orderedStatements = orderedStatements
    }

    public var startIndex: Int {
      self.orderedStatements.startIndex
    }

    public var endIndex: Int {
      self.orderedStatements.endIndex
    }

    public subscript(position: Int) -> Statement {
      self.orderedStatements[position]
    }
  }

  /// An ordered view over a grammar's rules.
  public struct Rules: RandomAccessCollection, Sendable {
    public typealias Element = Rule
    public typealias Index = Int

    private let orderedSymbols: [Symbol]
    private let rulesBySymbol: [Symbol: Rule]

    init(orderedSymbols: [Symbol], rulesBySymbol: [Symbol: Rule]) {
      self.orderedSymbols = orderedSymbols
      self.rulesBySymbol = rulesBySymbol
    }

    public var startIndex: Int {
      self.orderedSymbols.startIndex
    }

    public var endIndex: Int {
      self.orderedSymbols.endIndex
    }

    public subscript(position: Int) -> Rule {
      self.rulesBySymbol[self.orderedSymbols[position]]!
    }

    /// Accesses a rule by its symbol.
    public subscript(symbol: Symbol) -> Rule? {
      self.rulesBySymbol[symbol]
    }
  }
}
