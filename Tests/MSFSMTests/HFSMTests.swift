//
//  HFSMTests.swift
//  
//
//  Created by Stef MILLET on 02/03/2022.
//

import XCTest
@testable import MSFSM


/*
class HFSM: XCTestCase {

    enum SleepingState: FSMState {
        case awaken, asleep
    }
    
    enum SleepingEvent: FSMEvent {
        case awake, goToSleep
    }
    
    static let sleepingFSMStructure = FSMStructure<Character, Void, SleepingEvent>()
        .initial(.awaken)
            .on(.goToSleep) { _,_,_ in return .asleep }
        .state(.asleep)
            .on(.awake)     { _,_,_ in return .awaken }
    
    
    
    
    enum HealthState: FSMState {
        case dead
        case alive()
    }
    
    enum HealthEventLabel {
        case heal, hit
    }
    
    struct HealthEvent: FSMEvent {
        let label: HealthEventLabel
        let value: Int
    }
    
    static let healthFSMStructure = FSMStructure<Character, Void, HealthEvent>()
        .initial(.alive)
            .willLeave      { binder,_ in }
            .didEnter       { binder,_ in }
    
        .state(.dead)
}
*/
