local StateMachine = Object:extend()

function StateMachine:new(name, tbl_states, initial_state)
  if not Validator.is_string(name) then
    stderr.error("%s name must be string, received %s", self._name, type(name))
  end
  self._name = name

  if not Validator.is_table(tbl_states) then
    stderr.error("%s states argument must be table, received %s", self._name, type(tbl_states))
  end

  -- initialize valid states as empty table
  self._valid_states_with_events = {}

  -- store global event handlers temporarily
  local tmp_global_event_handlers_for_all_states

  -- iterate over all states
  for state_name, tbl_state_transitions in pairs(tbl_states) do
    -- ensure state is a string
    if not Validator.is_string(state_name) then
      stderr.error("%s state %s must be string, received %s", self._name, state_name, type(state_name))
    end

    -- ensure state transitions is a table
    if not Validator.is_table(tbl_state_transitions) then
      stderr.error("%s state with key %s needs to have table value, received %s", self._name, state_name, type(tbl_state_transitions))
    end

    -- check if special state "*" is provided, which means event handlers that should be applied to all states
    if state_name == "*" then
      -- special case where event handler functions should be added to all states
      tmp_global_event_handlers_for_all_states = tbl_state_transitions
    else
      -- normal case where state has one function for each event

      -- ensure state does not exist yet
      if self._valid_states_with_events[state_name] ~= nil then
        stderr.error("%s state %s already exists, cannot add duplicate", self._name)
      end

      -- add state to valid states array
      self._valid_states_with_events[state_name] = {}
      stderr.debug("%s added state %s", self._name, state_name)

      -- iterate over all transitions
      for event_name, fn_event_handler_for_state in pairs(tbl_state_transitions) do 
        -- ensure event name is string
        if not Validator.is_string(event_name) then
          stderr.error("%s state %s event_name %s must be string, received %s", self._name, state_name, event_name, type(event_name))
        end

        -- ensure event transition is a function
        if not Validator.is_function(fn_event_handler_for_state) then
          stderr.error("%s state %s event_name %s value must be handler function, received %s", self._name, state_name, event_name, type(fn_event_handler_for_state))
        end

        -- add event name to the states array for this state
        self._valid_states_with_events[state_name][event_name] = fn_event_handler_for_state

        stderr.debug("%s state %s added event_handler %s", self._name, state_name, event_name)
      end
    end
  end

  -- if global event handlers were provided, we should add them to every single state
  if Validator.is_table(tmp_global_event_handlers_for_all_states) then
    -- iterate over all global event handlers that should be added
    for event_name, fn_event_handler_for_all_states in pairs(tmp_global_event_handlers_for_all_states) do
      -- ensure event_name is string
      if not Validator.is_string(event_name) then
        stderr.error("%s state %s event_name %s must be string, received %s", self._name, state_name, event_name, type(event_name))
      end

      -- ensure event transition is a function
      if not Validator.is_function(fn_event_handler_for_all_states) then
        stderr.error("%s state %s event_name %s value must be handler function, received %s", self._name, state_name, event_name, type(fn_event_handler_for_all_states))
      end

      -- iterate over all existing states
      for state_name, tbl_state_transitions in pairs(self._valid_states_with_events) do
        -- ensure the event handler does not exist yet for this state, 
        -- otherwise it wouldn't be global event handler, right?
        if self._valid_states_with_events[state_name][event_name] ~= nil then
          stderr.error("%s state %s already has event handler for %s, even though this event handler has been defined globally", self._name, state_name, event_name)
        end

        -- add event handler
        self._valid_states_with_events[state_name][event_name] = fn_event_handler_for_all_states

        stderr.debug("%s state %s added global event_handler %s", self._name, state_name, event_name)
      end
    end
  end

  -- add dynamic getter functions is_$state e.g. is_maxmized() for easy checking for specific state 
  for state_name, _ in pairs(self._valid_states_with_events) do
    -- create function name
    local getter_function_name = "is_" .. state_name

    -- ensure getter function does not exist yet
    if self[getter_function_name] ~= nil then
      stderr.error("%s getter function %s already exists", self._name, getter_function_name)
    end

    stderr.debug("%s adding getter function %s for state %s", self._name, getter_function_name, state_name)

    -- add getter function
    self[getter_function_name] = function (self) 
      -- check if current state is the state for this getter functio
      local result = (self._current_state == state_name)
      -- stderr.debug("%s getter_function_name %s returns %s", self._name, getter_function_name, result)
      return result
    end
  end
    
  -- ensure initial state is string
  if not Validator.is_string(initial_state) then
    stderr.error("initial_state must be string, received %s", type(initial_state))
  end

  -- ensure initial state is valid state
  self:check_state_is_valid(initial_state)

  self._current_state = initial_state
end

function StateMachine:check_event_is_valid_for_current_state(event_name)
  -- ensure event is valid for this stae
  if self._valid_states_with_events[self._current_state][event_name] == nil then
    stderr.error("%s received invalid event: %s which is not defined for state %s", self._name, event_name, self._current_state)
  end
end

function StateMachine:check_state_is_valid(state_name)
  if self._valid_states_with_events[state_name] == nil then
    stderr.error("%s received invalid state: %s", self._name, state_name)
  end
end

function StateMachine:handle_event(event_name, a, b, c, d)
  stderr.debug("%s at state %s handle event %s with params %s %s %s %s", self._name, self._current_state, event_name, a, b, c, d)

  -- ensure event is valid in the current state
  self:check_event_is_valid_for_current_state(event_name)

  -- handle event
  local next_state = self._valid_states_with_events[self._current_state][event_name](event_name, a,b,c,d)

  stderr.debug("%s at processed event %s will change from state %s to new state %s", self._name, event_name, self._current_state, next_state)

  if next_state == nil then
    stderr.warn("%s next state after handling event %s is nil, will do nothing", self._name, event_name)
    return
  end

  -- check if state is different than current state
  if next_state == self._current_state then
    -- if state stays the same, do nothing 
    stderr.warn("%s next state %s is same as current state %s, will not trigger transition logic", self._name, next_state, self._current_state)
    return
  end

  -- ensure returned state is valid
  self:check_state_is_valid(next_state)

  -- if state changed, update it
  stderr.warn("%s event %s has changed current_state from %s to %s", self._name, event_name, self._current_state, next_state)
  self._current_state = next_state

  -- call transition hooks
  -- TODO: implement
end

function StateMachine:get_current_state()
  return self._current_state
end


return StateMachine