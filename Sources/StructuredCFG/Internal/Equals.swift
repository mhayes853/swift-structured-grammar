func equals(_ lhs: any Hashable, _ rhs: any Hashable) -> Bool {
  _equals(lhs, rhs)
}

private func _equals<T: Hashable>(_ lhs: T, _ rhs: any Hashable) -> Bool {
  lhs == (rhs as? T)
}
