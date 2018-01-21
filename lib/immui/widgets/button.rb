def button(renderer, x, y, w, h, label, ui_state, style={}, &on_click)
    coords = [x, y, w, h]

    bg_color = style[:bg] || renderer.gray(0.8)
    fg_color = style[:fg] || renderer.black
    border_color = style[:border] || renderer.black
    font = style[:font] || 'default'

    if not ui_state[:pressed]
	renderer.fill_rect x, y, w, h, bg_color
	renderer.rect x, y, w, h, border_color
	renderer.text(font, label, x+2, y, fg_color)
	evh = {:type => :mouse_down, coords: coords, callback: proc {|_ev| 
	    if not ui_state[:pressed]
	        ui_state[:pressed] = true
		true
	    else
		false
	    end
	}}
	renderer.register_event_handler(evh)
    else
	renderer.rect x, y, w, h, border_color
	renderer.text(font, label, x+5, y, fg_color)
	evh = {:type => :mouse_up, callback: proc {|ev|
	    if ui_state[:pressed] == true
	        ui_state[:pressed] = false
    	        on_click.call(ui_state) if on_click and within(ev.x, ev.y, coords)
		true
	    else
		false
	    end
	}}
	renderer.register_event_handler(evh)
    end
end
