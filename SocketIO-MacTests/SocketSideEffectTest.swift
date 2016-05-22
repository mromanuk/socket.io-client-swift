//
//  SocketSideEffectTest.swift
//  Socket.IO-Client-Swift
//
//  Created by Erik Little on 10/11/15.
//
//

import XCTest
@testable import SocketIOClientSwift

class SocketSideEffectTest: XCTestCase {
    let data = "test".data(using: NSUTF8StringEncoding)!
    let data2 = "test2".data(using: NSUTF8StringEncoding)!
    private var socket: SocketIOClient!
    
    override func setUp() {
        super.setUp()
        socket = SocketIOClient(socketURL: NSURL())
        socket.setTestable()
    }
    
    func testInitialCurrentAck() {
        XCTAssertEqual(socket.currentAck, -1)
    }
    
    func testFirstAck() {
        socket.emitWithAck("test")(timeoutAfter: 0) {data in}
        XCTAssertEqual(socket.currentAck, 0)
    }
    
    func testSecondAck() {
        socket.emitWithAck("test")(timeoutAfter: 0) {data in}
        socket.emitWithAck("test")(timeoutAfter: 0) {data in}
        
        XCTAssertEqual(socket.currentAck, 1)
    }
    
    func testHandleAck() {
        let expect = expectation(withDescription: "handled ack")
        socket.emitWithAck("test")(timeoutAfter: 0) {data in
            XCTAssertEqual(data[0] as? String, "hello world")
            expect.fulfill()
        }
        
        socket.parseSocketMessage("30[\"hello world\"]")
        waitForExpectations(withTimeout: 3, handler: nil)
    }
    
    func testHandleAck2() {
        let expect = expectation(withDescription: "handled ack2")
        socket.emitWithAck("test")(timeoutAfter: 0) {data in
            XCTAssertTrue(data.count == 2, "Wrong number of ack items")
            expect.fulfill()
        }
        
        socket.parseSocketMessage("61-0[{\"_placeholder\":true,\"num\":0},{\"test\":true}]")
        socket.parseBinaryData(NSData())
        waitForExpectations(withTimeout: 3, handler: nil)
    }
    
    func testHandleEvent() {
        let expect = expectation(withDescription: "handled event")
        socket.on("test") {data, ack in
            XCTAssertEqual(data[0] as? String, "hello world")
            expect.fulfill()
        }
        
        socket.parseSocketMessage("2[\"test\",\"hello world\"]")
        waitForExpectations(withTimeout: 3, handler: nil)
    }
    
    func testHandleStringEventWithQuotes() {
        let expect = expectation(withDescription: "handled event")
        socket.on("test") {data, ack in
            XCTAssertEqual(data[0] as? String, "\"hello world\"")
            expect.fulfill()
        }
        
        socket.parseSocketMessage("2[\"test\",\"\\\"hello world\\\"\"]")
        waitForExpectations(withTimeout: 3, handler: nil)
    }
    
    func testHandleOnceEvent() {
        let expect = expectation(withDescription: "handled event")
        socket.once(event: "test") {data, ack in
            XCTAssertEqual(data[0] as? String, "hello world")
            XCTAssertEqual(self.socket.testHandlers.count, 0)
            expect.fulfill()
        }
        
        socket.parseSocketMessage("2[\"test\",\"hello world\"]")
        waitForExpectations(withTimeout: 3, handler: nil)
    }
    
    func testOffWithEvent() {
        socket.on("test") {data, ack in }
        XCTAssertEqual(socket.testHandlers.count, 1)
        socket.on("test") {data, ack in }
        XCTAssertEqual(socket.testHandlers.count, 2)
        socket.off(event: "test")
        XCTAssertEqual(socket.testHandlers.count, 0)
    }
    
    func testOffWithId() {
        let handler = socket.on("test") {data, ack in }
        XCTAssertEqual(socket.testHandlers.count, 1)
        socket.on("test") {data, ack in }
        XCTAssertEqual(socket.testHandlers.count, 2)
        socket.off(id: handler)
        XCTAssertEqual(socket.testHandlers.count, 1)
    }
    
    func testHandlesErrorPacket() {
        let expect = expectation(withDescription: "Handled error")
        socket.on("error") {data, ack in
            if let error = data[0] as? String where error == "test error" {
                expect.fulfill()
            }
        }
        
        socket.parseSocketMessage("4\"test error\"")
        waitForExpectations(withTimeout: 3, handler: nil)
    }
    
    func testHandleBinaryEvent() {
        let expect = expectation(withDescription: "handled binary event")
        socket.on("test") {data, ack in
            if let dict = data[0] as? NSDictionary, data = dict["test"] as? NSData {
                XCTAssertEqual(data, self.data)
                expect.fulfill()
            }
        }
        
        socket.parseSocketMessage("51-[\"test\",{\"test\":{\"_placeholder\":true,\"num\":0}}]")
        socket.parseBinaryData(data)
        waitForExpectations(withTimeout: 3, handler: nil)
    }
    
    func testSocketDataToAnyObject() {
        let data = ["test", 1, 2.2, ["Hello": 2, "bob": 2.2], true, [1, 2], [1.1, 2]] as [SocketData]
        
        XCTAssertEqual(data.count, socket.socketDataToAnyObject(data: data).count)
    }
    
    func testHandleMultipleBinaryEvent() {
        let expect = expectation(withDescription: "handled multiple binary event")
        socket.on("test") {data, ack in
            if let dict = data[0] as? NSDictionary, data = dict["test"] as? NSData,
                data2 = dict["test2"] as? NSData {
                    XCTAssertEqual(data, self.data)
                    XCTAssertEqual(data2, self.data2)
                    expect.fulfill()
            }
        }
        
        socket.parseSocketMessage("52-[\"test\",{\"test\":{\"_placeholder\":true,\"num\":0},\"test2\":{\"_placeholder\":true,\"num\":1}}]")
        socket.parseBinaryData(data)
        socket.parseBinaryData(data2)
        waitForExpectations(withTimeout: 3, handler: nil)
    }
}
