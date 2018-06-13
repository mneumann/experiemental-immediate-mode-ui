$LOAD_PATH.unshift '../lib'
require 'eui/rect'
require 'eui/ui'

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

def slider(ctx, uid, slider_val, rect, is_horizontal, style)
	bg_color = style[:bg] || ctx.renderer.gray(0.8)
	fg_color = style[:fg] || ctx.renderer.rgb(255, 0, 0)
	border_color = style[:border]

	ctx.renderer.fill_rect rect, bg_color
	filled_rect = if is_horizontal
					  rect.with_w([(slider_val * rect.w).to_i, rect.w].min)
				  else
					  rect.with_h([(slider_val * rect.h).to_i, rect.h].min)
				  end
	ctx.renderer.fill_rect filled_rect, fg_color
	ctx.renderer.rect filled_rect, border_color if border_color

	if ctx.mouse_key == 1 and rect.contains(ctx.mx, ctx.my)
		if is_horizontal
			return ev_coord_to_slider_value(ctx.mx, rect.x, rect.w)
		else
			return ev_coord_to_slider_value(ctx.my, rect.y, rect.h)
		end
	else
		return slider_val
	end
end

def button(ctx, uid, rect, label, style = {})
	bg_color = style[:bg] || ctx.renderer.gray(0.8)
	fg_color = style[:fg] || ctx.renderer.black
	border_color = style[:border] || ctx.renderer.black
	font = style[:font] || 'default'

	draw_pressed = false
	click_action = false

	if rect.contains(ctx.mx, ctx.my)
		if ctx.active == uid
			# This button received a mouse click before
			if ctx.mouse_key == 0
				click_action = true
				ctx.active = nil
			else
				draw_pressed = true
			end
		elsif ctx.mouse_key == 1
			ctx.active = uid
			draw_pressed = true
		end
	end

	offset = if draw_pressed then 5 else 2 end
	ctx.renderer.fill_rect rect, bg_color
	ctx.renderer.rect rect, border_color
	ctx.renderer.text(font, label, rect.x + offset, rect.y + offset, fg_color)

	return click_action
end

class UIContext
	attr_accessor :mx, :my
	attr_accessor :mouse_key
	attr_accessor :active

	def initialize(ui)
		@ui = ui
		@mx = 0
		@my = 0
		@mouse_key = 0
	end

	def renderer
		@ui.renderer
	end
end

def main
  w = 600
  h = 480

  ui = UI.new(w, h, 'immui', '/usr/local/share/fonts/dejavu/DejaVuSans.ttf', 18)

  ctx = UIContext.new(ui)

  slider1_val = 0.5
  slider2_val = 1.0

  loop do
	ui.renderer.clear(ui.renderer.white)
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
		ctx.mx = event.x
		ctx.my = event.y
	when SDL::Event::MouseButtonDown
		ctx.mx = event.x
		ctx.my = event.y
		ctx.mouse_key = 1
	when SDL::Event::MouseButtonUp
		ctx.mx = event.x
		ctx.my = event.y
		ctx.mouse_key = 0
	end

	x1 = 10
	w1 = w - 20
	y1 = 10
	h1 = 40 
	y2 = y1 + h1 + 10
	y3 = y2 + h1 + 10
		
	if button(ctx, "but",
		   Rect.new(x1, y1, w1, h1),
		   "Click me",
		   { border: ui.renderer.black }) then
		p "clicked"
	end
	slider1_val = slider(ctx, "s1",
		   slider1_val,
		   Rect.new(x1, y2, w1, h1),
		   true,
		   { border: ui.renderer.black })
	slider2_val = slider(ctx, "s2",
		   slider2_val,
		   Rect.new(x1, y3, w1, h1),
		   true,
		   { border: ui.renderer.black })
	ui.update_screen
  end
end

main if $PROGRAM_NAME == __FILE__
