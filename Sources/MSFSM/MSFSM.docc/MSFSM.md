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
        .on(.hit)           { _,_,_ in return .wounded }
        .on(.severeHit)     { _,_,_ in return .dead }
    .state(.wounded)
        .on(.hit)           { _,_,_ in return .dead }
        .on(.severeHit)     { _,_,_ in return .dead }
        .on(.heal)          { _,_,_ in return .healthy }
    .state(.dead)
```

Easy no ? So clean, so readable...

One thing to note is that when you declare  an FSM structure, **there shall be one (and only one) initial state** (declared with `initial` instead of `state`). Forgetting the initial state (or declaring two) is a programmer error. It doesn't have to be the first declared one, but let's say it is a kind of convention.

You can also see that the State and Event types are provided as generic parameters, but we'll come back on that later.


### Separation of state

The ``SimplestFSM`` class holds its own `state` property, so it comes as ready-to-use configurable FSM. But most of the time, you need more. You need that the FSM rules one of your class property. That's where separation of state comes handy. Just have a look at that:

```

let healthFSMStructure  = FSMStructure<MyClass, Void, Event>()
    .initial(.healthy)
        .on(.hit)           { _,_,_ in return .wounded }
        .on(.severeHit)     { _,_,_ in return .dead }
    .state(.wounded)
        .on(.hit)           { _,_,_ in return .dead }
        .on(.severeHit)     { _,_,_ in return .dead }
        .on(.heal)          { _,_,_ in return .healthy }
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

What if you want to bind the FSM state to a property named differently than `state`, or what if you want to bind two different properties to two differents FSM structures ? Yes, the ``StateBinder`` helps you there too !

For example, let's say, you have something like this:

```
protocol HasHealthStatus {
    var healthStatus: State? { get set }
}

class HumanWarrior: HasHealthStatus {
    var healthStatus: State?
}
```

And you want that the FSM influences the healthStatus property, instead of a `state`property. What you could do is simply:

```
class HealthStatusBinder: StateBinder {
    weak var bindedHealthStatusHolder: HasHealthStatus!
    
    var state: State? {
        get { bindedHealthStatusHolder.healthStatus }
        set { bindedHealthStatusHolder.healthStatus = newValue }
    }
    
    init(bindedHealthStatusHolder: HasHealthStatus) {
        self.bindedHealthStatusHolder = bindedHealthStatusHolder
    }
}

class HumanWarrior: HasHealthStatus {
    
    var healthStatus: State?
    var healthStatusBinder: HealthStatusBinder!

    let fsm:    BindableFSM<HealthStatusBinder, Void, Event>
    
    init() {
        self.fsm = BindableFSM(structure: healthFSMStructure)
        self.healthStatusBinder = HealthStatusBinder(bindedHealthStatusHolder: self)
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

//  Define a character that has a health
class Character: HasHealth, StateBinder {
    var state: State?
    var health: Int  = 100
}

let fsmStructure = FSMStructure<Character, Void, Event>()
    .initial(.alive)
        .on(.hit)        { event,character,_ in
            character.health -= event.value
            if character.health <= 0 {
                return .dead
            }
            return .alive
        }
        .on(.heal)          { event,character,_ in
            character.health += event.value
            return .alive
        }
    .state(.dead)
```

See how we have defined a transition that can end up in one state or another, depending on the value of the event ?

We will come back to the power of generics when we talk about hierarchical FSM later.



### State callbacks and event transitions

States can be given **callbacks** that are called:
- When the state is entered `didEnter`. And when the state is left `willLeave`. Parameters are the state binder, and an user info that can be anything. See ``StateEnterOrLeaveCallback``
- When inside the state, as a regular call `update`. Its parameters are a time reference `TimeInterval`, the state binder, and an user info that can be anything. It return an optional of an event. This is handy when you want to e.g. wait for a certain amount of time and then send a wake up event. See ``StateUpdateCallback``. It is up to the programmer to call the update callback regularly (or when he/she wants).

Events can start *transition callbacks*, or *execution callbacks*. The difference between a transition and an execution callback is that **transition callbacks return the next state** (which can be the current state), whereas **execution callbacks don't return a state**, leaving the FSM in the same state. If a transition callback returns the current state, the `willLeave` and `didEnter` callbacks of the state will be executed.

You declare an execution callback using `.exec` instead of `.on`. Both take the event, the binder, and an user info that can be anything. Execution callback are very usefull when defining Hierarchical FSM.

See ``TransitionCallback`` and ``ExecutionCallback``.



### Hierarchical FSM

Yes ! That's possible ! By leveraging the power of the generics and the state and event callback, we can very simply build hierarchical FSM, still with this beautifull declarative syntax.

Let's do this:

![FSM3](FSM3.png)




## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
