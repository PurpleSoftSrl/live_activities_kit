import Flutter
import UIKit
import XCTest


@testable import live_activities_kit

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testIsSupportedReturnsBool() {
    let plugin = LiveActivitiesPlugin()

    let call = FlutterMethodCall(methodName: "isSupported", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertTrue(result is Bool)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testUnknownMethodReturnsNotImplemented() {
    let plugin = LiveActivitiesPlugin()

    let call = FlutterMethodCall(methodName: "someUnknownMethod", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertTrue((result as AnyObject) === FlutterMethodNotImplemented)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
