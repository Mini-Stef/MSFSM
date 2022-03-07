//
//  2 - EventWithValue.swift
//  
//
//  Created by Stef MILLET on 02/03/2022.
//

import XCTest
@testable import MSFSM





protocol HealthHolder: AnyObject {
    var health: Int { get set }
}

class EventWithValueTests: XCTestCase {


    //  Define the states of the FSM
    enum State: FSMState {
        case alive, dead
    }

    //  Define an event that will carry a value. Based on this value, and on the character's health, we will end
    //  up in one state or another
    //
    //  We must make sure that only the static part of the event (i.e. the label, not the value) is considered into
    //  comparisons, so that any hit/heal is considered a hit/heal, whatever the value
    struct Event: FSMEvent {
        enum EventLabel {
            case hit, heal
        }
        let label: EventLabel

        var value: Int
        
        //  Make sure that events are only compared with their static part (the label)
        //  i.e. remove the value from == and hash
        static func == (lhs: Event, rhs: Event) -> Bool {
            return lhs.label == rhs.label
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.label)
            //  Don't add the value !!!
        }
        
        static let hit  = Event(label: .hit,    value: 0)   //  we don't care about the value
        static let heal = Event(label: .heal,   value: 0)   //  we don't care about the value
    }

    static let fsmStructure = FSMStructure<State, HealthHolder, Event>()
        .initial(.alive)
            .on(.hit)        { event,_,_,healthHolder in
                healthHolder.health -= event.value
                if healthHolder.health <= 0 {
                    return .dead
                }
                return .alive
            }
            .on(.heal)          { event,_,_,healthHolder in
                healthHolder.health += event.value
                return .alive
            }
        .state(.dead)

    //  Define a character that has a health
    class Character: HealthHolder, StateBinder {
        var state: State?
        var health: Int  = 100
    }
    
    
    func testEventWithValueFSM() throws {
        
        let character = Character()
        
        let fsm = BindableFSM<State, HealthHolder, Event>(structure: EventWithValueTests.fsmStructure)
        
        //  Test initial state
        XCTAssert(character.state == nil)
        fsm.activate(time: 0, binder: AnyStateBinder(character), info: character)
        XCTAssert(character.state == .alive)

        //  Test first hit
        fsm.process(event: Event(label: .hit, value: 70), time: 0, binder: AnyStateBinder(character), info: character)
        XCTAssert(character.state == .alive)
        XCTAssert(character.health == 30)

        //  Test heal
        fsm.process(event: Event(label: .heal, value: 10), time: 0, binder: AnyStateBinder(character), info: character)
        XCTAssert(character.state == .alive)
        XCTAssert(character.health == 40)

        //  Kill !
        fsm.process(event: Event(label: .hit, value: 70), time: 0, binder: AnyStateBinder(character), info: character)
        XCTAssert(character.state == .dead)
    }

}
