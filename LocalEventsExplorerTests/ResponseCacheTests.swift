@testable import LocalEventsExplorer
import XCTest

final class ResponseCacheTests: XCTestCase {
    func testValueReturnedWithinTTL() async {
        let cache = ResponseCache(ttl: 10)
        let data = Data("test".utf8)

        await cache.setValue(data, forKey: "key")
        let result = await cache.value(forKey: "key")

        XCTAssertEqual(result, data)
    }

    func testValueTreatedAsMissAfterTTL() async throws {
        let cache = ResponseCache(ttl: 0.1)
        let data = Data("test".utf8)

        await cache.setValue(data, forKey: "key")

        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s

        let result = await cache.value(forKey: "key")
        XCTAssertNil(result)
    }

    func testDifferentKeysAreIndependent() async {
        let cache = ResponseCache(ttl: 10)
        let data1 = Data("one".utf8)
        let data2 = Data("two".utf8)

        await cache.setValue(data1, forKey: "a")
        await cache.setValue(data2, forKey: "b")

        let resultA = await cache.value(forKey: "a")
        let resultB = await cache.value(forKey: "b")
        XCTAssertEqual(resultA, data1)
        XCTAssertEqual(resultB, data2)
    }

    func testRemoveAllClearsCache() async {
        let cache = ResponseCache(ttl: 10)
        await cache.setValue(Data("x".utf8), forKey: "key")

        await cache.removeAll()

        let result = await cache.value(forKey: "key")
        XCTAssertNil(result)
    }
}
