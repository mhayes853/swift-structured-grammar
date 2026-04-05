import CustomDump
import StructuredCFG
import Testing

#if canImport(XGrammar)
@Suite
struct `JSONLanguage tests` {
  @Test(arguments: Self.validPayloads)
  func `Matcher Accepts Valid JSON Payloads`(payload: String) async throws {
    let matches = try await XGrammarTestSupport.matches(payload, language: JSON().language)

    expectNoDifference(matches, true)
  }

  @Test(arguments: Self.validObjectPayloads)
  func `Matcher Should Accept Valid JSON Object Payloads`(payload: String) async throws {
    let matches = try await XGrammarTestSupport.matches(payload, language: JSON().language)

    expectNoDifference(matches, true)
  }

  @Test
  func `Matcher Accepts Simple Object Regression Payload`() async throws {
    let payload = #"{"a":1}"#

    let matches = try await XGrammarTestSupport.matches(payload, language: JSON().language)

    expectNoDifference(matches, true)
  }

  @Test
  func `Matcher Accepts Nested Object Regression Payload`() async throws {
    let payload = #"{"a":["b"],"meta":{"ok":true}}"#

    let matches = try await XGrammarTestSupport.matches(payload, language: JSON().language)

    expectNoDifference(matches, true)
  }

  @Test
  func `Matcher Accepts Escaped Slash Regression Payload`() async throws {
    let payload = #"{"url":"https:\/\/example.com\/a\/b"}"#

    let matches = try await XGrammarTestSupport.matches(payload, language: JSON().language)

    expectNoDifference(matches, true)
  }

  @Test(arguments: Self.invalidPayloads)
  func `Matcher Rejects Invalid JSON Payloads`(payload: String) async throws {
    let matches = try await XGrammarTestSupport.matches(payload, language: JSON().language)

    expectNoDifference(matches, false)
  }

  @Test
  func `Matcher Respects ASCII Only Mode For Raw Unicode`() async throws {
    let unicodePayload = """
      {"message":"Héllo"}
      """
    let escapedPayload = """
      {"message":"H\\u00E9llo"}
      """

    let defaultUnicodeMatches = try await XGrammarTestSupport.matches(
      unicodePayload,
      language: JSON().language
    )
    let asciiUnicodeMatches = try await Self.matches(
      unicodePayload,
      with: JSON(asciiOnly: true)
    )
    let defaultEscapedMatches = try await XGrammarTestSupport.matches(
      escapedPayload,
      language: JSON().language
    )
    let asciiEscapedMatches = try await Self.matches(
      escapedPayload,
      with: JSON(asciiOnly: true)
    )

    expectNoDifference(defaultUnicodeMatches, true)
    expectNoDifference(defaultEscapedMatches, true)
    expectNoDifference(asciiEscapedMatches, true)
    expectNoDifference(asciiUnicodeMatches, false)
  }

  private static let validPayloads = [
    "[]",
    "[1,2,3]",
    "[1,true,null]"
  ]

  private static let validObjectPayloads = [
    "{}",
    "{\"name\":\"value\"}",
    "{\"escaped\":\"line\\n\\u0041\"}",
    "{\"url\":\"https:\\/\\/example.com\\/a\\/b\"}",
    "{\"items\":[1,true,null,{\"a\":\"b\"}],\"active\":false}",
    """
    {
      "data": {
        "id": "usr_123",
        "type": "user",
        "attributes": {
          "name": "Taylor",
          "email": "taylor@example.com",
          "active": true,
          "roles": ["admin", "editor"],
          "profile": {
            "age": 34,
            "locale": "en-US",
            "lastLogin": "2026-03-20T10:15:30Z"
          }
        }
      },
      "meta": {
        "requestId": "req_456",
        "page": 1,
        "hasMore": false
      }
    }
    """
  ]

  private static let invalidPayloads = [
    "{",
    "[1,]",
    #"{"a":}"#,
    #"{"a" 1}"#,
    #"{"a":01}"#,
    "true",
    "42",
    #""hello""#,
    """
    {
      "data": {
        "id": "usr_123",
        "type": "user",
        "attributes": {
          "name": "Taylor",
          "email": "taylor@example.com",
          "active": true,
          "roles": ["admin", "editor",],
          "profile": {
            "age": 34,
            "locale": "en-US",
            "lastLogin": "2026-03-20T10:15:30Z"
          }
        }
      },
      "meta": {
        "requestId": "req_456",
        "page": 1,
        "hasMore": false
      }
    }
    """
  ]

  private static func matches(_ payload: String, with language: JSON) async throws -> Bool {
    try await XGrammarTestSupport.matches(payload, language: language.language)
  }
}
#endif
