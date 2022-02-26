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
    public typealias StateUpdateCallback        = ((StateInfo?,TimeInterval) -> EventType?)

    ///
    /// A transition callback shall return the next state
    ///
    public typealias TransitionCallback = ((EventType) -> StateType)
    
    ///
    /// An executon callback processes an event without changing the state
    ///
    public typealias ExecutionCallback  = ((EventType) -> ())
    
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
    
    /// The type for a transition or execution callback
    private enum EventCallback {
        case transition(TransitionCallback)
        case execution(ExecutionCallback)
    }

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Properties
    
    /// The table of events per state
    private var eventTransitionTable    = [StateType:(stateDef: StateDef,
                                                      events:   [EventType:EventCallback])]()
    
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
                                               events:     [EventType:EventCallback]())
        
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
        eventsTable[event]  = .transition(transition)
        
        
        self.eventTransitionTable[self.lastAddedStateDef!.state] = (stateDef:   tableRow.stateDef,
                                                                    events:     eventsTable)
        
        return self
    }
    
    ///
    /// Adds an event/execution pair to the last added state
    ///
    public func exec(_ event: EventType, execution: @escaping ExecutionCallback) -> Self {
        
        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSM Error: using .exec, but no last added state.")
        }
        
        //  Add the event/transition to the table
        let tableRow        = self.eventTransitionTable[self.lastAddedStateDef!.state]!
        var eventsTable     = tableRow.events
        eventsTable[event]  = .execution(execution)
        
        
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
                       time:    TimeInterval) -> EventType? {
        let info    = self.eventTransitionTable[state]!.stateDef.info
        return self.eventTransitionTable[state]!.stateDef.updateClbk?(info, time)
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
        if let callback = self.eventTransitionTable[state]?.events[event] {
            
            switch callback {
            case .transition(let transition):
                self.leave(state: state)
                let nextState = transition(event)
                self.enter(state: nextState)
                return nextState
            case .execution(let execution):
                execution(event)
            }
        }
        return state
    }
}
