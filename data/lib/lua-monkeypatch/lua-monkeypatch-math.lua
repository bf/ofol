
-- math round functions
math.round = function (n)
  return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end
