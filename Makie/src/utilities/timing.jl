struct TrackedTask
    isrunning::Threads.Atomic{Bool}
    task::Task
end

Base.istaskdone(t::TrackedTask) = !t.isrunning[] || istaskdone(t.task)
const TRACKED_TASKS = TrackedTask[]
const TRACKED_TASKS_LOCK = Base.ReentrantLock()
const HAS_ATEXIT = Base.RefValue(false)

Base.wait(t::TrackedTask) = wait(t.task)

function Base.close(t::TrackedTask)
    t.isrunning[] = false
    yield()
    istaskdone(t.task) && return
    wait(t.task)
    return
end

function cleanup_tasks()
    for ttask in TRACKED_TASKS
        close(ttask)
    end
    empty!(TRACKED_TASKS)
    return
end

function async_tracked(f)
    isrunning = Threads.Atomic{Bool}(true)
    task = @async begin
        try
            f(isrunning)
        finally
            @lock TRACKED_TASKS_LOCK begin
                # Remove the task from the tracked tasks
                isrunning[] = false
                filter!(!istaskdone, TRACKED_TASKS)
            end
        end
    end
    ttask = TrackedTask(isrunning, task)

    @lock TRACKED_TASKS_LOCK push!(TRACKED_TASKS, ttask)

    if HAS_ATEXIT[]
        atexit(cleanup_tasks)
        HAS_ATEXIT[] = true
    end
    return ttask
end


mutable struct BudgetedTimer
    callback::Any

    target_delta_time::Float64
    min_sleep::Float64
    budget::Float64
    last_time::UInt64

    running::Bool
    task::Union{Nothing, TrackedTask}

    function BudgetedTimer(callback, delta_time::Float64, running::Bool, task::Union{Nothing, Task}, min_sleep = 0.015)
        return new(callback, delta_time, min_sleep, 0.0, time_ns(), running, task)
    end
end

"""
    BudgetedTimer(target_delta_time)
    BudgetedTimer(callback, target_delta_time[, start = true])

A timer that keeps track of a time budget between invocations of `sleep(timer)`,
`busysleep(timer)` or roundtrips of the timed task. The budget is then used to
correct the next sleep so that the average sleep time matches the targeted delta
time.

To avoid lag spikes from hurrying the timer for multiple iterations/invocations
only the difference to the nearest multiple of `target_delta_time` is counted.
E.g. if two calls to `sleep(timer)` are 2.3 delta times apart, 0.3 will be
relevant difference for the budget.
"""
function BudgetedTimer(delta_time::AbstractFloat; min_sleep = 0.015)
    return BudgetedTimer(identity, delta_time, false, nothing, min_sleep)
end

function BudgetedTimer(callback, delta_time::AbstractFloat, start = true; min_sleep = 0.015)
    timer = BudgetedTimer(callback, delta_time, true, nothing, min_sleep)
    if start
        timer.task = async_tracked() do isrunning
            while timer.running && isrunning[]
                timer.callback(timer)
                sleep(timer)
            end
        end
    end
    return timer
end

function start!(timer::BudgetedTimer)
    timer.budget = 0.0
    timer.last_time = time_ns()
    timer.running = true
    timer.callback(timer) # error check
    timer.task = async_tracked() do isrunning
        while timer.running && isrunning[]
            sleep(timer)
            timer.callback(timer)
        end
    end
    return
end

function start!(callback, timer::BudgetedTimer)
    timer.callback = callback
    return start!(timer)
end

function set_callback!(callback, timer::BudgetedTimer)
    return timer.callback = callback
end

function stop!(timer::BudgetedTimer)
    timer.running = false
    return
end

function Base.close(timer::BudgetedTimer)
    timer.callback = identity
    return stop!(timer)
end

function reset!(timer::BudgetedTimer, delta_time = timer.target_delta_time)
    timer.target_delta_time = delta_time
    timer.budget = 0.0
    return timer.last_time = time_ns()
end

function update_budget!(timer::BudgetedTimer)
    # The real time that has passed
    t = time_ns()
    time_passed = 1.0e-9 * (t - timer.last_time)
    # Update budget
    diff_to_target = timer.target_delta_time + timer.budget - time_passed
    if diff_to_target > -0.5 * timer.target_delta_time
        # used 0 .. 1.5 delta_time, keep difference (1 .. -0.5 delta times) as budget
        timer.budget = diff_to_target
    else
        # more than 1.5 delta_time used, get difference to next multiple of
        # delta_time as the budget
        timer.budget = (
            (diff_to_target - 0.5 * timer.target_delta_time)
                % timer.target_delta_time
        ) + 0.5 * timer.target_delta_time
    end
    timer.last_time = t
    return
end

"""
    sleep(timer::BudgetedTimer)

Sleep until one `timer.target_delta_time` has passed since the last call to
`sleep(timer)` or `busysleep(timer)` with the current time budget included.

This only relies on `Base.sleep()` for waiting.

This always yields to other tasks.
"""
function Base.sleep(timer::BudgetedTimer)
    # time since last sleep
    time_passed = 1.0e-9 * (time_ns() - timer.last_time)
    # How much time we should sleep for considering the real time we slept
    # for in the last iteration and biasing for the minimum sleep time
    sleep_time = timer.target_delta_time + timer.budget - time_passed - 0.5 * timer.min_sleep
    if sleep_time > 0.0
        sleep(sleep_time)
    else
        yield()
    end

    update_budget!(timer)
    return
end

"""
    busysleep(timer::BudgetedTimer)

Sleep until one `timer.target_delta_time` has passed since the last call to
`sleep(timer)` or `busysleep(timer)` with the current time budget included.

This uses `Base.sleep()` for an initial longer sleep and a time-checking while
loop for the remaining time for more precision.

This always yields to other tasks.
"""
function busysleep(timer::BudgetedTimer)
    # use normal sleep as much as possible
    time_passed = 1.0e-9 * (time_ns() - timer.last_time)
    sleep_time = timer.target_delta_time - time_passed + timer.budget - timer.min_sleep
    if sleep_time > 0.0
        sleep(sleep_time)
    else
        yield()
    end

    # busy sleep remaining time
    time_passed = 1.0e-9 * (time_ns() - timer.last_time)
    sleep_time = timer.target_delta_time - time_passed + timer.budget
    while time_ns() < timer.last_time + 1.0e9 * timer.target_delta_time + timer.budget
        yield()
    end

    update_budget!(timer)
    return
end
