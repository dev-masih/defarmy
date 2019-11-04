-- DefArmy
-- This module helps you to create groups (army) of game objects (soldiers) and organize
-- them in several different patterns or your customized pattern and manage moving and
-- rotating game objects as a group.

local M = {}

--- Store army data and it's members.
--- Structure: army_list[army_id] = { center_position, pattern_func, radius, rotation, member_padding, is_sticky, member_id_list[]:number }
local army_list = {}

--- Store soldiers data.
--- Structure: soldier_list[soldier_id] = { army_id, position, direction, status, is_assigned, initial_direction, distance_order, debug_color }
local soldier_list = {}

local army_id_iterator = 0
local soldier_id_iterator = 0

-- Math functions
local huge = math.huge
local sqrt = math.sqrt
local pow = math.pow
local modf = math.modf
local atan2 = math.atan2
local max = math.max
local fmod = math.fmod
local ceil = math.ceil

local SOLDIER_STATUS = {}
SOLDIER_STATUS.OUTSIDE = hash("soldier_status_outside")
SOLDIER_STATUS.WAITING = hash("soldier_status_waiting")
SOLDIER_STATUS.INSIDE = hash("soldier_status_inside")
SOLDIER_STATUS.INPLACE = hash("soldier_status_inplace")

--- Army patterns
M.PATTERN = {}
M.PATTERN.BOTTOM_TO_TOP_SQUARE = hash("pattern_bottom_to_top_square")
M.PATTERN.TOP_TO_BOTTOM_SQUARE = hash("pattern_top_to_bottom_square")
M.PATTERN.TRIANGLE = hash("pattern_triangle")
M.PATTERN.RHOMBUS_TALL = hash("pattern_rhombus_tall")
M.PATTERN.RHOMBUS_SHORT = hash("pattern_rhombus_short")
M.PATTERN.CUSTOMIZED = hash("pattern_customized")

local function distance(source, destination)
    return sqrt(pow(source.x - destination.x, 2) + pow(source.y - destination.y, 2))
end

local function debug_mark_soldier(position, soldier_id)
    if soldier_list[soldier_id].debug_color then
        local padding = army_list[soldier_list[soldier_id].army_id].member_padding / 2
        msg.post("@render:", "draw_line", { start_point = position + vmath.vector3(padding, padding, 0), end_point = position + vmath.vector3(-padding, -padding, 0), color = soldier_list[soldier_id].debug_color } )
        msg.post("@render:", "draw_line", { start_point = position + vmath.vector3(-padding, padding, 0), end_point = position + vmath.vector3(padding, -padding, 0), color = soldier_list[soldier_id].debug_color } )
    end
end

--- Army debugging.
--- @param army_id (number) army id number
--- @param debug_color (vector4) color used for debugging
function M.army_debug_draw(army_id, debug_color)
    assert(army_id, "You must provide a army id")
    assert(debug_color, "You must provide a debug color")

    assert(army_list[army_id], ("Unknown army id %s"):format(tostring(army_id)))

    msg.post("@render:", "draw_line", { start_point = army_list[army_id].center_position + vmath.vector3(5, 5, 0), end_point = army_list[army_id].center_position + vmath.vector3(-5, -5, 0), color = debug_color } )
    msg.post("@render:", "draw_line", { start_point = army_list[army_id].center_position + vmath.vector3(-5, 5, 0), end_point = army_list[army_id].center_position + vmath.vector3(5, -5, 0), color = debug_color } )
    msg.post("@render:", "draw_line", { start_point = army_list[army_id].center_position + vmath.vector3(-5, 0, 0), end_point = army_list[army_id].center_position + vmath.vector3(5, 0, 0), color = debug_color } )
    msg.post("@render:", "draw_line", { start_point = army_list[army_id].center_position + vmath.vector3(0, -5, 0), end_point = army_list[army_id].center_position + vmath.vector3(0, 5, 0), color = debug_color } )

    local far_point = vmath.vector3(0, (army_list[army_id].radius + 1) * army_list[army_id].member_padding / 2, 0)
    far_point = vmath.rotate(army_list[army_id].rotation, far_point) + army_list[army_id].center_position

    msg.post("@render:", "draw_line", { start_point = army_list[army_id].center_position, end_point = far_point, color = debug_color } )

    msg.post("@render:", "draw_line", { start_point = far_point + vmath.vector3(3, 3, 0), end_point = far_point + vmath.vector3(-3, -3, 0), color = debug_color } )
    msg.post("@render:", "draw_line", { start_point = far_point + vmath.vector3(-3, 3, 0), end_point = far_point + vmath.vector3(3, -3, 0), color = debug_color } )
    msg.post("@render:", "draw_line", { start_point = far_point + vmath.vector3(-3, 0, 0), end_point = far_point + vmath.vector3(3, 0, 0), color = debug_color } )
    msg.post("@render:", "draw_line", { start_point = far_point + vmath.vector3(0, -3, 0), end_point = far_point + vmath.vector3(0, 3, 0), color = debug_color } )
end

--- Turn on soldier position debugging.
--- @param soldier_id (number) soldier id number
--- @param debug_color (vector4) color used for debugging
function M.soldier_debug_on(soldier_id, debug_color)
    assert(soldier_id, "You must provide a soldier id")
    assert(debug_color, "You must provide a debug color")

    assert(soldier_list[soldier_id], ("Unknown soldier id %s"):format(tostring(soldier_id)))

    soldier_list[soldier_id].debug_color = debug_color
end

--- Turn off soldier position debugging.
--- @param soldier_id (number) soldier id number
function M.soldier_debug_off(soldier_id)
    assert(soldier_id, "You must provide a soldier id")

    assert(soldier_list[soldier_id], ("Unknown soldier id %s"):format(tostring(soldier_id)))

    soldier_list[soldier_id].debug_color = nil
end

local function pattern_bottom_to_top_square(total_count)
    local army_schema = {}
    local row_width = ceil(sqrt(total_count))
    local reminder = fmod(total_count, row_width)
    for i = 1, row_width do
        local value = modf(total_count / row_width)
        table.insert(army_schema, i, value)
        if reminder > 0 then
            army_schema[i] = army_schema[i] + 1
            reminder = reminder - 1
        end
    end
    return army_schema
end

local function pattern_top_to_bottom_square(total_count)
    local army_schema = {}
    local row_width = ceil(sqrt(total_count))
    local reminder = fmod(total_count, row_width)
    local value = modf(total_count / row_width)
    for i = 1, value do
        table.insert(army_schema, row_width)
    end
    if reminder > 0 then
        table.insert(army_schema, reminder)
    end
    return army_schema
end

local function pattern_triangle(total_count)
    local army_schema = {}
    local sum = total_count
    local row_width = 1
    for i = 1, total_count / 2 + 1 do table.insert(army_schema, 0) end
    for i = modf(total_count / 2 + 1), 1, -1 do
        if sum < row_width then
            army_schema[i] = sum
            break
        else
            sum = sum - row_width
            army_schema[i] = row_width
            row_width = row_width + 1
        end
    end
    return army_schema
end

local function pattern_rhombus_tall(total_count)
    local army_schema = {}
    local sum = total_count
    local row_width = 0
    local middle = modf(total_count / 4) + 1
    for i = 1, total_count / 2 + 1 do table.insert(army_schema, 0) end
    for i = 1, total_count do
        army_schema[middle] = army_schema[middle] + 1
        sum = sum - 1
        if sum == 0 then break end
        for i = 1, row_width do
            army_schema[middle + i] = army_schema[middle + i] + 1
            sum = sum - 1
            if sum == 0 then break end
            army_schema[middle - i] = army_schema[middle - i] + 1
            sum = sum - 1
            if sum == 0 then break end
        end
        if sum == 0 then break end
        row_width = row_width + 1
    end
    return army_schema
end

local function pattern_rhombus_short(total_count)
    local army_schema = {}
    local row_width = 0
    local sum = total_count
    local middle = modf(total_count / 4) + 1
    for i = 1, total_count / 2 + 1 do table.insert(army_schema, 0) end
    for i = 1, total_count do
        army_schema[middle] = army_schema[middle] + 1
        sum = sum - 1
        if sum == 0 then break end
        for i = 1, modf(row_width) do
            army_schema[middle + i] = army_schema[middle + i] + 1
            sum = sum - 1
            if sum == 0 then break end
            army_schema[middle - i] = army_schema[middle - i] + 1
            sum = sum - 1
            if sum == 0 then break end
        end
        if sum == 0 then break end
        row_width = row_width + 0.5
    end
    return army_schema
end

--- Create a group of game objects (army) with specified member padding and pattern.
--- @param army_center_position (vector3) army center position
--- @param army_initial_rotation (quat) army initial rotation quat
--- @param member_padding (number) padding between members
--- @param is_sticky (boolean) is members glued to their places in army
--- @param army_pattern (PATTERN) army pattern
--- @param pattern_func (func|nil) army customized pattern function [nil]
--- @return (number) army id
function M.army_create(army_center_position, army_initial_rotation, member_padding, is_sticky, army_pattern, pattern_func)
    assert(army_center_position, "You must provide an army center position")
    assert(army_initial_rotation, "You must provide an army initial rotation")
    assert(member_padding, "You must provide an member padding")
    if is_sticky == nil then assert(is_sticky, "You must provide a stickiness") end
    assert(army_pattern, "You must provide an army pattern")

    local pattern_function
    if army_pattern == M.PATTERN.BOTTOM_TO_TOP_SQUARE then
        pattern_function = pattern_bottom_to_top_square
    elseif army_pattern == M.PATTERN.TOP_TO_BOTTOM_SQUARE then
        pattern_function = pattern_top_to_bottom_square
    elseif army_pattern == M.PATTERN.TRIANGLE then
        pattern_function = pattern_triangle
    elseif army_pattern == M.PATTERN.RHOMBUS_TALL then
        pattern_function = pattern_rhombus_tall
    elseif army_pattern == M.PATTERN.RHOMBUS_SHORT then
        pattern_function = pattern_rhombus_short
    elseif army_pattern == M.PATTERN.CUSTOMIZED then
        pattern_function = pattern_func
        assert(pattern_function, "You must provide an army pattern function")
    else
        assert(false, ("Unknown army pattern %s"):format(tostring(army_pattern)))
    end

    army_id_iterator = army_id_iterator + 1
    local army_id = army_id_iterator
    army_list[army_id] = { center_position = army_center_position, member_padding = member_padding, radius = member_padding,
                           rotation = army_initial_rotation, pattern_func = pattern_function, is_sticky = is_sticky, member_id_list = {} }
    return army_id
end

--- Return an army members id.
--- @param army_id (number) army id number
--- @return (table) list of soldier's id that were members of that army
function M.army_members(army_id)
    assert(army_id, "You must provide an army id")

    assert(army_list[army_id], ("Unknown army id %s"):format(tostring(army_id)))

    return army_list[army_id].member_id_list
end

--- Remove a grouping of game objects (army) and release it's members.
--- @param army_id (number) army id number
function M.army_remove(army_id)
    assert(army_id, "You must provide an army id")

    assert(army_list[army_id], ("Unknown army id %s"):format(tostring(army_id)))

    for i = 1, #army_list[army_id].member_id_list do
        soldier_list[army_list[army_id].member_id_list[i]].army_id = 0
        soldier_list[army_list[army_id].member_id_list[i]].status = SOLDIER_STATUS.OUTSIDE
        soldier_list[army_list[army_id].member_id_list[i]].is_assigned = false
    end
    army_list[army_id] = nil
end

local function count_soldiers_not_outside_army(army_id)
    local count = 0
    for _, soldier_id in pairs(army_list[army_id].member_id_list) do
        if soldier_list[soldier_id].status ~= SOLDIER_STATUS.OUTSIDE then
            count = count + 1
        end
    end
    return count
end

local function rearenge_army(army_id, prefered_start_position)
    -- create army schema according to pattern function
    local total_count = count_soldiers_not_outside_army(army_id)
    local army_schema = army_list[army_id].pattern_func(total_count)

    -- remove empty rows in schema
    local counter = 0
    local j, len = 1, #army_schema
    for i = 1, len do
        if (army_schema[i] ~= 0) then
            counter = counter + army_schema[i]
            if (i ~= j) then
                army_schema[j] = army_schema[i]
                army_schema[i] = nil
            end
            j = j + 1
        else
            army_schema[i] = nil
        end
    end
    assert(counter == total_count, "Pattern is not add up to total count")

    -- assign army radius
    army_list[army_id].radius = #army_schema

    -- Store placeholder data.
    -- Structure: placeholder_list[placeholder_id] = { position, is_occupied, distance_order }
    local placeholder_list = {}

    -- create pattern placeholder from schema
    local reltive_x = 0
    local reltive_y = 0
    local padding = army_list[army_id].member_padding
    for i = 1, #army_schema do
        for j = 1, army_schema[i] do
            local mod_cell = army_schema[i] % 2
            local mod_row = #army_schema % 2

            if mod_cell == 0 then
                local rel_x = j - (army_schema[i] / 2)
                reltive_x = (rel_x - 1) * padding + (padding / 2)
            else
                local rel_x = j - ((army_schema[i] + 1) / 2)
                reltive_x = rel_x * padding
            end

            if mod_row == 0 then
                local rel_y = i - (#army_schema / 2)
                reltive_y = (rel_y - 1) * padding + (padding / 2)
            else
                local rel_y = i - ((#army_schema + 1) / 2)
                reltive_y = rel_y * padding
            end

            table.insert(placeholder_list, { position = vmath.vector3(reltive_x, reltive_y, 0), is_occupied = false, distance_order = 0 })
        end
        army_list[army_id].radius = max(army_list[army_id].radius, army_schema[i])
    end

    -- restart soldiers assigned flag
    local waiting_soldier_member_id = 1
    for i = 1, #army_list[army_id].member_id_list do
        soldier_list[army_list[army_id].member_id_list[i]].is_assigned = false
        if soldier_list[army_list[army_id].member_id_list[i]].status == SOLDIER_STATUS.INPLACE then
            soldier_list[army_list[army_id].member_id_list[i]].status = SOLDIER_STATUS.INSIDE
        elseif soldier_list[army_list[army_id].member_id_list[i]].status == SOLDIER_STATUS.WAITING then
            waiting_soldier_member_id = i
        end
    end

    -- allow the waiting soldier to first pick nearest placeholder if prefered_start_position was not set
    if not prefered_start_position then
        local min_dist = huge
        local min_placeholder_index = 1

        for i = 1, #placeholder_list do
            local new_dist = distance(vmath.rotate(army_list[army_id].rotation, placeholder_list[i].position),
                                      soldier_list[army_list[army_id].member_id_list[waiting_soldier_member_id]].position)
            if new_dist < min_dist then
                min_dist = new_dist
                min_placeholder_index = i
            end
        end

        prefered_start_position = placeholder_list[min_placeholder_index].position
        soldier_list[army_list[army_id].member_id_list[waiting_soldier_member_id]].position = prefered_start_position
        soldier_list[army_list[army_id].member_id_list[waiting_soldier_member_id]].is_assigned = true
        placeholder_list[min_placeholder_index].is_occupied = true
    end

    -- calculate each placeholder distance_order in relative to first picked placeholder
    for i = 1, #placeholder_list do
        placeholder_list[i].distance_order = distance(placeholder_list[i].position, prefered_start_position)
    end

    -- sort placeholders from high to low distance_order
    table.sort(placeholder_list, function(x, y) return x.distance_order > y.distance_order end)

    -- calculate each soldier distance_order in relative to first picked soldier
    for i = 1, #army_list[army_id].member_id_list do
        soldier_list[army_list[army_id].member_id_list[i]].distance_order = distance(soldier_list[army_list[army_id].member_id_list[i]].position,
                                                                                     prefered_start_position)
    end

    -- sort soldiers from high to low distance_order
    table.sort(army_list[army_id].member_id_list, function(x, y) return soldier_list[x].distance_order > soldier_list[y].distance_order end)

    -- assign each placeholder to it's nearest soldier
    for i = 1, #placeholder_list do
        if not placeholder_list[i].is_occupied then
            local min_dist = huge
            local min_soldier_id = 1

            for j = 1, #army_list[army_id].member_id_list do
                if not soldier_list[army_list[army_id].member_id_list[j]].is_assigned then
                    local dist = distance(placeholder_list[i].position,
                                          soldier_list[army_list[army_id].member_id_list[j]].position)

                    if soldier_list[army_list[army_id].member_id_list[j]].status ~= SOLDIER_STATUS.OUTSIDE then
                        local far_dist = distance(soldier_list[army_list[army_id].member_id_list[j]].position, prefered_start_position) -
                                         distance(placeholder_list[i].position, prefered_start_position)
                        dist = dist - far_dist
                    end

                    if dist < min_dist then
                        min_dist = dist
                        min_soldier_id = j
                    end
                end
            end

            soldier_list[army_list[army_id].member_id_list[min_soldier_id]].position = placeholder_list[i].position
            soldier_list[army_list[army_id].member_id_list[min_soldier_id]].is_assigned = true
            placeholder_list[i].is_occupied = true
        end
    end
end

--- Update an army center position.
--- @param army_id (number) army id number
--- @param army_center_position (vector3) new army center position
function M.army_update_position(army_id, army_center_position)
    assert(army_id, "You must provide an army id")
    assert(army_center_position, "You must provide an army center position")

    assert(army_list[army_id], ("Unknown army id %s"):format(tostring(army_id)))

    army_list[army_id].center_position = army_center_position
end

--- Update an army rotation.
--- @param army_id (number) army id number
--- @param army_rotation (quat) new army rotation quat
function M.army_update_rotation(army_id, army_rotation)
    assert(army_id, "You must provide an army id")
    assert(army_rotation, "You must provide an army rotation")

    assert(army_list[army_id], ("Unknown army id %s"):format(tostring(army_id)))

    army_list[army_id].rotation = army_rotation
end

--- Update an army pattern.
--- @param army_id (number) army id number
--- @param army_pattern (PATTERN) new army pattern
--- @param pattern_func (func|nil) army customized pattern function [nil]
function M.army_update_pattern(army_id, army_pattern, pattern_func)
    assert(army_id, "You must provide an army id")
    assert(army_pattern, "You must provide an army pattern")

    assert(army_list[army_id], ("Unknown army id %s"):format(tostring(army_id)))

    local pattern_function
    if army_pattern == M.PATTERN.BOTTOM_TO_TOP_SQUARE then
        pattern_function = pattern_bottom_to_top_square
    elseif army_pattern == M.PATTERN.TOP_TO_BOTTOM_SQUARE then
        pattern_function = pattern_top_to_bottom_square
    elseif army_pattern == M.PATTERN.TRIANGLE then
        pattern_function = pattern_triangle
    elseif army_pattern == M.PATTERN.RHOMBUS_TALL then
        pattern_function = pattern_rhombus_tall
    elseif army_pattern == M.PATTERN.RHOMBUS_SHORT then
        pattern_function = pattern_rhombus_short
    elseif army_pattern == M.PATTERN.CUSTOMIZED then
        pattern_function = pattern_func
        assert(pattern_function, "You must provide an army pattern function")
    else
        assert(false, ("Unknown army pattern %s"):format(tostring(army_pattern)))
    end

    army_list[army_id].pattern_func = pattern_function
    rearenge_army(army_id, vmath.vector3(0, 0, 0))
end

--- Update an army stickiness.
--- @param army_id (number) army id number
--- @param is_sticky (boolean) is members glued to their places in army
function M.army_update_stickiness(army_id, is_sticky)
    assert(army_id, "You must provide an army id")
    if is_sticky == nil then assert(is_sticky, "You must provide a stickiness") end

    assert(army_list[army_id], ("Unknown army id %s"):format(tostring(army_id)))

    army_list[army_id].is_sticky = is_sticky

    for i = 1, #army_list[army_id].member_id_list do
        if soldier_list[army_list[army_id].member_id_list[i]].status == SOLDIER_STATUS.INPLACE then
            soldier_list[army_list[army_id].member_id_list[i]].status = SOLDIER_STATUS.INSIDE
        end
    end
end

--- Create a new soldier and optionally assign it to an army.
--- @param position (vector3) soldier current position
--- @param initial_direction (vector3) soldier initial direction vecotr
--- @param army_id (number|nil) optional army id number
--- @return (number) soldier id
function M.soldier_create(position, initial_direction, army_id)
    assert(position, "You must provide a position")
    assert(initial_direction, "You must provide an initial direction")

    if army_id then
        assert(army_list[army_id], ("Unknown army id %s"):format(tostring(army_id)))
    else
        army_id = 0
    end

    soldier_id_iterator = soldier_id_iterator + 1
    local soldier_id = soldier_id_iterator

    soldier_list[soldier_id] = { army_id = army_id, position = position, direction = initial_direction,
                                 status = SOLDIER_STATUS.OUTSIDE, is_assigned = false,
                                 initial_direction = initial_direction, distance_order = 0 }

    if army_id ~= 0 then
        table.insert(army_list[army_id].member_id_list, soldier_id)
    end

    return soldier_id
end

--- Assign an existing soldier to a given army.
--- @param soldier_id (number) soldier id number
--- @param army_id (number) army id number
function M.soldier_join_army(soldier_id, army_id)
    assert(soldier_id, "You must provide a soldier id")
    assert(army_id, "You must provide an army id")

    assert(soldier_list[soldier_id], ("Unknown soldier id %s"):format(tostring(soldier_id)))
    assert(army_list[army_id], ("Unknown army id %s"):format(tostring(army_id)))

    local last_army_id = soldier_list[soldier_id].army_id
    if last_army_id ~= 0 then
        for i = 1, #army_list[last_army_id].member_id_list do
            if soldier_id == army_list[last_army_id].member_id_list[i] then
                table.remove(army_list[last_army_id].member_id_list, i)
                break
            end
        end
    end

    soldier_list[soldier_id].army_id = army_id
    table.insert(army_list[army_id].member_id_list, soldier_id)
end

--- Deassign a soldier from army.
--- @param soldier_id (number) soldier id number
function M.soldier_leave_army(soldier_id)
    assert(soldier_id, "You must provide a soldier id")

    assert(soldier_list[soldier_id], ("Unknown soldier id %s"):format(tostring(soldier_id)))

    if soldier_list[soldier_id].army_id ~= 0 then
        local army_id = soldier_list[soldier_id].army_id

        soldier_list[soldier_id].army_id = 0
        soldier_list[soldier_id].status = SOLDIER_STATUS.OUTSIDE
        soldier_list[soldier_id].is_assigned = false

        for i = 1, #army_list[army_id].member_id_list do
            if soldier_id == army_list[army_id].member_id_list[i] then
                table.remove(army_list[army_id].member_id_list, i)
                break
            end
        end

        rearenge_army(army_id, soldier_list[soldier_id].postion)
    end
end

--- Completely remove a soldier.
--- @param soldier_id (number) soldier id number
function M.soldier_remove(soldier_id)
    assert(soldier_id, "You must provide a soldier id")

    assert(soldier_list[soldier_id], ("Unknown soldier id %s"):format(tostring(soldier_id)))

    local army_id = soldier_list[soldier_id].army_id
    local last_position = soldier_list[soldier_id].postion
    soldier_list[soldier_id] = nil

    if army_id ~= 0 then
        for i = 1, #army_list[army_id].member_id_list do
            if soldier_id == army_list[army_id].member_id_list[i] then
                table.remove(army_list[army_id].member_id_list, i)
                break
            end
        end
        rearenge_army(army_id, last_position)
    end
end

local function normalize(vec)
    if vec.x == 0 and vec.y == 0 then
        return vmath.vector3()
    else
        return vmath.normalize(vec)
    end
end

--- Calculate a soldier next postion and rotation.
--- @param soldier_id (number) soldier id number
--- @param current_position (vecotr3) soldier current position
--- @param speed (number) soldier speed
--- @param threshold (number|nil) optional soldier placement detection threshold [1]
--- @return (vector3) soldier next position
--- @return (quat) soldier next rotation
function M.soldier_move(soldier_id, current_position, speed, threshold)
    assert(soldier_id, "You must provide a soldier id")
    assert(current_position, "You must provide a current position")
    assert(speed, "You must provide a speed")

    -- if soldier removed
    if soldier_list[soldier_id] == nil then
        return nil, nil
    end

    -- if soldier is not in any army
    if soldier_list[soldier_id].army_id == 0 then
        local rotation = vmath.quat_rotation_z(atan2(soldier_list[soldier_id].direction.y, soldier_list[soldier_id].direction.x)
                             - atan2(soldier_list[soldier_id].initial_direction.y, soldier_list[soldier_id].initial_direction.x))

        debug_mark_soldier(current_position, soldier_id)
        return current_position, rotation
    end

    local army_id = soldier_list[soldier_id].army_id

    if soldier_list[soldier_id].status == SOLDIER_STATUS.OUTSIDE then
        if distance(army_list[army_id].center_position, current_position) < (army_list[army_id].radius + 3) * army_list[army_id].member_padding / 2 then
            -- soldier is inside army area
            soldier_list[soldier_id].status = SOLDIER_STATUS.WAITING
            soldier_list[soldier_id].position = soldier_list[soldier_id].position - army_list[army_id].center_position

            rearenge_army(army_id)

            soldier_list[soldier_id].status = SOLDIER_STATUS.INSIDE
            local direction_vector = vmath.rotate(army_list[army_id].rotation, soldier_list[soldier_id].position) + army_list[army_id].center_position - current_position
            direction_vector.z = 0
            direction_vector = normalize(direction_vector)
            local position = (current_position +  direction_vector * speed)

            local rotation_vector = vmath.lerp(0.2 * speed, soldier_list[soldier_id].direction, direction_vector)
            local rotation = vmath.quat_rotation_z(atan2(rotation_vector.y, rotation_vector.x) - atan2(soldier_list[soldier_id].initial_direction.y, soldier_list[soldier_id].initial_direction.x))
            soldier_list[soldier_id].direction = rotation_vector

            return position, rotation
        else
            -- soldier is outside of army area
            local dist_partial = (army_list[army_id].radius + 2) * army_list[army_id].member_padding / 2
            local dist_total = distance(current_position, army_list[army_id].center_position)
            soldier_list[soldier_id].position = vmath.lerp(dist_partial / dist_total, army_list[army_id].center_position, current_position)

            debug_mark_soldier(soldier_list[soldier_id].position, soldier_id)

            local direction_vector = soldier_list[soldier_id].position - current_position
            direction_vector.z = 0
            direction_vector = normalize(direction_vector)
            local position = (current_position +  direction_vector * speed)

            local rotation_vector = vmath.lerp(0.2 * speed, soldier_list[soldier_id].direction, direction_vector)
            local rotation = vmath.quat_rotation_z(atan2(rotation_vector.y, rotation_vector.x) - atan2(soldier_list[soldier_id].initial_direction.y, soldier_list[soldier_id].initial_direction.x))
            soldier_list[soldier_id].direction = rotation_vector

            return position, rotation
        end
    elseif soldier_list[soldier_id].status == SOLDIER_STATUS.INPLACE then
        local position = vmath.rotate(army_list[army_id].rotation, soldier_list[soldier_id].position) + army_list[army_id].center_position

        local rotated_initial_direction = vmath.rotate(army_list[army_id].rotation, soldier_list[soldier_id].initial_direction)
        local rotation_vector = vmath.lerp(0.2 * speed, soldier_list[soldier_id].direction, rotated_initial_direction)
        local rotation = vmath.quat_rotation_z(atan2(rotation_vector.y, rotation_vector.x) - atan2(soldier_list[soldier_id].initial_direction.y, soldier_list[soldier_id].initial_direction.x))
        soldier_list[soldier_id].direction = rotation_vector

        debug_mark_soldier(position, soldier_id)
        return position, rotation
    else
        local soldier_position = vmath.rotate(army_list[army_id].rotation, soldier_list[soldier_id].position) + army_list[army_id].center_position
        if not threshold then threshold = 1 end
        if distance(soldier_position, current_position) > threshold then
            -- soldier is not in placeholder
            local direction_vector = vmath.rotate(army_list[army_id].rotation, soldier_list[soldier_id].position) + army_list[army_id].center_position

            debug_mark_soldier(direction_vector, soldier_id)

            direction_vector = direction_vector - current_position
            direction_vector.z = 0
            direction_vector = normalize(direction_vector)
            local position = (current_position +  direction_vector * speed)

            local rotation_vector = vmath.lerp(0.2 * speed, soldier_list[soldier_id].direction, direction_vector)
            local rotation = vmath.quat_rotation_z(atan2(rotation_vector.y, rotation_vector.x) - atan2(soldier_list[soldier_id].initial_direction.y, soldier_list[soldier_id].initial_direction.x))
            soldier_list[soldier_id].direction = rotation_vector

            return position, rotation
        else
            -- soldier is in placeholder
            if army_list[army_id].is_sticky then
                soldier_list[soldier_id].status = SOLDIER_STATUS.INPLACE
            end

            local position = vmath.rotate(army_list[army_id].rotation, soldier_list[soldier_id].position) + army_list[army_id].center_position

            local rotated_initial_direction = vmath.rotate(army_list[army_id].rotation, soldier_list[soldier_id].initial_direction)
            local rotation_vector = vmath.lerp(0.2 * speed, soldier_list[soldier_id].direction, rotated_initial_direction)
            local rotation = vmath.quat_rotation_z(atan2(rotation_vector.y, rotation_vector.x) - atan2(soldier_list[soldier_id].initial_direction.y, soldier_list[soldier_id].initial_direction.x))
            soldier_list[soldier_id].direction = rotation_vector

            debug_mark_soldier(position, soldier_id)
            return position, rotation
        end
    end
end

return M