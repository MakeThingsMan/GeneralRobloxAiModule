-- in studio place this into a module script and parent it to the generalized data controller 

local module = {}

function module.convert(object)
	local temp = game:GetService("HttpService"):JSONEncode(object)
	return temp
end

function module.unconvert(object)
	local temp = nil
	if object ~= nil then 
		temp = game:GetService("HttpService"):JSONDecode(object)
	end
	return temp
end

function module.convertE(object)
	local temp = {}
	for i, v in pairs(object) do
		if v.Name == nil then
			temp[i] = v
		else
			temp[i] = v.Name
		end
	end
	return temp
end

function module.unconvertE(object)
	local temp = {}
	for i, v in pairs(object)  do
		temp[i] = game.ReplicatedStorage:FindFirstChild(v,true)
	end
	return temp
end

return module