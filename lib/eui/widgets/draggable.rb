require 'eui/rect'

# region_rect describes the region in which the handle can be moved.
#
# ui_state must include handle_x, handle_y
#
# NOTE that nothing is drawn. This "widget" is a pure event handler
def draggable(renderer, handle_w, handle_h, region_rect, ui_state, &on_change)
  handle_x = ui_state[:handle_x] || 0
  handle_y = ui_state[:handle_y] || 0
  if !(ui_state[:pressed])
    evh = { type: :mouse_down, rect: Rect.new(handle_x, handle_y, handle_w, handle_h), callback: proc { |_ev|
                                                                                                   if !(ui_state[:pressed])
                                                                                                     ui_state[:pressed] = true
                                                                                                     yield(ui_state) if on_change
                                                                                                     true
                                                                                                   else
                                                                                                     false
                                                                                                   end
                                                                                                 } }
    renderer.register_event_handler(evh)
  else
    evh2 = { type: :mouse_move, callback: proc { |ev|
                                            if ui_state[:pressed] == true
                                              new_handle_x = (ui_state[:handle_x] || 0) + ev.xrel
                                              new_handle_x = region_rect.x if new_handle_x < region_rect.x
                                              new_handle_x = region_rect.x2 if new_handle_x > region_rect.x2

                                              new_handle_y = (ui_state[:handle_y] || 0) + ev.yrel
                                              new_handle_y = region_rect.y if new_handle_y < region_rect.y
                                              new_handle_y = region_rect.y2 if new_handle_y > region_rect.y2

                                              ui_state[:handle_x] = new_handle_x
                                              ui_state[:handle_y] = new_handle_y

                                              yield(ui_state) if on_change
                                              true
                                            else
                                              false
                                            end
                                          } }

    evh1 = { type: :mouse_up, callback: proc { |_ev|
      if ui_state[:pressed] == true
        ui_state[:pressed] = false
        yield(ui_state) if on_change
        true
      else
        false
        end
    } }

    renderer.register_event_handler(evh1)
    renderer.register_event_handler(evh2)
  end
end
