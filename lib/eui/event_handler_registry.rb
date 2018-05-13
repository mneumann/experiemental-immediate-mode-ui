require 'sdl'

class EventHandlerRegistry
  def initialize
    @event_handlers = []
  end

  def register_event_handler(ev)
    @event_handlers.push(ev)
  end

  def reset_event_handlers
    @event_handlers.clear
  end

  private def find_matching_event_handlers(event)
    @event_handlers.reverse_each do |handler|
      next unless ((handler[:type] == :mouse_move) && event.is_a?(SDL::Event::MouseMotion)) ||
                  ((handler[:type] == :mouse_down) && event.is_a?(SDL::Event::MouseButtonDown)) ||
                  ((handler[:type] == :mouse_up) && event.is_a?(SDL::Event::MouseButtonUp))
      rect = handler[:rect]
      yield handler if rect.nil? || rect.contains(event.x, event.y)
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
      find_matching_event_handlers(event) do |handler|
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
