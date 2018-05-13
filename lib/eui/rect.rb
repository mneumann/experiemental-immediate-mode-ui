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
