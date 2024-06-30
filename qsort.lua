function qsort(prm) -- qsort
  local n=prm.n or error "no n"
  local cmp=prm.cmp or error "no cmp"
  local swp=prm.swp or error "no swp"
  local thresh=7
  local stack,i,j={{1,n}}
  while #stack>0 do
    local L,R=table.unpack(table.remove(stack))
    while R-L>=thresh do
      -- local m=(L+R)>>1 -- lua 5.3+
      local m=math.floor((L+R)/2) -- lua 5.1
      swp(m,L) i=L+1 j=R
      if cmp(i,j)>0 then swp(i,j) end
      if cmp(L,j)>0 then swp(L,j) end
      if cmp(i,L)>0 then swp(i,L) end
      while true do
        repeat i=i+1 until cmp(i,L)>=0
        repeat j=j-1 until cmp(j,L)<=0
        if i>j then break else swp(i,j) end
      end
      swp(L,j)
      if j-L>R-i then table.insert(stack,{L,j}) L=i
      else            table.insert(stack,{i,R}) R=j end
    end
    i=L+1
    while i<=R do j=i while j>L and cmp(j-1,j)>0 do swp(j-1,j) j=j-1 end i=i+1 end
  end
end
