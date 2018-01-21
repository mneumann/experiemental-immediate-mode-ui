$LOAD_PATH.unshift "./lib"
require 'immui/core'
require 'immui/widgets/button'
require 'immui/widgets/slider'

if __FILE__ == $0
    UI.new(600, 400, "immui", '/usr/local/share/fonts/dejavu/DejaVuSans.ttf', 18).run do |renderer, ui_state| 
	for y, i in 10.step(380, 30).with_index
	    id = [:button, i]
	    widget_state = lazy(ui_state, id)
	    style = {fg: ui_state[:focus] == id ? renderer.rgb(255, 0, 0) : renderer.black}
	    button(renderer, 10, y, 100, 20, "Hello #{i}", widget_state, style) {|s| ui_state[:focus] = s[:id] }
	end
	for y, i in 10.step(380, 30).with_index
	    id = [:slider, i]
	    widget_state = lazy(ui_state, id)
	    style = {
		border: ui_state[:focus] == id ? renderer.black : nil
	    }
	    slider_x(renderer, 120, y, 420, 20, widget_state, style) {|s| ui_state[:focus] = s[:id] }
	end
	widget_state = lazy(ui_state, [:global_slider])
	slider_y(renderer, 560, 10, 20, 380, widget_state, {fg: renderer.red(widget_state[:value] || 1.0)}) do |s|
            ui_state[:focus] = s[:id]
	    # Update all other sliders with the same value as the global slider
	    ui_state.each_pair {|key, v|
		v[:value] = s[:value] if key[0] == :slider
	    }
	end
    end
end
