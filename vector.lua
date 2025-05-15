Vector = {}
--why do we need a metatable to add two tables? because: it's more readable, now we can just add them the same way we would integers

--not a whole new function, just modifying a normal table(?)
metatable = { --this is not built in, just a name we put
  __call = function (self, a, b) --__ is metatable functions | we are overwriting what the __call function does | normally can't call a table because it's not a function, but now we can - calling it now means "create a table"
    local vec = {
      x = a,
      y = b
    }
    setmetatable(vec, metatable)
    return vec
  end,
  __add = function(a, b)
    return Vector(a.x + b.x, a.y + b.y)
  end,
  __sub = function(a, b)
    return Vector(a.x - b.x, a.y - b.y)
  end,
  __mul = function(a, b) --these names (that is, mul) are built in, not user defined
    if type(a) == "number" then return Vector(a*b.x, a*b.y) end --lua doesn't care if int or float, it's just a number; also this can be split up over multiple lines
    if type(b) == "number" then return Vector(a.x * b, a.y * b) end
    --if both numbers, then we never even get to this piont because it would just us the normal built in multiplication
    --so we don't need an if since the only remaining possibility is "both vectors"
    return Vector(a.x * b.x, a.y * b.y)
  end,
  __eq = function(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    local xClose = math.abs(a.x - b.x) < 1
    local yClose = math.abs(a.y - b.y) < 1
    return xClose and yClose
  end
}

setmetatable(Vector, metatable)