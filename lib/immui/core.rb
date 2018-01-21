require 'sdl'

def within(x, y, coords)
    return true if coords.nil?
    return x >= coords[0] && 
	y >= coords[1] &&
	x < coords[0] + coords[2] && 
	y < coords[1] + coords[3]
end

class Renderer
    def initialize(screen, screen_w, screen_h)
	@screen = screen
	@screen_w = screen_w
	@screen_h = screen_h

	@black = rgb(0, 0, 0)
	@white = rgb(255, 255, 255)
	@fonts = {}
	@event_handlers = []
    end

    def clear(color=@black)
	fill_rect 0, 0, @screen_w, @screen_h, color
    end

    def rgb(r, g, b)
	[r, g, b]
    end

    def internal_color(rgb_triple)
	@screen.mapRGB(*rgb_triple)
    end
    private :internal_color

    def black() @black end
    def white() @white end
    def gray(scale) v=(255*scale).to_i; rgb(v, v, v) end
    def red(scale=1.0) rgb((255*scale).to_i, 0, 0) end
    def random_color() rgb(rand(256), rand(256), rand(256)) end

    def fill_rect(x, y, w, h, color)
	color = internal_color(color) if color.is_a? Array
	@screen.fillRect x, y, w, h, color
    end

    def rect(x, y, w, h, color)
	color = internal_color(color) if color.is_a? Array
	@screen.drawRect x, y, w, h, color
    end

    def line(x, y, w, h, color)
	@screen.drawLine x, y, w, h, color
    end

    def add_font(name, font)
	@fonts[name] = font
    end

    def text(font_name, str, x, y, color)
	@fonts[font_name].draw_solid_utf8(@screen, str, x, y, *color)
    end

    def register_event_handler(ev)
	@event_handlers.push(ev)
    end

    def reset_event_handlers
	@event_handlers.clear
    end

    def find_matching_event_handlers(event)
	@event_handlers.reverse_each do |handler|
	    if (handler[:type] == :mouse_move and event.kind_of? SDL::Event::MouseMotion) ||
	       (handler[:type] == :mouse_down and event.kind_of? SDL::Event::MouseButtonDown) ||
	       (handler[:type] == :mouse_up and event.kind_of? SDL::Event::MouseButtonUp) then
		if within(event.x, event.y, handler[:coords])
		    yield handler
		end
	    end
	end
    end
end

class UI
    def initialize(w, h, title, ttf_font_file, font_size)
    	SDL.init SDL::INIT_VIDEO
	@screen = SDL::Screen.open(w, h, 16, SDL::SWSURFACE | SDL::ANYFORMAT)
    	SDL::WM::set_caption(title, title)
    	SDL::TTF.init

    	font = SDL::TTF.open(ttf_font_file, font_size)
    	font.style = SDL::TTF::STYLE_NORMAL

    	@renderer = Renderer.new(@screen, w, h) 
    	@renderer.add_font('default', font)
    end

    def run(ui_state = {})
	needs_redraw = true
	loop do
	    if needs_redraw
		@renderer.reset_event_handlers
		@renderer.clear(@renderer.white)
		yield @renderer, ui_state
		@screen.updateRect 0, 0, 0, 0
	    end
	    needs_redraw = handle_event()
	end
    end

    def handle_event
	event = SDL::Event.poll
	case event
	when nil
	when SDL::Event::Quit
	    SDL::Key.scan
	    exit
	when SDL::Event::KeyDown
	    SDL::Key.scan
	    exit if event.sym == SDL::Key::ESCAPE
	when SDL::Event::MouseMotion, SDL::Event::MouseButtonUp, SDL::Event::MouseButtonDown
	    needs_redraw = false
	    @renderer.find_matching_event_handlers(event) do |handler|
		needs_redraw = true if handler[:callback].call(event)
		# Only fire the first successful event (XXX).
		break if needs_redraw
	    end	
	    return needs_redraw
	else
	    p event
	end

	return false
    end
end

#
# Lazily initializes ui state
#
def lazy(ui_state, id, &block)
    return ui_state[id] if ui_state.has_key?(id)
    new_val = block ? block.call(id) : {id: id}
    ui_state[id] = new_val
    return new_val
end

class Rect < Struct.new(:x, :y, :w, :h)
    def x2() self.x + self.w - 1 end
    def y2() self.y + self.h - 1 end
    def to_a() [self.x, self.y, self.w, self.h] end
end

class Point < Struct.new(:x, :y)
    # Clips self inside the rect described by `rect`.
    # Returns a new Point.
    def clip_in_rect(rect)
	Point.new(
	    [[self.x, rect.x].max, rect.x2].min,
	    [[self.y, rect.y].max, rect.y2].min
	)
    end
end
