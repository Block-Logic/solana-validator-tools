# Monkey Patch String Class
class String
  def between(token_start, token_end)
    self[/#{Regexp.escape(token_start)}(.*?)#{Regexp.escape(token_end)}/m, 1]
  end
end

# Monkey patch Array class
class Array
  def median
    sorted = self.sort
    mid = (sorted.length - 1) / 2.0
    (sorted[mid.floor] + sorted[mid.ceil]) / 2.0
  end
end
