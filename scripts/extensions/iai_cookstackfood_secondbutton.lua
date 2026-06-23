
local ImageButton = require("widgets/imagebutton")

AddClassPostConstruct("widgets/containerwidget", function(self)
	local old = self.Open
	self.Open = function(self, container, doer, ...)
		old(self, container, doer, ...)
		
		local widget = container.replica.container:GetWidget()
		if widget.buttoninfo_iai_cookstackfood ~= nil then
			self.button_iai_cookstackfood = self:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex", nil, nil, {1,1}, {0,0}))
			self.button_iai_cookstackfood.image:SetScale(1.07)
			self.button_iai_cookstackfood.text:SetPosition(2,-2)
			self.button_iai_cookstackfood:SetPosition(widget.buttoninfo_iai_cookstackfood.position)
			self.button_iai_cookstackfood:SetText(widget.buttoninfo_iai_cookstackfood.text)
			if widget.buttoninfo_iai_cookstackfood.fn ~= nil then
				self.button_iai_cookstackfood:SetOnClick(function()
					if doer ~= nil then
						if doer:HasTag("busy") then
							--Ignore button click when doer is busy
							return
						elseif doer.components.playercontroller ~= nil then
							local iscontrolsenabled, ishudblocking = doer.components.playercontroller:IsEnabled()
							if not (iscontrolsenabled or ishudblocking) then
								--Ignore button click when controls are disabled
								--but not just because of the HUD blocking input
								return
							end
						end
					end
					widget.buttoninfo_iai_cookstackfood.fn(container, doer)
				end)
			end
			self.button_iai_cookstackfood:SetFont(BUTTONFONT)
			self.button_iai_cookstackfood:SetDisabledFont(BUTTONFONT)
			self.button_iai_cookstackfood:SetTextSize(33)
			self.button_iai_cookstackfood.text:SetVAlign(ANCHOR_MIDDLE)
			self.button_iai_cookstackfood.text:SetColour(0,0,0,1)
			
			if TheInput:ControllerAttached() then
				self.button_iai_cookstackfood:Hide()
			end
			
			self.button_iai_cookstackfood.inst:ListenForEvent("continuefrompause", function()
				if TheInput:ControllerAttached() then
					self.button_iai_cookstackfood:Hide()
				else
					self.button_iai_cookstackfood:Show()
				end
			end, TheWorld)
			
			self:Refresh()
		end
	end
	
	local old = self.Close
	self.Close = function(self)
		if self.isopen then
			if self.button_iai_cookstackfood then
				self.button_iai_cookstackfood:Kill()
				self.button_iai_cookstackfood = nil
			end
		end
		
		old(self)
	end
end)
