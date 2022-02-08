dofile('init.lua')

local function dump(obj)
    if type(obj) == 'string' then
        return ('%q'):format(obj)
    elseif type(obj) == 'table' then
        local entries = {}
        for k, v in pairs(obj) do
            if type(k) == 'string' and k:match('^[a-zA-Z_][a-zA-Z0-9_]*$') then
                entries[#entries + 1] = k .. ' = ' .. dump(v)
            else
                entries[#entries + 1] = '[' .. dump(k) .. '] = ' .. dump(v)
            end
        end
        table.sort(entries)
        return '{' .. table.concat(entries, ', ') .. '}'
    end
    return tostring(obj)
end

local function equal(t1, t2)
    if type(t1) ~= 'table' or type(t2) ~= 'table' then
        return t1 == t2
    end
    for k, v in pairs(t1) do
        if not equal(v, t2[k]) then
            print(k, v, dump(t1), dump(t2))
            return false
        end
    end
    for k in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end
    return true
end

local function assert_equal(obj1, ...)
    for i = 1, select('#', ...) do
        local objn = select(i, ...)
        if not equal(obj1, objn) then
            error(('%s ~= %s'):format(obj1, objn))
        end
    end
end

local function test_parse(fs, expected_tree)
    -- Make single elements lists and add formspec_version
    if expected_tree.type then
        expected_tree = {expected_tree}
    end
    if not expected_tree.formspec_version then
        expected_tree.formspec_version = 1
    end

    local tree = assert(formspec_ast.parse(fs))
    assert_equal(tree, expected_tree)
end

local function test_parse_unparse(fs, expected_tree)
    test_parse(fs, expected_tree)
    local unparsed_fs = assert(formspec_ast.unparse(expected_tree))
    assert_equal(fs, unparsed_fs)
end

test_parse_unparse([=[label[123,456;yay abc def\, ghi\; jkl mno \]\\]]=], {
    formspec_version = 1,
    {
        type = 'label',
        x = 123,
        y = 456,
        label = 'yay abc def, ghi; jkl mno ]\\'
    }
})

local fs = [[
    formspec_version[2]
    size[5,2]
    padding[1,2]
    no_prepend[]
    container[1,1]
        label[0,0;Containers are fun\]\\]
        container[-1,-1]
            button[0.5,0;4,1;name;Label]
        container_end[]
        label[0,1;Nested containers work too.]
        scroll_container[0,2;1,1;scrollbar;vertical]
            button[0.5,0;4,1;name;Label]
        scroll_container_end[]
    container_end[]
    image[0,1;1,1;air.png]
    set_focus[name;true]
    dropdown[0,0;1;test;abc,def,ghi,jkl;2]
    dropdown[0,0;1;test;abc,def,ghi,jkl;2;true]
    field_close_on_enter[my-field;false]
    bgcolor[blue]
    bgcolor[blue;true]
    bgcolor[blue;both;green]
    tooltip[1,2;3,4;text]
    tooltip[elem;text;bgcolor]
    background9[1,2;3,4;bg.png;false;5]
    background9[1,2;3,4;bg.png;false;5,6]
    background9[1,2;3,4;bg.png;false;5,6,7,8]
    tablecolumns[text;image;color,option=value;tree]
    list[test;test2;1,2;3,4;5]
    list[test6;test7;8,9;10,11]
]]
fs = ('\n' .. fs):gsub('\n[ \n]*', '')

test_parse_unparse(fs, {
    formspec_version = 2,
    {
        type = "size",
        w = 5,
        h = 2,
    },
    {
        type = "padding",
        x = 1,
        y = 2,
    },
    {
        type = "no_prepend"
    },
    {
        type = "container",
        x = 1,
        y = 1,
        {
            type = "label",
            x = 0,
            y = 0,
            label = "Containers are fun]\\",
        },
        {
            type = "container",
            x = -1,
            y = -1,
            {
                type = "button",
                x = 0.5,
                y = 0,
                w = 4,
                h = 1,
                name = "name",
                label = "Label",
            },
        },
        {
            type = "label",
            x = 0,
            y = 1,
            label = "Nested containers work too.",
        },
        {
            type = "scroll_container",
            x = 0,
            y = 2,
            w = 1,
            h = 1,
            scrollbar_name = "scrollbar",
            orientation = "vertical",
            -- scroll_factor = nil,
            {
                h = 1,
                y = 0,
                label = "Label",
                w = 4,
                name = "name",
                x = 0.5,
                type = "button"
            },
        },
    },
    {
        type = "image",
        x = 0,
        y = 1,
        w = 1,
        h = 1,
        texture_name = "air.png",
    },
    {
        type = "set_focus",
        name = "name",
        force = true,
    },
    {
        type = "dropdown",
        x = 0,
        y = 0,
        w = 1,
        name = "test",
        item = {"abc", "def", "ghi", "jkl"},
        selected_idx = 2,
    },
    {
        type = "dropdown",
        x = 0,
        y = 0,
        w = 1,
        name = "test",
        item = {"abc", "def", "ghi", "jkl"},
        selected_idx = 2,
        index_event = true,
    },
    {
        type = "field_close_on_enter",
        name = "my-field",
        close_on_enter = false,
    },
    {
        type = "bgcolor",
        bgcolor = "blue",
    },
    {
        type = "bgcolor",
        bgcolor = "blue",
        fullscreen = true,
    },
    {
        type = "bgcolor",
        bgcolor = "blue",
        fullscreen = "both",
        fbgcolor = "green",
    },
    {
        type = "tooltip",
        x = 1,
        y = 2,
        w = 3,
        h = 4,
        tooltip_text = "text",
    },
    {
        type = "tooltip",
        gui_element_name = "elem",
        tooltip_text = "text",
        bgcolor = "bgcolor",
    },
    {
        type = "background9",
        x = 1,
        y = 2,
        w = 3,
        h = 4,
        texture_name = "bg.png",
        auto_clip = false,
        middle_x = 5,
    },
    {
        type = "background9",
        x = 1,
        y = 2,
        w = 3,
        h = 4,
        texture_name = "bg.png",
        auto_clip = false,
        middle_x = 5,
        middle_y = 6,
    },
    {
        type = "background9",
        x = 1,
        y = 2,
        w = 3,
        h = 4,
        texture_name = "bg.png",
        auto_clip = false,
        middle_x = 5,
        middle_y = 6,
        middle_x2 = 7,
        middle_y2 = 8,
    },
    {
        type = "tablecolumns",
        tablecolumns = {
            {type = "text", opts = {}},
            {type = "image", opts = {}},
            {type = "color", opts = {option = "value"}},
            {type = "tree", opts = {}},
        },
    },
    {
        type = "list",
        inventory_location = "test",
        list_name = "test2",
        x = 1,
        y = 2,
        w = 3,
        h = 4,
        starting_item_index = 5,
    },
    {
        type = "list",
        inventory_location = "test6",
        list_name = "test7",
        x = 8,
        y = 9,
        w = 10,
        h = 11,
    },
})

local function remove_trailing_params(elem_s, elem, ...)
    local res = {}
    local strings = {}
    local optional_params = {...}
    for i = #optional_params, 1, -1 do
        local p = optional_params[i]
        local no_copy = {}
        if type(p) == "table" then
            for _, param in ipairs(p) do
                no_copy[param] = true
            end
        else
            no_copy[p] = true
        end

        res[i] = elem
        strings[i] = elem_s
        elem_s = elem_s:gsub(";[^;]+%]$", "]")
        local old_elem = elem
        elem = {}
        for k, v in pairs(old_elem) do
            if not no_copy[k] then
                elem[k] = v
            end
        end
    end
    return table.concat(strings, ""), res
end

test_parse_unparse(remove_trailing_params(
    "model[1,2;3,4;abc;def;ghi,jkl;5,6;true;false;7,8;9]",
    {
        type = "model",
        x = 1,
        y = 2,
        w = 3,
        h = 4,
        name = "abc",
        mesh = "def",
        textures = {"ghi", "jkl"},
        rotation_x = 5,
        rotation_y = 6,
        continuous = true,
        mouse_control = false,
        frame_loop_begin = 7,
        frame_loop_end = 8,
        animation_speed = 9
    },
    {"rotation_x", "rotation_y"}, "continuous", "mouse_control",
    {"frame_loop_begin", "frame_loop_end"}, "animation_speed"
))


-- Make sure style[] (un)parses correctly
local s = 'style[test1,test2;def=ghi]style_type[test;abc=def]'
assert_equal(s, assert(formspec_ast.interpret(s)))
test_parse('style[name,name2;bgcolor=blue;textcolor=yellow]', {
    type = "style",
    selectors = {
        "name",
        "name2",
    },
    props = {
        bgcolor = "blue",
        textcolor = "yellow",
    },
})

-- Ensure the style[] unparse compatibility works correctly
assert_equal(
    'style_type[test;abc=def]',
    assert(formspec_ast.unparse({
        {
            type = 'style_type',
            name = 'test',
            props = {
                abc = 'def',
            },
        }
    })),
    assert(formspec_ast.unparse({
        {
            type = 'style_type',
            selectors = {
                'test',
            },
            props = {
                abc = 'def',
            },
        }
    }))
)

-- Ensure flatten works correctly
assert_equal(
    'label[0,0;abc]label[2,2;def]scroll_container[1,1;2,2;test;vertical]' ..
        'image[1,1;1,1;def]scroll_container_end[]',
    formspec_ast.unparse(formspec_ast.flatten(assert(formspec_ast.parse([[
        label[0,0;abc]
        container[3,2]
            container[-1,0]
                label[0,0;def]
            container_end[]
        container_end[]
        scroll_container[1,1;2,2;test;vertical]
            image[1,1;1,1;def]
        scroll_container_end[]
    ]]))))
)

-- Ensure invsize[] is converted to size[]
assert_equal(assert(formspec_ast.interpret('invsize[12,34]')), 'size[12,34]')

print('Tests pass')
