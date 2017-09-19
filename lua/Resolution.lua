local function histogram(model)
	local groups = model.society:split("class")
	local counter = DataFrame{c1 = {} , c2 = {}, c3 = {}, c4 = {}}
	local max = 1

	forEachElement(groups, function(_, group)
		forEachAgent(group, function(agent)
			local dist = math.ceil(agent:workdistance())

			if dist > max then
				max = dist
			end
		end)
	end)

	forEachElement(groups, function(idx, group)
		local size = #group

		for i = 0, max do
			counter[i][idx] = 0
		end

		forEachAgent(group, function(agent)
			local dist = math.ceil(agent:workdistance())
			counter[idx][dist] = counter[idx][dist] + 1 / size
		end)
	end)

	return Chart{
		target = counter,
		xLabel = "Distance",
		yLabel = "Proportion",
		title = model:title()
	}
end

local function totalHistogram(model)
	local society = model.society
	local  counter = DataFrame{total = {}}
	local max = 1

	forEachAgent(society, function(agent)
		local dist = math.ceil(agent:workdistance())

		if dist > max then
			max = dist
		end
	end)

	for i = 0, max do
		counter.total[i] = 0
	end

	forEachAgent(society, function(agent)
		local dist = math.ceil(agent:workdistance())
		counter.total[dist] = counter.total[dist] + 1
	end)

	return Chart{
		target = counter,
		xLabel = "Distance",
		yLabel = "Proportion",
		title = model:title()
	}
end

local function counter(class, placement)
	return function(cell)
		local count = 0

		forEachAgent(cell, placement, function(agent)
			if agent.class == class then
				count = count + 1
			end
		end)

		return count
	end
end

--- A Model that describes the relation between tranport and segregation.
-- @arg data.quantity The quantity of agents on the city. The default value is 3200.
-- @arg data.cityDimension The city dimension. The default value is 20.
-- @arg data.strategy The decision-making strategy for moving to another place. Agents can decide between living near the workplace or living close to neighbors of the same class. The default value is "decideWorkplace".
-- @arg data.c1 The parameter that represents the amount of richest class. The default value is 0.1.
-- @arg data.c2 The parameter that represents the amount of rich class. The default value is 0.2.
-- @arg data.c3 The parameter that represents the amount of poor class. The default value is 0.3.
-- @arg data.c4 The parameter that represents the amount of poorest class. The default value is 0.4.
-- @arg data.finalTime The final time of the simulation. The default value is 300.
Resolution = Model{
	c1 = 0.1,
	c2 = 0.2,
	c3 = 0.3,
	c4 = 0.4,
	strategy = Choice{"decideWorkplace", "decideNeighborhood", "decideBoth"},
	quantity = 3200,
	cityDimension = 20,
	finalTime = 300,
	init = function(model)
		model.cell = Cell{
			c1_house = counter("c1", "house"), c1_workplace = counter("c1", "workplace"),
			c2_house = counter("c2", "house"), c2_workplace = counter("c2", "workplace"),
			c3_house = counter("c3", "house"), c3_workplace = counter("c3", "workplace"),
			c4_house = counter("c4", "house"), c4_workplace = counter("c4", "workplace")
		}

		local priority = {
			c1 = 4,
			c2 = 3,
			c3 = 2,
			c4 = 1
		}

		local groupedWork = {
			c1 = true,
			c2 = false,
			c3 = true,
			c4 = false
		}

		model.citizen = Agent{
			class = Random{c1 = model.c1, c2 = model.c2, c3 = model.c3, c4 = model.c4},
			workdistance = function(self)
				return self:getCell("house"):distance(self:getCell("workplace"))
			end,
			decideBoth = function(self, candidate, newGrade, currentGrade)
				return newGrade > currentGrade and self:workdistance() > candidate:distance(self:getCell("workplace"))
			end,
			decideWorkplace = function(self, candidate)
				return self:workdistance() > candidate:distance(self:getCell("workplace"))
			end,
			decideNeighborhood = function(_, _, newGrade, currentGrade)
				return newGrade > currentGrade
			end,
			priority = function(self)
				return priority[self.class]
			end,
			workGrade = function(self, workplace)
				local count = 0
				local quantity = 0

				forEachNeighbor(workplace, "workplace", function(neigh)
					forEachAgent(neigh, "workplace", function(agent)
						quantity = quantity + 1

						if agent.class == self.class then
							count = count + 1
						end
					end)
				end)

				if groupedWork[self.class] then
					return count / quantity
				else
					return (quantity - count) / quantity
				end
			end,
			houseGrade = function(self, house)
				local count = 0
				local quantity = 0

				forEachNeighbor(house, "house", function(cell)
					forEachAgent(cell, "house", function(agent)
						quantity = quantity + 1

						if agent.class == self.class then
							count = count + 1
						end
					end)
				end)

				return count / quantity
			end,
			updateHouse = function(self)
				local candidate = model.city:sample()
				local current = self:getCell("house")

				local currentGrade = self:houseGrade(current)
				local newGrade     = self:houseGrade(candidate)

				if self:decision(candidate, newGrade, currentGrade) then
					local agents = candidate:getAgents("house")
					local exchange

					forEachElement(agents, function(_, agent)
						if self:priority() > agent:priority() then
							exchange = agent
							return false
						end
					end)

					if exchange then
						self:move(candidate, "house")
						exchange:move(current, "house")
					end
				end
			end,
			updateWork = function(self)
				local candidate = model.city:sample()
				local current = self:getCell("workplace")

				local currentGrade = self:workGrade(current)
				local newGrade     = self:workGrade(candidate)

				if self:decision(candidate, newGrade, currentGrade) then
					local exchange

					forEachAgent(candidate, "workplace", function(agent)
						if self:priority() > agent:priority() then
							exchange = agent
							return false
						end
					end)

					if exchange then
						self:move(candidate, "workplace")
						exchange:move(current, "workplace")
					end
				end
			end,
			execute = function(self)
				if Random():number() > 0.8 then
					self:updateWork()
				elseif Random():number() > 0.8 then
					self:updateHouse()
				end
			end
		}

		model.citizen.decision = model.citizen[model.strategy]

		model.city = CellularSpace{
			xdim = model.cityDimension,
			instance = model.cell
		}

		model.city:createNeighborhood{
			name = "house",
			self = true
		}

		model.city:createNeighborhood{
			name = "workplace",
			strategy = "mxn",
			m = 5,
		}

		model.society = Society{
			instance = model.citizen,
			quantity = model.quantity
		}

		model.max = 8

		model.env = Environment{model.city, model.society}
		model.env:createPlacement{max = model.max, name = "house"}
		model.env:createPlacement{max = model.max, name = "workplace"}

		model.maph1 = Map{target = model.city, select = "c1_house", min = 0, max = model.max, slices = 11, color = "Blues"}
		model.maph2 = Map{target = model.city, select = "c2_house", min = 0, max = model.max, slices = 11, color = "Blues"}
		model.maph3 = Map{target = model.city, select = "c3_house", min = 0, max = model.max, slices = 11, color = "Blues"}
		model.maph4 = Map{target = model.city, select = "c4_house", min = 0, max = model.max, slices = 11, color = "Blues"}

		model.mapw1 = Map{target = model.city, select = "c1_workplace", min = 0, max = model.max, slices = 11, color = "Reds"}
		model.mapw2 = Map{target = model.city, select = "c2_workplace", min = 0, max = model.max, slices = 11, color = "Reds"}
		model.mapw3 = Map{target = model.city, select = "c3_workplace", min = 0, max = model.max, slices = 11, color = "Reds"}
		model.mapw4 = Map{target = model.city, select = "c4_workplace", min = 0, max = model.max, slices = 11, color = "Reds"}

		model.timer = Timer{
			Event{action = model.society},
			Event{action = model.maph1}, Event{action = model.maph2}, Event{action = model.maph3}, Event{action = model.maph4},
			Event{action = model.mapw1}, Event{action = model.mapw2}, Event{action = model.mapw3}, Event{action = model.mapw4},
		}

		model.mapHistogram = histogram(model)
		model.mapTotalHistogram = totalHistogram(model)
	end
}