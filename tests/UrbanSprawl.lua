-- Test file for UrbanSprawl.lua
-- Author: Pedro R. Andrade and Washington Franca

return{
	UrbanSprawl = function(unitTest)
		local model = UrbanSprawl{finalTime = 10, transportCost = 50}

		model:run()
		unitTest:assertSnapshot(model.map, "UrbanSprawl.png", 0.05)

		local densityChart = Chart{
			target = model:densityGradient(),
			select = "density",
			xAxis = "distanceToCBD",
			style = "dots",
			width = 4
		}
		unitTest:assertSnapshot(densityChart, "DensityChart.png", 0.05)

		unitTest:assertEquals(model:cgi(), 0.069, 0.005)
		unitTest:assertEquals(model:nsi(), 0.67, 0.05)
		unitTest:assertEquals(model:residentialArea(), 749.2, 0.5)
	end,
}
