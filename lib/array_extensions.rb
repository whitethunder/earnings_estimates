class Array
  def sum
    self.inject(0) {|accum, c| accum + c.to_f }
  end

  def average
    self.sum.to_f / self.size
  end
end
