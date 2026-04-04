enum UnicodeHelpers {
  static func gbnfUnicodeEscape(for scalar: Unicode.Scalar) -> String {
    if scalar.value <= 0xFFFF {
      return "\\u" + paddedHexString(scalar.value, length: 4)
    }
    return "\\U" + paddedHexString(scalar.value, length: 8)
  }

  static func paddedHexString(_ value: UInt32) -> String {
    paddedHexString(value, length: 8)
  }

  static func paddedHexString(_ value: UInt32, length: Int) -> String {
    let hex = String(value, radix: 16).uppercased()
    let padding = String(repeating: "0", count: length - hex.count)
    return padding + hex
  }
}
