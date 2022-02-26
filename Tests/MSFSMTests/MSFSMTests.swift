import XCTest
@testable import MSFSM




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
        fsm.update(time: 0)
        fsm.process(event: .goToLow)
        
        XCTAssert(fsm.currentState == .lowState)
        
        fsm.deactivate()
    }
}
