$LOAD_PATH.unshift "."
require 'immui'

if __FILE__ == $0
    UI.new(640, 480, "immui", '/usr/local/share/fonts/dejavu/DejaVuSans.ttf', 18).run do |renderer, ui_state| 
	for y, i in 50.step(400, 30).with_index
	    button(renderer, 10, y, 100, 20, "Hello #{i}", lazy(ui_state, :"button#{i}")) do |ui_s| p ui_s end
	    slider_x(renderer, 120, y, 400, 20, lazy(ui_state, :"slider#{i}")) do end
	end
	slider_x(renderer, 120, 440, 400, 20, lazy(ui_state, :global_slider)) do |state|
	    # Update all other sliders with the same value as the global slider
	    ui_state.each_pair {|k, v|
		if k.to_s.start_with?("slider")
		    v[:value] = state[:value]
		end
	    }
	end
    end
end
