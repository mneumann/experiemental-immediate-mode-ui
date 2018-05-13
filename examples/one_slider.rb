$LOAD_PATH.unshift '../lib'
require 'eui/rect'
require 'eui/point'
require 'eui/lazy'
require 'eui/ui'
require 'eui/widgets/slider'

def main
  w = 600
  h = 480
  UI.new(w, h, 'immui', '/usr/local/share/fonts/dejavu/DejaVuSans.ttf', 18).run do |renderer, ui_state, event_handler_registry|
	renderer.clear(renderer.white)

    id = :slider
	widget_state = lazy(ui_state, id)
    style = {
      border: ui_state[:focus] == id ? renderer.black : nil
    }
	slider_x(renderer, event_handler_registry, Rect.new(10, 10, w-20, h-20) , widget_state, style) { |s| ui_state[:focus] = s[:id] }
  end
end

main if $PROGRAM_NAME == __FILE__
