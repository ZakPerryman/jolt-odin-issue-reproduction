package joltc

import "core:c"

import "core:math/linalg"
import "core:math/linalg/hlsl"

when ODIN_OS == .Windows {
    @(private) CLIB_PATH :: "lib/joltc.lib"
    @(private) LIB_PATH :: "lib/jolt.lib"

    foreign import lib {
        CLIB_PATH,
        LIB_PATH,
    }
} else {
    @(private) CLIB_PATH :: "lib/joltc.a"
    @(private) LIB_PATH :: "lib/jolt.a"

    foreign import lib {
        CLIB_PATH,
        LIB_PATH,
    }
}

ObjectLayer :: distinct c.uint16_t
BroadphaseLayer :: distinct c.uint8_t

PhysicsUpdateError :: distinct c.uint32_t;
PHYSICS_UPDATE_ERROR_NONE : PhysicsUpdateError                     = 0;
PHYSICS_UPDATE_ERROR_MANIFOLD_CACHE_FULL : PhysicsUpdateError      = 1 << 0;
PHYSICS_UPDATE_ERROR_BODY_PAIR_CACHE_FULL : PhysicsUpdateError     = 1 << 1;
PHYSICS_UPDATE_ERROR_CONTACT_CONSTRAINTS_FULL : PhysicsUpdateError = 1 << 2;

BodyID :: distinct c.uint32_t
SubBodyID :: distinct c.uint32_t

BroadPhaseLayerInterface :: struct {
    GetNumBroadPhaseLayers : #type proc "c" (self: rawptr) -> c.uint,
    GetBroadPhaseLayer : #type proc "c" (self: rawptr, inLayer: ObjectLayer) -> BroadphaseLayer,
}

BroadPhaseLayerFilter :: struct {
    ShouldCollide : #type proc "c" (in_layer: BroadphaseLayer) -> bool
}

ObjectLayerFilter :: struct {
    ShouldCollide : #type proc "c" (in_layer: ObjectLayer) -> bool
}

ObjectLayerPairFilter :: struct {
    ShouldCollide : #type proc "c" (in_layer1: ObjectLayer, in_layer2: ObjectLayer) -> bool
}

ObjectVsBroadPhaseLayerFilter :: struct {
    ShouldCollide : #type proc "c" (in_layer1: ObjectLayer, in_layer2: BroadphaseLayer) -> bool
}

ShapeType :: enum c.uint8_t {
    CONVEX,
	COMPOUND,
	DECORATED,
	MESH,
	HEIGHT_FIELD,
	SOFTBODY,
	USER1,
	USER2,
	USER3,
	USER4,
}

Activation :: enum c.uint32_t {
	ACTIVATE      = 0,
	DONT_ACTIVATE = 1,
}

PhysicsSystem :: struct {}
BodyInterface :: struct {}
TempAllocator :: struct {}
JobSystem :: struct {}

Body :: struct {}
Shape :: struct {}

String :: struct {}

MotionType :: enum c.uint8_t {
    STATIC,
	KINEMATIC,
	DYNAMIC,
}

AllowedDOFs :: enum c.uint8_t {
    NONE         = 0b000000,
	ALL          = 0b111111,
	TRANSLATIONX = 0b000001,
	TRANSLATIONY = 0b000010,
	TRANSLATIONZ = 0b000100,
	ROTATIONX    = 0b001000,
	ROTATIONY    = 0b010000,
	ROTATIONZ    = 0b100000,
	PLANE2D      = TRANSLATIONX | TRANSLATIONY | ROTATIONZ,
}

MotionQuality :: enum c.uint8_t {
    DISCRETE,
	LINEAR_CAST,
}

OverrideMassProperties :: enum c.uint8_t {
    CALC_MASS_INERTIA,
	CALC_INERTIA,
	MASS_INERTIA_PROVIDED,
}

BodyCreationSettings :: struct {
    Position: hlsl.float4,
	Rotation: quaternion128,
	LinearVelocity: hlsl.float4,
	AngularVelocity: hlsl.float4,
	UserData: c.uint64_t,
	ObjectLayer: ObjectLayer,
	// CollisionGroup: CollisionGroup ,
	MotionType: MotionType,
	AllowedDOFs: AllowedDOFs,
	AllowDynamicOrKinematic: bool,
	IsSensor: bool,
	CollideKinematicVsNonDynamic: bool,
	UseManifoldReduction: bool,
	ApplyGyroscopicForce: bool,
	MotionQuality: MotionQuality,
	EnhancedInternalEdgeRemoval: bool,
	AllowSleeping: bool,
	Friction: c.float,
	Restitution: c.float,
	LinearDamping: c.float,
	AngularDamping: c.float,
	MaxLinearVelocity: c.float,
	MaxAngularVelocity: c.float,
	GravityFactor: c.float,
	NumVelocityStepsOverride: c.uint,
	NumPositionStepsOverride: c.uint,
	OverrideMassProperties: OverrideMassProperties,
	InertiaMultiplier: c.float,

	Shape: ^Shape,
}

BoxShapeSettings :: struct {
    userData: rawptr,
    density: c.float,
    halfExtent: hlsl.float4,
    convexRadius: c.float,
}

BroadPhaseLayerInterfaceImpl :: struct {}
ObjectVsBroadPhaseLayerFilterImpl :: struct {}
ObjectLayerPairFilterImpl :: struct {}

@(link_prefix="JPC_", default_calling_convention="c", require_results)
foreign lib {
    RegisterDefaultAllocator :: proc() ---
    FactoryInit :: proc() ---
    FactoryDelete :: proc() ---
    RegisterTypes :: proc() ---
    UnregisterTypes :: proc() ---

    BroadPhaseLayerInterface_new :: proc(self: rawptr, interface: BroadPhaseLayerInterface) -> ^BroadPhaseLayerInterfaceImpl ---
    ObjectVsBroadPhaseLayerFilter_new :: proc(self: rawptr, filter: ObjectVsBroadPhaseLayerFilter) -> ^ObjectVsBroadPhaseLayerFilterImpl ---
    ObjectLayerPairFilter_new :: proc(self: rawptr, filter: ObjectLayerPairFilter) -> ^ObjectLayerPairFilterImpl ---

    PhysicsSystem_new :: proc() -> ^PhysicsSystem ---
    PhysicsSystem_delete :: proc(physicsSystem: ^PhysicsSystem) ---

    PhysicsSystem_Init :: proc(
        physicsSystem: ^PhysicsSystem,
        inMaxBodies : c.uint,
        inNumBodyMutexes : c.uint,
        inMaxBodyPairs : c.uint,
        inMaxContactConstraints : c.uint,
        inBroadPhaseLayerInterface: ^BroadPhaseLayerInterfaceImpl,
        inObjectVsBroadPhaseLayerFilter: ^ObjectVsBroadPhaseLayerFilterImpl,
        inObjectLayerPairFilter: ^ObjectLayerPairFilterImpl
    ) ---

    TempAllocatorImpl_new :: proc() -> ^TempAllocator ---
    TempAllocatorImpl_delete :: proc(allocator: ^TempAllocator) ---

    JobSystemThreadPool_new2 :: proc(maxJobs: c.uint, maxBarriers: c.uint) -> ^JobSystem ---
    JobSystemThreadPool_new3 :: proc(maxJobs: c.uint, maxBarriers: c.uint, numThreads: c.int) -> ^JobSystem ---
    JobSystemThreadPool_delete :: proc(jobSystem: ^JobSystem) ---

    BoxShapeSettings_default :: proc(settings: ^BoxShapeSettings) ---
    BoxShapeSettings_Create :: proc(settings: ^BoxShapeSettings, outShape: ^^Shape, outError: ^^String) ---

    PhysicsSystem_GetBodyInterface :: proc(physicsSystem: ^PhysicsSystem) -> ^BodyInterface ---

    BodyInterface_CreateBody :: proc(self: ^BodyInterface, inSettings: ^BodyCreationSettings) -> ^Body ---
    BodyInterface_DestroyBody :: proc (self: ^BodyInterface, inBodyID: BodyID) ---
    BodyInterface_DestroyBodies :: proc (self: ^BodyInterface, inBodyIDs: [^]BodyID, inNumber: c.int) ---
    BodyInterface_AddBody :: proc (self: ^BodyInterface, inBodyID: BodyID, activation: Activation) ---
    BodyInterface_RemoveBody :: proc (self: ^BodyInterface, inBodyID: BodyID) ---
    BodyInterface_IsAdded :: proc (self: ^BodyInterface, inBodyID: BodyID) -> bool ---
    BodyInterface_CreateAndAddBody :: proc (self: ^BodyInterface, inSettings: ^BodyCreationSettings, inActivationMode: Activation) -> BodyID ---

    BodyInterface_IsActive :: proc(self: ^BodyInterface, inBodyID: BodyID) -> bool ---

    BodyInterface_GetCenterOfMassPosition :: proc(self: ^BodyInterface, inBodyID: BodyID) -> hlsl.float4 ---

    BodyInterface_GetPositionAndRotation :: proc(self: ^BodyInterface, inBodyID: BodyID, outPosition: ^hlsl.float4, outRotation: ^quaternion128) ---
    BodyInterface_SetPositionAndRotation :: proc(self: ^BodyInterface, inBodyID: BodyID, inPosition: hlsl.float4, inRotation: quaternion128) ---

    Body_GetPosition :: proc(self: ^Body) -> hlsl.float4 ---
    Body_GetRotation :: proc(self: ^Body) -> quaternion128 ---

    BodyCreationSettings_default :: proc(settings: ^BodyCreationSettings) ---

    Body_GetID :: proc(self: ^Body) -> BodyID ---

    String_c_str :: proc(str: ^String) -> cstring ---

    PhysicsSystem_Update :: proc(
        physicsSystem: ^PhysicsSystem,
        deltaTime: c.float,
        inCollisionSteps: c.int,
        allocator: ^TempAllocator,
        jobSystem: ^JobSystem,
    ) -> PhysicsUpdateError ---
}

