# MSFSM

This package is yet-another Finite State Machine package. Yes, just yet-another FSM package... but with some really cool features...



## Overview

So what does it bring ? Where's the added value ? Well, this package provides:

- A **generic definition** of the FSM elements such as states and events, so that you can use whatever type you want for that. OK, kind of cool, but 'déjà vu'...
- A **declarative syntax** for defining the FSM in simple and expressive way. That's something...

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

- And it allows complex FSM features such as **Hierarchical FSM**, or **multi-token FSM**, or **on-event transition to several possible states** to be implemented very simply. Yes baby !



## Doc and Unit Tests

Beyond the code, the package comes with **full DocC documentation**, and **unit tests covering 91,4% of the code**. The uncovered part is just basic error handling that calls fatalerror upon programmer errors.

