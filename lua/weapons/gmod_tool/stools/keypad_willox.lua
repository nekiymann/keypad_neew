

if (SERVER) then
	CreateConVar('sbox_maxkeypads', 4)
end

TOOL.Category = "РП"
TOOL.Name = "Кейпад"
TOOL.Command = nil

TOOL.ClientConVar['weld'] = '1'
TOOL.ClientConVar['freeze'] = '1'

TOOL.ClientConVar['password'] = '1234'
TOOL.ClientConVar['secure'] = '0'

TOOL.ClientConVar['repeats_granted'] = '0'
TOOL.ClientConVar['repeats_denied'] = '0'

TOOL.ClientConVar['length_granted'] = '0.1'
TOOL.ClientConVar['length_denied'] = '0.1'

TOOL.ClientConVar['delay_granted'] = '0'
TOOL.ClientConVar['delay_denied'] = '0'

TOOL.ClientConVar['init_delay_granted'] = '0'
TOOL.ClientConVar['init_delay_denied'] = '0'

TOOL.ClientConVar['key_granted'] = '0'
TOOL.ClientConVar['key_denied'] = '0'

cleanup.Register("keypads")

if CLIENT then
	language.Add("tool.keypad_willox.name", "Кейпад")
	language.Add("tool.keypad_willox.0", "Кейпад")
	language.Add("tool.keypad_willox.desc", "Кейпад")

	language.Add("Undone_Keypad", "Отмена кейпада")
	language.Add("Cleanup_keypads", "Кейпады")
	language.Add("Cleaned_keypads", "Удалить все кейпады")

	language.Add("SBoxLimit_keypads", "Лимит!")
end

function TOOL:SetupKeypad(ent, pass)
	local data = {
		Password = pass,

		RepeatsGranted = self:GetClientNumber("repeats_granted"),
		RepeatsDenied = self:GetClientNumber("repeats_denied"),

		LengthGranted = self:GetClientNumber("length_granted"),
		LengthDenied = self:GetClientNumber("length_denied"),

		DelayGranted = self:GetClientNumber("delay_granted"),
		DelayDenied = self:GetClientNumber("delay_denied"),

		InitDelayGranted = self:GetClientNumber("init_delay_granted"),
		InitDelayDenied = self:GetClientNumber("init_delay_denied"),

		KeyGranted = self:GetClientNumber("key_granted"),
		KeyDenied = self:GetClientNumber("key_denied"),

		Secure = util.tobool(self:GetClientNumber("secure"))
	}

	ent:SetKeypadOwner(self:GetOwner())
	ent:SetData(data)
end

function TOOL:RightClick(tr)
	if not IsValid(tr.Entity) or tr.Entity:GetClass():lower() != "keypad" then return false end

	if CLIENT  then return true end

	local ply = self:GetOwner()
	local password = tonumber(ply:GetInfo("keypad_willox_password"))

	local spawn_pos = tr.HitPos
	local trace_ent = tr.Entity

	if password == nil or (string.len(tostring(password)) > 4) or (string.find(tostring(password), "0")) then
		ply:PrintMessage(3, "Неправильный пароль!")
		return false
	end
	if trace_ent:GetKeypadOwner() == ply then
		self:SetupKeypad(trace_ent, password)

		return true
	end
end

function TOOL:LeftClick(tr)
	if IsValid(tr.Entity) and tr.Entity:GetClass():lower() == "player" then return false end

	if CLIENT then return true end

	local ply = self:GetOwner()
	local password = self:GetClientNumber("password")

	local spawn_pos = tr.HitPos + tr.HitNormal
	local trace_ent = tr.Entity

	if password == nil or (string.len(tostring(password)) > 4) or (string.find(tostring(password), "0")) then
		ply:PrintMessage(3, "Неправильный пароль!")
		return false
	end

	if not self:GetWeapon():CheckLimit("keypads") then return false end

	local ent = ents.Create("keypad")
	ent:SetPos(spawn_pos)
	ent:SetAngles(tr.HitNormal:Angle())
	ent:Spawn()

	ent:SetPlayer(ply)

	local freeze = util.tobool(self:GetClientNumber("freeze"))
	local weld = util.tobool(self:GetClientNumber("weld"))

	if freeze or weld then
		local phys = ent:GetPhysicsObject() 

		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end

	if weld then
		local weld = constraint.Weld(ent, trace_ent, 0, 0, 0, true, false)
	end

	self:SetupKeypad(ent, password)

	undo.Create("Keypad")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCount("keypads", ent)
	ply:AddCleanup("keypads", ent)

	return true
end


if CLIENT then
	local function ResetSettings(ply)
		ply:ConCommand("keypad_willox_repeats_granted 0")
		ply:ConCommand("keypad_willox_repeats_denied 0")
		ply:ConCommand("keypad_willox_length_granted 0.1")
		ply:ConCommand("keypad_willox_length_denied 0.1")
		ply:ConCommand("keypad_willox_delay_granted 0")
		ply:ConCommand("keypad_willox_delay_denied 0")
		ply:ConCommand("keypad_willox_init_delay_granted 0")
		ply:ConCommand("keypad_willox_init_delay_denied 0")
	end

	concommand.Add("keypad_willox_reset", ResetSettings)

	function TOOL.BuildCPanel(CPanel)
		local r, l = CPanel:TextEntry("Пароль", "keypad_willox_password")
		r:SetTall(22)

		CPanel:ControlHelp("Максимум цифер: 4\nРазрешенные цифры: 1-9")

		CPanel:CheckBox("Безопасный режим", "keypad_willox_secure")
		CPanel:CheckBox("Сварка", "keypad_willox_weld")
		CPanel:CheckBox("Заморозка", "keypad_willox_freeze")

		local ctrl = vgui.Create("CtrlNumPad", CPanel)
			ctrl:SetConVar1("keypad_willox_key_granted")
			ctrl:SetConVar2("Keypad_willox_key_denied")
			ctrl:SetLabel1("Granted")
			ctrl:SetLabel2("Denied")
		CPanel:AddPanel(ctrl)

		local granted = vgui.Create("DForm")
			granted:SetName("Настройки Granted")

			granted:NumSlider("Длина:", "keypad_willox_length_granted", 0.1, 10, 2)
			granted:NumSlider("Задержка:", "keypad_willox_init_delay_granted", 0, 10, 2)
			granted:NumSlider("Дополнительная задержка:", "keypad_willox_delay_granted", 0, 10, 2)
			granted:NumSlider("Повторы:", "keypad_willox_repeats_granted", 0, 5, 0)
		CPanel:AddItem(granted)

		local denied = vgui.Create("DForm")
			denied:SetName("Настройки Denied")

				denied:NumSlider("Длина:", "keypad_willox_length_denied", 0.1, 10, 2)
				denied:NumSlider("Задержка:", "keypad_willox_init_delay_denied", 0, 10, 2)
				denied:NumSlider("Дополнительная задержка:", "keypad_willox_delay_denied", 0, 10, 2)
				denied:NumSlider("Повторы:", "keypad_willox_repeats_denied", 0, 5, 0)
		CPanel:AddItem(denied)

		CPanel:Button("Обнулить настройки", "keypad_willox_reset")

		CPanel:Help("")

		local faq = CPanel:Help("Информация")
			faq:SetFont("GModWorldtip")

		CPanel:Help("UrbanichkaRP")
	end
end



