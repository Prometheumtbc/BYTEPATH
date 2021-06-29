local bpm = 120
local length = 128
local song = "../chart_name.ogg"

function prepareChart()
    require 'chart.csv'
end

function getBPM()
    return bpm
end

function getSong()
    return song
end