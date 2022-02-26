//
//  SingleTokenFSM.swift
//  MSFSM
//
//  Created by Stef MILLET on 26/02/2022.
//  Copyright © 2022 Stef MILLET. All rights reserved.
//

import Foundation   //  TimeInterval



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   -

///
/// A class that defines a single token FSM
///
public class SingleTokenFSM<StateType: FSMState, InfoType, EventType: FSMEvent> {
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Types

    /// State enter and leave callback
    public typealias StateEnterOrLeaveCallback  = FSMStructure<StateType,InfoType,EventType>.StateEnterOrLeaveCallback

    /// State update callback
    public typealias StateUpdateCallback        = FSMStructure<StateType,InfoType,EventType>.StateUpdateCallback

    /// A transition callback shall return the next state
    public typealias TransitionCallback         = FSMStructure<StateType,InfoType,EventType>.TransitionCallback

    /// A execution callback shall return the next state
    public typealias ExecutionCallback          = FSMStructure<StateType,InfoType,EventType>.ExecutionCallback


    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Properties

    /// The structure of the FSM
    private var structure                   = FSMStructure<StateType,InfoType,EventType>()
    
    /// The initial state when the FSM is activated
    private var initialState:               StateType!
    
    /// The current FSM state
    public private(set) var currentState:   StateType!
    
    /// The information for the callbacks
    public private(set) var info:           InfoType
    
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Init
    
    public init(info: InfoType) {
        self.info   = info
    }

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Building the FSM
    
    ///
    /// Adds a state to the finite state machine
    ///
    public func state(_ state: StateType) -> Self {
        self.structure = self.structure.state(state)
        return self
    }
    
    ///
    /// Modifies the didEnter callback of the last added state
    ///
    public func didEnter(_ clbk: @escaping StateEnterOrLeaveCallback) -> Self {
        self.structure = self.structure.didEnter(clbk)
        return self
    }

    ///
    /// Modifies the update callback of the last added state
    ///
    public func update(_ clbk: @escaping StateUpdateCallback) -> Self {
        self.structure = self.structure.update(clbk)
        return self
    }

    ///
    /// Modifies the willLeave callback of the last added state
    ///
    public func willLeave(_ clbk: @escaping StateEnterOrLeaveCallback) -> Self {
        self.structure = self.structure.willLeave(clbk)
        return self
    }

    ///
    /// Adds an event/transition pair to the last added state
    ///
    public func on(_ event: EventType, transition: @escaping TransitionCallback) -> Self {
        self.structure = self.structure.on(event, transition: transition)
        return self
    }

    ///
    /// Adds an event/execution pair to the last added state
    ///
    public func exec(_ event: EventType, execution: @escaping ExecutionCallback) -> Self {
        self.structure = self.structure.exec(event, execution: execution)
        return self
    }

    ///
    /// Defines the default start state
    ///
    public func initial(_ state: StateType) -> Self {
        self.initialState = state
        return self
    }

    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Action !

    ///
    /// Sets the FSM in working order.
    ///
    /// The initial state is entered.
    ///
    public func activate() {
        self.currentState   = self.initialState
        self.structure.enter(state: self.currentState, info: self.info)
    }
    
    ///
    /// Unsets the FSM
    ///
    public func deactivate() {
        if let currentState = self.currentState {
            self.structure.leave(state: currentState, info: self.info)
            self.currentState  = nil
        }
    }
    
    ///
    /// The method to call regularly to perform the update of the current state
    ///
    public func update(time:    TimeInterval) -> EventType? {
        if let currentState = self.currentState {
            return self.structure.update(state: currentState, time: time, info: self.info)
        }
        return nil
    }
    
    ///
    /// Executes the transition when an event occurs and we are in a specified state
    ///
    /// Returns the next state, or the current state if the event isn't an event of the state.
    ///
    /// The willLeave method of the state is executed (if any).
    /// The transition is executed
    /// The didEnter method of the next state is executed (if any).
    ///
    public func process(event: EventType) {
        if let currentState = self.currentState {
            self.currentState   = self.structure.reactTo(state: currentState,
                                                         event: event,
                                                         info:  self.info)
        }
    }
}


//  Simplification for Void information
public extension SingleTokenFSM where InfoType == Void {
    convenience init() {
        self.init(info: (()))
    }
}
