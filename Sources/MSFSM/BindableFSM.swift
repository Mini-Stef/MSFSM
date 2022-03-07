//
//  BindableFSM.swift
//  MSFSM
//
//  Created by Stef MILLET on 27/02/2022.
//  Copyright © 2022 Stef MILLET. All rights reserved.
//

import Foundation   //  TimeInterval



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   -

///
/// A FSM class that binds its state to a variable stored elsewhere
///
public class BindableFSM<StateType: FSMState, InfoType, EventType: FSMEvent>: FSM {
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Types

    /// Shortcut to the type erasing class for AnyStateBinder<StateType>
    public typealias StateBinderType   = AnyStateBinder<StateType>

    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Properties

    /// The FSM structure
    private let structure:   FSMStructure<StateType, InfoType, EventType>
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Init

    public init(structure:          FSMStructure<StateType, InfoType, EventType>) {
        self.structure          = structure
    }
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Action !

    public func activate(time:      TimeInterval = 0,
                         binder:   StateBinderType,
                         info:     InfoType) {
        if self.structure.hasMemory {
            if let memory = binder.memory {
                binder.state    = memory
            } else {
                binder.state    = self.structure.initialState!
            }
        } else {
            binder.state    = self.structure.initialState!
        }
        self.structure.enter(time: time, binder: binder, info: info)
    }

    public func deactivate(time:      TimeInterval = 0,
                           binder:   StateBinderType,
                           info:     InfoType) {
        if self.structure.hasMemory {
            binder.memory   = binder.state
        }
        self.structure.leave(time: time, binder: binder, info: info)
        binder.state    = nil
    }

    public func update(time:   TimeInterval = 0,
                       binder: StateBinderType,
                       info:   InfoType) -> EventType? {
        self.structure.update(time: time, binder: binder, info: info)
    }
    
    public func process(event:     EventType,
                        time:      TimeInterval = 0,
                        binder:    StateBinderType,
                        info:      InfoType) {
        self.structure.reactTo(event:   event,
                               time:    time,
                               binder:  binder,
                               info:    info)
    }
}



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   - Simplification for Void information

public extension BindableFSM where InfoType == Void {
    func activate(time:      TimeInterval = 0,
                  binder:   StateBinderType) {
        self.activate(time: time, binder: binder, info: (()))
    }
    
    func deactivate(time:      TimeInterval = 0,
                    binder:   StateBinderType) {
        self.deactivate(time: time, binder: binder, info: (()))
    }
    
    func update(time:   TimeInterval = 0,
                binder: StateBinderType) -> EventType? {
        self.update(time: time, binder: binder, info: (()))
    }
    
    func process(event:     EventType,
                 time:      TimeInterval = 0,
                 binder:    StateBinderType) {
        self.process(event: event, time: time, binder: binder, info: (()))
    }
}
