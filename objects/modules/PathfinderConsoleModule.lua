PathfinderConsoleModule = Object:extend()

function PathfinderConsoleModule:new(console, y)
    self.console = console
    self.y = y

    self.console:addLine(':: booting pathfinder')

    gotoRoom('PathfinderConsole')
end

function PathfinderConsoleModule:update(dt)
    
end

function PathfinderConsoleModule:draw()
    
end
