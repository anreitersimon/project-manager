import XCTest
@testable import ExampleUIKit
@testable import Core

class ExampleUIKitTests: XCTestCase {

    func testDescription() {
        print(ExampleUIKitDescription.features)
    }

	func testCoreResources() {
		let _ = CoreDescription.resources
	}
}