# ``MSFSM``

This package is yet-another Finite State Machine package. Yes, just yet-another FSM package... but with some really cool features...



## Overview

So what does it bring ? Where's the added value ? Well, this package provides:

- A **generic definition** of the FSM elements such as states and events, so that you can use whatever type you want for that. OK, kind of cool, but 'déjà vu'...
- A **declarative syntax** for defining the FSM in simple and expressive way. That's something...
- And it allows complex FSM features such as **Hierarchical FSM**, or **multi-token FSM**, or **on-event transition to several possible states** to be implemented very simply. Yes baby !


### Declarative syntax

![Simple FSM 1](SimpleFSM1.png)

The above FSM would be declared like this:

```
enum State: Int, FSMState {
    case healthy, wounded, dead
}

enum Event: Int, FSMEvent {
    case hit, severeHit, heal
}

let fsm = SimplestFSM<State, Event>()
    .initial(.healthy)
        .on(.hit)           { _,_,_,_ in return .wounded }
        .on(.severeHit)     { _,_,_,_ in return .dead }
    .state(.wounded)
        .on(.hit)           { _,_,_,_ in return .dead }
        .on(.severeHit)     { _,_,_,_ in return .dead }
        .on(.heal)          { _,_,_,_ in return .healthy }
    .state(.dead)
```

Easy no ? So clean, so readable...

One thing to note is that when you declare  an FSM structure, **there shall be one (and only one) initial state** (declared with `initial` instead of `state`). Forgetting the initial state (or declaring two) is a programmer error. It doesn't have to be the first declared one, but let's say it is a kind of convention.

You can also see that the State and Event types are provided as generic parameters, but we'll come back on that later.


### Separation of state

The ``SimplestFSM`` class holds its own `state` property, so it comes as ready-to-use configurable FSM. But most of the time, you need more. You need that the FSM rules one of your class property. That's where separation of state comes handy. Just have a look at that:

```

let healthFSMStructure  = FSMStructure<State, Void, Event>()
    .initial(.healthy)
        .on(.hit)           { _,_,_,_ in return .wounded }
        .on(.severeHit)     { _,_,_,_ in return .dead }
    .state(.wounded)
        .on(.hit)           { _,_,_,_ in return .dead }
        .on(.severeHit)     { _,_,_,_ in return .dead }
        .on(.heal)          { _,_,_,_ in return .healthy }
    .state(.dead)


class MyClass: StateBinder {
    
    var state:  State?
    
    //  Because MyClass conforms to StateBinder, when an event changes the state of the FSM, the
    //  `state`property will be modified

    let fsm:    BindableFSM<MyClass, Void, Event>
    
    init() {
        self.fsm = BindableFSM(structure: healthFSMStructure)
    }
}
```

Because the class `MyClass` conforms to ``StateBinder``, and because it holds a BindableFSM property, any state change in the FSM modifies the `state` property. 

Why is that so cool ? Because, suddenly, by defining one and only one FSM structure (the `healthFSMStructure` constant in the sample code), you can have several instances of `MyClass`, each with a different and independant state. You suddenly have a **multi-token FSM**.

Let's go further.

What if you want to bind the FSM state to a property named differently than `state`, or what if you want to bind two different properties to two differents FSM structures ? The ``AnyStateBinder`` is there to help.

```
class MyClass {
    
    var healthStatus: State?
    
    //  Add a state binder that takes care about indirection between FSM State and 'healthStatus' instead of 'state'
    var healthStatusBinder: AnyStateBinder<State>!
    
    let fsm:    BindableFSM<State, Void, Event>
    
    init() {
        self.fsm = BindableFSM(structure: healthFSMStructure)
        self.healthStatusBinder  = AnyStateBinder(getClosure:   { self.healthStatus },
                                                  setClosure:   { newValue in self.healthStatus = newValue })
    }
}
```

That's it ! Now the FSM modifies the `healthStatus`property. And of course, you can have as many properties as you want, all influenced by a different BindableFSM.

Cherry on the cake, as you fully control the get/set methods of the `HealthStatusBinder`, you could add some code to, let's say, send a message to update your UI.



### The power of generics

As you may have noticed, the state and event type are generic parameters to the ``FSMStructure`` class. Their only constraint is to conform to the ``FSMState`` and ``FSMEvent`` protocols. There is no requirement in those protocols, appart from being `Hashable`. They just mark a type as able to be used as a State or an Event.

Now, in the above examples, we used enums, which is pretty usual. But we could very well use structs, with some variable values inside. The only **important** point being that the variable part is not used in the hash computation (remember, your struct must be `Hashable`). This would allow to do something like this.

![FSM2](FSM2.png)

```
//  Define the states of the FSM
enum State: FSMState {
    case alive, dead
}

//  Define an event that will carry a value. Based on this value, and on the character's health, we will end
//  up in one state or another
//
//  We must make sure that only the static part of the event (i.e. the label, not the value) is considered into
//  comparisons, so that any hit/heal is considered a hit/heal, whatever the value
struct Event: FSMEvent {
    enum EventLabel {
        case hit, heal
    }
    let label: EventLabel

    var value: Int
    
    //  Make sure that events are only compared with their static part (the label)
    //  i.e. remove the value from == and hash
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.label == rhs.label
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.label)
        //  Don't add the value !!!
    }
    
    static let hit  = Event(label: .hit,    value: 0)   //  we don't care about the value
    static let heal = Event(label: .heal,   value: 0)   //  we don't care about the value
}

//  Define a protocol for the class that will be holding the health property. An instance of that class will be
//  provided as parameter of transitions so the transition can modify the health value
protocol HealthHolder: AnyObject {
    var health: Int { get set }
}


let fsmStructure = FSMStructure<State, HealthHolder, Event>()
    .initial(.alive)
        .on(.hit)        { event,_,_,healthHolder in
            healthHolder.health -= event.value
            if healthHolder.health <= 0 {
                return .dead
            }
            return .alive
        }
        .on(.heal)          { event,_,_,healthHolder in
            healthHolder.health += event.value
            return .alive
        }
    .state(.dead)
```

See how we have defined a transition that can end up in two different states (.alive and .dead), depending on the value contained of the event ?

We will come back to the power of generics when we talk about hierarchical FSM later.



### State callbacks and event transitions

States can be given **callbacks** that are called:
- When the state is entered `didEnter`. And when the state is left `willLeave`. Parameters are the state binder, and an user info that can be anything. See ``StateEnterOrLeaveCallback``
- When inside the state, as a regular call `update`. Its parameters are a time reference `TimeInterval`, the state binder, and an user info that can be anything. It return an optional of an event. This is handy when you want to e.g. wait for a certain amount of time and then send a wake up event. See ``StateUpdateCallback``. It is up to the programmer to call the update callback regularly (or when he/she wants).

Events can start *transition callbacks*, or *execution callbacks*. The difference between a transition and an execution callback is that **transition callbacks return the next state** (which can be the current state), whereas **execution callbacks don't return a state**, leaving the FSM in the same state. If a transition callback returns the current state, the `willLeave` and `didEnter` callbacks of the state will be executed.

You declare an execution callback using `.exec` instead of `.on`. Both take the event, the binder, and an user info that can be anything. Execution callback are very usefull when defining Hierarchical FSM.

See ``TransitionCallback`` and ``ExecutionCallback``.

Here is an example of FSM declaration with callbacks. Still very clean and readable.

```
let fsm = SimpleFSM<State, Info, Event>()
    .initial(.healthy)
        .willLeave          { _,_,info in info.hasLeftHealthy = true }
        .on(.hit)           { _,_,_,_ in return .wounded }
        .on(.severeHit)     { _,_,_,_ in return .dead }
    .state(.wounded)
        .update             { _,_,_,info in info.hasUpdatedWounded = true ; return nil }
        .on(.hit)           { _,_,_,_ in return .dead }
        .on(.severeHit)     { _,_,_,_ in return .dead }
        .on(.heal)          { _,_,_,_ in return .healthy }
    .state(.dead)
        .didEnter           { _,_,info in info.hasEnteredDead = true }
```


### How to use

So far, we have seen how to declare FSM structures, and FSM that hold their own state, or can bind to a state property (whatever its name) held by a class. But how do we use those FSM ? This is defined by the ``FSM`` protocol.

There are four methods to use an FSM:

* ``FSM/activate(binder:info:)`` must be called once before any other method. It sets the current state of the FSM to the initial FSM tate and calls its `didEnter` callback. Before a call to `activate` the state is supposed to be `nil` (that's why states are optionals). Not calling `activate` on an FSM before any other method is a programmer error. Calling it twice without calling `deactive` in between results in an undefined behaviour.
* ``FSM/deactivate(binder:info:)`` does the opposite of `activate`. It calls the `willLeave` callback of the current state before deactivating the FSM. After a deactivation, the state is `nil`.
* ``FSM/process(event:binder:info:)`` is to be called when an event occurs and needs to be processed by the FSM. This method will take care of changing the state if needed, calling the `willLeave` and `didEnter` callbacks as necessary.
* ``FSM/update(time:binder:info:)`` is to be called whenever needed to execution actions needed while staying in a state. It calls the `update` state callback. It can return an event that can be processed later on.

Note that all those callback receives the state binder as parameter, so that they can retrieve the current state of the FSM if needed. Changing the current state in the callbacks can results in undefined behaviour.

They also receive an `info` parameter that can hold any information needed by the callbacks. In our above example, the info was holding the health value that was influenced by the hit or heal value in the event.


### Hierarchical FSM

Yes ! That's possible ! By leveraging the power of the generics and the state and event callback, we can very simply build hierarchical FSM, still with this beautifull declarative syntax.

Let's do this:

![FSM3](FSM3.png)

```
//  First, define the structure of the sub-FSM - very simple
enum SleepingState: FSMState {
    case awaken, asleep
}

enum SleepingEvent: FSMEvent {
    case awake, goToSleep
}

let sleepingFSMStructure = FSMStructure<SleepingState, Void, SleepingEvent>()
    .initial(.awaken)
        .on(.goToSleep) { _,_,_,_ in return .asleep }
    .state(.asleep)
        .on(.awake)     { _,_,_,_ in return .awaken }



//  Then define, the father FSM


//  Let's define a state with an enum. One of the case will have an associated value that is a BindableFSM
//  with the sleepingFSMStructure structure.
//  As explained above, we make sure that only the static part is taken into account for hashin and comparison
enum HealthState: FSMState {
    case dead
    case alive(BindableFSM<SleepingState, Void, SleepingEvent>)

    static let alive: HealthState = .alive(BindableFSM(structure: sleepingFSMStructure))

    //  Make sure that only the static part is taken into account for hashing and comparison
    //  i.e. remove the value from == and hash
    static func == (lhs: HealthState, rhs: HealthState) -> Bool {
        switch (lhs, rhs) {
        case    (.dead, .dead),
                (.alive, .alive):
            return true
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .dead:     hasher.combine(0)
        case .alive:    hasher.combine(1)
        }
    }
}

//  We do the same with an event that is holding information (for the multi-ending-state transition)
//  See above if you missed that
enum HealthEvent: FSMEvent {
    case heal(Int), hit(Int)
    case awake, goToSleep

    static let heal: HealthEvent   = .heal(0)
    static let hit: HealthEvent    = .hit(0)

    //  Make sure that only the static part is taken into account for hashing and comparison
    //  i.e. remove the value from == and hash
    static func == (lhs: HealthEvent, rhs: HealthEvent) -> Bool {
        switch (lhs, rhs) {
        case    (.heal, .heal),
                (.hit, .hit),
                (.awake, .awake),
                (.goToSleep, .goToSleep):
            return true
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .heal: hasher.combine(0)
        case .hit:  hasher.combine(1)
        case .awake:  hasher.combine(2)
        case .goToSleep:  hasher.combine(3)
        }
    }
}


//  The FSM will have to be binded to two states, one for each level of the FSM. The first level state
//  (alive/dead) will be provided by the binder. We'll bind the second state via the info parameters
//  Let's define a protocol for that info parameter

protocol SleepStateBinderProvider {
    var sleepStatusBinder: AnyStateBinder<SleepingState>! { get }
}


//  The FSM structure will then be defined as follows.
//  We use the states callbacks. When entering/leaving the alive state, we activate/deactivate the subFSM
//  And we don't forget to forward sleep/awake events to teh sub FSM in our execution callacks on alive state
let healthFSMStructure = FSMStructure<HealthState, SleepStateBinderProvider & HealthHolder, HealthEvent>()
    .initial(.alive)
        .didEnter       { _,binder,info in
            let aliveState  = binder.state!
            if case let .alive(subFsm) = aliveState {
                subFsm.activate(binder: info.sleepStatusBinder!)
            }
        }
        .willLeave      { _,binder,info in
            let aliveState  = binder.state!
            if case let .alive(subFsm) = aliveState {
                subFsm.deactivate(binder: info.sleepStatusBinder!)
            }
        }
        .on(.hit)       { event,_,_,healthHolder in
            if case let .hit(hitValue) = event {
                healthHolder.health -= hitValue
                if healthHolder.health <= 0 {
                    return .dead
                }
            }
            return .alive
        }
        .exec(.heal)          { event,_,_,healthHolder in
            if case let .heal(healValue) = event {
                healthHolder.health += healValue
            }
        }
        .exec(.goToSleep) { _,_,binder,info in
            let aliveState  = binder.state!
            if case let .alive(subFsm) = aliveState {
                subFsm.process(event: .goToSleep, binder: info.sleepStatusBinder!)
            }
        }
        .exec(.awake) { _,_,binder,info in
            let aliveState  = binder.state!
            if case let .alive(subFsm) = aliveState {
                subFsm.process(event: .awake, binder: info.sleepStatusBinder!)
            }
        }
    .state(.dead)


    //  Tadaaaaaa !!!

```

OK, declaring the Hierarchical FSM is a bit more complex, mostly because of the `Hashable` part of states and events, but hey ! I bet this is still is pretty straightforward compared to any Hierarchical FSM you've used in the past, right ? Also, how many times are you really using HFSM ?


You can check all the examples, as they are provided in the package Unit Tests.



### The final touch

Yes, but there is a little "one more thing...". In the HFSM example, if you are asleep and you get hit, then you'll end up awaken. While this might be the desired behaviour, what if we want to remain asleep ? Because the hit event starts a transition, we get out of the alive state, and in again, thus deactivating/reactivating the sleep subFSM, thus going back to its initial state.

Well, that's where `memory` comes to the rescue...

If, instead of using `initial`, we use `memory`, then the FSM will remember its last state when reactivated. In that case, the binder to the state must conform to ``StateBinderWithMemory``.


## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
