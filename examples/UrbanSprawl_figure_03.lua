
--@example Relationship among urban sprawl indicators and segregation indicators.

import("urban")
local dataFigA = {}
local dataFigB = {}

sessionInfo().graphics = false
for meanIncome = 700, 1700, 100 do
	for stdIncome = 300, 800, 100 do
		model = UrbanSprawl{meanIncome = meanIncome, stdIncome = stdIncome}
		model:run()
		table.insert(dataFigA, {density = mean(model:density()), residentialArea = model:residentialArea()})
		table.insert(dataFigB, {nsi = model:nsi(), cgi = model:cgi()})
	end
end
sessionInfo().graphics = true

table.sort(dataFigA, function(v1, v2) return v1.residentialArea < v2.residentialArea end)
table.sort(dataFigB, function(v1, v2) return v1.nsi < v2.nsi end)

local densityGradients = {}
local residentialAreas = {}
local nsi = {}
local cgi = {}
for i=1, #dataFigA do
	table.insert(densityGradients, dataFigA[i].density)
	table.insert(residentialAreas, dataFigA[i].residentialArea)
	table.insert(nsi, dataFigB[i].nsi)
	table.insert(cgi, dataFigB[i].cgi)
end

local df1 = DataFrame{density = densityGradients, residentialArea = residentialAreas}
Chart{target = df1, select = "density", xAxis = "residentialArea", style = "dots", width = 4}

local df2 = DataFrame{cgi = cgi, nsi = nsi}
Chart{target = df2, select = "cgi", xAxis = "nsi", style = "dots", width = 4}
