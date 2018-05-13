def ev_coord_to_slider_value(ev_x, x, w)
  v = ev_x - x
  if v >= w
    1.0
  elsif v <= 0
    0.0
  else
    v / w.to_f
  end
end

def slider(renderer, rect, is_horizontal, ui_state, style = {}, &on_change)
  slider_val = ui_state[:value] || 0.0

  bg_color = style[:bg] || renderer.gray(0.8)
  fg_color = style[:fg] || renderer.rgb(255, 0, 0)
  border_color = style[:border]

  renderer.fill_rect rect, bg_color
  filled_rect = if is_horizontal
                  rect.with_w([(slider_val * rect.w).to_i, rect.w].min)
                else
                  rect.with_h([(slider_val * rect.h).to_i, rect.h].min)
  end
  renderer.fill_rect filled_rect, fg_color
  renderer.rect filled_rect, border_color if border_color

  if !(ui_state[:pressed])
    evh = { type: :mouse_down, rect: rect, callback: proc { |ev|
                                                       if !(ui_state[:pressed])
                                                         ui_state[:pressed] = true
                                                         ui_state[:value] = is_horizontal ? ev_coord_to_slider_value(ev.x, rect.x, rect.w) :
                                                              ev_coord_to_slider_value(ev.y, rect.y, rect.h)
                                                         yield(ui_state) if on_change
                                                         true
                                                       else
                                                         false
                                                       end
                                                     } }
    renderer.register_event_handler(evh)
  else
    evh1 = { type: :mouse_up, callback: proc { |ev|
                                          if ui_state[:pressed] == true
                                            ui_state[:pressed] = false
                                            ui_state[:value] = is_horizontal ? ev_coord_to_slider_value(ev.x, rect.x, rect.w) :
                                                 ev_coord_to_slider_value(ev.y, rect.y, rect.h)
                                            yield(ui_state) if on_change
                                            true
                                          else
                                            false
                                          end
                                        } }

    evh2 = { type: :mouse_move, callback: proc { |ev|
      if ui_state[:pressed] == true
        ui_state[:value] = is_horizontal ? ev_coord_to_slider_value(ev.x, rect.x, rect.w) :
            ev_coord_to_slider_value(ev.y, rect.y, rect.h)
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

def slider_x(renderer, rect, ui_state, style = {}, &on_change)
  slider(renderer, rect, true, ui_state, style, &on_change)
end

def slider_y(renderer, rect, ui_state, style = {}, &on_change)
  slider(renderer, rect, false, ui_state, style, &on_change)
end
