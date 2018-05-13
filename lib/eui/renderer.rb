require 'eui/event_handler_mixin'

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


