#
# Lazily initializes ui state
#
def lazy(ui_state, id, &block)
  return ui_state[id] if ui_state.key?(id)
  new_val = block ? yield(id) : { id: id }
  ui_state[id] = new_val
  new_val
end
