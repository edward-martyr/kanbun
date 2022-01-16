function directtex(str)
    coroutine.yield(str)
end

function to_TeX_box(str)
    directtex("\\ExplSyntaxOn\\newbox\\kanbun_lua_box\\sbox\\kanbun_lua_box{"..str.."}\\ExplSyntaxOff")
    return tex.getbox('kanbun_lua_box')
end

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function main_loop()
    brackets = {}
    -- 
    brackets["furigana"] = {"(", ")"}
    brackets["okurigana"] = {"{","}"} -- allow user to omit
    brackets["kaeriten"] = {"[","]"}
    brackets["furigana4saidokumoji"] = {"‹","›"}
    brackets["okurigana4saidokumoji"] = {"«","»"}
    -- 
    -- other_brackets["punctuation"] = {"⦉","⦊"}
    -- other_brackets["kanji"] = {"⌊","⌋"}
    -- other_brackets["multikanji"] = {"‘","’"}
    -- other_brackets["unit"] = {"“","”"}
    -- 
    left_brackets = {}
    right_brackets = {}
    for k,v in pairs(brackets) do
        table.insert(left_brackets, v[1])
        table.insert(right_brackets, v[2])
    end

    -- punctuation_str = "〻―・、，。…「」『』"
    punctuation_str = "㆐〻―—・、，。…「」『』！？："
    left_punctuation_str = "「『"

    lines_chars_table = {}
    tex_kana_bool = token.create("g_kana_bool")
    tex_true_bool = token.create("c_true_bool")
    for i,l in ipairs(verb_table) do
        split_line = {}
        for c in l:gmatch(utf8.charpattern) do
            table.insert(split_line, c)
        end

        -- some unknown bug (in \matchkana ?) solved by changing the last entry to an empty string if not ascii
        for i,c in ipairs(split_line) do
            last_index = i
        end
        if utf8.codepoint(split_line[last_index] or " ") < 128 then 
            split_line[last_index+1]=""
        else
            split_line[last_index]=""
        end

        last_bracket_index = 0
        for j,c in ipairs(split_line) do
            if has_value(left_brackets, c) then
                last_bracket_index = j
            end
            if last_bracket_index == 0 then
                directtex("\\matchkana{"..c.."}")
                if tex_kana_bool.mode == tex_true_bool.mode then 
                    split_line[j] = brackets["okurigana"][1]..c..brackets["okurigana"][2]
                else
                    split_line[j] = "“⌊"..c.."⌋”"
                end
            end
            if has_value(right_brackets, c) then
                last_bracket_index = 0
            end
        end
        table.insert(lines_chars_table, split_line)
    end

    annotated_lines_table = {}
    for i,l in ipairs(lines_chars_table) do
        line = table.concat(l, "")

        line = string.gsub(line, brackets["okurigana"][2]..brackets["okurigana"][1], "")
        for k,v in pairs(brackets) do
            line = string.gsub(line, "”(%"..v[1]..")", "%1")
            line = string.gsub(line, "(%"..v[2]..")(“)", "%1”%2")
        end
        for c in line:gmatch(utf8.charpattern) do
            last = c
        end
        if has_value(right_brackets, last) then 
            str = str .. '”'
        end
        line = string.gsub(line, "⌊‘⌋”", "‘")
        line = string.gsub(line, "“⌊’⌋", "’")
        for p in punctuation_str:gmatch(utf8.charpattern) do
            line = string.gsub(line, "”“⌊("..p..")⌋", "⦉%1⦊")
        end
        line = string.gsub(line, "⦊⦉", "")

        -- reverse the makeshift bug fix to \matchkana
        line = string.gsub(line, "“⌊⌋”", "")

        -- process annotated text
        tmp_number_of_multikanji_braces = {utf8.char(61442), utf8.char(61443)}
        -- process line into units
        split_line = {}
        for c in line:gmatch(utf8.charpattern) do
            table.insert(split_line, c)
        end
        units = {}
        unit_content = {}
        last_bracket_index = 0
        for j,c in ipairs(split_line) do
            if c == "”" then
                last_bracket_index = last_bracket_index - 1
            end
            if last_bracket_index < 1 then
                table.insert(units, table.concat(unit_content, ""))
                unit_content = {}
            else
                table.insert(unit_content, c)
            end
            if c == "“" then
                last_bracket_index = last_bracket_index + 1
            end
        end
        -- account for multikanji
        for j,u in ipairs(units) do
            split_unit = {}
            for c in u:gmatch(utf8.charpattern) do
                table.insert(split_unit, c)
            end
            number_of_multikanji = 0
            local last_k
            for k,c in ipairs(split_unit) do
                if c == "“" then
                    number_of_multikanji = number_of_multikanji + 1
                    last_k = k
                end
            end
            for m,c in ipairs(split_unit) do
                if m == last_k then
                    split_unit[m] = "“"..tmp_number_of_multikanji_braces[1]..number_of_multikanji..tmp_number_of_multikanji_braces[2]
                end
            end
            units[j] = table.concat(split_unit, "")
            if number_of_multikanji > 0 then
                units[j] = string.gsub(units[j], "“(.-)”’(.*)", "“%1%2”")
                units[j] = string.gsub(units[j], "‘", "")
                tmp_unit = units[j]
                table.remove(units, j)
                for new_unit in tmp_unit:gmatch"“(.-)”" do
                    table.insert(units, j, new_unit)
                    j = j + 1
                end
            end
        end
        for j,u in ipairs(units) do
            if u == "" then
                table.remove(units, j)
            end
        end
        next_left_punct_ = ""
        for j,u in ipairs(units) do
            right_okuri_ = u:match("%{(.-)%}") or ""
            kanji_ = u:match("⌊(.-)⌋") or ""
            right_furi_ = u:match("%((.-)%)") or ""
            left_furi_ = u:match("‹(.-)›") or ""
            left_okuri_ = u:match("«(.-)»") or ""
            punct_ = u:match("⦉(.-)⦊") or ""
            --
            -- punct_ = punct_:gsub("―", "\\tateten")
            -- punct_ = punct_:gsub("—", "\\tateten")
            -- punct_ = punct_:gsub("〻", "\\ninojiten")
            --
            kaeriten_ = u:match("%[(.-)%]") or ""
            multikanji_ = u:match(tmp_number_of_multikanji_braces[1].."(.-)"..tmp_number_of_multikanji_braces[2]) or 0
            if punctuation_str:match(kanji_) then
                punct_ = kanji_
                kanji_ = ""
            end
            left_punct_ = next_left_punct_
            next_left_punct_ = ""
            for p_ in punct_:gmatch(utf8.charpattern) do
                if left_punctuation_str:match(p_) then
                    next_left_punct_ = next_left_punct_ .. p_
                end
            end
            for p_ in left_punctuation_str:gmatch(utf8.charpattern) do
                punct_ = string.gsub(punct_, p_, "")
            end
            if u:match(tmp_number_of_multikanji_braces[1]) then
                multiruby_raise_by_ = 0
                for trace_back_index = 1, multikanji_-1 do
                    multiruby_raise_by_ = multiruby_raise_by_ + to_TeX_box(units[j - trace_back_index]).width/(kanbunzwtosp)
                end
                units[j -  multikanji_ + 1] = units[j -  multikanji_ + 1]:gsub("\\kanjiunit", "\\hbox{\\kanjiunit")
                units[j] = "\\kanjiunit{\\multifuriokuri["..multiruby_raise_by_.."]{"..right_furi_.."}{"..right_okuri_.."}}{"..left_punct_.."}{"..kanji_.."}{"..punct_.."}{"..kaeriten_.."}{\\multifuriokuri["..multiruby_raise_by_.."]{"..left_furi_.."}{"..left_okuri_.."}}}"
            else
                if kanji_ == "" then
                    units[j] = ""
                else
                    units[j] = "\\kanjiunit{\\furiokuri{"..right_furi_.."}{"..right_okuri_.."}}{"..left_punct_.."}{"..kanji_.."}{"..punct_.."}{"..kaeriten_.."}{\\furiokuri{"..left_furi_.."}{"..left_okuri_.."}}"
                end
            end
        end
        line = table.concat(units, "")

        table.insert(annotated_lines_table, line)
    end

    -- ouput
    output = "{\\kanbunfont"..table.concat(annotated_lines_table, "\\par").."\\par}"
    directtex("\\def\\printkanbun{"..output.."}")
    directtex("\\def\\printkanbuncode{\\directlua{print('')print(output)}}")

    -- end loop in TeX
    directtex("\\continuefalse")
end
