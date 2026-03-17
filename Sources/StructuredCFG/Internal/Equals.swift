func equals(_ lhs: any Equatable, _ rhs: any Equatable) -> Bool {
  _equals(lhs, rhs)
}

private func _equals<T: Equatable>(_ lhs: T, _ rhs: any Equatable) -> Bool {
  lhs == (rhs as? T)
}
