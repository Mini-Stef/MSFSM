//
//  FSMStructure.swift
//  MSFSM
//
//  Created by Stef MILLET on 26/02/3033.
//  Copyright © 2022 Stef MILLET. All rights reserved.
//

import Foundation   //  TimeInterval



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   -



///
/// A class that defines a Finite State Machine structure that is easy to build
///
public class FSMStructure<StateType: FSMState, InfoType, EventType: FSMEvent>: BuildableFSM {

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Types

    ///
    /// A type that defines a state of the machine
    ///
    private class StateDefinition {
        /// The name (identifier of the state) - shall be unique in the FSM
        public let state:   StateType

        /// State entrance callback
        public var didEnterClbk:   StateEnterOrLeaveCallback<StateType,InfoType>?
        /// State update callback
        public var updateClbk:     StateUpdateCallback<StateType,InfoType,EventType>?
        /// State leave callback
        public var willLeaveClbk:  StateEnterOrLeaveCallback<StateType,InfoType>?
        
        public init(state: StateType) {
            self.state   = state
        }
    }
    
    /// The type for a transition or execution callback
    private enum EventCallback {
        case transition(TransitionCallback<StateType,InfoType,EventType>)
        case execution(ExecutionCallback<StateType,InfoType,EventType>)
    }

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Properties
    
    /// The table of events per state
    private var eventTransitionTable        = [StateType:(stateDef: StateDefinition,
                                                          events:   [EventType:EventCallback])]()
    
    /// The entry state of the FSM
    public private(set) var initialState:   StateType!

    /// Tells whether we have a memory
    public private(set) var hasMemory:      Bool    = false

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Init

    public init() {}
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Building the FSM
    
    /// The last added state
    private var lastAddedStateDef: StateDefinition? = nil

    public func state(_ state: StateType) -> Self {
        
        //  Make sure the state doesn't already exists
        guard self.eventTransitionTable[state] == nil else {
            fatalError("FSMStructure Error: using .state with an already defined state.")
        }
        
        //  Create the state
        let stateDef    = StateDefinition(state: state)

        //  Add a row in the event/transition table for that state
        self.eventTransitionTable[state]    = (stateDef:   stateDef,
                                               events:     [EventType:EventCallback]())
        
        //  Note this is the last added state
        self.lastAddedStateDef              = stateDef
        
        return self
    }
    
    public func initial(_ state: StateType) -> Self {

        //  Make sure the there is no initial state already
        guard self.initialState == nil else {
            fatalError("FSMStructure Error: using .initial with an already defined initial state.")
        }

        self.initialState = state
        return self.state(state)
    }

    public func memory(_ state: StateType) -> Self {
        self.hasMemory  = true
        return self.initial(state)
    }

    public func didEnter(_ clbk: @escaping StateEnterOrLeaveCallback<StateType,InfoType>) -> Self {

        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSMStructure Error: using .didEnter, but no last added state.")
        }
        
        self.lastAddedStateDef!.didEnterClbk = clbk
        
        return self
    }

    public func update(_ clbk: @escaping StateUpdateCallback<StateType,InfoType,EventType>) -> Self {

        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSMStructure Error: using .update, but no last added state.")
        }
        
        self.lastAddedStateDef!.updateClbk = clbk
        
        return self
    }

    public func willLeave(_ clbk: @escaping StateEnterOrLeaveCallback<StateType,InfoType>) -> Self {

        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSMStructure Error: using .willLeave, but no last added state.")
        }
        
        self.lastAddedStateDef!.willLeaveClbk = clbk
        
        return self
    }

    public func on(_ event:     EventType,
                   transition:  @escaping TransitionCallback<StateType, InfoType, EventType>) -> Self {
        
        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSMStructure Error: using .on, but no last added state.")
        }
        
        //  Add the event/transition to the table
        let tableRow        = self.eventTransitionTable[self.lastAddedStateDef!.state]!
        var eventsTable     = tableRow.events
        eventsTable[event]  = .transition(transition)
        
        
        self.eventTransitionTable[self.lastAddedStateDef!.state] = (stateDef:   tableRow.stateDef,
                                                                    events:     eventsTable)
        
        return self
    }
    
    public func exec(_ event:   EventType,
                     execution: @escaping ExecutionCallback<StateType, InfoType,EventType>) -> Self {
        
        //  We must have a last added state in order to use this builder function
        guard self.lastAddedStateDef != nil else {
            fatalError("FSMStructure Error: using .exec, but no last added state.")
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
    public func enter(binder:   StateBinderType,
                      info:     InfoType) {
        self.eventTransitionTable[binder.state!]!.stateDef.didEnterClbk?(binder, info)
    }
    
    ///
    /// The method to call regularly to perform the current update of the state
    ///
    /// It returns an event that can be generated by the callback. The event is not processed
    ///
    public func update(time:    TimeInterval,
                       binder:  StateBinderType,
                       info:    InfoType) -> EventType? {
        return self.eventTransitionTable[binder.state!]!.stateDef.updateClbk?(time, binder, info)
    }
    
    ///
    /// Calls the exit callback of a state
    ///
    public func leave(binder:   StateBinderType,
                      info:     InfoType) {
        self.eventTransitionTable[binder.state!]!.stateDef.willLeaveClbk?(binder, info)
    }

    
    ///
    /// Executes the transition/execution callback when an event occurs inside the specified state
    ///
    /// This method will:
    /// - Do nothing if the event is not an acceptable event of the current state
    /// - If, in the current state, the event triggers a transition:
    ///     - call the willLeave method of the current state
    ///     - call the transition callback
    ///     - change the state using the state binder
    ///     - call the didEnter method of the new state
    /// - If, in the urrent state, the event triggers an execution callback
    ///     - just execute this callback
    ///
    public func reactTo(event:  EventType,
                        binder: StateBinderType,
                        info:   InfoType) {
        if let callback = self.eventTransitionTable[binder.state!]?.events[event] {
            switch callback {
            case .transition(let transition):
                self.leave(binder: binder, info: info)
                let nextState   = transition(event, binder, info)
                binder.state    = nextState
                self.enter(binder: binder, info: info)
            case .execution(let execution):
                execution(event, binder, info)
            }
        }
    }
}
