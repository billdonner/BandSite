import XCTest
@testable import BandSite

final class BandSiteTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BandSite().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
