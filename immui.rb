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
    def gray(v) rgb(v, v, v) end

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
	@event_handlers.each do |handler|
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

# -----------------------------------------------------------
# Widgets
# -----------------------------------------------------------

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

def slider(renderer, x, y, w, h, is_horizontal, ui_state, style={}, &on_change)
    coords = [x, y, w, h]
    slider_val = ui_state[:value] || 0.0

    bg_color = style[:bg] || renderer.gray(200)
    fg_color = style[:fg] || renderer.rgb(255, 0, 0)

    renderer.fill_rect x, y, w, h, bg_color
    if is_horizontal
        renderer.fill_rect x, y, [(slider_val * w).to_i, w].min, h, fg_color
    else
        renderer.fill_rect x, y, w, [(slider_val * h).to_i, h].min, fg_color
    end

    if not ui_state[:pressed]
	evh = {:type => :mouse_down, coords: coords, callback: proc {|ev| 
	    if not ui_state[:pressed]
	        ui_state[:pressed] = true
	        ui_state[:value] = is_horizontal ? ev_coord_to_slider_value(ev.x, x, w) : ev_coord_to_slider_value(ev.y, y, h)
    	        on_change.call(ui_state) if on_change
		true
	    else
		false
	    end
	}}
	renderer.register_event_handler(evh)
    else
	evh1 = {:type => :mouse_up, callback: proc {|ev|
	    if ui_state[:pressed] == true
	        ui_state[:pressed] = false
	        ui_state[:value] = is_horizontal ? ev_coord_to_slider_value(ev.x, x, w) : ev_coord_to_slider_value(ev.y, y, h)
    	        on_change.call(ui_state) if on_change
		true
	    else
		false
	    end
	}}

	evh2 = {:type => :mouse_move, callback: proc {|ev|
	    if ui_state[:pressed] == true
	        ui_state[:value] = is_horizontal ? ev_coord_to_slider_value(ev.x, x, w) : ev_coord_to_slider_value(ev.y, y, h)
    	        on_change.call(ui_state) if on_change
		true
	    else
		false
	    end
	}}
	renderer.register_event_handler(evh1)
	renderer.register_event_handler(evh2)
    end
end

def slider_x(renderer, x, y, w, h, ui_state, style={}, &on_change)
    slider(renderer, x, y, w, h, true, ui_state, style, &on_change)
end

def slider_y(renderer, x, y, w, h, ui_state, style={}, &on_change)
    slider(renderer, x, y, w, h, false, ui_state, style, &on_change)
end

def button(renderer, x, y, w, h, label, ui_state, style={}, &on_click)
    coords = [x, y, w, h]

    bg_color = style[:bg] || renderer.gray(200)
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
