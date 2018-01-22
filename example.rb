$LOAD_PATH.unshift "./lib"
require 'eui/core'
require 'eui/widgets/button'
require 'eui/widgets/slider'
require 'eui/widgets/draggable'

if __FILE__ == $0
    UI.new(600, 480, "immui", '/usr/local/share/fonts/dejavu/DejaVuSans.ttf', 18).run do |renderer, ui_state|
	for y, i in 10.step(300, 30).with_index
	    id = [:button, i]
	    widget_state = lazy(ui_state, id)
	    style = {fg: ui_state[:focus] == id ? renderer.rgb(255, 0, 0) : renderer.black}
	    button(renderer, 10, y, 100, 20, "Hello #{i}", widget_state, style) {|s| ui_state[:focus] = s[:id] }
	end
	for y, i in 10.step(300, 30).with_index
	    id = [:slider, i]
	    widget_state = lazy(ui_state, id)
	    style = {
		border: ui_state[:focus] == id ? renderer.black : nil
	    }
	    slider_x(renderer, 120, y, 420, 20, widget_state, style) {|s| ui_state[:focus] = s[:id] }
	end
	widget_state = lazy(ui_state, [:global_slider])
	slider_y(renderer, 560, 10, 20, 290, widget_state, {fg: renderer.red(widget_state[:value] || 1.0)}) do |s|
            ui_state[:focus] = s[:id]
	    # Update all other sliders with the same value as the global slider
	    ui_state.each_pair {|key, v|
		v[:value] = s[:value] if key[0] == :slider
	    }
	end

	# This draws a box in which the drag handles will float
	renderer.fill_rect(10, 310, 570, 160, renderer.gray(0.8))

	for i in 0 .. 9
	    drag_handle_state = lazy(ui_state, [:drag, i]) {|id| {id: id, handle_x: 10 + (i*45), handle_y: 310, color: renderer.random_color(), drag_size: 40}}
	    drag_size = drag_handle_state[:drag_size]
	    renderer.fill_rect(drag_handle_state[:handle_x], drag_handle_state[:handle_y], drag_size, drag_size, drag_handle_state[:color])
	    draggable(renderer, drag_size, drag_size, Rect.new(10, 310, 570-drag_size, 160-drag_size), drag_handle_state)
	end
    end
end
