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

def slider(renderer, x, y, w, h, is_horizontal, ui_state, style={}, &on_change)
    coords = [x, y, w, h]
    slider_val = ui_state[:value] || 0.0

    bg_color = style[:bg] || renderer.gray(0.8)
    fg_color = style[:fg] || renderer.rgb(255, 0, 0)
    border_color = style[:border]

    renderer.fill_rect x, y, w, h, bg_color
    if is_horizontal
	ww = [(slider_val * w).to_i, w].min
        renderer.fill_rect x, y, ww, h, fg_color
        renderer.rect x, y, ww, h, border_color if border_color
    else
        hh = [(slider_val * h).to_i, h].min
        renderer.fill_rect x, y, w, hh, fg_color
        renderer.rect x, y, w, hh, border_color if border_color
    end

    if not ui_state[:pressed]
	evh = {:type => :mouse_down, coords: coords, callback: proc {|ev| 
	    if not ui_state[:pressed]
	        ui_state[:pressed] = true
	        ui_state[:value] = is_horizontal ? ev_coord_to_slider_value(ev.x, x, w) : ev_coord_to_slider_value(ev.y, y, h)
    	        on_change.call(ui_state) if on_change
		true
	    else
		false
	    end
	}}
	renderer.register_event_handler(evh)
    else
	evh1 = {:type => :mouse_up, callback: proc {|ev|
	    if ui_state[:pressed] == true
	        ui_state[:pressed] = false
	        ui_state[:value] = is_horizontal ? ev_coord_to_slider_value(ev.x, x, w) : ev_coord_to_slider_value(ev.y, y, h)
    	        on_change.call(ui_state) if on_change
		true
	    else
		false
	    end
	}}

	evh2 = {:type => :mouse_move, callback: proc {|ev|
	    if ui_state[:pressed] == true
	        ui_state[:value] = is_horizontal ? ev_coord_to_slider_value(ev.x, x, w) : ev_coord_to_slider_value(ev.y, y, h)
    	        on_change.call(ui_state) if on_change
		true
	    else
		false
	    end
	}}
	renderer.register_event_handler(evh1)
	renderer.register_event_handler(evh2)
    end
end

def slider_x(renderer, x, y, w, h, ui_state, style={}, &on_change)
    slider(renderer, x, y, w, h, true, ui_state, style, &on_change)
end

def slider_y(renderer, x, y, w, h, ui_state, style={}, &on_change)
    slider(renderer, x, y, w, h, false, ui_state, style, &on_change)
end
