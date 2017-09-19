-- Test file for Utils.lua
-- Author: Pedro R. Andrade and Washington Franca

return{
	sum = function(unitTest)
		local data = {1, 2, 3, 4, 5}
		unitTest:assertEquals(sum(data), 15)
	end,
	mean = function(unitTest)
		local data = {1, 2, 3, 4, 5}
		unitTest:assertEquals(mean(data), 3)
	end,
	min = function(unitTest)
		local data = {1, 2, 3, 4, 5}
		unitTest:assertEquals(min(data), 1)
	end,
	median = function(unitTest)
		local data = {1, 2, 3, 4, 5}
		unitTest:assertEquals(median(data), 3)
	end,
	percentile = function(unitTest)
		local data = {1, 2, 3, 4, 5}
		unitTest:assertEquals(percentile(data, 0.75), 4)
	end,
	percentileRank = function(unitTest)
		local data = {1, 2, 3, 4, 5}
		unitTest:assertEquals(percentileRank(data, 4), 0.75, 0.1)
	end,
	removeDuplicates = function(unitTest)
		local data = {1, 1, 1, 2, 2}
		local unique = removeDuplicates(data)
		unitTest:assertEquals(unique[1], 1)
		unitTest:assertEquals(unique[2], 2)
	end,
}
