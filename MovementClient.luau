local MovementClient = {}

export type MovementContext = {
	state: any,
	camera: Camera?,
	setWalkSpeed: (speed: number) -> (),
	alive: boolean,
	canAim: boolean?,
	firing: boolean?,
	root: BasePart?,
	humanoid: Humanoid?,
	slideSound: Sound?,
	playSlideAnimation: (() -> ())?,
	stopSlideAnimation: (() -> ())?,
}

local function create(getActiveMovement: (ctx: MovementContext) -> any)
	return function(getCtx: () -> MovementContext)
		local function applyCurrentSpeed() end

		local function getCurrentWalkSpeed(): number
			local ctx = getCtx()
			local state = ctx.state
			local mov = getActiveMovement(ctx)
			local speed: number

			if state.sliding then
				return 0
			elseif state.crouching then
				speed = mov.CrouchSpeed
			elseif ctx.canAim then
				speed = mov.WalkSpeed * (mov.AimSpeedMul or 0.55)
			elseif state.tacSprinting then
				speed = mov.TacSprintSpeed or (mov.SprintSpeed * 1.18)
			elseif state.sprinting then
				speed = mov.SprintSpeed
			else
				speed = mov.WalkSpeed
			end

			if ctx.firing and mov.FiringSpeedMul then
				speed = speed * mov.FiringSpeedMul
			end
			if state.airborne then
				speed = speed * (mov.AirSpeedMul or 0.92)
			end
			if state.landingPenalty > 0 then
				speed = speed * (1 - state.landingPenalty)
			end
			if state.slideCancelTime > 0 then
				local elapsed = os.clock() - state.slideCancelTime
				local boostDuration = mov.SlideCancelBoostDuration or 0.15
				if elapsed < boostDuration then
					speed = speed * (mov.SlideCancelBoostMul or 1.1)
				else
					state.slideCancelTime = 0
				end
			end
			return speed
		end

		local function startSprint()
			local c = getCtx()
			local s = c.state
			if s.crouching or s.sliding or c.canAim or not c.alive then return end
			local mov = getActiveMovement(c)
			if s.sprintStamina <= 0 then return end
			s.sprinting = true
			s.tacSprinting = false
		end

		local function stopTacSprint()
			local s = getCtx().state
			if s.tacSprinting then
				s.tacSprinting = false
				s.lastTacSprintEnd = os.clock()
			end
		end

		local function startTacSprint()
			local c = getCtx()
			local s = c.state
			if s.crouching or s.sliding or c.canAim or not c.alive then return end
			if s.tacSprintStamina <= 0 then return end
			local mov = getActiveMovement(c)
			local cooldown = mov.TacSprintCooldown or 0.5
			if os.clock() - s.lastTacSprintEnd < cooldown then return end
			s.tacSprinting = true
			s.sprinting = true
		end

		local function stopSprint()
			local s = getCtx().state
			s.sprinting = false
			stopTacSprint()
			s.lastStaminaUse = os.clock()
			applyCurrentSpeed()
		end

		local function cancelSlide()
			local c = getCtx()
			local s = c.state
			if not s.sliding then return end
			s.sliding = false
			s.slideDirection = nil
			s.crouching = false
			s.sprinting = true
			s.slideCancelTime = os.clock()
			if c.stopSlideAnimation then c.stopSlideAnimation() end
			applyCurrentSpeed()
		end

		local function startCrouch()
			local c = getCtx()
			local s = c.state
			if not c.alive then return end
			if s.airborne then return end
			local mov = getActiveMovement(c)
			local slideCost = mov.SlideStaminaCost or 0
			local canSlide = (s.sprinting or s.tacSprinting)
				and os.clock() - s.lastSlideTime > (mov.SlideCooldown or 2.8)
				and s.sprintStamina >= slideCost

			if canSlide then
				local wasTacSprinting = s.tacSprinting
				s.sliding = true
				s.crouching = true
				s.tacSprinting = false

				local entrySpeed = wasTacSprinting and (mov.TacSprintSpeed or mov.SprintSpeed) or mov.SprintSpeed
				local maxSpeed = mov.TacSprintSpeed or mov.SprintSpeed
				local speedRatio = math.clamp(entrySpeed / maxSpeed, 0, 1)
				local minDur = mov.SlideDuration or 0.38
				local maxDur = mov.SlideMaxDuration or mov.SlideDuration or 1
				local duration = minDur + (maxDur - minDur) * speedRatio

				local baseSlideSpeed = mov.SlideSpeed * (wasTacSprinting and 1.15 or 1)
				local currentVel = c.root and c.root.AssemblyLinearVelocity or Vector3.zero
				local horizontalSpeed = Vector3.new(currentVel.X, 0, currentVel.Z).Magnitude
				s.slideVelocity = math.max(baseSlideSpeed, horizontalSpeed * 1.08)

				s.slideEnd = os.clock() + duration
				s.lastSlideTime = os.clock()
				s.slideCancelTime = 0

				local lookFlat = (c.camera and c.camera.CFrame.LookVector * Vector3.new(1, 0, 1)) or Vector3.new(0, 0, -1)
				s.slideDirection = lookFlat.Magnitude > 0.01 and lookFlat.Unit or Vector3.new(0, 0, -1)
				s.sprintStamina = math.max(0, s.sprintStamina - slideCost)
				s.lastStaminaUse = os.clock()

				if c.slideSound then
					c.slideSound.Parent = c.camera or game:GetService("Workspace").CurrentCamera
					c.slideSound:Play()
				end
				if c.playSlideAnimation then c.playSlideAnimation() end
				return
			end

			s.crouching = true
			s.sprinting = false
			s.tacSprinting = false
			applyCurrentSpeed()
		end

		local function stopCrouch()
			local c = getCtx()
			local s = c.state
			if s.sliding then
				cancelSlide()
				return
			end
			s.crouching = false
			s.sliding = false
			s.slideDirection = nil
			applyCurrentSpeed()
		end

		local function getSlideVelocity(): { Vector3, number }?
			local c = getCtx()
			local s = c.state
			if not s.sliding or not s.slideDirection then return nil end
			local mov = getActiveMovement(c)
			local slideStart = s.slideEnd - (mov.SlideMaxDuration or mov.SlideDuration or 1)
			local elapsed = os.clock() - slideStart
			local duration = s.slideEnd - slideStart
			local progress = math.clamp(elapsed / duration, 0, 1)
			local decel = progress ^ 2.8
			local speed = s.slideVelocity * (1 - decel) + mov.CrouchSpeed * decel
			speed = math.min(speed, mov.SlideSpeedMax or 32)
			return { s.slideDirection, speed }
		end

		local function updateSlideEnd()
			local c = getCtx()
			local s = c.state
			if s.sliding then
				applyCurrentSpeed()
				if os.clock() >= s.slideEnd then
					s.sliding = false
					s.slideDirection = nil
					s.crouching = true
					if c.stopSlideAnimation then c.stopSlideAnimation() end
					applyCurrentSpeed()
				end
			end
		end

		local function startJump()
			local c = getCtx()
			local s = c.state
			if not c.alive or s.airborne or s.sliding then return end
			local hum = c.humanoid
			if not hum then return end
			if s.crouching then
				s.crouching = false
				applyCurrentSpeed()
			end
			s.jumping = true
			s.airborne = true
			s.airborneStartTime = os.clock()
			s.fallStartY = (c.root and c.root.Position.Y) or 0
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		local function updateAirborneState()
			local c = getCtx()
			local s = c.state
			local hum = c.humanoid
			if not hum then return end
			local isOnGround = hum.FloorMaterial ~= Enum.Material.Air
			if s.airborne and isOnGround then
				local mov = getActiveMovement(c)
				local fallDist = s.fallStartY - (c.root and c.root.Position.Y or 0)
				fallDist = math.max(0, fallDist)
				local heavyThreshold = mov.LandingHeightThreshold or 10
				if fallDist > 2 then
					if fallDist > heavyThreshold then
						s.landingPenalty = mov.LandingPenaltyHeavy or 0.35
					else
						local ratio = math.clamp((fallDist - 2) / (heavyThreshold - 2), 0, 1)
						s.landingPenalty = ratio * (mov.LandingPenaltyLight or 0.15)
					end
				end
				s.airborne = false
				s.jumping = false
				s.lastLandTime = os.clock()
			elseif not s.airborne and not isOnGround then
				s.airborne = true
				s.airborneStartTime = os.clock()
				s.fallStartY = (c.root and c.root.Position.Y) or 0
			end
		end

		local function updateAirControl(dt: number)
			local c = getCtx()
			local s = c.state
			if not s.airborne or not c.root then return end
			local mov = getActiveMovement(c)
			local airControl = mov.AirControlFactor or 0.3
			local hum = c.humanoid
			if not hum then return end
			local wishDir = hum.MoveDirection
			if wishDir.Magnitude < 0.01 then return end
			local currentVel = c.root.AssemblyLinearVelocity
			local horizontalVel = Vector3.new(currentVel.X, 0, currentVel.Z)
			local targetVel = wishDir.Unit * math.max(horizontalVel.Magnitude, mov.WalkSpeed)
			local steer = (targetVel - horizontalVel) * airControl * dt * (mov.AirAccelRate or 6)
			local newHorizontal = horizontalVel + steer
			local maxAirSpeed = (mov.SprintSpeed or 16) * (mov.AirSpeedMul or 0.92)
			if newHorizontal.Magnitude > maxAirSpeed then
				newHorizontal = newHorizontal.Unit * maxAirSpeed
			end
			c.root.AssemblyLinearVelocity = Vector3.new(newHorizontal.X, currentVel.Y, newHorizontal.Z)
		end

		local function updateLandingPenalty(dt: number)
			local c = getCtx()
			local s = c.state
			if s.landingPenalty > 0 then
				local mov = getActiveMovement(c)
				local decay = (mov.LandingPenaltyDecay or 4) * dt
				s.landingPenalty = math.max(0, s.landingPenalty - decay)
			end
		end

		local function updateStamina(dt: number)
			local c = getCtx()
			local s = c.state
			local mov = getActiveMovement(c)
			if s.tacSprinting and c.alive then
				local drain = (mov.TacSprintDrainRate or 80) * dt
				s.tacSprintStamina = math.max(0, s.tacSprintStamina - drain)
				if s.tacSprintStamina <= 0 then stopTacSprint() end
			elseif c.alive then
				local regenDelay = mov.TacSprintRegenDelay or 1.5
				if os.clock() - s.lastTacSprintEnd >= regenDelay then
					local max = mov.TacSprintStaminaMax or 100
					s.tacSprintStamina = math.min(max, s.tacSprintStamina + (mov.TacSprintRegenRate or 15) * dt)
				end
			end
			if s.sprinting and c.alive then
				local drain = (mov.SprintDrainRate or 35) * dt
				s.sprintStamina = math.max(0, s.sprintStamina - drain)
				s.lastStaminaUse = os.clock()
				if s.sprintStamina <= 0 then
					s.sprinting = false
					s.tacSprinting = false
					applyCurrentSpeed()
				end
			elseif c.alive then
				local regenDelay = mov.StaminaRegenDelay or 0.5
				if os.clock() - s.lastStaminaUse >= regenDelay then
					local maxStam = mov.SprintStaminaMax or 100
					s.sprintStamina = math.min(maxStam, s.sprintStamina + (mov.SprintRegenRate or 25) * dt)
				end
			end
		end

		return {
			getCurrentWalkSpeed = getCurrentWalkSpeed,
			getSlideVelocity = getSlideVelocity,
			applyCurrentSpeed = applyCurrentSpeed,
			startSprint = startSprint,
			stopSprint = stopSprint,
			startTacSprint = startTacSprint,
			stopTacSprint = stopTacSprint,
			startCrouch = startCrouch,
			stopCrouch = stopCrouch,
			cancelSlide = cancelSlide,
			startJump = startJump,
			updateSlideEnd = updateSlideEnd,
			updateStamina = updateStamina,
			updateAirborneState = updateAirborneState,
			updateAirControl = updateAirControl,
			updateLandingPenalty = updateLandingPenalty,
		}
	end
end

MovementClient.create = create
return MovementClient
