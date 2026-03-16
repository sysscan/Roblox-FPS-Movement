-- Central state bag for the movement system.
-- MovementClient reads and writes these fields each frame.
-- Call reset() on respawn to zero everything out.

local MovementState = {}

export type MoveState = {
	sprinting: boolean,
	crouching: boolean,
	sliding: boolean,
	slideEnd: number,              -- timestamp when the current slide expires
	lastSlideTime: number,         -- last slide start, used for cooldown checks
	slideDirection: (Vector3 | nil),
	sprintStamina: number,
	lastStaminaUse: number,        -- tracks regen delay
	tacSprinting: boolean,
	tacSprintStamina: number,
	lastTacSprintEnd: number,      -- tracks tac sprint cooldown and regen delay
	jumping: boolean,
	airborne: boolean,
	airborneStartTime: number,
	lastLandTime: number,
	landingPenalty: number,        -- 0..1 speed multiplier that decays after landing
	fallStartY: number,           -- Y position when the player left the ground
	slideVelocity: number,        -- entry speed of the current slide
	slideCancelTime: number,      -- set on cancel, drives the brief speed boost window
}

export type MovementConfig = {
	-- core speeds
	WalkSpeed: number,
	SprintSpeed: number,
	CrouchSpeed: number,
	SlideSpeed: number,

	-- slide tuning
	SlideDuration: number?,
	SlideMaxDuration: number?,
	SlideCooldown: number?,
	SlideStaminaCost: number?,
	SlideSpeedMax: number?,
	SlideCancelBoostDuration: number?,
	SlideCancelBoostMul: number?,

	-- aiming
	AimSpeedMul: number?,

	-- sprint stamina
	SprintStaminaMax: number?,
	SprintDrainRate: number?,
	SprintRegenRate: number?,
	StaminaRegenDelay: number?,

	-- tac sprint stamina (separate pool)
	TacSprintSpeed: number?,
	TacSprintDrainRate: number?,
	TacSprintStaminaMax: number?,
	TacSprintRegenRate: number?,
	TacSprintRegenDelay: number?,
	TacSprintCooldown: number?,

	-- air movement
	AirSpeedMul: number?,
	AirControlFactor: number?,
	AirAccelRate: number?,

	-- landing penalties
	LandingPenaltyLight: number?,
	LandingPenaltyHeavy: number?,
	LandingPenaltyDecay: number?,
	LandingHeightThreshold: number?,

	JumpHeight: number?,
}

-- Creates a fresh state with stamina pools filled to max.
function MovementState.create(defaultMovement: MovementConfig)
	local moveState: MoveState = {
		sprinting = false,
		crouching = false,
		sliding = false,
		slideEnd = 0,
		lastSlideTime = 0,
		slideDirection = nil,
		sprintStamina = defaultMovement.SprintStaminaMax or 100,
		lastStaminaUse = 0,
		tacSprinting = false,
		tacSprintStamina = defaultMovement.TacSprintStaminaMax or 100,
		lastTacSprintEnd = 0,
		jumping = false,
		airborne = false,
		airborneStartTime = 0,
		lastLandTime = 0,
		landingPenalty = 0,
		fallStartY = 0,
		slideVelocity = 0,
		slideCancelTime = 0,
	}

	return {
		moveState = moveState,
		reset = function()
			moveState.sprinting = false
			moveState.crouching = false
			moveState.sliding = false
			moveState.slideDirection = nil
			moveState.sprintStamina = defaultMovement.SprintStaminaMax or 100
			moveState.lastStaminaUse = 0
			moveState.tacSprinting = false
			moveState.tacSprintStamina = defaultMovement.TacSprintStaminaMax or 100
			moveState.lastTacSprintEnd = 0
			moveState.jumping = false
			moveState.airborne = false
			moveState.landingPenalty = 0
			moveState.slideVelocity = 0
			moveState.slideCancelTime = 0
		end,
	}
end

return MovementState
