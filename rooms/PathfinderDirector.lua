PathfinderDirector = Object:extend()

function PathfinderDirector:new()
    
end

function PathfinderDirector:update(dt)

end

function PathfinderDirector:getChart(chart)
    self.loadedChartDirector = require 'objects/charts/' .. chart .. '/chartDirector.lua'
    -- fetch beats per minute and seconds per beat
    self.bpm = self.loadedChart:getBPM()
    self.spb = 60 / bpm
    self.audio = self.loadedChart:getSong()
    
end

function PathfinderDirector:setObjects(chart)

end