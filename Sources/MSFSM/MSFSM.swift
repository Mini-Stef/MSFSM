//
//  MSFSM.swift
//  MSFSM
//
//  Created by Stef MILLET on 26/02/3033.
//  Copyright © 2022 Stef MILLET. All rights reserved.
//

import Foundation   //  TimeInterval



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   -

///
/// The protocol for states
///
public protocol FSMState: Hashable {}



///
/// The protocol for events
///
public protocol FSMEvent: Hashable {}



///
/// A class that defines a Finite State Machine structure that is easy to build
///
public class FSMStructure<StateType: FSMState, StateInfo, EventType: FSMEvent> {

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Types

    /// State enter and leave callback
    public typealias StateEnterOrLeaveCallback  = ((StateInfo?) -> ())

    /// State update callback
    public typealias StateUpdateCallback        = ((StateInfo?,TimeInterval) -> ())

    ///
    /// A transition callback shall return the next state
    ///
    public typealias TransitionCallback = ((EventType) -> StateType)
    
    ///
    /// A type that defines a state of the machine
    ///
    private class StateDefinition<UserInfo> {
        /// The name (identifier of the state) - shall be unique in the FSM
        public let state:   StateType
        /// The user info
        public var info:    UserInfo?

        /// State entrance callback
        public var didEnterClbk:   StateEnterOrLeaveCallback?
        /// State update callback
        public var updateClbk:     StateUpdateCallback?
        /// State leave callback
        public var willLeaveClbk:  StateEnterOrLeaveCallback?
        
        public init(state: StateType) {
            self.state   = state
        }
    }
    
    /// The type for the state
    private typealias StateDef   = StateDefinition<StateInfo>

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Properties
    
    /// The table of events per state
    private var eventTransitionTable    = [StateType:(stateDef: StateDef,
                                                      events:   [EventType:TransitionCallback])]()
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Init

    public init() {}
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Building the FSM
    
    /// The last added state
    private var lastAddedStateDef: StateDef?    = nil

    ///
    /// Adds a state to the finite state machine
    ///
    public func state(_ state: StateType) -> Self {
        
        //  Create the state
        let stateDef    = StateDef(state: state)

        //  Add a row in the event/transition table for that state
        self.eventTransitionTable[state]    = (stateDef:   stateDef,
                                               events:     [EventType:TransitionCallback]())
        
        //  Note this is the last added state
        self.lastAddedStateDef              = stateDef
        
        return self
    }
    
    ///
    /// Sets the info for the state
    ///
    public func info(_ info: StateInfo) -> Self {

        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSM Error: using .info, but no last added state.")
        }
        
        self.lastAddedStateDef!.info = info
        
        return self
    }
    
    ///
    /// Modifies the didEnter callback of the last added state
    ///
    public func didEnter(_ clbk: @escaping StateEnterOrLeaveCallback) -> Self {

        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSM Error: using .didEnter, but no last added state.")
        }
        
        self.lastAddedStateDef!.didEnterClbk = clbk
        
        return self
    }

    ///
    /// Modifies the update callback of the last added state
    ///
    public func update(_ clbk: @escaping StateUpdateCallback) -> Self {

        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSM Error: using .update, but no last added state.")
        }
        
        self.lastAddedStateDef!.updateClbk = clbk
        
        return self
    }

    ///
    /// Modifies the willLeave callback of the last added state
    ///
    public func willLeave(_ clbk: @escaping StateEnterOrLeaveCallback) -> Self {

        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSM Error: using .willLeave, but no last added state.")
        }
        
        self.lastAddedStateDef!.willLeaveClbk = clbk
        
        return self
    }

    ///
    /// Adds an event/transition pair to the last added state
    ///
    public func on(_ event: EventType, transition: @escaping TransitionCallback) -> Self {
        
        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSM Error: using .on, but no last added state.")
        }
        
        //  Add the event/transition to the table
        let tableRow        = self.eventTransitionTable[self.lastAddedStateDef!.state]!
        var eventsTable     = tableRow.events
        eventsTable[event]  = transition
        
        
        self.eventTransitionTable[self.lastAddedStateDef!.state] = (stateDef:   tableRow.stateDef,
                                                                    events:     eventsTable)
        
        return self
    }
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Action !

    ///
    /// Calls the entrance callback of a state
    ///
    public func enter(state:    StateType) {
        self.eventTransitionTable[state]!.stateDef.didEnterClbk?(self.eventTransitionTable[state]!.stateDef.info)
    }
    
    ///
    /// The method to call regularly to perfor the current update of the state
    ///
    public func update(state:   StateType,
                       time:    TimeInterval) {
        self.eventTransitionTable[state]!.stateDef.updateClbk?(self.eventTransitionTable[state]!.stateDef.info,
                                                               time)
    }
    
    ///
    /// Calls the exit callback of a state
    ///
    public func leave(state:    StateType) {
        self.eventTransitionTable[state]!.stateDef.willLeaveClbk?(self.eventTransitionTable[state]!.stateDef.info)
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
    public func at(state: StateType, reactTo event: EventType) -> StateType {
        if let transition = self.eventTransitionTable[state]?.events[event] {
            self.leave(state: state)
            let nextState = transition(event)
            self.enter(state: nextState)
            return nextState
        }
        return state
    }
}


///
/// A class that defines a single token FSM
///
public class SingleTokenFSM<StateType: FSMState, StateInfo, EventType: FSMEvent> {
    
    public typealias StateEnterOrLeaveCallback  = FSMStructure<StateType,StateInfo,EventType>.StateEnterOrLeaveCallback
    public typealias StateUpdateCallback        = FSMStructure<StateType,StateInfo,EventType>.StateUpdateCallback
    public typealias TransitionCallback         = FSMStructure<StateType,StateInfo,EventType>.TransitionCallback

    private var structure       = FSMStructure<StateType,StateInfo,EventType>()
    
    private var initialState:   StateType!
    public private(set) var currentState:   StateType!
    
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
    /// Sets the info for the state
    ///
    public func info(_ info: StateInfo) -> Self {
        self.structure = self.structure.info(info)
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
        self.structure.enter(state: self.currentState)
    }
    
    ///
    /// Unsets the FSM
    ///
    public func deactivate() {
        if let currentState = self.currentState {
            self.structure.leave(state: currentState)
            self.currentState  = nil
        }
    }
    
    ///
    /// The method to call regularly to perform the update of the current state
    ///
    public func update(time:    TimeInterval) {
        if let currentState = self.currentState {
            self.structure.update(state: currentState, time: time)
        }
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
            self.currentState   = self.structure.at(state:    currentState,
                                                    reactTo:  event)
        }
    }
}
