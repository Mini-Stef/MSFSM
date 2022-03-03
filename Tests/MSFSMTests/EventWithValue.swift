//
//  EventWithValue.swift
//  
//
//  Created by Stef MILLET on 02/03/2022.
//

import XCTest
@testable import MSFSM





protocol HasHealth: AnyObject {
    var health: Int { get set }
}

class EventWithValue: XCTestCase {


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

    //  Define a character that has a health
    class Character: HasHealth, StateBinder {
        var state: State?
        var health: Int  = 100
    }


    static let fsmStructure = FSMStructure<Character, Void, Event>()
        .initial(.alive)
            .on(.hit)        { event,character,_ in
                character.health -= event.value
                if character.health <= 0 {
                    return .dead
                }
                return .alive
            }
            .on(.heal)          { event,character,_ in
                character.health += event.value
                return .alive
            }
        .state(.dead)

    
    
    
    func testEventWithValueFSM() throws {
        
        let character = Character()
        
        let fsm = BindableFSM<Character, Void, Event>(structure: EventWithValue.fsmStructure)
        
        //  Test initial state
        XCTAssert(character.state == nil)
        fsm.activate(binder: character)
        XCTAssert(character.state == .alive)

        //  Test first hit
        fsm.process(event: Event(label: .hit, value: 70), binder: character)
        XCTAssert(character.state == .alive)
        XCTAssert(character.health == 30)

        //  Test heal
        fsm.process(event: Event(label: .heal, value: 10), binder: character)
        XCTAssert(character.state == .alive)
        XCTAssert(character.health == 40)

        //  Kill !
        fsm.process(event: Event(label: .hit, value: 70), binder: character)
        XCTAssert(character.state == .dead)
    }

}
