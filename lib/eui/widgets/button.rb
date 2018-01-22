def button(renderer, rect, label, ui_state, style={}, &on_click)
    bg_color = style[:bg] || renderer.gray(0.8)
    fg_color = style[:fg] || renderer.black
    border_color = style[:border] || renderer.black
    font = style[:font] || 'default'

    if not ui_state[:pressed]
	renderer.fill_rect rect, bg_color
	renderer.rect rect, border_color
	renderer.text(font, label, rect.x+2, rect.y, fg_color)
	evh = {:type => :mouse_down, rect: rect, callback: proc {|_ev| 
	    if not ui_state[:pressed]
	        ui_state[:pressed] = true
		true
	    else
		false
	    end
	}}
	renderer.register_event_handler(evh)
    else
	renderer.rect rect, border_color
	renderer.text(font, label, rect.x+5, rect.y, fg_color)
	evh = {:type => :mouse_up, callback: proc {|ev|
	    if ui_state[:pressed] == true
	        ui_state[:pressed] = false
		on_click.call(ui_state) if on_click and rect.contains(ev.x, ev.y)
		true
	    else
		false
	    end
	}}
	renderer.register_event_handler(evh)
    end
end
