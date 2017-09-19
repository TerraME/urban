
--@example Relationship between mean income and density gradient and residential area.

import("urban")
local dataFigA = {}
local dataFigB = {}
local ginis = {"gini01", "gini03", "gini05"}
local stdIncomes = {300, 500, 800}

sessionInfo().graphics = false
for i = 1, #ginis do
	local rowFigA = {}
	local rowFigB = {}
	for meanIncome = 700, 1700, 100 do
		model = UrbanSprawl{meanIncome = meanIncome, stdIncome = stdIncomes[i]}
		model:run()
		rowFigA[meanIncome] = mean(model:density())
		rowFigB[meanIncome] = model:residentialArea()
	end
	dataFigA[ginis[i]] = rowFigA
	dataFigB[ginis[i]] = rowFigB
end
sessionInfo().graphics = true

local gini01 = {}
local gini03 = {}
local gini05 = {}
local meanIncomes = {}

for meanIncome = 700, 1700, 100 do
	table.insert(gini01, dataFigA.gini01[meanIncome])
	table.insert(gini03, dataFigA.gini03[meanIncome])
	table.insert(gini05, dataFigA.gini05[meanIncome])
	table.insert(meanIncomes, meanIncome)
end

local df1 = DataFrame{
	gini01 = gini01,
	gini03 = gini03,
	gini05 = gini05,
	meanIncomes = meanIncomes
}
Chart{
	target = df1,
	select = {"gini01", "gini03", "gini05"},
	xAxis = "meanIncomes",
	yLabel = "Density gradient"
}

gini01 = {}
gini03 = {}
gini05 = {}
for meanIncome = 700, 1700, 100 do
	table.insert(gini01, dataFigB.gini01[meanIncome])
	table.insert(gini03, dataFigB.gini03[meanIncome])
	table.insert(gini05, dataFigB.gini05[meanIncome])
end

local df2 = DataFrame{
	gini01 = gini01,
	gini03 = gini03,
	gini05 = gini05,
	meanIncomes = meanIncomes
}
Chart{
	target = df2,
	select = {"gini01", "gini03", "gini05"},
	xAxis = "meanIncomes",
	yLabel = "Residential area"
}
