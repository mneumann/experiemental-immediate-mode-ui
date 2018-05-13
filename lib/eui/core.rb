require 'sdl'

class Rect < Struct.new(:x, :y, :w, :h)
  def contains(x, y)
    x >= self.x &&
      y >= self.y &&
      x < self.x + w &&
      y < self.y + h
  end

  def x2
    x + w - 1
  end

  def y2
    y + h - 1
  end

  def to_a
    [x, y, w, h]
  end

  def with_w(new_w)
    Rect.new(x, y, new_w, h)
  end

  def with_h(new_h)
    Rect.new(x, y, w, new_h)
  end
end

class Point < Struct.new(:x, :y)
  # Clips self inside the rect described by `rect`.
  # Returns a new Point.
  def clip_in_rect(rect)
    Point.new(
      [[x, rect.x].max, rect.x2].min,
      [[y, rect.y].max, rect.y2].min
    )
  end
end

module EventHandlingMixin
  def init_event_handlers
    @event_handlers = []
  end

  def register_event_handler(ev)
    @event_handlers.push(ev)
  end

  def reset_event_handlers
    @event_handlers.clear
  end

  def find_matching_event_handlers(event)
    @event_handlers.reverse_each do |handler|
      next unless ((handler[:type] == :mouse_move) && event.is_a?(SDL::Event::MouseMotion)) ||
                  ((handler[:type] == :mouse_down) && event.is_a?(SDL::Event::MouseButtonDown)) ||
                  ((handler[:type] == :mouse_up) && event.is_a?(SDL::Event::MouseButtonUp))
      rect = handler[:rect]
      yield handler if rect.nil? || rect.contains(event.x, event.y)
    end
  end
end

class Renderer
  include EventHandlingMixin

  def initialize(screen, screen_w, screen_h)
    @screen = screen
    @screen_rect = Rect.new(0, 0, screen_w, screen_h)

    @black = rgb(0, 0, 0)
    @white = rgb(255, 255, 255)
    @fonts = {}

    init_event_handlers
  end

  def clear(color = @black)
    fill_rect @screen_rect, color
  end

  def rgb(r, g, b)
    [r, g, b]
  end

  private def internal_color(rgb_triple)
    @screen.mapRGB(*rgb_triple)
  end

  attr_reader :black

  attr_reader :white

  def gray(scale)
    v = (255 * scale).to_i
    rgb(v, v, v)
  end

  def red(scale = 1.0)
    rgb((255 * scale).to_i, 0, 0)
  end

  def random_color
    rgb(rand(256), rand(256), rand(256))
  end

  def fill_rect(rect, color)
    color = internal_color(color) if color.is_a? Array
    @screen.fillRect *rect.to_a, color
  end

  def rect(rect, color)
    color = internal_color(color) if color.is_a? Array
    @screen.drawRect *rect.to_a, color
  end

  def line(x1, y1, x2, y2, color)
    @screen.drawLine x1, y1, x2, y2, color
  end

  def add_font(name, font)
    @fonts[name] = font
  end

  def text(font_name, str, x, y, color)
    @fonts[font_name].draw_solid_utf8(@screen, str, x, y, *color)
  end
end

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

#
# Lazily initializes ui state
#
def lazy(ui_state, id, &block)
  return ui_state[id] if ui_state.key?(id)
  new_val = block ? yield(id) : { id: id }
  ui_state[id] = new_val
  new_val
end
