-- Test file for UrbanSprawl.lua
-- Author: Pedro R. Andrade and Washington Franca

return{
	UrbanSprawl = function(unitTest)
		local model = UrbanSprawl{}

		model:run()
		unitTest:assertSnapshot(model.map, "UrbanSprawl.png", 0.05)
	end,
}

