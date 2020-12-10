local mean = function(t)
	local m = 0
	for _, v in pairs(t) do
		m = m + v
	end

	if #t == 0 then return 0 end

	return m/#t
end

local min = function(t)
	local m = math.huge
	for _, v in pairs(t) do
		m = math.min(m, v)
	end

	if #t == 0 then return 0 end

	return m
end

-- Get the median of a table.
local median = function( t )
  local temp={}

  -- deep copy table so that when we sort it, the original is unchanged
  -- also weed out any non numbers
  for _,v in pairs(t) do
    table.insert( temp, v )
  end

  table.sort( temp, function(x,y) return x<y end)

  -- If we have an even number of table elements or odd.
  if math.fmod(#temp,2) == 0 then
    -- return mean value of middle two elements
    return ( temp[#temp/2] + temp[(#temp/2)+1] ) / 2
  else
    -- return middle element
    return temp[math.ceil(#temp/2)]
  end
end

local files = filesByExtension("urban", "csv")
local incomeFiles = {}
forEachElement(files, function(_, file)
	local _, name = file:split()
	incomeFiles[name]=file
end)

--- A Model that describes the corelation between urban sprawl and income segregation.
-- @arg data.pop The initial population. The default value is 1000.
-- @arg data.cityDimension The city dimension. The default value is 25.
-- @arg data.initialRent The initial/minimum rent price per living unit. The default value is 10.
-- @arg data.initialArea The initial/maximum available living area per cell. The default value is 100.
-- @arg data.initialAvgGood The average composite goods in the model. The default value is 400.
-- @arg data.transportCost The transport cost per unit. The range of value is from 1 to 50. The default value is 10.
-- @arg data.alpha The preference parameter for disposable income in Cobb-Douglas production function. The preference parameter for amount of living area is 1-α. It must be a value between 0 and 1, with default 0.5.
-- @arg data.inequalityLevel The predefined income distributions according to the inequality level. It must be a value between "low", "medium" or "high", with default "high".
-- @arg data.movingDiscount The discount-rate to move to a new place. It must be a value between 0.1 and 1, with default 0.9.
-- @arg data.stress If this parameter is true, only households feeling stress will start to search for new places. Otherwise, all households will search for new places regardless their current state. The default value is true.
-- @arg data.senseRadius If this parameter is true, the sensing radius of households will be set proportionally to their income. The minimum radius will be 1 distant units. The default value is true.
-- @arg data.finalTime The final time of the simulation. The default value is 50.
-- @image UrbanSprawl.bmp
UrbanSprawl = Model{
	finalTime = 50,

	cityDimension = 25,
	pop = 1000,
	initialRent = 10,
	transportCost = Choice{min=1, max=50, default=10},
	initialArea = 100,
	initialAvgGood = 400,
	alpha = Choice{min=0, max=1, default=0.5},
	inequalityLevel = Choice{"high", "medium", "low"},
	stress = true,
	senseRadius=false,
	movingDiscount = Choice{min = 0.1, max = 1, default = 0.9},

	init=function(model)
		local incomeData = incomeFiles[model.inequalityLevel]:read()

		model.cell = Cell{
			avaiableArea=100,
			maximumArea = 100,
			rent = model.initialRent,
			rentCalculation = function(self)
				local totalArea = 0
				local avArea = 0
				forEachNeighbor(self, function(neigh)
					avArea = avArea + neigh.avaiableArea
					totalArea = totalArea + neigh.maximumArea
				end)
				local rentIndex = 0.3*((totalArea-avArea)/totalArea) + 0.7*((self.maximumArea-self.avaiableArea)/self.maximumArea)

				if rentIndex > 0.9 then
					return self.rent*1.1
				elseif rentIndex < 0.5 then
					return math.max(self.rent*0.9, model.initialRent)
				end

				return self.rent
			end,
			dist = function(self)
				return self:distance(model.city.CBD)
			end,
			transportCost = function(self)
				return self:dist() * model.transportCost
			end,
			incomeLevel = function(self)
				if self == model.city.CBD then
					return "cbd"
				end
				local m = self:meanIncome()
				if m == 0 then
					return "empty"
				elseif m > 1200 then
					return "rich"
				elseif m < 800 then
					return "poor"
				else
					return "middle"
				end
			end,
			meanIncome = function(self)
				local tIncome = {}
				forEachAgent(self, function(agent)
					table.insert(tIncome, agent.income)
				end)
				return mean(tIncome)
			end,
			execute = function(self)
				self.rent = self:rentCalculation()
			end
		}
		model.city = CellularSpace{
			xdim = model.cityDimension,
			instance = model.cell
		}
		model.city:createNeighborhood()
		model.city.CBD = model.city:get(round(model.cityDimension/2),round(model.cityDimension/2))

		model.realCity = Trajectory{
			target = model.city,
			select = function(cell) return cell ~= model.city.CBD end,
			greater = function(c1, c2) return c1.x < c2.x end,
		}

		model.agent = Agent{
			area = 0,
			utility = 0,
			requiredArea=10,
			homelessTime=0,

			init = function(self)
				self.income = tonumber(incomeData[tonumber(self.id)].x)
			end,
			isStressed = function(self)
				local selfSatisfaction = 0
				if self.income-model.society.minIncome ~= 0 then
					selfSatisfaction = (self.utility-model.society.minUtility)/(self.income-model.society.minIncome)
				end

				local overallSatisfaction = 0
				if model.society.medianIncome-model.society.minIncome ~= 0 then
					overallSatisfaction = (model.society.medianUtility-model.society.minUtility)/(model.society.medianIncome-model.society.minIncome)
				end

				return selfSatisfaction < overallSatisfaction
			end,
			sense = function(self)
				local candidates = {}
				for _=1, 10 do
					local cell = model.realCity:sample()
					local area = self:takenArea(cell)
					if cell == self:getCell() then
						area = self.area
					end
					local utility = self:utilityCalculation(cell, area)
					table.insert(candidates, {cell=cell, area=area, utility=utility})
				end

				table.sort(candidates, function(c1, c2) return c1.utility > c2.utility end)

				return candidates
			end,
			tryMove = function(self, options)
				for i=1, #options do
					local bestOption = options[i]
					if bestOption.utility*model.movingDiscount > self.utility then
						local oldCell = self:getCell()
						local newCell = bestOption.cell

						oldCell.avaiableArea = oldCell.avaiableArea + self.area
						self.area = bestOption.area
						newCell.avaiableArea = newCell.avaiableArea - self.area
						self:move(newCell)
						self:updateStates()
						return true
					end
				end
				return false
			end,
			execute = function(self)
				if model.timer:getTime() == 1 or self:isStressed() or not model.stress then
					model.society.needMove = model.society.needMove+1
					local options = self:sense()
					if self:tryMove(options) then
						model.society.actualMove = model.society.actualMove+1
					end
				end
			end,
			takenArea = function(self, cell)
				local area = (1-model.alpha)*((self.income - cell:transportCost())/cell.rent)
				if self.requiredArea >= area then
					area = math.min(self.requiredArea, cell.avaiableArea)
				elseif cell.avaiableArea < area then
					area = cell.avaiableArea
				end
				if area < self.requiredArea then
					area = 0
				end
				return area
			end,
			utilityCalculation = function(self, cell, area)
				local good = self:goodCalculation(cell, area)
				return math.pow(math.max(good, 0), model.alpha) * math.pow(math.max(area, 0), 1-model.alpha)
			end,
			goodCalculation = function(self, cell, area)
				return self.income - area*cell.rent - cell:transportCost()
			end,
			updateStates = function(self)
				self.utility = self:utilityCalculation(self:getCell(), self.area)
			end
		}
		model.society = Society{
			quantity = model.pop,
			instance = model.agent,
			actualMove = 0,
			needMove = 0,
			avgGood = model.initialAvgGood,

			updateSociety = function(self)
				local tIncome = {}
				local tUtility = {}
				forEachAgent(self, function(agent)
					table.insert(tIncome, agent.income)
					table.insert(tUtility, agent.utility)
				end)
				self.minIncome = min(tIncome)
				self.medianIncome = median(tIncome)
				self.minUtility = min(tUtility)
				self.medianUtility = median(tUtility)
			end,
			deads = function(self)
				return model.pop - #self
			end
		}
		model.group = Group{
			target=model.society,
			greater=function(a1, a2)
				return a1.income < a2.income
			end
		}

		model.env = Environment{model.city, model.society}
		model.env:createPlacement{max=math.ceil(model.pop/(model.cityDimension*model.cityDimension)+1)}

		model.map = Map{target = model.city, select = "incomeLevel", color = {"gray", "red", "blue","white","yellow"}, value = {"empty", "cbd", "poor", "middle", "rich"}, grid=true}

		model.timer = Timer{
			Event{action = function() model.society.actualMove=0;model.society.needMove=0; end, priority=1},
			Event{action = model.group, priority=2},
			Event{action = function() model.society:updateStates() end, priority=3},
			Event{action = model.realCity, priority = 3},
			Event{action = function() model.society:updateSociety() end, priority=4},

			Event{action=model.map}
		}
	end
}