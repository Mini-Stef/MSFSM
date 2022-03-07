//
//  SimpleFSM.swift
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
/// This class contains its own state, and can't support Hierarchical FSM.
///
public class SimpleFSM<StateType: FSMState, InfoType, EventType: FSMEvent>: BuildableFSM, StateBinderWithMemory {

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Properties

    /// The structure of the FSM
    private             var structure:  FSMStructure<StateType ,InfoType, EventType>
    private             var fsm:        BindableFSM<StateType, InfoType, EventType>
    
    /// The current FSM state
    public              var state:  StateType?

    /// The state memory if needed
    public              var memory: StateType?

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Init
    
    ///
    /// Use this init when you want to define the structure using the BuildableFSM methods
    ///
    public convenience init() {
        self.init(structure: FSMStructure<StateType, InfoType, EventType>())
    }

    ///
    /// Use this init when you want to define the structure separately.
    ///
    /// This might be usefull when you want several instance of the same FSM, each one with their token and info.
    ///
    public init(structure:  FSMStructure<StateType, InfoType, EventType>) {
        self.structure  = structure
        self.fsm        = BindableFSM(structure: structure)
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
    /// Defines the default start state
    ///
    public func initial(_ state: StateType) -> Self {
        self.structure = self.structure.initial(state)
        return self
    }

    ///
    /// Modifies the didEnter callback of the last added state
    ///
    public func didEnter(_ clbk: @escaping StateEnterOrLeaveCallback<StateType, InfoType>) -> Self {
        self.structure = self.structure.didEnter(clbk)
        return self
    }

    ///
    /// Modifies the update callback of the last added state
    ///
    public func update(_ clbk: @escaping StateUpdateCallback<StateType, InfoType, EventType>) -> Self {
        self.structure = self.structure.update(clbk)
        return self
    }

    ///
    /// Modifies the willLeave callback of the last added state
    ///
    public func willLeave(_ clbk: @escaping StateEnterOrLeaveCallback<StateType, InfoType>) -> Self {
        self.structure = self.structure.willLeave(clbk)
        return self
    }

    ///
    /// Adds an event/transition pair to the last added state
    ///
    public func on(_ event:     EventType,
                   transition:  @escaping TransitionCallback<StateType, InfoType, EventType>) -> Self {
        self.structure = self.structure.on(event, transition: transition)
        return self
    }

    ///
    /// Adds an event/execution pair to the last added state
    ///
    public func exec(_ event:   EventType,
                     execution: @escaping ExecutionCallback<StateType, InfoType,EventType>) -> Self {
        self.structure = self.structure.exec(event, execution: execution)
        return self
    }

    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Action !

    public func activate(time:  TimeInterval = 0,
                         info:  InfoType) {
        self.fsm.activate(time: time, binder: AnyStateBinder(self), info: info)
    }
    
    public func deactivate(time:    TimeInterval = 0,
                           info:    InfoType) {
        self.fsm.deactivate(time: time, binder: AnyStateBinder(self), info: info)
    }
    
    public func update(time:   TimeInterval = 0,
                       info:   InfoType) -> EventType? {
        self.fsm.update(time: time, binder: AnyStateBinder(self), info: info)
    }
    
    public func process(event:     EventType,
                        time:   TimeInterval = 0,
                        info:      InfoType) {
        self.fsm.process(event: event, time: time, binder: AnyStateBinder(self), info: info)
    }
}



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   - Simplification for Void information

public extension SimpleFSM where InfoType == Void {
    func activate(time:  TimeInterval = 0) {
        self.fsm.activate(time: time, binder: AnyStateBinder(self), info: (()))
    }
    
    func deactivate(time:  TimeInterval = 0) {
        self.fsm.deactivate(time: time, binder: AnyStateBinder(self), info: (()))
    }
    
    func update(time:   TimeInterval = 0) -> EventType? {
        self.fsm.update(time: time, binder: AnyStateBinder(self), info: (()))
    }
    
    func process(event:     EventType,
                 time:  TimeInterval = 0) {
        self.fsm.process(event: event, time: time, binder: AnyStateBinder(self), info: (()))
    }
}

///
/// A ``SimpleFSM`` which Info generic parameter is Void
///
public typealias SimplestFSM<StateType: FSMState, EventType: FSMEvent> = SimpleFSM<StateType, Void, EventType>
