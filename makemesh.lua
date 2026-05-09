local makeMesh={}

local svgpath=require "svgpath"
-- makeMesh.svgpath=svgpath

function makeMesh.makeMeshFromShape(image,shape)
    local g=love.graphics
    local w,h=image:getDimensions()
    local points=svgpath.polygon(shape)
    local poly,data={},{}
    for k,v in pairs(points) do
        table.insert(poly,v[1])
        table.insert(poly,v[2])
    end
    local tr=love.math.triangulate(poly)
    for k,v in pairs(tr) do
        table.insert(data,{ v[1],v[2], v[1]/w,v[2]/h })
        table.insert(data,{ v[3],v[4], v[3]/w,v[4]/h })
        table.insert(data,{ v[5],v[6], v[5]/w,v[6]/h })
    end
    local mesh=g.newMesh(data,"triangles")
    mesh:setTexture(image)
    return mesh
end

return makeMesh