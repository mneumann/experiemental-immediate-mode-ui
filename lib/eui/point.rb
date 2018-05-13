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
