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
public class BindableFSM<StateBinderType: StateBinder, InfoType, EventType: FSMEvent>: FSM {
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Properties

    /// The FSM structure
    private let structure:   FSMStructure<StateBinderType,InfoType,EventType>
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Init

    public init(structure:          FSMStructure<StateBinderType,InfoType,EventType>) {
        self.structure          = structure
    }
    
    //------------------------------------------------------------------------------------------------------------------
    //  MARK:   -   Action !

    public func activate(binder:   StateBinderType,
                         info:     InfoType) {
        binder.state    = self.structure.initialState!
        self.structure.enter(binder: binder, info: info)
    }

    public func deactivate(binder:   StateBinderType,
                           info:     InfoType) {
        self.structure.leave(binder: binder, info: info)
        binder.state    = nil
    }

    public func update(time:   TimeInterval,
                       binder: StateBinderType,
                       info:   InfoType) -> EventType? {
        self.structure.update(time: time, binder: binder, info: info)
    }
    
    public func process(event:     EventType,
                        binder:    StateBinderType,
                        info:      InfoType) {
        self.structure.reactTo(event:   event,
                               binder:  binder,
                               info:    info)
    }
}



//----------------------------------------------------------------------------------------------------------------------
//  MARK:   - Simplification for Void information

public extension BindableFSM where InfoType == Void {
    func activate(binder:   StateBinderType) {
        self.activate(binder: binder, info: (()))
    }
    
    func deactivate(binder:   StateBinderType) {
        self.deactivate(binder: binder, info: (()))
    }
    
    func update(time:   TimeInterval,
                binder: StateBinderType) -> EventType? {
        self.update(time: time, binder: binder, info: (()))
    }
    
    func process(event:     EventType,
                 binder:    StateBinderType) {
        self.process(event: event, binder: binder, info: (()))
    }
}
