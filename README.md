# Roblox FPS Movement

Movement system with sprint, tactical sprint, crouch, slide, stamina, air control, and landing penalty.

## Installation

Copy `MovementClient.luau` and `MovementState.luau` into your project.

## Usage

```lua
local MovementClient = require(path.to.MovementClient)
local MovementState = require(path.to.MovementState)

local defaultMovement = {
    WalkSpeed = 12,
    SprintSpeed = 16,
    CrouchSpeed = 6,
    SlideSpeed = 24,
    SlideDuration = 0.38,
    SlideMaxDuration = 1,
    SlideCooldown = 2.8,
    SlideStaminaCost = 40,
    SprintStaminaMax = 100,
    SprintDrainRate = 35,
    SprintRegenRate = 25,
    TacSprintSpeed = 19,
    TacSprintStaminaMax = 100,
    TacSprintDrainRate = 80,
    TacSprintRegenRate = 15,
    TacSprintCooldown = 0.5,
    AirSpeedMul = 0.92,
    AirControlFactor = 0.3,
    LandingPenaltyLight = 0.15,
    LandingPenaltyHeavy = 0.35,
}

local state = MovementState.create(defaultMovement)
local getCtx = function()
    return {
        state = state.moveState,
        camera = workspace.CurrentCamera,
        setWalkSpeed = function(s) humanoid.WalkSpeed = s end,
        alive = true,
        canAim = false,
        firing = false,
        root = character:FindFirstChild("HumanoidRootPart"),
        humanoid = character:FindFirstChildOfClass("Humanoid"),
    }
end

local movementApi = MovementClient.create(function(ctx) return defaultMovement end)(getCtx)
```

### Slide Physics

Apply slide velocity each frame when sliding. Reduce root friction during slide (e.g. `CustomPhysicalProperties` with Friction 0.04).

```lua
local slideData = movementApi.getSlideVelocity()
if slideData then
    local dir, speed = slideData[1], slideData[2]
    root.AssemblyLinearVelocity = Vector3.new((dir * speed).X, currentVel.Y, (dir * speed).Z)
end
```

### Per-Weapon Movement

Pass a function that returns different configs by weapon:

```lua
MovementClient.create(function(ctx)
    return weaponConfigs[ctx.state.activeWeapon].Movement or defaultMovement
end)(getCtx)
```

## License

MIT
