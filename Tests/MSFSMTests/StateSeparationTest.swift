//
//  StateSeparationTest.swift
//  
//
//  Created by Stef MILLET on 02/03/2022.
//

import XCTest
@testable import MSFSM




class StateSeparationTest: XCTestCase {
    
    enum State: Int, FSMState {
        case healthy, wounded, dead
    }

    enum Event: Int, FSMEvent {
        case hit, severeHit, heal
    }

    static let healthFSMStructure  = FSMStructure<MyClass, Void, Event>()
        .initial(.healthy)
            .on(.hit)           { _,_,_ in return .wounded }
            .on(.severeHit)     { _,_,_ in return .dead }
        .state(.wounded)
            .on(.hit)           { _,_,_ in return .dead }
            .on(.severeHit)     { _,_,_ in return .dead }
            .on(.heal)          { _,_,_ in return .healthy }
        .state(.dead)

    class MyClass: StateBinder {
        
        var state:  State?
        
        //  Because MyClass conforms to StateBinder, when an event changes the state of the FSM, the
        //  `state`property will be modified
        let fsm:    BindableFSM<MyClass, Void, Event>
        
        init() {
            self.fsm = BindableFSM(structure: healthFSMStructure)
        }
    }

    func testBindableFSM() throws {
        
        let myClass = MyClass()
        
        //  Test initial state
        XCTAssert(myClass.state == nil)
        myClass.fsm.activate(binder: myClass)
        XCTAssert(myClass.state == .healthy)

        //  Test wrong event
        myClass.fsm.process(event: .heal, binder: myClass)
        let _ = myClass.fsm.update(time: 0, binder: myClass)
        XCTAssert(myClass.state == .healthy)

        //  Test good event
        myClass.fsm.process(event: .hit, binder: myClass)
        XCTAssert(myClass.state == .wounded)
        
        //  Deactivate
        myClass.fsm.deactivate(binder: myClass)
        XCTAssert(myClass.state == nil)
    }
}






enum State: Int, FSMState {
    case healthy, wounded, dead
}

enum Event: Int, FSMEvent {
    case hit, severeHit, heal
}

protocol HasHealthStatus: AnyObject {
    var healthStatus: State? { get set }
}

class HealthStatusBinder: StateBinder {
    weak var bindedHealthStatusHolder: HasHealthStatus!
    
    var state: State? {
        get { bindedHealthStatusHolder.healthStatus }
        set { bindedHealthStatusHolder.healthStatus = newValue }
    }
    
    init(bindedHealthStatusHolder: HasHealthStatus) {
        self.bindedHealthStatusHolder = bindedHealthStatusHolder
    }
}


class StateSeparationTest2: XCTestCase {

    static let healthFSMStructure  = FSMStructure<HealthStatusBinder, Void, Event>()
        .initial(.healthy)
            .on(.hit)           { _,_,_ in return .wounded }
            .on(.severeHit)     { _,_,_ in return .dead }
        .state(.wounded)
            .on(.hit)           { _,_,_ in return .dead }
            .on(.severeHit)     { _,_,_ in return .dead }
            .on(.heal)          { _,_,_ in return .healthy }
        .state(.dead)

    class HumanWarrior: HasHealthStatus {
        
        var healthStatus: State?
        var healthStatusBinder: HealthStatusBinder!

        let fsm:    BindableFSM<HealthStatusBinder, Void, Event>
        
        init() {
            self.fsm = BindableFSM(structure: healthFSMStructure)
            self.healthStatusBinder = HealthStatusBinder(bindedHealthStatusHolder: self)
        }
    }


    func testOtherPropertyBindingFSM() throws {
        
        let myClass = HumanWarrior()
        
        //  Test initial state
        XCTAssert(myClass.healthStatus == nil)
        myClass.fsm.activate(binder: myClass.healthStatusBinder)
        XCTAssert(myClass.healthStatus == .healthy)

        //  Test wrong event
        myClass.fsm.process(event: .heal, binder: myClass.healthStatusBinder)
        let _ = myClass.fsm.update(time: 0, binder: myClass.healthStatusBinder)
        XCTAssert(myClass.healthStatus == .healthy)

        //  Test good event
        myClass.fsm.process(event: .hit, binder: myClass.healthStatusBinder)
        XCTAssert(myClass.healthStatus == .wounded)
        
        //  Deactivate
        myClass.fsm.deactivate(binder: myClass.healthStatusBinder)
        XCTAssert(myClass.healthStatus == nil)
    }

}
