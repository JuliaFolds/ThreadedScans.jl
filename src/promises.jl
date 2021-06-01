const NOT_READY = 0
const READY = 1
const WAITING = 2
const CLOSED = 3

mutable struct OneWayPromise{T}
    state::Threads.Atomic{Int}
    dummy1::Threads.Atomic{Int}
    dummy2::Threads.Atomic{Int}
    dummy3::Threads.Atomic{Int}
    value::T
    task::Task

    OneWayPromise{T}() where {T} = new{T}(
        Threads.Atomic{Int}(NOT_READY),
        # Dummies:
        Threads.Atomic{Int}(0),
        Threads.Atomic{Int}(0),
        Threads.Atomic{Int}(0),
    )
end
# TODO: remove indirection of `Threads.Atomic` and then add some pads
# TODO: separate put/take handles

function Base.put!(promise::OneWayPromise, value)
    @_assert promise.state[] !== READY "`put!` called twice?"

    # Before the CAS, the caller of `put!` owns `promise.value` field:
    promise.value = value

    # Publish the value:
    old = NOT_READY
    old = Threads.atomic_cas!(promise.state, old, READY)
    if old === WAITING
        old = Threads.atomic_cas!(promise.state, old, READY)
        if old === WAITING
            schedule(promise.task)
        elseif old === CLOSED
            error("promise is closed")
        else
            error("unreachable state: ", old)
        end
    end
    @_assert old in (NOT_READY, WAITING, CLOSED)
    @_assert promise.state[] in (READY, CLOSED)

    return promise
end

function Base.take!(promise::OneWayPromise, ::Nothing = nothing)
    # Before the CAS, the caller of `take!` owns `promise.task` field:
    promise.task = current_task()

    old = NOT_READY
    old = Threads.atomic_cas!(promise.state, old, WAITING)
    @_assert old in (NOT_READY, READY, CLOSED)
    if old === NOT_READY
        wait()
        old = promise.state[]
        @_assert old in (READY, CLOSED)
    end
    if old === CLOSED
        error("promise is closed")
    end
    return promise.value
end

function Base.take!(promise::OneWayPromise, spin::Integer)
    for _ in 1:spin
        state = promise.state[]
        if state === READY
            return promise.value
        end
        if state === CLOSED
            error("promise is closed")
        end
        pause()
    end
    return take!(promise)
end

function Base.close(promise::OneWayPromise)
    old = promise.state[]
    while true
        old === READY && return
        old === CLOSED && return
        state = Threads.atomic_cas!(promise.state, old, CLOSED)
        if state === old
            if state === WAITING
                schedule(promise.task)
            end
            return
        end
    end
end
