require 'sdl'
require 'eui/renderer'
require 'eui/event_handler_registry'

class UI
  attr_reader :renderer

  def initialize(w, h, title, ttf_font_file, font_size)
    SDL.init SDL::INIT_VIDEO
    @screen = SDL::Screen.open(w, h, 16, SDL::SWSURFACE | SDL::ANYFORMAT)
    SDL::WM.set_caption(title, title)
    SDL::TTF.init

    font = SDL::TTF.open(ttf_font_file, font_size)
    font.style = SDL::TTF::STYLE_NORMAL

    @renderer = Renderer.new(@screen, w, h)
    @renderer.add_font('default', font)
  end

  def update_screen
    @screen.updateRect 0, 0, 0, 0
  end

  def run(ui_state = {})
    needs_redraw = true
    event_handler_registry = EventHandlerRegistry.new
    loop do
      if needs_redraw
        event_handler_registry.reset_event_handlers
        yield @renderer, ui_state, event_handler_registry
		update_screen()
      end
	  needs_redraw = event_handler_registry.handle_event
    end
  end
end
