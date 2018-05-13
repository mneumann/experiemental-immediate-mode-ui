require 'sdl'

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
