
-- @example Average income per patch in one exemplary simulation run for mean income 1200 and Gini coefficient 0.3.
-- @image figure_02.bmp

import("urban")

scenario = UrbanSprawl{transportCost=50}

local map2 = Map{target = scenario.city, select = "meanIncome", color = {"black","yellow","white"}, slices=12, grid=true}
scenario.timer:add(Event{action=map2})

scenario:run()