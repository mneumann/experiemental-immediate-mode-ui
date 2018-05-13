require 'sdl'
require 'eui/renderer'

class UI
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

  def run(ui_state = {})
    needs_redraw = true
    loop do
      if needs_redraw
        @renderer.reset_event_handlers
        @renderer.clear(@renderer.white)
        yield @renderer, ui_state
        @screen.updateRect 0, 0, 0, 0
        end
      needs_redraw = handle_event
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

    false
  end
end
