-- adapted from https://tex.stackexchange.com/a/451951

-- We need some utilities from ConTeXt
callbacks = callbacks or {}
callbacks.supported = callbacks.supported or {}
dofile(kpse.find_file("util-fmt.lua"))
dofile(kpse.find_file("node-ini.lua"))
dofile(kpse.find_file("font-mps.lua"))
-- dofile(kpse.find_file("font-shp.lua")) -- unnecessary on current TeX version

-- That's a simple REImplemetation of ConTeXt's \showshape macro
function outlinejfontpaths(character)
    local fontid = font.current()
    -- prioritise using tate luatexja font
    local curjfnt = tex.getattribute('ltj@curjfnt')
    local curtfnt = tex.getattribute('ltj@curtfnt')
    if curjfnt >= 0 then
        fontid = curjfnt
    end
    if curtfnt >= 0 then
        fontid = curtfnt
    end

    local shapedata   = fonts.hashes.shapes[fontid] -- by index
    local chardata    = fonts.hashes.characters[fontid] -- by unicode
    local shapeglyphs = shapedata.glyphs or { }

    character = utf.byte(character)
    local c = chardata[character]
    if c then
        if not c.index then
            return {}
        end
        local glyph = shapeglyphs[c.index]
        if glyph and (glyph.segments or glyph.sequence) then
            local units  = shapedata.units or 1000
            local factor = 100/units
            local paths  = fonts.metapost.paths(glyph,factor)
            return paths
        end
    end
end
