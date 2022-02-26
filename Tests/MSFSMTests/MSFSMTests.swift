import XCTest
@testable import MSFSM





enum SheepEvent: FSMEvent {
    case dogCameNear
    case takeGrazeOrMoveDecision
    case endMove
}

enum SheepNormalSubState: String, FSMState {
    case waiting, grazing, moving
}

enum SheepState: FSMState {
    static func == (lhs: SheepState, rhs: SheepState) -> Bool {
        switch lhs {
        case .afraid:
            switch rhs {
            case .afraid:
                return true
            default:
                return false
            }
        default:
            switch rhs {
            case .afraid:
                return false
            default:
                return true
            }
        }
    }
    
    func hash(into hasher: inout Hasher) {}
    
    case afraid
    case normal(SingleTokenFSM<SheepNormalSubState,Void,SheepEvent>)
}









final class MSFSMTests: XCTestCase {
    
    enum State: String, FSMState {
        case highState, lowState
    }
    
    enum Event: Int, FSMEvent {
        case goToLow, goTohigh
    }

    func testFSMStructureBuilding() throws {
        
        let fsm = FSMStructure<State,Void,Event>()
            .state(.highState)
                .didEnter       { _ in print("Entering High State") }
                .willLeave      { _ in print("Leaving High State") }
                .on(.goToLow)   { _ in print("Going from High to Low") ; return .lowState }
            .state(.lowState)
                .didEnter       { _ in print("Entering Low State") }
                .willLeave      { _ in print("Leaving Low State") }
                .on(.goTohigh)  { _ in print("Going from Low to High") ; return .highState }
        
        let shouldBeLowState    = fsm.at(state: .highState, reactTo: .goToLow)
        XCTAssert(shouldBeLowState == .lowState)
    }
    
    func testFSMSingleTokenBuilding() throws {
        
        let fsm = SingleTokenFSM<State,Void,Event>()
            .state(.highState)
                .didEnter       { _ in print("Entering High State") }
                .willLeave      { _ in print("Leaving High State") }
                .on(.goToLow)   { _ in print("Going from High to Low") ; return .lowState }
            .state(.lowState)
                .didEnter       { _ in print("Entering Low State") }
                .willLeave      { _ in print("Leaving Low State") }
                .on(.goTohigh)  { _ in print("Going from Low to High") ; return .highState }
                .initial(.highState)
        
        fsm.activate()
        let _ = fsm.update(time: 0)
        fsm.process(event: .goToLow)
        
        XCTAssert(fsm.currentState == .lowState)
        
        fsm.deactivate()
    }
    
    
    
    
    
    
    
    
    func testSheepAutomaton() throws {
        
        let sheepSubFSM = SingleTokenFSM<SheepNormalSubState,Void,SheepEvent>()
            .state(.waiting)
                .update { _,_ in
                    print("Choose to graze or move")
                    return .takeGrazeOrMoveDecision
                }
                .on(.takeGrazeOrMoveDecision) { _ in
                    print("I decided to graze")
                    return .grazing  /* should be 50/50 */
                }
            .state(.grazing)
                .didEnter { _ in
                    print("Decide how many seconds to graze, and schedule sheep to think at that time")
                }
                .update { _,_ in
                    print("There is nothing to do, I'm grazing, just wait for thinking time event")
                    return nil
                }
                .on(.takeGrazeOrMoveDecision) { _ in
                    print("I decided to move")
                    return .moving
                }
            .state(.moving)
                .didEnter { _ in
                    print("Decide where to move, and schedule sheep to think at the end of the journey")
                }
                .update { _,_ in
                    print("Update position")
                    return nil
                }
                .willLeave { _ in
                    print("Force end position")
                }
                .on(.endMove) { _ in
                    print("I completed my move, I decide to graze")
                    return .grazing
                }
            .initial(.waiting)

        
        let sheepFsm    = SingleTokenFSM<SheepState,Void,SheepEvent>()
            .state(.normal(sheepSubFSM))
                .didEnter { _ in
                    sheepSubFSM.activate()
                }
                .update { _, time in
                    sheepSubFSM.update(time: time)
                }
                .willLeave { _ in
                    sheepSubFSM.deactivate()
                }
                .on(.dogCameNear) { _ in
                    print("Remove sheep from think scheduler")
                    return .afraid
                }
                .exec(.takeGrazeOrMoveDecision) { _ in
                    sheepSubFSM.process(event: .takeGrazeOrMoveDecision)
                }
                .exec(.endMove) { _ in
                    sheepSubFSM.process(event: .endMove)
                }
            .state(.afraid)
                .didEnter { _ in
                    print("Decide where to run, and schedule sheep to think at the end of the journey")
                }
                .update { _,_ in
                    print("Update position")
                    return nil
                }
                .willLeave { _ in
                    print("Force end position")
                }
                .on(.endMove) { _ in
                    print("I completed my run")
                    return .normal(sheepSubFSM)
                }
            .initial(.normal(sheepSubFSM))
        
        sheepFsm.activate()
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        print("Think time !!!")
        sheepFsm.process(event: .takeGrazeOrMoveDecision)
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        sheepFsm.process(event: .endMove)
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        sheepFsm.process(event: .dogCameNear)
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        sheepFsm.process(event: .takeGrazeOrMoveDecision)   //  Error
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        sheepFsm.process(event: .takeGrazeOrMoveDecision)   //  Error
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        sheepFsm.process(event: .endMove)
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
        sheepFsm.process(event: .endMove)   //  Error
        if let evt = sheepFsm.update(time: 0) {
            sheepFsm.process(event: evt)
        }
    }
}
