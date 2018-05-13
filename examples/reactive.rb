$LOAD_PATH.unshift '../lib'
require 'eui/rect'
require 'eui/point'
require 'eui/lazy'
require 'eui/ui'

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
		block.call(@value)
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
	end

	def unlisten(handle)
		@listeners.remove(handle)
	end
end

class Events
	attr_reader :mouse_pos, :mouse_button_down, :mouse_button_up
	attr_reader :mouse_button_state

	def initialize
		@mouse_pos = Behavior.new([0, 0])
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

class Slider
	attr_reader :value

	def initialize(rect, is_horizontal, style)
		@rect = rect
		@is_horizontal = is_horizontal
		@style = style
		@value = Behavior.new(0.0)
	end

	def attach(ui, events)
		@value.listen do |slider_val|
			draw(ui.renderer, slider_val)
			ui.update_screen
		end
		events.mouse_button_down.listen do |mouse_pos|
		  mx, my = *mouse_pos
		  if @rect.contains(mx, my)
			  if @is_horizontal
				@value.push(ev_coord_to_slider_value(mx, @rect.x, @rect.w))
			  else
				@value.push(ev_coord_to_slider_value(my, @rect.y, @rect.h))
			  end
		  end
		end  
		events.mouse_pos.listen do |mouse_pos|
		  mx, my = *mouse_pos
		  if @rect.contains(mx, my) and events.mouse_button_state.get_current_value == :down
			  if @is_horizontal
				@value.push(ev_coord_to_slider_value(mx, @rect.x, @rect.w))
			  else
				@value.push(ev_coord_to_slider_value(my, @rect.y, @rect.h))
			  end
		  end
		end
	end

	private def draw(renderer, slider_val)
		bg_color = @style[:bg] || renderer.gray(0.8)
		fg_color = @style[:fg] || renderer.rgb(255, 0, 0)
		border_color = @style[:border]

		renderer.fill_rect @rect, bg_color
		filled_rect = if @is_horizontal
						  @rect.with_w([(slider_val * @rect.w).to_i, @rect.w].min)
					  else
						  @rect.with_h([(slider_val * @rect.h).to_i, @rect.h].min)
					  end
		renderer.fill_rect filled_rect, fg_color
		renderer.rect filled_rect, border_color if border_color
	end
end


def main
  w = 600
  h = 480

  ui = UI.new(w, h, 'immui', '/usr/local/share/fonts/dejavu/DejaVuSans.ttf', 18)
  ui.renderer.clear(ui.renderer.white)
  ui.update_screen

  events = Events.new  

  slider1 = Slider.new(Rect.new(10, 10, w-20, (h-20)/2), true, { border: ui.renderer.black })
  slider2 = Slider.new(Rect.new(10, 10+(h-20)/2, w-20, (h-20)/2), true, { border: ui.renderer.black })
  slider2.value.push(0.5)

  slider1.attach(ui, events)
  slider2.attach(ui, events)

  loop do
	events.poll
  end
end

main if $PROGRAM_NAME == __FILE__
