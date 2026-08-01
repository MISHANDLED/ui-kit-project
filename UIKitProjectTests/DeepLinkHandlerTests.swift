//
//  DeepLinkHandlerTests.swift
//  UIKitProjectTests
//

import XCTest
@testable import UIKitProject

final class DeepLinkHandlerTests: XCTestCase {
    private let handler = DeepLinkHandler(
        customScheme: "uikitproject",
        universalLinkHosts: ["links.example.com"]
    )

    func testCustomSchemeMapsToRoute() throws {
        let url = try XCTUnwrap(URL(string: "uikitproject://open/pan"))

        XCTAssertEqual(handler.route(from: url), .panGesture)
    }

    func testPageDeepLinkParsesIndex() throws {
        let url = try XCTUnwrap(URL(string: "uikitproject://open/pages?index=12"))

        XCTAssertEqual(handler.route(from: url), .page(index: 12))
    }

    func testPageDeepLinkRejectsInvalidIndex() throws {
        let url = try XCTUnwrap(URL(string: "uikitproject://open/pages?index=-1"))

        XCTAssertNil(handler.route(from: url))
    }

    func testUniversalLinkFromAllowedHostMapsToRoute() throws {
        let url = try XCTUnwrap(URL(string: "https://links.example.com/open/date-picker"))

        XCTAssertEqual(handler.route(from: url), .datePicker)
    }

    func testUniversalLinkFromUnknownHostIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "https://malicious.example/open/date-picker"))

        XCTAssertNil(handler.route(from: url))
    }

    func testUnknownDestinationIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "uikitproject://open/unknown"))

        XCTAssertNil(handler.route(from: url))
    }
}
