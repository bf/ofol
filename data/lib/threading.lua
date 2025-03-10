-- multi-threading and thread management 
-- refactored from code/init.lua


-- threading object with functions
local threading = {}

-- list of threads
local threads = setmetatable({}, { __mode = "k" })

-- number of threads created so far
local thread_counter = 0

-- create thread
function threading.add_thread(f, weak_ref, ...)
  -- stderr.debug_backtrace("adding thread")
  local key = weak_ref
  if not key then
    thread_counter = thread_counter + 1
    key = thread_counter
  end
  assert(threads[key] == nil, "Duplicate thread reference")
  local args = {...}
  local fn = function() return try_catch(f, table.unpack(args)) end
  threads[key] = { cr = coroutine.create(fn), wake = 0 }
  return key
end


-- main threading loop which will interrupt threads to keep fps
threading.run_threads = coroutine.wrap(function()
  while true do
    local max_time = 1 / CONSTANT_FRAMES_PER_SECOND - 0.004
    local minimal_time_to_wake = math.huge

    local threads = {}
    -- We modify core.threads while iterating, both by removing dead threads,
    -- and by potentially adding more threads while we yielded early,
    -- so we need to extract the threads list and iterate over that instead.
    for k, thread in pairs(threads) do
      threads[k] = thread
    end

    for k, thread in pairs(threads) do
      -- Run thread if it wasn't deleted externally and it's time to resume it
      if threads[k] and thread.wake < system.get_time() then
        local _, wait = assert(coroutine.resume(thread.cr))
        if coroutine.status(thread.cr) == "dead" then
          threads[k] = nil
        else
          wait = wait or (1/30)
          thread.wake = system.get_time() + wait
          minimal_time_to_wake = math.min(minimal_time_to_wake, wait)
        end
      else
        minimal_time_to_wake =  math.min(minimal_time_to_wake, thread.wake - system.get_time())
      end

      -- stop running threads if we're about to hit the end of frame
      if system.get_time() - core.frame_start > max_time then
        coroutine.yield(0, false)
      end
    end

    coroutine.yield(minimal_time_to_wake, true)
  end
end)


return threading