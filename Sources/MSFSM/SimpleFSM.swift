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
public class SimpleFSM<StateType: FSMState, InfoType, EventType: FSMEvent>: BuildableFSM, StateBinder {

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Properties

    /// The structure of the FSM
    private             var structure:  FSMStructure<SimpleFSM<StateType, InfoType, EventType>,InfoType,EventType>
    private             var fsm:        BindableFSM<SimpleFSM<StateType, InfoType, EventType>, InfoType, EventType>
    
    /// The current FSM state
    public              var state:  StateType?

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Init
    
    ///
    /// Use this init when you want to define the structure using the BuildableFSM methods
    ///
    public convenience init() {
        self.init(structure: FSMStructure<SimpleFSM<StateType, InfoType, EventType>, InfoType, EventType>())
    }

    ///
    /// Use this init when you want to define the structure separately.
    ///
    /// This might be usefull when you want several instance of the same FSM, each one with their token and info.
    ///
    public init(structure:  FSMStructure<SimpleFSM<StateType, InfoType, EventType>, InfoType, EventType>) {
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
    public func didEnter(_ clbk: @escaping StateEnterOrLeaveCallback<SimpleFSM<StateType, InfoType, EventType>, InfoType>) -> Self {
        self.structure = self.structure.didEnter(clbk)
        return self
    }

    ///
    /// Modifies the update callback of the last added state
    ///
    public func update(_ clbk: @escaping StateUpdateCallback<SimpleFSM<StateType, InfoType, EventType>, InfoType, EventType>) -> Self {
        self.structure = self.structure.update(clbk)
        return self
    }

    ///
    /// Modifies the willLeave callback of the last added state
    ///
    public func willLeave(_ clbk: @escaping StateEnterOrLeaveCallback<SimpleFSM<StateType, InfoType, EventType>, InfoType>) -> Self {
        self.structure = self.structure.willLeave(clbk)
        return self
    }

    ///
    /// Adds an event/transition pair to the last added state
    ///
    public func on(_ event:     EventType,
                   transition:  @escaping TransitionCallback<SimpleFSM<StateType, InfoType, EventType>, InfoType, EventType>) -> Self {
        self.structure = self.structure.on(event, transition: transition)
        return self
    }

    ///
    /// Adds an event/execution pair to the last added state
    ///
    public func exec(_ event:   EventType,
                     execution: @escaping ExecutionCallback<StateBinderType, InfoType,EventType>) -> Self {
        self.structure = self.structure.exec(event, execution: execution)
        return self
    }

    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Action !

    public func activate(info:     InfoType) {
        self.fsm.activate(binder: self, info: info)
    }
    
    public func deactivate(info:     InfoType) {
        self.fsm.deactivate(binder: self, info: info)
    }
    
    public func update(time:   TimeInterval,
                       info:   InfoType) -> EventType? {
        self.fsm.update(time: time, binder: self, info: info)
    }
    
    public func process(event:     EventType,
                        info:      InfoType) {
        self.fsm.process(event: event, binder: self, info: info)
    }
}



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   - Simplification for Void information

public extension SimpleFSM where InfoType == Void {
    func activate() {
        self.fsm.activate(binder: self, info: (()))
    }
    
    func deactivate() {
        self.fsm.deactivate(binder: self, info: (()))
    }
    
    func update(time:   TimeInterval) -> EventType? {
        self.fsm.update(time: time, binder: self, info: (()))
    }
    
    func process(event:     EventType) {
        self.fsm.process(event: event, binder: self, info: (()))
    }
}

///
/// A ``SimpleFSM`` which Info generic parameter is Void
///
public typealias SimplestFSM<StateType: FSMState, EventType: FSMEvent> = SimpleFSM<StateType, Void, EventType>
