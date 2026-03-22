import CustomDump
import StructuredCFG
import Testing
import XGrammar

@Suite
struct `JSONLanguage tests` {
  @Test(arguments: Self.validPayloads)
  func `Matcher Accepts Valid JSON Payloads`(payload: String) async throws {
    let matches = try await Self.matches(payload, with: JSON())

    expectNoDifference(matches, true)
  }

  @Test(arguments: Self.validObjectPayloads)
  func `Matcher Should Accept Valid JSON Object Payloads`(payload: String) async throws {
    let matches = try await Self.matches(payload, with: JSON())

    expectNoDifference(matches, true)
  }

  @Test
  func `Matcher Accepts Simple Object Regression Payload`() async throws {
    let payload = #"{"a":1}"#

    let matches = try await Self.matches(payload, with: JSON())

    expectNoDifference(matches, true)
  }

  @Test
  func `Matcher Accepts Nested Object Regression Payload`() async throws {
    let payload = #"{"a":["b"],"meta":{"ok":true}}"#

    let matches = try await Self.matches(payload, with: JSON())

    expectNoDifference(matches, true)
  }

  @Test(arguments: Self.invalidPayloads)
  func `Matcher Rejects Invalid JSON Payloads`(payload: String) async throws {
    let matches = try await Self.matches(payload, with: JSON())

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

    let defaultUnicodeMatches = try await Self.matches(unicodePayload, with: JSON())
    let asciiUnicodeMatches = try await Self.matches(
      unicodePayload,
      with: JSON(asciiOnly: true)
    )
    let defaultEscapedMatches = try await Self.matches(escapedPayload, with: JSON())
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

  private static func matcher(for language: JSON) async throws -> XGrammar.Grammar.Matcher {
    let grammar = try XGrammar.Grammar(language: language.language)
    return try await grammar.matcher(
      for: XGrammarTestSupport.matcherTokenizer,
      terminatesWithoutStopToken: true
    )
  }

  private static func matches(_ payload: String, with language: JSON) async throws -> Bool {
    let matcher = try await Self.matcher(for: language)

    for token in payload.map(String.init) {
      guard let tokenID = XGrammarTestSupport.matcherTokenIDs[token] else {
        return false
      }
      guard matcher.accept(tokenID) else {
        return false
      }
    }

    return matcher.isTerminated
  }
}
