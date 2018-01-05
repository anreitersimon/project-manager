import XCTest
@testable import Example
@testable import Core
@testable import ExampleUIKit

class ExampleTests: XCTestCase {

    func testDescription() {
        print(ExampleDescription.features)
    }

	func testCoreResources() {
		let _ = CoreDescription.resources
	}
	func testExampleUIKitResources() {
		let _ = ExampleUIKitDescription.resources
	}
}