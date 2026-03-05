local MovementState = {}

export type MoveState = {
	sprinting: boolean,
	crouching: boolean,
	sliding: boolean,
	slideEnd: number,
	lastSlideTime: number,
	slideDirection: (Vector3 | nil),
	sprintStamina: number,
	lastStaminaUse: number,
	tacSprinting: boolean,
	tacSprintStamina: number,
	lastTacSprintEnd: number,
	jumping: boolean,
	airborne: boolean,
	airborneStartTime: number,
	lastLandTime: number,
	landingPenalty: number,
	fallStartY: number,
	slideVelocity: number,
	slideCancelTime: number,
}

export type MovementConfig = {
	WalkSpeed: number,
	SprintSpeed: number,
	CrouchSpeed: number,
	SlideSpeed: number,
	SlideDuration: number?,
	SlideMaxDuration: number?,
	SlideCooldown: number?,
	SlideStaminaCost: number?,
	SlideSpeedMax: number?,
	SlideCancelBoostDuration: number?,
	SlideCancelBoostMul: number?,
	AimSpeedMul: number?,
	SprintStaminaMax: number?,
	SprintDrainRate: number?,
	SprintRegenRate: number?,
	StaminaRegenDelay: number?,
	TacSprintSpeed: number?,
	TacSprintDrainRate: number?,
	TacSprintStaminaMax: number?,
	TacSprintRegenRate: number?,
	TacSprintRegenDelay: number?,
	TacSprintCooldown: number?,
	AirSpeedMul: number?,
	AirControlFactor: number?,
	AirAccelRate: number?,
	LandingPenaltyLight: number?,
	LandingPenaltyHeavy: number?,
	LandingPenaltyDecay: number?,
	LandingHeightThreshold: number?,
	JumpHeight: number?,
}

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
