//
//  1 - StateSeparationTest.swift
//  
//
//  Created by Stef MILLET on 02/03/2022.
//

import XCTest
@testable import MSFSM




class StateSeparationTest: XCTestCase {
    
    //
    //  Demonstration of state separation. I want to show a class that has a 'state' property, and this property is
    //  ruled by an FSM
    //
    
    enum State: Int, FSMState {
        case healthy, wounded, dead
    }

    enum Event: Int, FSMEvent {
        case hit, severeHit, heal
    }

    static let healthFSMStructure  = FSMStructure<State, Void, Event>()
        .initial(.healthy)
            .on(.hit)           { _,_,_,_ in return .wounded }
            .on(.severeHit)     { _,_,_,_ in return .dead }
        .state(.wounded)
            .on(.hit)           { _,_,_,_ in return .dead }
            .on(.severeHit)     { _,_,_,_ in return .dead }
            .on(.heal)          { _,_,_,_ in return .healthy }
        .state(.dead)

    class MyClass: StateBinder {
        
        var state:  State?
        
        //  Because MyClass conforms to StateBinder, when an event changes the state of the FSM, the
        //  `state`property will be modified
        let fsm:    BindableFSM<State, Void, Event>
        
        init() {
            self.fsm = BindableFSM(structure: healthFSMStructure)
        }
    }

    func testBindableFSM() throws {
        
        let myClass = MyClass()
        
        //  Test initial state
        XCTAssert(myClass.state == nil)
        myClass.fsm.activate(time: 0, binder: AnyStateBinder(myClass))
        XCTAssert(myClass.state == .healthy)

        //  Test wrong event
        myClass.fsm.process(event: .heal, time: 0, binder: AnyStateBinder(myClass))
        let _ = myClass.fsm.update(time: 0, binder: AnyStateBinder(myClass))
        XCTAssert(myClass.state == .healthy)

        //  Test good event
        myClass.fsm.process(event: .hit, time: 0, binder: AnyStateBinder(myClass))
        XCTAssert(myClass.state == .wounded)
        
        //  Deactivate
        myClass.fsm.deactivate(time: 0, binder: AnyStateBinder(myClass))
        XCTAssert(myClass.state == nil)
    }
}









class StateSeparationTest2: XCTestCase {

    //
    //  Demonstration of state separation, on a property with a different name
    //

    enum State: Int, FSMState {
        case healthy, wounded, dead
    }

    enum Event: Int, FSMEvent {
        case hit, severeHit, heal
    }

    static let healthFSMStructure  = FSMStructure<State, Void, Event>()
        .initial(.healthy)
            .on(.hit)           { _,_,_,_ in return .wounded }
            .on(.severeHit)     { _,_,_,_ in return .dead }
        .state(.wounded)
            .on(.hit)           { _,_,_,_ in return .dead }
            .on(.severeHit)     { _,_,_,_ in return .dead }
            .on(.heal)          { _,_,_,_ in return .healthy }
        .state(.dead)


    class MyClass {
        
        var healthStatus: State?
        
        //  Add a state binder that takes care about indirection between FSM State and 'healthStatus' instead of 'state'
        var healthStatusBinder: AnyStateBinder<State>!
        
        let fsm:    BindableFSM<State, Void, Event>
        
        init() {
            self.fsm = BindableFSM(structure: healthFSMStructure)
            self.healthStatusBinder  = AnyStateBinder(getClosure:   { self.healthStatus },
                                                      setClosure:   { newValue in self.healthStatus = newValue })
        }
    }


    func testOtherPropertyBindingFSM() throws {
        
        let myClass = MyClass()
        
        //  Test initial state
        XCTAssert(myClass.healthStatus == nil)
        myClass.fsm.activate(time: 0, binder: AnyStateBinder(myClass.healthStatusBinder))
        XCTAssert(myClass.healthStatus == .healthy)

        //  Test wrong event
        myClass.fsm.process(event: .heal, time: 0, binder: AnyStateBinder(myClass.healthStatusBinder))
        let _ = myClass.fsm.update(time: 0, binder: AnyStateBinder(myClass.healthStatusBinder))
        XCTAssert(myClass.healthStatus == .healthy)

        //  Test good event
        myClass.fsm.process(event: .hit, time: 0, binder: AnyStateBinder(myClass.healthStatusBinder))
        XCTAssert(myClass.healthStatus == .wounded)
        
        //  Deactivate
        myClass.fsm.deactivate(time: 0, binder: AnyStateBinder(myClass.healthStatusBinder))
        XCTAssert(myClass.healthStatus == nil)
    }

}
