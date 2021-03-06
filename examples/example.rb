$LOAD_PATH.unshift '../lib'
require 'eui/rect'
require 'eui/point'
require 'eui/lazy'
require 'eui/ui'
require 'eui/widgets/button'
require 'eui/widgets/slider'
require 'eui/widgets/draggable'

class Placement
  def initialize(bounds_rect)
    @bounds_rect = bounds_rect
    reset
  end

  def reset
    @current_pos = Point.new(@bounds_rect.x, @bounds_rect.y)
    self
  end

  def move_right(w)
    @current_pos = Point.new(@current_pos.x + w, @current_pos.y)
    self
  end

  def place_down(w, h, gap = 0)
    rect = Rect.new(@current_pos.x, @current_pos.y, w, h)
    @current_pos = Point.new(@current_pos.x, @current_pos.y + h + gap)
    rect
  end
end

def main
  w = 600
  h = 480
  UI.new(w, h, 'immui', '/usr/local/share/fonts/dejavu/DejaVuSans.ttf', 18).run do |renderer, ui_state, evhr|
	renderer.clear(renderer.white)
    placement = Placement.new(Rect.new(10, 10, w - 20, h - 20))

    for i in 0..9 do
      id = [:button, i]; widget_state = lazy(ui_state, id)
      style = { fg: ui_state[:focus] == id ? renderer.rgb(255, 0, 0) : renderer.black }
      button(renderer, evhr, placement.place_down(100, 20, 10), "Hello #{i}", widget_state, style) { |s| ui_state[:focus] = s[:id] }
    end

    placement.reset.move_right(100 + 10)

    for i in 0..9 do
      id = [:slider, i]; widget_state = lazy(ui_state, id)
      style = {
        border: ui_state[:focus] == id ? renderer.black : nil
      }
      slider_x(renderer, evhr, placement.place_down(420, 20, 10), widget_state, style) { |s| ui_state[:focus] = s[:id] }
    end

    placement.reset.move_right(100 + 10 + 420 + 20)

    id = [:global_slider]; widget_state = lazy(ui_state, id)
    slider_y(renderer, evhr, placement.place_down(20, 290), widget_state, fg: renderer.red(widget_state[:value] || 1.0)) do |s|
      ui_state[:focus] = s[:id]
      # Update all other sliders with the same value as the global slider
      ui_state.each_pair do |key, v|
        v[:value] = s[:value] if key[0] == :slider
      end
    end

    # This draws a box in which the drag handles will float
    renderer.fill_rect(Rect.new(10, 310, 570, 160), renderer.gray(0.8))

    for i in 0..9 do
      drag_handle_state = lazy(ui_state, [:drag, i]) { |id| { id: id, handle_x: 10 + (i * 45), handle_y: 310, color: renderer.random_color, drag_size: 40 } }
      drag_size = drag_handle_state[:drag_size]
      renderer.fill_rect(Rect.new(drag_handle_state[:handle_x], drag_handle_state[:handle_y], drag_size, drag_size), drag_handle_state[:color])
      draggable(renderer, evhr, drag_size, drag_size, Rect.new(10, 310, 570 - drag_size, 160 - drag_size), drag_handle_state)
    end
  end
end

main if $PROGRAM_NAME == __FILE__
