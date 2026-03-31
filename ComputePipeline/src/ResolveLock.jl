mutable struct YieldingSpinLock <: Base.AbstractLock
    # pad so this doesn't get pulled to the CPU with other stuff
    @atomic owned::Int

    function YieldingSpinLock()
        l = new()
        @atomic l.owned = 0
        return l
    end
end

Base.assert_havelock(l::YieldingSpinLock) = islocked(l) ? nothing : Base.concurrency_violation()

function Base.lock(l::YieldingSpinLock)
    while true
        if @inline trylock(l)
            return
        end
        yield()
    end
end

function Base.trylock(l::YieldingSpinLock)
    if l.owned::Int == 0
        GC.disable_finalizers()
        p = (@atomicswap :acquire l.owned = 1)::Int
        if p == 0
            return true
        end
        GC.enable_finalizers()
    end
    return false
end

function Base.unlock(l::YieldingSpinLock)
    if (@atomicswap :release l.owned = 0)::Int == 0
        error("unlock count must match lock count")
    end
    GC.enable_finalizers()
    return
end

function Base.islocked(l::YieldingSpinLock)
    return (@atomic :monotonic l.owned)::Int != 0
end


#=
Thought behind this lock:

lock(l), unlock(l):
- lock for updating values, which is a brief lock
- lock() similar to SpinLock:
    - use `@atomic locked` to identify ownership
    - if acquired and not in resolve mode: done
    - if acquired and in resolve mode: drop, wait on signal from resolve unlock
    - if not acquired: yield, retry
- unlock() releases like SpinLock - drop ownership in locked

lock(l, id), unlock(l, id)
- lock for resolve, which allows id based reentry
- lock():
    - get ownership (yield and retry until success)
    - if no id: set id, set count = 1, release ownership, return
    - if this id: increment count, release ownership, return
    - if other id: wait on unlock signal, retry
- unlock():
    - get ownership (yield and retry until success)
    - if this id: decrement count
        - if count == 0: clear id, notify once
=#


mutable struct ResolveLock <: Base.AbstractLock
    # pad so this doesn't get pulled to the CPU with other stuff
    @atomic locked::Int
    owned_by::UInt64
    count::Int64
    release::Base.ThreadSynchronizer

    function ResolveLock()
        l = new()
        @atomic l.locked = 0
        l.owned_by = 0
        l.count = 0
        l.release = Base.ThreadSynchronizer()
        return l
    end
end

function generate_lock_key()
    id = hash(Base.current_task(), time_ns())
    return id === 0 ? generate_id() : id
end

Base.assert_havelock(l::ResolveLock) = islocked(l) ? nothing : Base.concurrency_violation()

function Base.trylock(l::ResolveLock)
    if l.locked::Int == 0
        GC.disable_finalizers()
        p = (@atomicswap :acquire l.locked = 1)::Int
        if p == 0
            return true
        end
        GC.enable_finalizers()
    end
    return false
end

function Base.lock(l::ResolveLock)
    while true
        if @inline trylock(l)
            if l.owned_by == 0
                # was fully unlocked, now it's ours
                return true
            else
                # in use by shared version, give up lock and wait for shared
                # release
                @atomic :release l.locked = 0
                lock(l.release)
                if l.owned_by == 0
                    unlock(l.release)
                    continue
                end
                wait(l.release)
                unlock(l.release)
            end
        end
        yield()
    end
    return false
end

function Base.unlock(l::ResolveLock)
    if (@atomicswap :release l.locked = 0)::Int == 0
        error("unlock count must match lock count")
    end
    GC.enable_finalizers()
    return
end

function Base.lock(l::ResolveLock, id)
    while true
        # if we can't get the lock we assume it's used by a fast exiting block,
        # so we just yield and retry
        if @inline trylock(l)
            if l.owned_by == 0
                # was fully unlocked, mark it as ours
                l.owned_by = id
                l.count = 1
                # and lift the locked as we
                @atomic :release l.locked = 0
                return true
            elseif l.owned_by == id
                # id already owns lock, increment
                l.count += 1
                @atomic :release l.locked = 0
                return true
            else
                # used by some other id, wait for it to notify us
                lock(l.release)
                @atomic :release l.locked = 0
                wait(l.release)
                unlock(l.release)
            end
        end
        yield()
    end
    return false
end

function Base.unlock(l::ResolveLock, id)
    while true
        # if we can't get the lock we assume it's used by a fast exiting block,
        # so we just yield and retry
        if @inline trylock(l)
            if l.owned_by == id
                # id already owns lock, increment
                l.count -= 1
                if l.count == 0
                    l.owned_by = 0
                end
                @atomic :release l.locked = 0
                lock(l.release)
                notify(l.release, all = false)
                unlock(l.release)
                GC.enable_finalizers()
                return true
            else
                error("unlock count does not match lock count")
            end
        end
        yield()
    end
    return
end

function Base.islocked(l::ResolveLock)
    a = (@atomic :monotonic l.locked)::Int != 0
    b = (@atomic :monotonic l.owned_by) != 0
    return a || b
end