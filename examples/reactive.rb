$LOAD_PATH.unshift '../lib'
require 'eui/rect'
require 'eui/point'
require 'eui/lazy'
require 'eui/ui'
require 'eui/widgets/slider'


class Behavior
	def initialize(initial_value)
		@value = initial_value
		@listeners = []
	end

	def get_current_value
		@value
	end

	def push(new_value)
		if new_value != @value
			@value = new_value
			notify
		end
	end

	def listen(&block)
		@listeners.push(block)
		return block
	end

	def unlisten(handle)
		@listeners.remove(handle)
	end

	def notify
		@listeners.each do |listener|
			listener.call(@value)
		end
	end
end

class Stream
	def initialize
		@listeners = []
	end

	def push(new_value)
		@listeners.each do |listener|
			listener.call(new_value)
		end
	end

	def listen(&block)
		@listeners.push(block)
		return block
	end

	def unlisten(handle)
		@listeners.remove(handle)
	end
end

class Events
	attr_reader :mouse_pos, :mouse_button_down, :mouse_button_up
	attr_reader :mouse_button_state

	def initialize
		@mouse_pos = Behavior.new([0, 0]) # ???
		@mouse_button_down = Stream.new
		@mouse_button_up = Stream.new
		@mouse_button_state = Behavior.new(:up)
		@mouse_button_down.listen do ||
			@mouse_button_state.push(:down)
		end
		@mouse_button_up.listen do ||
			@mouse_button_state.push(:up)
		end
	end

	def poll
		event = SDL::Event.poll
		case event
		when nil
		when SDL::Event::Quit
		  SDL::Key.scan
		  exit
		when SDL::Event::KeyDown
		  SDL::Key.scan
		  exit if event.sym == SDL::Key::ESCAPE
		when SDL::Event::MouseMotion
			@mouse_pos.push([event.x, event.y])
		when SDL::Event::MouseButtonDown
			@mouse_button_down.push([event.x, event.y])
		when SDL::Event::MouseButtonUp
			@mouse_button_up.push([event.x, event.y])
		end
	end
end

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

def react_slider(events, slider_value, rect, is_horizontal)
	events.mouse_button_down.listen do |mouse_pos|
	  mx, my = *mouse_pos
	  if rect.contains(mx, my)
		  if is_horizontal
			slider_value.push(ev_coord_to_slider_value(mx, rect.x, rect.w))
		  else
			slider_value.push(ev_coord_to_slider_value(my, rect.y, rect.h))
		  end
	  end
    end  
	events.mouse_pos.listen do |mouse_pos|
	  mx, my = *mouse_pos
	  if rect.contains(mx, my) and events.mouse_button_state.get_current_value == :down
		  if is_horizontal
			slider_value.push(ev_coord_to_slider_value(mx, rect.x, rect.w))
		  else
			slider_value.push(ev_coord_to_slider_value(my, rect.y, rect.h))
		  end
	  end
	end
end

def draw_slider(renderer, rect, is_horizontal, slider_val, style = {})
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
end


def draw_ui(w, h, renderer, ui_state)
	renderer.clear(renderer.white)
    style = { border: renderer.black }
	draw_slider(renderer, Rect.new(10, 10, w-20, (h-20)/2), true, ui_state[:slider_value1].get_current_value, style)
	draw_slider(renderer, Rect.new(10, 10+(h-20)/2, w-20, (h-20)/2), true, ui_state[:slider_value2].get_current_value, style)
end

def main
  w = 600
  h = 480

  ui_state = {
		slider_value1: Behavior.new(0),
		slider_value2: Behavior.new(0.5),
  }

  ui = UI.new(w, h, 'immui', '/usr/local/share/fonts/dejavu/DejaVuSans.ttf', 18)

  ui_state[:slider_value1].listen do ||
	  style = { border: ui.renderer.black }
	  draw_slider(ui.renderer, Rect.new(10, 10, w-20, (h-20)/2), true, ui_state[:slider_value1].get_current_value, style)
	  #draw_ui(w, h, ui.renderer, ui_state)
	  ui.update_screen
  end
  ui_state[:slider_value2].listen do ||
	  style = { border: ui.renderer.black }
	  draw_slider(ui.renderer, Rect.new(10, 10+(h-20)/2, w-20, (h-20)/2), true, ui_state[:slider_value2].get_current_value, style)
	  #draw_ui(w, h, ui.renderer, ui_state)
	  ui.update_screen
  end

  events = Events.new  

  react_slider(events, ui_state[:slider_value1], Rect.new(10, 10, w-20, (h-20)/2), true)
  react_slider(events, ui_state[:slider_value2], Rect.new(10, 10+(h-20)/2, w-20, (h-20)/2), true)

  draw_ui(w, h, ui.renderer, ui_state)
  ui.update_screen

  loop do
	events.poll
  end
end

main if $PROGRAM_NAME == __FILE__
