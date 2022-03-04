//
//  HFSMTests.swift
//  
//
//  Created by Stef MILLET on 02/03/2022.
//

import XCTest
@testable import MSFSM



//  First, define the structure of the sub-FSM - very simple
enum SleepingState: FSMState {
    case awaken, asleep
}

enum SleepingEvent: FSMEvent {
    case awake, goToSleep
}

let sleepingFSMStructure = FSMStructure<SleepingState, Void, SleepingEvent>()
    .memory(.asleep)
        .on(.awake)     { _,_,_ in return .awaken }
    .state(.awaken)
        .on(.goToSleep) { _,_,_ in return .asleep }



//  Then define, the father FSM


//  Let's define a state with an enum. One of the case will have an associated value that is a BindableFSM
//  with the sleepingFSMStructure structure.
//  As explained above, we make sure that only the static part is taken into account for hashin and comparison
enum HealthState: FSMState {
    case dead
    case alive(BindableFSM<SleepingState, Void, SleepingEvent>)

    static let alive: HealthState = .alive(BindableFSM(structure: sleepingFSMStructure))

    //  Make sure that only the static part is taken into account for hashing and comparison
    //  i.e. remove the value from == and hash
    static func == (lhs: HealthState, rhs: HealthState) -> Bool {
        switch (lhs, rhs) {
        case    (.dead, .dead),
                (.alive, .alive):
            return true
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .dead:     hasher.combine(0)
        case .alive:    hasher.combine(1)
        }
    }
}

//  We do the same with an event that is holding information (for the multi-ending-state transition)
//  See above if you missed that
enum HealthEvent: FSMEvent {
    case heal(Int), hit(Int)
    case awake, goToSleep

    static let heal: HealthEvent   = .heal(0)
    static let hit: HealthEvent    = .hit(0)

    //  Make sure that only the static part is taken into account for hashing and comparison
    //  i.e. remove the value from == and hash
    static func == (lhs: HealthEvent, rhs: HealthEvent) -> Bool {
        switch (lhs, rhs) {
        case    (.heal, .heal),
                (.hit, .hit),
                (.awake, .awake),
                (.goToSleep, .goToSleep):
            return true
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .heal: hasher.combine(0)
        case .hit:  hasher.combine(1)
        case .awake:  hasher.combine(2)
        case .goToSleep:  hasher.combine(3)
        }
    }
    
}


//  The FSM will have to be binded to two states, one for each level of the FSM. The first level state
//  (alive/dead) will be provided by the binder. We'll bind the second state via the info parameters
//  Let's define a protocol for that info parameter

protocol SleepStateBinderProvider {
    var sleepStatusBinder: AnyStateBinder<SleepingState>! { get }
}



//  The FSM structure will then be defined as follows.
//  We use the states callbacks. When entering/leaving the alive state, we activate/deactivate the subFSM
//  And we don't forget to forward sleep/awake events to teh sub FSM in our execution callacks on alive state
let healthFSMStructure = FSMStructure<HealthState, SleepStateBinderProvider & HealthHolder, HealthEvent>()
    .initial(.alive)
        .didEnter       { binder,info in
            let aliveState  = binder.state!
            if case let .alive(subFsm) = aliveState {
                subFsm.activate(binder: info.sleepStatusBinder!)
            }
        }
        .willLeave      { binder,info in
            let aliveState  = binder.state!
            if case let .alive(subFsm) = aliveState {
                subFsm.deactivate(binder: info.sleepStatusBinder!)
            }
        }
        .on(.hit)       { event,_,healthHolder in
            if case let .hit(hitValue) = event {
                healthHolder.health -= hitValue
                if healthHolder.health <= 0 {
                    return .dead
                }
            }
            return .alive
        }
        .exec(.heal)          { event,_,healthHolder in
            if case let .heal(healValue) = event {
                healthHolder.health += healValue
            }
        }
        .exec(.goToSleep) { _,binder,info in
            let aliveState  = binder.state!
            if case let .alive(subFsm) = aliveState {
                subFsm.process(event: .goToSleep, binder: info.sleepStatusBinder!)
            }
        }
        .exec(.awake) { _,binder,info in
            let aliveState  = binder.state!
            if case let .alive(subFsm) = aliveState {
                subFsm.process(event: .awake, binder: info.sleepStatusBinder!)
            }
        }
    .state(.dead)



class HFSM: XCTestCase {

    class Character: SleepStateBinderProvider & HealthHolder {
        var health: Int
        
        var healthState:        HealthState?
        var healthStatusBinder: AnyStateBinder<HealthState>!

        var sleepState:         SleepingState?
        var sleepStateMemory:   SleepingState?
        var sleepStatusBinder:  AnyStateBinder<SleepingState>!

        let fsm:                BindableFSM<HealthState, SleepStateBinderProvider & HealthHolder, HealthEvent>
        
        init() {
            self.health = 100
            self.fsm    = BindableFSM(structure: healthFSMStructure)
            self.healthStatusBinder  = AnyStateBinder(getClosure:   { self.healthState },
                                                      setClosure:   { newValue in self.healthState = newValue })
            self.sleepStatusBinder   = AnyStateBinder(getClosure:   { self.sleepState },
                                                      setClosure:   { newValue in self.sleepState = newValue },
                                                      getMClosure:  { self.sleepStateMemory },
                                                      setMClosure:  { newValue in self.sleepStateMemory = newValue })
        }
    }
    
    func testHFSM() throws {
        
        let character   = Character()
        
        XCTAssert(character.healthState == nil)
        XCTAssert(character.sleepState == nil)
        XCTAssert(character.health == 100)
        
        character.fsm.activate(binder: character.healthStatusBinder, info: character)
        XCTAssert(character.healthState == .alive)
        XCTAssert(character.sleepState == .asleep)
        XCTAssert(character.health == 100)

        character.fsm.process(event: .heal(10), binder: character.healthStatusBinder, info: character)
        XCTAssert(character.healthState == .alive)
        XCTAssert(character.sleepState == .asleep)
        XCTAssert(character.health == 110)

        character.fsm.process(event: .hit(50), binder: character.healthStatusBinder, info: character)
        XCTAssert(character.healthState == .alive)
        XCTAssert(character.sleepState == .asleep)
        XCTAssert(character.health == 60)

        character.fsm.process(event: .awake, binder: character.healthStatusBinder, info: character)
        XCTAssert(character.healthState == .alive)
        XCTAssert(character.sleepState == .awaken)
        XCTAssert(character.health == 60)

        character.fsm.process(event: .hit(40), binder: character.healthStatusBinder, info: character)
        XCTAssert(character.healthState == .alive)
        XCTAssert(character.sleepState == .awaken)
        XCTAssert(character.health == 20)

        character.fsm.process(event: .hit(40), binder: character.healthStatusBinder, info: character)
        XCTAssert(character.healthState == .dead)
        XCTAssert(character.sleepState == nil)
        XCTAssert(character.health == -20)
    }
}
