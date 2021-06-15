PathfinderConsole = Object:extend()

function PathfinderConsole:new()
    self.timer = Tim()
    self.area = Area(self)

    self.main_canvas = love.graphics.newCanvas(gw, gh)
    self.final_canvas = love.graphics.newCanvas(gw, gh)
    self.temp_canvas = love.graphics.newCanvas(gw, gh)
    self.glitch_canvas = love.graphics.newCanvas(gw, gh)
    self.rgb_shift_mag = 0
    self.font = fonts.Anonymous_8
    self.arch = fonts.Arch_8

    self.lines = {}
    self.line_y = 8
    camera:lookAt(gw/2, gh/2)
    camera.scale = 1
    self.modules = {}

    self.glitches = {}

    in_pathfinder = true

    command_history_index = #command_history

    self:pathfinderIntro()

    input:unbindAll()
    input:bind('left', 'left')
    input:bind('right', 'right')
    input:bind('up', 'up')
    input:bind('down', 'down')
    input:bind('mouse1', 'left_click')
    input:bind('return', 'return')
    input:bind('backspace', 'backspace')
    input:bind('escape', 'escape')
    input:bind('dpleft', 'left')
    input:bind('dpright', 'right')
    input:bind('dpup', 'up')
    input:bind('dpdown', 'down')
    input:bind('fright', 'escape')
    input:bind('fdown', 'return')
    input:bind('fleft', 'return')
    input:bind('select', 'escape')
    input:bind('start', 'start')
    input:bind('tab', 'tab')

    save()
    fadeVolume('music', 1, 0.05)
    fadeVolume('game', 1, 0.0)

    self.timer:every(0.05, function()
        local r = 127 + love.math.random(-8, 8)
        table.insert(self.glitches, GlitchDisplacementC(love.math.random(0, gw), love.math.random(0, gh), love.math.random(16, 48), love.math.random(8, 16), {r, r, r}))
    end)

    self.timer:every({0.1, 0.2}, function() self.area:addGameObject('GlitchDisplacement') end)
end

function PathfinderConsole:update(dt)
    self.timer:update(dt)
    self.area:update(dt)

    for _, line in ipairs(self.lines) do line:update(dt) end
    for _, module in ipairs(self.modules) do module:update(dt) end
    for i = #self.glitches, 1, -1 do
        self.glitches[i]:update(dt)
        if self.glitches[i].dead then table.remove(self.glitches, i) end
    end

    if self.bytepath_main_active then
        if input:pressed('up') then
            self.bytepath_main_selection_index = self.bytepath_main_selection_index - 1
            if self.bytepath_main_selection_index == 0 then self.bytepath_main_selection_index = #self.bytepath_main_selection_widths end
            playMenuSwitch()
        end

        if input:pressed('down') then
            self.bytepath_main_selection_index = self.bytepath_main_selection_index + 1
            if self.bytepath_main_selection_index == 7 then self.bytepath_main_selection_index = 1 end
            playMenuSwitch()
        end

        if input:pressed('return') then
            self:rgbShift()
            self.bytepath_main = false
            local command = self.bytepath_main_texts[self.bytepath_main_selection_index]
            for i = 1, #command do
                local c = command:sub(i, i)
                self.timer:after(0.025*i, function() love.event.push('keypressed', c) end)
            end
            self.timer:after(0.025*(#command+1) + 0.25, function() 
                if self.input_line then 
                    self.input_line:enter() 
                    playKeystroke()
                    self:rgbShift()
                end 
            end)
        end

        if input:pressed('start') then
            self:rgbShift()
            local command = 'start'
            self:addToCommandHistory(command)
            for i = 1, #command do
                local c = command:sub(i, i)
                self.timer:after(0.025*i, function() love.event.push('keypressed', c) end)
            end
            self.timer:after(0.025*(#command+1) + 0.25, function() 
                if self.input_line then 
                    self.input_line:enter() 
                    playKeystroke()
                    self:rgbShift()
                end 
            end)
        end
    end
    if not self.bytepath_main then self.bytepath_main_active = false end
end

function PathfinderConsole:draw()
    love.graphics.setCanvas(self.glitch_canvas)
    love.graphics.clear()
        love.graphics.setColor(127, 127, 127)
        love.graphics.rectangle('fill', 0, 0, gw, gh)
        love.graphics.setColor(255, 255, 255)
        self.area:drawOnly({'glitch'})
    love.graphics.setCanvas()

    love.graphics.setCanvas(self.main_canvas)
    love.graphics.clear()
        camera:attach(0, 0, gw, gh)
        for _, line in ipairs(self.lines) do line:draw() end
        for _, module in ipairs(self.modules) do module:draw() end

        if self.bytepath_main_active then
            local width = self.bytepath_main_selection_widths[self.bytepath_main_selection_index]
            local r, g, b = unpack(hp_color)
            love.graphics.setColor(r, g, b, 128)
            local x_offset = self.font:getWidth('~ type ')
            love.graphics.rectangle('fill', 8 + x_offset - 2, self.bytepath_main_y + self.bytepath_main_selection_index*12 - 7, width + 4, self.font:getHeight())
            love.graphics.setColor(255, 255, 255, 255)
        end
        camera:detach()
    love.graphics.setCanvas()

    love.graphics.setCanvas(self.temp_canvas)
    love.graphics.clear()
        love.graphics.setColor(255, 255, 255)
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setShader(shaders.glitch)
        shaders.glitch:send('glitch_map', self.glitch_canvas)
        love.graphics.draw(self.main_canvas, 0, 0, 0, 1, 1)
        love.graphics.setShader()
  		love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()

    love.graphics.setCanvas(self.final_canvas)
    love.graphics.clear()
        love.graphics.setColor(255, 255, 255)
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setShader(shaders.rgb_shift)
        shaders.rgb_shift:send('amount', {random(-self.rgb_shift_mag, self.rgb_shift_mag)/gw, random(-self.rgb_shift_mag, self.rgb_shift_mag)/gh})
        love.graphics.draw(self.temp_canvas, 0, 0, 0, 1, 1)
        love.graphics.setShader()
  		love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()

    if not disable_expensive_shaders then
        love.graphics.setShader(shaders.distort)
        shaders.distort:send('time', time)
        shaders.distort:send('horizontal_fuzz', 0.2*(distortion/10))
        shaders.distort:send('rgb_offset', 0.2*(distortion/10))
    end
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.draw(self.final_canvas, 0, 0, 0, sx, sy)
    love.graphics.setBlendMode('alpha')
    love.graphics.setShader()
end

function PathfinderConsole:destroy()
    
end

function PathfinderConsole:addLine(after, text, duration, swaps)
    self.timer:after(after, function()
        if text ~= '' then playComputerLine() end
        if self.bytepath_main then 
            if text == '~ type @help# for help' then
                self.bytepath_main_y = self.line_y
            end
        end
        table.insert(self.lines, ConsoleLine(8, self.line_y, {text = text, duration = duration, swaps = swaps}))
        self.line_y = self.line_y + 12
        if self.line_y > gh then camera:lookAt(camera.x, camera.y + 12) end 
    end)
end

function PathfinderConsole:addInputLine(delay, text)
    self.timer:after(delay, function()
        self.input_line = PathfinderConsoleInputLine(8, self.line_y, {text = text, console = self})
        table.insert(self.lines, self.input_line)
        self.line_y = self.line_y + 12
        if self.line_y > gh then camera:lookAt(camera.x, camera.y + 12) end 
    end)
end

function PathfinderConsole:getRandomArchWord()
    local word = ''
    local random_letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWYXZ'
    for i = 1, love.math.random(1, 5) do 
        local r = love.math.random(1, #random_letters)
        word = word .. random_letters:utf8sub(r, r) 
    end
    return word
end

function PathfinderConsole:keypressed(key)
    if self.input_line and self:isConsoleCharacter(key) then 
        self.bytepath_main = false
        self.input_line:keypressed(key) 
    end
end

function PathfinderConsole:addToCommandHistory(command)
    table.insert(command_history, command)
    command_history_index = #command_history
end

function PathfinderConsole:isConsoleCharacter(key)
    local keys = {'space', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'}
    if fn.any(keys, key) then return true end
end

function PathfinderConsole:pathfinderMain(delay)
    local delay = delay or 0 
    local classes_string = ''
    for _, class in ipairs(classes) do
        if class_colors[class] == ammo_color then
            classes_string = classes_string .. '<' .. class .. '> - '
        elseif class_colors[class] == hp_color then
            classes_string = classes_string .. '@' .. class .. '# - '
        elseif class_colors[class] == boost_color then
            classes_string = classes_string .. '$' .. class .. '% - '
        elseif class_colors[class] == default_color then
            classes_string = classes_string .. class .. ' - '
        elseif class_colors[class] == skill_point_color then
            classes_string = classes_string .. ';' .. class .. ', - '
        end
    end

    self:addLine(delay + 0.02, ':: running ;PATHFINDER [path], in SAFE MODE')
    self:addLine(delay + 0.04, ':: ' .. os.date("%a %b %d ") .. tostring(tonumber(os.date("%Y"))+1000) .. os.date(" %X ") .. 'on ;VCON1,')
    self:addLine(delay + 0.06, '')
    self:addLine(delay + 0.08, 'Accessed PATHFINDER from terminal <' .. string.sub(id, 1, 8) .. '>')
    self:addLine(delay + 0.10, '')
    self:addLine(delay + 0.12, '')
    self:addLine(delay + 0.14, '')
    self:addLine(delay + 0.16, '~ type @connect# to begin PATHFINDER')
    self:addLine(delay + 0.18, '~ type @rewrite# to access previous PATHFINDER data')
    self:addLine(delay + 0.20, '~ type @help# to view all builtin commands')
    self:addLine(delay + 0.22, '~ type @credits# to view PATHFINDER credits')
    self:addLine(delay + 0.24, '~ type @return# to return to the BYTEPATH terminal')
    self:addLine(delay + 0.26, '~ type @shutdown# to terminate PATHFINDER')
    self:addLine(delay + 0.28, '')
    self:addInputLine(delay + 0.30, '[;root,]arch~ ')

    self.timer:after(delay, function()
        self.bytepath_main = true
        self.bytepath_main_active = false
        self.bytepath_main_selection_index = 1
        self.bytepath_main_texts = {'connect', 'rewrite', 'help', 'credits', 'return', 'shutdown'}
        self.bytepath_main_selection_widths = {self.font:getWidth('connect'), self.font:getWidth('rewrite'), self.font:getWidth('help'), self.font:getWidth('credits'), self.font:getWidth('return'), self.font:getWidth('shutdown')}
        if loop > 0 then self.bytepath_main_y = self.line_y + 13*12
        else self.bytepath_main_y = self.line_y + 13*12 - 12 end
        self.timer:after(0.38, function() self.bytepath_main_active = true end)
    end)
end

function PathfinderConsole:pathfinderMain2()
    local delay = delay or 0 
    local classes_string = ''
    for _, class in ipairs(classes) do
        if class_colors[class] == ammo_color then
            classes_string = classes_string .. '<' .. class .. '> - '
        elseif class_colors[class] == hp_color then
            classes_string = classes_string .. '@' .. class .. '# - '
        elseif class_colors[class] == boost_color then
            classes_string = classes_string .. '$' .. class .. '% - '
        elseif class_colors[class] == default_color then
            classes_string = classes_string .. class .. ' - '
        elseif class_colors[class] == skill_point_color then
            classes_string = classes_string .. ';' .. class .. ', - '
        end
    end

    self:addLine(delay + 0.02, ':: running ;PATHFINDER [path], in SAFE MODE')
    self:addLine(delay + 0.04, ':: ' .. os.date("%a %b %d ") .. tostring(tonumber(os.date("%Y"))+1000) .. os.date(" %X ") .. 'on ;VCON1,')
    self:addLine(delay + 0.06, '')
    self:addLine(delay + 0.08, 'Accessed PATHFINDER from terminal <' .. string.sub(id, 1, 8) .. '>')
    self:addLine(delay + 0.10, '')
    self:addLine(delay + 0.12, '')
    self:addLine(delay + 0.14, '')
    self:addLine(delay + 0.16, '~ type @connect# to begin PATHFINDER')
    self:addLine(delay + 0.18, '~ type @rewrite# to access previous PATHFINDER data')
    self:addLine(delay + 0.20, '~ type @help# to view all builtin commands')
    self:addLine(delay + 0.22, '~ type @credits# to view PATHFINDER credits')
    self:addLine(delay + 0.24, '~ type @return# to return to the BYTEPATH terminal')
    self:addLine(delay + 0.26, '~ type @shutdown# to terminate PATHFINDER')
    self:addLine(delay + 0.28, '')
    self:addInputLine(delay + 0.30, '[;root,]arch~ ')

    self.timer:after(delay, function()
        self.bytepath_main = true
        self.bytepath_main_active = false
        self.bytepath_main_selection_index = 1
        self.bytepath_main_texts = {'connect', 'rewrite', 'help', 'credits', 'return', 'shutdown'}
        self.bytepath_main_selection_widths = {self.font:getWidth('connect'), self.font:getWidth('rewrite'), self.font:getWidth('help'), self.font:getWidth('credits'), self.font:getWidth('return'), self.font:getWidth('shutdown')}
        if loop > 0 then self.bytepath_main_y = self.line_y + 13*12
        else self.bytepath_main_y = self.line_y + 13*12 - 12 end
        self.timer:after(0.38, function() self.bytepath_main_active = true end)
    end)
end

function PathfinderConsole:pathfinderIntro()
    delay = 1.50
    self:addLine(delay + 1.0, ':: requesting pathfinder access', 4, {{':: requesting pathfinder access', '<access granted>'}})
    self:addLine(delay + 2.0, '...', 5, {{'...', ':: retrieved modules'}})
    self:addLine(delay + 3.0, '...', 4.33, {{'...', ':: extracted packages'}})
    self:addLine(delay + 4.0, '...', 3.78, {{'...', ':: compiled resources'}})
    self:addLine(delay + 7.98, ':: finalizing build')
    self:addLine(delay + 9, 'Welcome to ;PATHFINDER,')
    self:pathfinderMain(delay + 11)
end

function PathfinderConsole:rgbShift()
    self.rgb_shift_mag = random(1, 1.5)
    self.timer:tween(0.1, self, {rgb_shift_mag = 0}, 'in-out-cubic', 'rgb_shift')
end

function PathfinderConsole:glitch(x, y)
    for i = 1, 6 do
        self.timer:after(0.1*i, function()
            self.area:addGameObject('GlitchDisplacement', x + random(-32, 32), y + random(-32, 32)) 
        end)
    end
end

function PathfinderConsole:glitchError()
    for i = 1, 10 do self.timer:after(0.1*i, function() self.area:addGameObject('GlitchDisplacement') end) end
    self.rgb_shift_mag = random(4, 8)
    self.timer:tween(1, self, {rgb_shift_mag = 0}, 'in-out-cubic', 'rgb_shift')
end
