import ApplicationServices
import Testing

@testable import MAAccessibility

@Suite("AXFailure")
struct AXFailureTests {
    @Test("Maps known AXError values to readable names")
    func errorNames() {
        #expect(AXFailure.name(for: .success) == "success")
        #expect(AXFailure.name(for: .cannotComplete) == "cannotComplete")
        #expect(AXFailure.name(for: .attributeUnsupported) == "attributeUnsupported")
        #expect(AXFailure.name(for: .apiDisabled) == "apiDisabled")
    }

    @Test("Description includes the error name")
    func description() {
        #expect(AXFailure.notFound.description == "AXFailure.notFound")
        #expect(AXFailure.timeout.description == "AXFailure.timeout")
        #expect(AXFailure.apiError(.cannotComplete).description.contains("cannotComplete"))
    }

    @Test("Equatable by case and payload")
    func equatable() {
        #expect(AXFailure.apiError(.success) == AXFailure.apiError(.success))
        #expect(AXFailure.apiError(.success) != AXFailure.apiError(.failure))
        #expect(AXFailure.notFound != AXFailure.timeout)
    }
}
