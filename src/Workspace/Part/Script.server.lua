local touched = false
script.Parent.Touched:Connect(function(p)
	if touched then return end
	touched = true
	
	local w = Instance.new("WeldConstraint")
	w.Part0 = script.Parent
	w.Part1 = p
	
	script.Parent.Massless = false
	w.Parent = script.Parent
	script.Parent.Anchored = false
end)