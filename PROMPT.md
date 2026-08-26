You are implementing a small Roblox/Luau reactive UI animation framework called `ui`.

This framework is primarily for:
- reactivity
- binding behavior to existing Studio-authored UI
- animation
- events
- pleasant testing/assertions

It is NOT a UI construction framework.

The actual Instances and hierarchy are created manually in Roblox Studio.

The framework should make the behavioral/animation side of UI concise, functional, reactive, composable, and pleasant.

==================================================
0. BEFORE YOU IMPLEMENT ANYTHING
==================================================

Before writing code, inspect the existing project through Studio MCP.

Locate and understand the ACTUAL implementations and APIs of:

- Rx
- Observable
- SpringObject
- AccelTween, if present
- Maid / cleanup utilities, if present/useful
- any existing animation scheduler/utilities that may matter

Rx, Observable, and SpringObject are known to exist in Studio MCP.

DO NOT guess their APIs from this prompt.

The project's actual modules are authoritative.

For design inspiration, study Nevermore's Blend API:

https://quenty.github.io/NevermoreEngine/api/Blend/

Blend is NOT installed in this project.

DO NOT:
- add Blend as a dependency
- vendor Blend
- copy Blend wholesale
- recreate Blend's UI construction system

We are taking inspiration from:
- its Observable-based composition
- Spring/AccelTween concepts
- its general ability to transform reactive inputs

We specifically want our own much smaller API designed around EXISTING Studio UI.

Also take light inspiration from Vide:
- functional feel
- minimal ceremony
- reactive expressions
- simple data flow

But DO NOT make a Vide clone either.

==================================================
1. DESIGN PHILOSOPHY
==================================================

Priorities, in order:

1. Extremely pleasant API
2. Consistency across the entire API
3. Small conceptual surface
4. Functional/data-oriented design
5. Observable interoperability
6. Good animation ergonomics
7. Excellent cleanup semantics
8. Strong `--!strict` Luau typing
9. Good testing/debugging ergonomics
10. Performance

The framework should feel like:

    data -> transformations -> bindings

NOT:

    objects -> methods -> managers -> components

Avoid OOP in the PUBLIC API.

BAD:

    value:Set(10)
    value:Get()
    spring:Impulse(5)
    scope:Bind(...)
    tween:Play()

GOOD:

    value(10)
    value()

    ui.impulse(spring, 5)
    ui.bind(root, {...})
    ui.play(...)

Internals can use whatever structure makes sense.

Externally, operations should generally look like:

    ui.operation(data, ...)

All public module function names MUST use camelCase.

Examples:

    ui.value
    ui.derive
    ui.fromObservable
    ui.accelTween

Not:

    ui.Value
    ui.FromObservable
    ui.AccelTween

==================================================
2. THE MOST IMPORTANT CONSISTENCY RULE
==================================================

There should be ONE unified concept of a reactive input.

Conceptually:

    type Reactive<T> =
        T
        | Value<T>
        | Observable<T>
        | (() -> T)

Where technically reasonable, APIs consuming reactive values should accept the same forms:

    constant
    ui Value
    raw Observable
    reactive function

Examples:

    ui.spring(1)

    ui.spring(scaleTarget)

    ui.spring(scaleObservable)

    ui.spring(function()
        return selected() and 1.2 or 1
    end)

Likewise:

    ui.tween(...)
    ui.accelTween(...)

and property bindings inside:

    ui.bind(...)

should use the same underlying normalization semantics.

DO NOT independently implement reactive input handling inside every feature.

Create ONE internal normalization mechanism.

Conceptually something like:

    observe(input)

or:

    toObservable(input)

The actual internal name does not matter.

The important thing is:

    bind
    spring
    tween
    accelTween
    derive

must not gradually acquire subtly different definitions of "reactive".

There may be contextual exceptions, especially functions inside `ui.bind`, which are described below.

==================================================
3. `ui.value`
==================================================

This is the fundamental primitive.

Usage:

    local count = ui.value(0)

    print(count()) -- 0

    count(10)

    print(count()) -- 10

A writable Value is callable:

    value()
        -> read

    value(newValue)
        -> write

Every Value MUST have an Observable underneath it.

Expose that Observable:

    value.observable

Example:

    local count = ui.value(0)

    count.observable:Subscribe(function(value)
        print(value)
    end)

Observable is the backend/interoperability layer.

Users should NOT need to interact with Observable for ordinary UI code.

Determine exact Observable behavior by inspecting the actual implementation through Studio MCP.

Do not assume its semantics.

Think carefully about:
- initial/current values
- subscriptions
- lazy behavior
- completion
- cleanup
- error behavior

A Value should compose naturally with the project's Rx ecosystem.

==================================================
4. READONLY VALUES
==================================================

Transformations such as:

    ui.derive(...)
    ui.spring(...)
    ui.tween(...)
    ui.accelTween(...)
    ui.fromObservable(...)

should generally return readonly Value-like objects.

They should support:

    result()

and:

    result.observable

But not:

    result(newValue)

unless there is a strong reason for that specific API.

Give a useful error if somebody attempts to write to a readonly Value.

The important idea is:

Consumers should generally NOT care where a Value originated.

These should all feel similar:

    local a = ui.value(10)
    local b = ui.derive(...)
    local c = ui.spring(...)
    local d = ui.tween(...)
    local e = ui.fromObservable(...)

    print(a())
    print(b())
    print(c())
    print(d())
    print(e())

    a.observable
    b.observable
    c.observable
    d.observable
    e.observable

==================================================
5. `ui.fromObservable`
==================================================

Convert an existing Nevermore Observable into the pleasant Value interface.

Usage:

    local value = ui.fromObservable(observable)

    print(value())

    ui.bind(label, {
        Text = value,
    })

The result should generally be readonly.

It still exposes:

    value.observable

Do not introduce permanent subscriptions or leaks simply because `fromObservable` was called.

Nevermore Observables are lazy; inspect the actual implementation and preserve sensible semantics.

Think carefully about what:

    value()

means before the Observable has emitted anything.

Do not silently invent behavior.

If necessary, design a sensible explicit solution and document it.

==================================================
6. `ui.derive`
==================================================

Provide automatic dependency tracking.

Example:

    local first = ui.value(10)
    local second = ui.value(20)

    local total = ui.derive(function()
        return first() + second()
    end)

    print(total()) -- 30

    first(50)

    print(total()) -- 70

Calling a ui Value inside the reactive callback registers it as a dependency.

The result is readonly:

    total()

    total.observable

Nested derivations must work:

    local a = ui.value(10)

    local b = ui.derive(function()
        return a() * 2
    end)

    local c = ui.derive(function()
        return b() + 5
    end)

Think carefully about:
- automatic dependency tracking
- dependency cleanup
- dependencies changing dynamically
- nested derives
- diamond dependency graphs
- duplicate recomputation
- initial evaluation
- errors
- circular dependencies if reasonably detectable
- Observable laziness

Example of changing dependencies:

    local useA = ui.value(true)
    local a = ui.value(1)
    local b = ui.value(2)

    local result = ui.derive(function()
        if useA() then
            return a()
        else
            return b()
        end
    end)

When `useA()` becomes false, `a` should no longer be an active dependency and `b` should become one.

Do not build a gigantic custom reactive runtime if Rx can cleanly handle part of the problem.

But do not force users to manually write Rx pipelines either.

==================================================
7. `ui.peek`
==================================================

Provide an untracked read.

Example:

    local result = ui.derive(function()
        return a() + ui.peek(b)
    end)

Changes to `a` invalidate result.

Changes to `b` do NOT.

Outside a reactive context:

    ui.peek(value)

simply returns its current value.

==================================================
8. `ui.effect`
==================================================

For arbitrary reactive side effects:

    local health = ui.value(100)

    local cleanup = ui.effect(function()
        print("health:", health())
    end)

The function automatically tracks Values read inside it.

When dependencies change, rerun the effect.

Cleanup:

    cleanup()

must stop it completely.

Effects are for SIDE EFFECTS.

Do not make effects the normal way to bind properties.

BAD:

    ui.effect(function()
        frame.Visible = visible()
    end)

GOOD:

    ui.bind(frame, {
        Visible = visible,
    })

Determine and document whether effects execute immediately.

Prefer predictable synchronous initial execution if compatible with the Observable architecture.

==================================================
9. `ui.bind` IS A DEFINING FEATURE
==================================================

The UI hierarchy already exists in Studio.

Example hierarchy:

    ScreenGui
      Ctn
        Element
          UIScale
          ImageLabel
        TextLabel
        Background
        HideButton

We should be able to describe its behavior with:

    ui.bind(ScreenGui, {
        Ctn = {
            Visible = rolling,

            Size = function()
                return UDim2.fromScale(
                    0.3,
                    hidden() and 0.3 or 1
                )
            end,

            Element = {
                Position = function()
                    return UDim2.fromScale(0.5, position())
                end,

                UIScale = {
                    Scale = scale,
                },

                ImageLabel = {
                    ImageTransparency = transparency,
                },
            },

            TextLabel = {
                Rotation = rotation,
            },

            Background = {
                Visible = function()
                    return rolling() and not hidden()
                end,
            },

            HideButton = {
                Visible = rolling,

                Text = function()
                    return getBuilderIcon(
                        hidden() and "eye" or "eye-slash",
                        true
                    )
                end,

                Activated = function()
                    hidden(not hidden())
                end,
            },
        },
    })

NESTING IS ENCOURAGED.

This is not an unfortunate implementation detail.

Nested binding tables are part of the intended aesthetic of the framework.

They act like a behavior sheet for a Studio-authored hierarchy.

==================================================
10. `ui.bind` RESOLUTION RULES
==================================================

`ui.bind(instance, tree)` should interpret each entry based primarily on the TARGET MEMBER.

Conceptually:

    ui.bind(instance, {
        Property = binding,
        Event = handler,
        Child = {
            ...
        },
    })

The behavior should be deterministic.

----------------------------------------
PROPERTY + CONSTANT
----------------------------------------

Example:

    ui.bind(frame, {
        Visible = true,
        BackgroundTransparency = 0.5,
    })

Assign once.

----------------------------------------
PROPERTY + VALUE
----------------------------------------

Example:

    ui.bind(frame, {
        Visible = visible,
    })

Subscribe to the Value's Observable.

Set the property initially/currently and when it changes.

----------------------------------------
PROPERTY + RAW OBSERVABLE
----------------------------------------

Example:

    ui.bind(frame, {
        Visible = visibleObservable,
    })

Subscribe directly.

----------------------------------------
PROPERTY + FUNCTION
----------------------------------------

A function assigned to a PROPERTY is an IMPLICIT reactive expression.

Example:

    ui.bind(frame, {
        Visible = function()
            return enabled() and not hidden()
        end,
    })

This is conceptually equivalent to:

    ui.bind(frame, {
        Visible = ui.derive(function()
            return enabled() and not hidden()
        end),
    })

But avoid unnecessary intermediate objects/subscriptions if bind can implement this more efficiently.

This is extremely important.

Users should NOT need to write:

    Visible = ui.derive(function()
        ...
    end)

for disposable one-off property expressions.

Prefer:

    Visible = function()
        ...
    end

Explicit `ui.derive` remains useful when the derived concept deserves to exist independently.

----------------------------------------
EVENT + FUNCTION
----------------------------------------

If the corresponding Instance member is an RBXScriptSignal/event, a function is an EVENT HANDLER.

Example:

    ui.bind(button, {
        Activated = function()
            open(not open())
        end,
    })

Equivalent behavior to:

    button.Activated:Connect(function()
        open(not open())
    end)

The connection belongs to the binding lifetime.

Event arguments must pass through naturally:

    ui.bind(textBox, {
        FocusLost = function(enterPressed, inputObject)
            print(enterPressed, inputObject)
        end,
    })

Do not wrap event arguments.

----------------------------------------
CHILD + TABLE
----------------------------------------

If the key corresponds to an existing child Instance and the supplied value is a table:

    ui.bind(UI, {
        Ctn = {
            Element = {
                UIScale = {
                    Scale = scale,
                },
            },
        },
    })

recursively descend.

DO NOT create Instances.

==================================================
11. BINDING AMBIGUITY
==================================================

A function has contextual meaning inside bind.

This is intentional:

    ui.bind(button, {
        Visible = function()
            return enabled()
        end,

        Activated = function()
            enabled(not enabled())
        end,
    })

`Visible` is a property.

Therefore the function is reactive.

`Activated` is an event.

Therefore the function is an event handler.

DO NOT globally define:

    function = reactive expression

Functions are interpreted according to context.

The internal normalization layer should support explicit modes/context where necessary.

==================================================
12. BINDING ERRORS
==================================================

Give excellent errors.

If a nested child does not exist:

    ui.bind: Could not resolve "ScreenGui.Ctn.Element.UIScale"

If an event receives something invalid:

    ui.bind(button, {
        Activated = true,
    })

error approximately:

    ui.bind: Expected function for event "Button.Activated", got boolean

If a property gets an invalid nested table:

    ui.bind(frame, {
        Visible = {},
    })

produce a useful error explaining that Visible is a property, not a child binding.

Do not silently ignore invalid bindings.

==================================================
13. BINDING CLEANUP
==================================================

One binding owns EVERYTHING recursively beneath it.

Example:

    local cleanup = ui.bind(UI, {
        Button = {
            Visible = function()
                return enabled()
            end,

            Activated = function()
                enabled(not enabled())
            end,
        },

        Label = {
            Text = function()
                return tostring(count())
            end,
        },
    })

Then:

    cleanup()

must:
- disconnect Button.Activated
- unsubscribe Button.Visible
- unsubscribe Label.Text
- clean reactive expressions
- recursively clean nested bindings
- release all connections/subscriptions owned by bind

Use Maid if the project's Maid implementation makes sense.

Inspect it first.

==================================================
14. `ui.derive` VS IMPLICIT BIND DERIVATION
==================================================

Explicit derive is for shared/named reactive concepts.

Example:

    local canPurchase = ui.derive(function()
        return coins() >= price() and not purchasing()
    end)

Then:

    ui.bind(UI, {
        Purchase = {
            Visible = canPurchase,

            Activated = function()
                if canPurchase() then
                    purchase()
                end
            end,
        },

        InsufficientFunds = {
            Visible = function()
                return not canPurchase()
            end,
        },
    })

This is desirable.

Do not encourage:

    Text = ui.derive(function()
        return tostring(count())
    end)

when:

    Text = function()
        return tostring(count())
    end

is sufficient.

==================================================
15. MOTION VALUES
==================================================

Animation transformations consume reactive inputs and return readonly reactive Values.

Example:

    local target = ui.value(1)

    local scale = ui.spring(target, {
        speed = 30,
        damping = 0.5,
    })

Then:

    scale()
    scale.observable

And:

    ui.bind(frame, {
        UIScale = {
            Scale = scale,
        },
    })

Changing:

    target(1.2)

causes the animated output to react.

The consumer should not care whether something came from:

    ui.value
    ui.derive
    ui.spring
    ui.tween
    ui.accelTween
    ui.fromObservable

==================================================
16. `ui.spring`
==================================================

MUST use the project's SpringObject implementation underneath.

DO NOT write custom spring physics.

Inspect SpringObject through Studio MCP first.

Desired usage:

    local target = ui.value(0)

    local position = ui.spring(target, {
        speed = 20,
        damping = 0.5,
    })

    target(1)

Config:

    ui.spring(input, {
        speed = 20,
        damping = 0.5,
    })

Reasonable defaults are allowed.

Because reactive input semantics should be consistent, these should ideally all work:

    ui.spring(1)

    ui.spring(target)

    ui.spring(targetObservable)

    ui.spring(function()
        return selected() and 1.2 or 1
    end)

The source controls SpringObject's target.

The resulting readonly Value exposes the animated SpringObject position.

Do not create a RenderStepped connection PER SPRING unless SpringObject's architecture genuinely makes that the correct approach.

Prefer a centralized animation scheduler if polling/stepping is necessary.

Investigate SpringObject before deciding.

==================================================
17. `ui.impulse`
==================================================

Provide spring impulses functionally:

    ui.impulse(position, -1)
    ui.impulse(scale, 5)
    ui.impulse(rotation, -240)

NOT:

    scale:Impulse(5)

`ui.spring` may carry private metadata identifying its SpringObject/backend.

That metadata should remain invisible during ordinary usage.

`ui.impulse` should validate that the supplied Value supports impulses.

Bad usage should produce a useful error:

    ui.impulse(normalValue, 5)

Do not silently do nothing.

Support whatever datatypes SpringObject genuinely supports.

==================================================
18. `ui.snap`
==================================================

Provide functional immediate snapping:

    ui.snap(scale)

For a spring, this should immediately place it at the requested target/current intended state.

Determine sensible semantics for other motion Values.

If snap does not make conceptual sense for a motion type, fail clearly instead of inventing strange behavior.

==================================================
19. `ui.accelTween`
==================================================

Use the project's existing AccelTween implementation IF IT EXISTS.

Inspect Studio MCP.

Take inspiration from Blend's AccelTween Observable transformation.

Desired API:

    local target = ui.value(0)

    local position = ui.accelTween(target, {
        acceleration = 30,
    })

The result:

    position()
    position.observable

Again, support the unified reactive input forms where reasonable.

If AccelTween does NOT exist in the project:

DO NOT secretly implement a replacement.

Structure the adapter cleanly and report that the dependency is missing.

==================================================
20. `ui.tween`
==================================================

Provide a normal duration/easing based tween.

Usage:

    local target = ui.value(0)

    local transparency = ui.tween(target, {
        duration = 0.2,
        easing = ui.ease.quadOut,
    })

When target changes:

    target(1)

animate from the CURRENT rendered value to the new target.

If retargeted halfway:

    target(0.5)

continue smoothly from the current rendered state.

Support common Roblox interpolatable types where practical:

- number
- Vector2
- Vector3
- UDim
- UDim2
- Color3
- CFrame, if reasonable

Centralize interpolation.

Do not duplicate interpolation code throughout the framework.

Do not overengineer obscure datatypes.

==================================================
21. EASING
==================================================

Expose simple functions:

    ui.ease.linear

    ui.ease.quadIn
    ui.ease.quadOut
    ui.ease.quadInOut

    ui.ease.cubicIn
    ui.ease.cubicOut
    ui.ease.cubicInOut

Potentially:

    ui.ease.sineIn
    ui.ease.sineOut
    ui.ease.sineInOut

    ui.ease.backOut

if they remain small and useful.

An easing function should simply be conceptually:

    (number) -> number

Do not create easing objects/classes.

==================================================
22. REACTIVE MOTION CONFIG
==================================================

Design the architecture so reactive motion configuration is POSSIBLE, but do not overcomplicate v1 merely to support it.

For example, it may eventually be useful to allow:

    local speed = ui.value(20)

    local scale = ui.spring(target, {
        speed = speed,
        damping = function()
            return selected() and 0.5 or 0.8
        end,
    })

If SpringObject makes this straightforward, supporting it is desirable because it follows the framework's consistency rule.

But input target reactivity is much more important than reactive configuration.

Do not compromise the core implementation for this.

==================================================
23. EVENTS ARE NOT AUTOMATICALLY OBSERVABLES
==================================================

Do NOT force every Roblox event into Rx.

This is good:

    ui.bind(button, {
        Activated = function()
            clicked(clicked() + 1)
        end,
    })

And ordinary Roblox code remains valid:

    button.Activated:Connect(...)

Do not introduce:

    ui.event(...)
    ui.useEvent(...)
    ui.observeEvent(...)

unless there is a demonstrated need later.

Rx remains available as an escape hatch for advanced stream behavior.

==================================================
24. OBSERVABLE INTEROPERABILITY
==================================================

This is CRITICAL.

A Value exposes:

    value.observable

Raw Observables should be usable directly where reactive inputs are accepted.

Example:

    ui.bind(frame, {
        Visible = observable,
    })

And:

    local value = ui.fromObservable(observable)

Advanced users should be able to intentionally drop down into Rx:

    local observable = value.observable:Pipe({
        Rx.map(...),
        Rx.throttleDefer(),
    })

Then come back:

    local result = ui.fromObservable(observable)

The philosophy is:

    ui = pleasant common case

    Rx / Observable = powerful escape hatch

DO NOT recreate dozens of Rx operators.

==================================================
25. ANIMATION COMPOSITION
==================================================

Keep this feature SMALL.

We may want readable one-off animation sequences:

    ui.play({
        ui.parallel({
            ui.to(scaleTarget, 1.2, {
                spring = {
                    speed = 40,
                    damping = 0.5,
                },
            }),

            ui.to(rotationTarget, 15, {
                tween = {
                    duration = 0.15,
                    easing = ui.ease.quadOut,
                },
            }),
        }),

        ui.wait(0.2),

        ui.to(scaleTarget, 1),
    })

Animation commands should be plain tagged DATA.

Conceptually:

    {
        kind = "to",
        value = scaleTarget,
        target = 1.2,
        motion = ...,
    }

Potential API:

    ui.to(...)
    ui.wait(...)
    ui.call(...)
    ui.parallel({...})
    ui.sequence({...})
    ui.play(...)

Passing a table directly to:

    ui.play({...})

may imply sequence.

`ui.play` returns a cancellation/cleanup function.

This is LOWER PRIORITY than:

    value
    derive
    bind
    spring
    tween
    events

Do not let the animation DSL become a framework inside the framework.

==================================================
26. TESTING / ASSERTION API
==================================================

Bundle a tiny pleasant assertion API.

I specifically want fluent syntax like:

    ui.expect(value()).toBe(10)

    ui.expect(frame.Visible).toBe(true)

This should feel nice enough that testing UI/reactive code is enjoyable.

Initial API:

    ui.expect(actual).toBe(expected)

    ui.expect(actual).toEqual(expected)

    ui.expect(actual).toBeTruthy()

    ui.expect(actual).toBeFalsy()

    ui.expect(actual).toBeNil()

    ui.expect(actual).toBeNear(expected, epsilon?)

Exception assertions:

    ui.expect(function()
        error("boom")
    end).toThrow()

    ui.expect(function()
        error("boom")
    end).toThrow("boom")

Negation should be pleasant.

Preferred if it works cleanly in Luau:

    ui.expect(actual).never.toBe(expected)

Otherwise:

    ui.expect(actual).not_.toBe(expected)

Choose whichever produces the cleanest implementation/types.

Do not create a giant testing framework.

==================================================
27. ASSERTION FAILURE MESSAGES
==================================================

Failure messages should be genuinely useful.

Example:

    Expected:
        10

    Received:
        12

For tables:

    ui.expect(actual).toEqual(expected)

should perform meaningful deep equality and produce readable representations.

Think about:
- nested tables
- arrays
- Roblox datatypes
- Instance references
- strings
- nil
- NaN if relevant

Do not spend enormous complexity producing Jest-quality diffs.

Just make failures clean and readable.

==================================================
28. OPTIONAL REACTIVE ASSERTIONS
==================================================

It may eventually be useful to support:

    ui.expect(value).toEventuallyBe(10)

or Observable-related assertions.

DO NOT implement these in v1 unless they can be done cleanly and deterministically.

The synchronous assertion API matters much more.

Keep the testing implementation isolated from the reactive runtime.

==================================================
29. CLEANUP MODEL
==================================================

Anything that OWNS subscriptions/connections must have deterministic cleanup.

Examples:

    local cleanup = ui.bind(...)
    cleanup()

    local cleanup = ui.effect(...)
    cleanup()

    local cancel = ui.play(...)
    cancel()

Do not add public:

    :Destroy()

everywhere just because Roblox libraries commonly do.

If Values themselves need explicit destruction due to implementation realities, investigate whether this indicates a lifetime architecture problem first.

Nevermore Observables are lazy, so avoid hidden permanent subscriptions.

Use Maid internally if appropriate.

==================================================
30. PERFORMANCE / DATA-ORIENTED DESIGN
==================================================

Prefer data-oriented internals where they genuinely help.

Potentially:

- centralized animation scheduler
- dense arrays of active tween records
- dense arrays of active spring observation records
- swap-remove inactive records
- no table allocations every frame
- avoid one RunService connection per animation
- only update active animation records
- avoid assigning Roblox properties when the value hasn't changed if cheap to detect

For example, instead of:

    SpringA -> RenderStepped connection
    SpringB -> RenderStepped connection
    SpringC -> RenderStepped connection

prefer something conceptually like:

    RunService
        |
        v
    motionScheduler
        |
        +-- SpringA
        +-- SpringB
        +-- SpringC

IF SpringObject requires polling.

But inspect SpringObject first.

It may expose functionality that changes the optimal architecture.

DOD does NOT mean "never mutate anything".

Mutable internal animation records are fine.

The important thing is separating DATA from OPERATIONS and avoiding an OOP-heavy public API.

==================================================
31. TYPES
==================================================

Everything should use:

    --!strict

Invest effort into useful exported types.

In particular:

    Value<T>
    ReadonlyValue<T>

should preserve T reasonably well.

Reactive input types should also preserve T where possible.

Do not destroy ergonomics attempting perfect typing of arbitrary recursively nested Roblox hierarchies.

`ui.bind` will necessarily have dynamic boundaries because property/child/event resolution happens against Instances.

Using `any` at unavoidable dynamic Roblox reflection boundaries is preferable to creating an unusable generic monster.

Avoid `any` elsewhere where practical.

==================================================
32. INTERNAL STRUCTURE
==================================================

Do not blindly follow this structure if project conventions suggest something better.

A reasonable shape might be:

    ui/
        init.lua

        reactive/
            value.lua
            derive.lua
            effect.lua
            tracking.lua
            input.lua
            observable.lua

        binding/
            bind.lua
            resolve.lua

        motion/
            scheduler.lua
            spring.lua
            accelTween.lua
            tween.lua
            easing.lua
            interpolate.lua

        animation/
            commands.lua
            play.lua

        testing/
            expect.lua
            format.lua
            equal.lua

        utility/
            cleanup.lua

The consumer should generally only need:

    local ui = require(...)

==================================================
33. CORE TESTS: VALUE
==================================================

Test:

- initial read
- write
- multiple writes
- Observable receives changes
- multiple Observable subscribers
- unsubscribe behavior
- readonly values reject writes
- errors are useful

==================================================
34. CORE TESTS: DERIVE
==================================================

Test:

- one dependency
- multiple dependencies
- nested derivations
- dependency graph changes
- peek does not track
- readonly behavior
- diamond dependency graphs
- cleanup/lazy behavior
- errors inside derivations
- unnecessary duplicate recomputation if relevant

==================================================
35. CORE TESTS: EFFECT
==================================================

Test:

- initial execution
- dependency changes
- multiple dependencies
- dynamic dependencies
- cleanup
- no execution after cleanup

==================================================
36. CORE TESTS: FROM OBSERVABLE
==================================================

Test:

- receives emissions
- exposes underlying Observable
- current value behavior
- subscription cleanup
- completion behavior if relevant
- error behavior if relevant

==================================================
37. CORE TESTS: BIND PROPERTIES
==================================================

Test constants:

    Visible = true

Test Value:

    Visible = visible

Test Observable:

    Visible = observable

Test reactive function:

    Visible = function()
        return enabled()
    end

Test:
- initial property assignment
- updates
- multiple dependencies
- dynamic dependencies
- nested hierarchy
- multiple nested levels
- cleanup
- invalid property
- missing child
- useful error paths

==================================================
38. CORE TESTS: BIND EVENTS
==================================================

Test:

    local clicks = ui.value(0)

    ui.bind(button, {
        Activated = function()
            clicks(clicks() + 1)
        end,
    })

Ensure:
- handler connects
- handler executes
- handler can mutate Values
- event arguments pass through
- cleanup disconnects event
- invalid event handler gives useful error

Most importantly, test mixed usage:

    local enabled = ui.value(true)
    local clicks = ui.value(0)

    ui.bind(button, {
        Visible = function()
            return enabled()
        end,

        Text = function()
            return `Clicks: {clicks()}`
        end,

        Activated = function()
            clicks(clicks() + 1)
        end,
    })

All three must coexist naturally.

==================================================
39. CORE TESTS: SPRING
==================================================

Test:

- actually uses SpringObject
- initial state
- target changes
- Observable emissions
- Value reads
- impulse
- snap
- cleanup
- no leaked frame connections
- multiple simultaneous springs
- constants as input
- Values as input
- Observables as input
- reactive functions as input if supported

==================================================
40. CORE TESTS: ACCEL TWEEN
==================================================

If AccelTween exists:

Test:
- actually uses AccelTween
- target changes
- Observable emissions
- Value reads
- cleanup
- supported reactive inputs

If it doesn't exist:

Do not fake it.

==================================================
41. CORE TESTS: TWEEN
==================================================

Test:
- initial state
- reaches target
- retargets while running
- starts retarget from current rendered value
- easing
- number interpolation
- Vector2
- Vector3
- UDim
- UDim2
- Color3
- cleanup/cancellation
- no leaked frame connections
- multiple simultaneous tweens

==================================================
42. CORE TESTS: EXPECT
==================================================

Test:

    toBe
    toEqual
    toBeTruthy
    toBeFalsy
    toBeNil
    toBeNear
    toThrow
    negation

Test failure messages too.

==================================================
43. DESIRED REAL-WORLD USAGE
==================================================

This example represents the intended feel of the framework.

If the implementation makes this substantially uglier, reconsider the architecture.

    local ui = require(...)

    local hidden = ui.value(false)
    local rolling = ui.value(false)

    local positionTarget = ui.value(0.5)
    local scaleTarget = ui.value(1)
    local rotationTarget = ui.value(0)
    local fovTarget = ui.value(70)

    local position = ui.spring(positionTarget, {
        speed = 20,
        damping = 0.5,
    })

    local scale = ui.spring(scaleTarget, {
        speed = 30,
        damping = 0.5,
    })

    local rotation = ui.spring(rotationTarget, {
        speed = 40,
        damping = 0.5,
    })

    local fov = ui.spring(fovTarget, {
        speed = 2,
    })

    ui.bind(UI, {
        Ctn = {
            Visible = rolling,

            Size = function()
                return UDim2.fromScale(
                    0.3,
                    hidden() and 0.3 or 1
                )
            end,

            Element = {
                Position = function()
                    return UDim2.fromScale(0.5, position())
                end,

                UIScale = {
                    Scale = scale,
                },

                ImageLabel = {
                    ImageTransparency = ui.tween(function()
                        return hidden() and 1 or 0
                    end, {
                        duration = 0.15,
                        easing = ui.ease.quadOut,
                    }),
                },
            },

            TextLabel = {
                Rotation = rotation,
            },

            Background = {
                Visible = function()
                    return rolling() and not hidden()
                end,
            },

            HideButton = {
                Visible = rolling,

                Text = function()
                    return getBuilderIcon(
                        hidden() and "eye" or "eye-slash",
                        true
                    )
                end,

                Activated = function()
                    hidden(not hidden())
                end,
            },
        },
    })

    ui.bind(workspace.CurrentCamera, {
        FieldOfView = fov,
    })

    local function rollEffect()
        ui.impulse(position, -1)
        ui.impulse(scale, 5)
        ui.impulse(rotation, -240)
    end

Notice what is NOT present:

- no RunService loop in UI code
- no manual property subscriptions
- no manual event cleanup
- no explicit derive for disposable property expressions
- no components
- no hooks
- no virtual DOM
- no animation objects with public methods
- no giant Rx pipelines

==================================================
44. ANOTHER DESIRED EXAMPLE
==================================================

A button should be this simple:

    local ui = require(...)

    local hovered = ui.value(false)
    local pressed = ui.value(false)
    local enabled = ui.value(true)

    local scale = ui.spring(function()
        if pressed() then
            return 0.95
        elseif hovered() then
            return 1.05
        else
            return 1
        end
    end, {
        speed = 35,
        damping = 0.7,
    })

    ui.bind(Button, {
        Active = enabled,

        BackgroundTransparency = function()
            return enabled() and 0 or 0.5
        end,

        UIScale = {
            Scale = scale,
        },

        MouseEnter = function()
            hovered(true)
        end,

        MouseLeave = function()
            hovered(false)
            pressed(false)
        end,

        MouseButton1Down = function()
            pressed(true)
        end,

        MouseButton1Up = function()
            pressed(false)
        end,

        Activated = function()
            if enabled() then
                print("clicked")
            end
        end,
    })

This is the kind of consistency we want.

State:

    ui.value

Transformation:

    ui.spring

Reactive property:

    Property = function() ... end

Reactive Value property:

    Property = value

Event:

    Event = function(...) ... end

Hierarchy:

    Child = {
        ...
    }

It should be immediately understandable.

==================================================
45. THINGS I EXPLICITLY DO NOT WANT
==================================================

DO NOT introduce:

- components
- hooks
- JSX
- React concepts
- virtual DOM
- UI construction
- lifecycle methods
- public classes
- public animation objects with methods
- `:set()`
- `:get()`
- `:bind()`
- `:spring()`
- verbose Rx for normal usage
- duplicated Rx operators
- giant scope/context systems
- every Roblox event becoming an Observable
- a giant animation timeline language
- custom spring physics
- Blend as a runtime dependency
- unnecessary wrappers around Roblox events
- one RunService connection per animation if avoidable
- magic that silently ignores invalid bindings

==================================================
46. PUBLIC API TARGET
==================================================

The CORE should ideally fit approximately within:

    ui.value(initial)
    ui.fromObservable(observable)

    ui.derive(fn)
    ui.peek(value)
    ui.effect(fn)

    ui.bind(instance, bindings)

    ui.spring(input, config?)
    ui.accelTween(input, config?)
    ui.tween(input, config?)

    ui.impulse(motion, amount)
    ui.snap(motion)

    ui.expect(actual)

    ui.ease.*

Secondary animation composition:

    ui.to(...)
    ui.wait(...)
    ui.call(...)
    ui.parallel(...)
    ui.sequence(...)
    ui.play(...)

Do not add public functions casually.

Every new public function should justify why the existing primitives cannot express the use case cleanly.

==================================================
47. IMPLEMENTATION PROCESS
==================================================

DO NOT immediately implement the entire framework.

Work in this order.

STEP 1:
Inspect the project structure and conventions.

STEP 2:
Inspect Rx.

Understand:
- operators
- subscription semantics
- cleanup
- scheduling
- laziness

STEP 3:
Inspect Observable.

Understand:
- Observable.new
- Subscribe
- subscription lifetime
- completion
- failure
- lazy execution

STEP 4:
Inspect SpringObject.

Understand:
- construction
- target
- position
- velocity
- speed
- damping
- impulse
- stepping/time behavior
- supported datatypes

STEP 5:
Inspect AccelTween if present.

STEP 6:
Inspect Maid/cleanup conventions.

STEP 7:
Study Blend's public API for architectural inspiration.

Do not copy its construction API.

STEP 8:
Before implementing, propose the internal architecture.

Specifically explain:
- Value representation
- readonly Value representation
- Observable ownership
- dependency tracking
- reactive input normalization
- bind member resolution
- event handling
- spring scheduling
- tween scheduling
- cleanup/lifetime model

STEP 9:
Show several representative end-user examples.

Check them against this prompt.

STEP 10:
Implement:

    ui.value
    ui.fromObservable
    ui.derive
    ui.peek
    ui.effect

STEP 11:
Test the reactive core thoroughly.

STEP 12:
Implement:

    ui.bind

including:
- properties
- reactive functions
- raw Observables
- nested children
- events
- cleanup

STEP 13:
Test bind thoroughly.

STEP 14:
Implement:

    ui.spring
    ui.impulse
    ui.snap

using SpringObject.

STEP 15:
Test spring thoroughly.

STEP 16:
Implement:

    ui.accelTween

only if the dependency exists.

STEP 17:
Implement:

    ui.tween
    ui.ease

STEP 18:
Test motion thoroughly.

STEP 19:
Implement:

    ui.expect

STEP 20:
Test assertions.

STEP 21:
Only after the core feels excellent, consider:

    ui.to
    ui.wait
    ui.call
    ui.parallel
    ui.sequence
    ui.play

==================================================
48. API DESIGN CHECKPOINT
==================================================

Before finalizing any API decision, ask:

    "Would a user reasonably expect this to work here
    because something very similar works somewhere else?"

For reactive INPUTS, aim for:

    constant
    Value
    Observable
    function

For reactive OUTPUTS, aim for:

    readonly callable Value
    .observable escape hatch

For mutable state:

    local state = ui.value(initial)

    state()
    state(new)

For operations:

    ui.operation(data, ...)

For lifetime-owning operations:

    local cleanup = ui.operation(...)
    cleanup()

For Studio hierarchy behavior:

    ui.bind(root, {
        ...
    })

For a property:

    Property = constant
    Property = value
    Property = observable
    Property = function() ... end

For an event:

    Event = function(...) ... end

For a child:

    Child = {
        ...
    }

If you introduce an exception to these rules, there should be a concrete technical reason.

==================================================
49. FINAL GOAL
==================================================

The framework should feel SMALL.

A programmer should understand roughly 80% of it from:

    ui.value
    ui.derive
    ui.bind
    ui.spring
    ui.tween
    ui.expect

The underlying implementation can be sophisticated.

The surface should not feel sophisticated.

Observable should feel like infrastructure, not ceremony.

SpringObject should feel like infrastructure, not ceremony.

Rx should feel like an escape hatch, not ceremony.

Studio should remain the place where the UI hierarchy is designed.

`ui` should simply make that hierarchy behave beautifully.