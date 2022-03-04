//
//  0 - SimpleFSMTests.swift
//  
//
//  Created by Stef MILLET on 01/03/2022.
//

import XCTest
@testable import MSFSM



class SimpleFSMTests: XCTestCase {

    //
    //  This is testing 90% of the package, just with:
    //  1   -   A very simple FSM test
    //  2   -   Testing the state callbakcs
    //
    
    enum State: Int, FSMState {
        case healthy, wounded, dead
    }

    enum Event: Int, FSMEvent {
        case hit, severeHit, shout, heal
    }

    func testVerySimpleFSM() throws {
        
        //
        //  Demonstration of the declarative syntax
        //
        let fsm = SimplestFSM<State, Event>()
            .initial(.healthy)
                .on(.hit)           { _,_,_ in return .wounded }
                .on(.severeHit)     { _,_,_ in return .dead }
            .state(.wounded)
                .on(.hit)           { _,_,_ in return .dead }
                .on(.severeHit)     { _,_,_ in return .dead }
                .on(.heal)          { _,_,_ in return .healthy }
            .state(.dead)
        fsm.activate()
        
        //  Test initial state
        XCTAssert(fsm.state == .healthy)
        
        //  Test wrong event
        fsm.process(event: .heal)
        let _ = fsm.update(time: 0)
        XCTAssert(fsm.state == .healthy)

        //  Test good event
        fsm.process(event: .hit)
        XCTAssert(fsm.state == .wounded)
        
        //  Deactivate
        fsm.deactivate()
        XCTAssert(fsm.state == nil)
    }

    
    
    func testSimpleFSMWithCallbacks() throws {
        
        class Info {
            var hasEnteredHealthy   = false
            var hasEnteredWounded   = false
            var hasEnteredDead      = false
            var hasUpdatedHealthy   = false
            var hasUpdatedWounded   = false
            var hasUpdatedDead      = false
            var hasLeftHealthy      = false
            var hasLeftWounded      = false
            var hasLeftDead         = false
            var hasShouted          = false
        }
        let info = Info()

        let fsm = SimpleFSM<State, Info, Event>()
            .initial(.healthy)
                .willLeave          { _,info in info.hasLeftHealthy = true }
                .on(.hit)           { _,_,_ in return .wounded }
                .on(.severeHit)     { _,_,_ in return .dead }
            .state(.wounded)
                .update             { _,_,info in info.hasUpdatedWounded = true ; return nil }
                .on(.hit)           { _,_,_ in return .dead }
                .on(.severeHit)     { _,_,_ in return .dead }
                .on(.heal)          { _,_,_ in return .healthy }
                .exec(.shout)       { _,_,info in info.hasShouted = true }
            .state(.dead)
                .didEnter           { _,info in info.hasEnteredDead = true }
        fsm.activate(info: info)
        
        //  Test initial state
        XCTAssert(fsm.state == .healthy)
        
        //  Test wrong event
        XCTAssert(info.hasLeftHealthy == false)
        fsm.process(event: .heal, info: info)
        XCTAssert(fsm.state == .healthy)
        XCTAssert(info.hasLeftHealthy == false)

        //  Test good event
        XCTAssert(info.hasUpdatedWounded == false)
        XCTAssert(info.hasShouted == false)
        fsm.process(event: .hit, info: info)
        fsm.process(event: .shout, info: info)
        let _ = fsm.update(time: 0, info: info)
        XCTAssert(fsm.state == .wounded)
        XCTAssert(info.hasLeftHealthy == true)
        XCTAssert(info.hasUpdatedWounded == true)
        XCTAssert(info.hasShouted == true)
        
        //  Kill !
        XCTAssert(info.hasEnteredDead == false)
        fsm.process(event: .hit, info: info)
        XCTAssert(fsm.state == .dead)
        XCTAssert(info.hasEnteredDead == true)

        //  Deactivate
        fsm.deactivate(info: info)
        XCTAssert(fsm.state == nil)
    }
}
