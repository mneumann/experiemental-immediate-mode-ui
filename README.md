# Experimental graphical UI

This is a proof-of-concept graphical UI (aka "hack").
For now this is written in Ruby.

Is this an immediate mode or retained mode UI? Well, it looks like an immediate
mode UI, but under the hood, it's probably not. It neither does event
processing while rendering, nor does it repaint every frame.  Instead, events
are registered whenver the UI renders and processed in a separate event-loop.

This is what I got after four hours of hacking:

![Screencast of UI](/images/screencast.gif?raw=true "Screencast")

## Widgets

* Buttons
* Horizontal and vertical sliders
* Draggable
