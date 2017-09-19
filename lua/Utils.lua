-- @header A file containing useful functions for the Urban Sprawl model.

--- Return the summation of all numbers from a given table.
-- @arg t A table of numbers t.
-- @usage import("urban")
-- sum({1, 2, 3, 4, 5})
function sum(t)
	local m = 0
	for _, v in pairs(t) do
		if type(v) == "number" then
			m = m + v
		end
	end
	return m
end

--- Return the mean of all numbers from a given table.
-- @arg t A table of numbers t.
-- @usage import("urban")
-- mean({1, 2, 3, 4, 5})
function mean(t)
	if #t == 0 then return 0 end
	return sum(t) / #t
end

--- Return the smallest number from a given table.
-- @arg t A table of numbers t.
-- @usage import("urban")
-- min({1, 2, 3, 4, 5})
function min(t)
	local m = math.huge
	for _, v in pairs(t) do
		m = math.min(m, v)
	end
	return m
end

--- Return the median of all numbers from a given table.
-- @arg t A table of numbers t.
-- @usage import("urban")
-- median({1, 2, 3, 4, 5})
function median(t)
  local temp={}
  for _, v in pairs(t) do
    table.insert(temp, v)
  end
  table.sort(temp, function(x,y) return x < y end)
  if math.fmod(#temp, 2) == 0 then
    return (temp[#temp / 2] + temp[(#temp / 2) + 1] )/2
  else
    return temp[math.ceil(#temp / 2)]
  end
end

--- Return a table containing only unique values.
-- @arg t A table of elements t.
-- @usage import("urban")
-- removeDuplicates({1, 1, 3, 4, 5})
function removeDuplicates(t)
	local hash = {}
	local unique = {}
	for _, v in pairs(t) do
		if not hash[v] then
			hash[v] = true
			table.insert(unique, v)
		end
	end
	return unique
end

--- Return the qth percentile from a given table.
-- @arg t A table of elements t.
-- @arg q Percentile to compute.
-- @arg sorted A boolean value defining whether the table is already sorted. Default is false.
-- @usage import("urban")
-- percentile({1, 2, 3, 4, 5}, 0.5, false)
function percentile(t, q, sorted)
	if not sorted then
		local tCopy = {}
		for _,v in pairs(t) do
			table.insert(tCopy, v)
		end
		table.sort(tCopy)
		t = tCopy
	end

	return t[math.ceil(q * #t)]
end

--- Return the quantity of scores that are below than a given score from a given table.
-- @arg t A table of scores t.
-- @arg score A score that is compared to the elements in t.
-- @usage import("urban")
-- percentileRank({1, 2, 3, 4, 5}, 4)
function percentileRank(t, score)
	local n = #t
	local s = 0
	local l = 0
	for _, v in pairs(t) do
		if v < score then
			l = l + 1
		elseif v == score then
			s = s + 1
		end
	end
	return (l+s*0.5)/n
end
