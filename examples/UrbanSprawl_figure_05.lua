
--@example Relationship between Gini’s coefficient and income segregation indicators.

import("urban")
local dataFigA = {}
local dataFigB = {}
local ginis = {0.1, 0.2, 0.3, 0.4, 0.5}
local stdIncomes = {300, 400, 500, 600, 700, 800}

sessionInfo().graphics = false
for meanIncome = 900, 1500, 300 do
	local rowFigA = {}
	local rowFigB = {}
	for i = 1, #ginis do
		model = UrbanSprawl{meanIncome = meanIncome, stdIncome = stdIncomes[i]}
		model:run()
		rowFigA[ginis[i]] = model:nsi()
		rowFigB[ginis[i]] = model:cgi()
	end
	dataFigA[meanIncome] = rowFigA
	dataFigB[meanIncome] = rowFigB
end
sessionInfo().graphics = true

local mean900 = {}
local mean1200 = {}
local mean1500 = {}

for _, gini in pairs(ginis) do
	table.insert(mean900, dataFigA[900][gini])
	table.insert(mean1200, dataFigA[1200][gini])
	table.insert(mean1500, dataFigA[1500][gini])
end

local df1 = DataFrame{
	mean900 = mean900,
	mean1200 = mean1200,
	mean1500 = mean1500,
	ginis = ginis
}
Chart{
	target = df1,
	select = {"mean900", "mean1200", "mean1500"},
	xAxis = "ginis",
	yLabel = "NSI"
}

mean900 = {}
mean1200 = {}
mean1500 = {}
for _, gini in pairs(ginis) do
	table.insert(mean900, dataFigB[900][gini])
	table.insert(mean1200, dataFigB[1200][gini])
	table.insert(mean1500, dataFigB[1500][gini])
end

local df2 = DataFrame{
	mean900 = mean900,
	mean1200 = mean1200,
	mean1500 = mean1500,
	giniCoefficient = ginis
}
Chart{
	target = df2,
	select = {"mean900", "mean1200", "mean1500"},
	xAxis = "giniCoefficient",
	yLabel = "CGI"
}
