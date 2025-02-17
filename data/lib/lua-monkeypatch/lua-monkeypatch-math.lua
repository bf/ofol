
-- math round functions
math.round = function (n)
  return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end

-- clamp value between min and max
math.clamp = function (n, lo, hi)
  return math.max(math.min(n, hi), lo)
end