//
//  FSMProtocols.swift
//  MSFSM
//
//  Created by Stef MILLET on 27/02/2022.
//  Copyright © 2022 Stef MILLET. All rights reserved.
//

import Foundation   //  TimeInterval



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   -   Basic protocols

///
/// The protocol to conform to identify a type as usable as an FSM state
///
public protocol FSMState: Hashable {}



///
/// The protocol to conform to identify a type as usable as an FSM event
///
public protocol FSMEvent: Hashable {}



///
/// A protocol for an element that will provide a state
///
public protocol StateBinder: AnyObject {
    associatedtype StateType: FSMState
    
    /// Access to the state information
    var state:  StateType?  { get set }
}

///
/// A Type-erasing type for a StateBinder
///
public class AnyStateBinder<StateType: FSMState>: StateBinder {
    private let getClosure: (() -> StateType?)
    private let setClosure: ((StateType?) -> ())
    
    public  var state: StateType? {
        get { self.getClosure() }
        set { self.setClosure(newValue) }
    }
    
    public init<BinderType: StateBinder>(_ erased: BinderType) where BinderType.StateType == StateType {
        self.getClosure = { erased.state }
        self.setClosure = { newValue in erased.state = newValue }
    }
}


//----------------------------------------------------------------------------------------------------------------------
//  MARK:   -   FSM protocol

///
/// A protocol to use an FSM
///
public protocol FSM {
    associatedtype  EventType:          FSMEvent
    associatedtype  StateBinderType:    StateBinder
    associatedtype  InfoType
    
    ///
    /// Sets the FSM in working order.
    ///
    /// The initial state is entered (with its entry callback called, if any).
    ///
    func activate(binder:   StateBinderType,
                  info:     InfoType)

    ///
    /// Unsets the FSM
    ///
    /// The current state is left (with its exit callback called, if any).
    ///
    func deactivate(binder: StateBinderType,
                    info:   InfoType)

    ///
    /// The method to call regularly to perform the update of the current state
    ///
    /// It returns an ooptional generated event. This can be used e.g. after a waiting time. The returned event
    /// is not yet processed.
    ///
    func update(time:   TimeInterval,
                binder: StateBinderType,
                info:   InfoType) -> EventType?

    ///
    /// Processes an event by executing a transition or execution callback.
    ///
    /// If, in the current state, the event is associated to:
    /// - an transition callback, then:
    ///     - the willLeave method of the state is executed (if any)
    ///     - the transition is executed
    ///     - the didEnter method of the next state is executed (if any)
    ///     This is done event if the next state is the same as the current state.
    /// - an execution callback, then
    ///     - the execution callback is executed
    ///
    func process(event:     EventType,
                 binder:    StateBinderType,
                 info:      InfoType)
}



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   -   FSM Structure types and protocol

/// State enter and leave callback
public typealias StateEnterOrLeaveCallback<StateBinderType: StateBinder,
                                           InfoType>        = ((StateBinderType,InfoType) -> ())

/// State update callback
public typealias StateUpdateCallback<StateBinderType: StateBinder,
                                     InfoType,
                                     EventType: FSMEvent>   = ((TimeInterval, StateBinderType, InfoType) -> EventType?)

/// A transition callback shall return the next state
public typealias TransitionCallback<StateBinderType: StateBinder,
                                    InfoType,
                                    EventType: FSMEvent>    = ((EventType, StateBinderType, InfoType) ->
                                                                                            StateBinderType.StateType)

/// An executon callback processes an event without changing the state
public typealias ExecutionCallback<StateBinderType: StateBinder,
                                   InfoType,
                                   EventType: FSMEvent>     = ((EventType, StateBinderType, InfoType) -> ())



///
/// A protocol to build an FSM
///
public protocol BuildableFSM {
    associatedtype  StateBinderType:    StateBinder
    associatedtype  InfoType
    associatedtype  EventType:          FSMEvent
    
    typealias   StateType   = StateBinderType.StateType

    ///
    /// Adds a state to the finite state machine
    ///
    func state(_ state: StateType) -> Self

    ///
    /// Defines the default start state
    ///
    func initial(_ state: StateType) -> Self

    ///
    /// Modifies the didEnter callback of the last added state
    ///
    func didEnter(_ clbk: @escaping StateEnterOrLeaveCallback<StateBinderType,InfoType>) -> Self

    ///
    /// Modifies the update callback of the last added state
    ///
    func update(_ clbk: @escaping StateUpdateCallback<StateBinderType,InfoType,EventType>) -> Self

    ///
    /// Modifies the willLeave callback of the last added state
    ///
    func willLeave(_ clbk: @escaping StateEnterOrLeaveCallback<StateBinderType,InfoType>) -> Self

    ///
    /// Adds an event/transition pair to the last added state
    ///
    func on(_ event: EventType, transition: @escaping TransitionCallback<StateBinderType,InfoType,EventType>) -> Self

    ///
    /// Adds an event/execution pair to the last added state
    ///
    func exec(_ event: EventType, execution: @escaping ExecutionCallback<StateBinderType,InfoType,EventType>) -> Self
}
