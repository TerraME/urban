-- Test file for Resolution.lua
-- Author: Pedro R. Andrade and Washington Franca

return{
	Resolution = function(unitTest)
		local model = Resolution{finalTime = 5, strategy = decideBoth, quantity = 300, cityDimension = 15}
		model:run()
		unitTest:assertSnapshot(model.mapHistogram, "ResolutionHistogram.png", 0.05)
		unitTest:assertSnapshot(model.mapTotalHistogram, "ResolutionTotalHistogram.png", 0.05)
	end,
}
