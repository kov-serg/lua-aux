function case(i,d)
  return function(t) local r=t[i] or d
    if type(r)=='function' then r=r() end
    return r
end end
