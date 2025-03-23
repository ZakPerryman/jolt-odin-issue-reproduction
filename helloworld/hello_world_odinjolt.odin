package main

import "core:c"
import "core:fmt"
import "../vendor/JoltC"

ObjectLayers :: enum JoltC.ObjectLayer {
    STATIC,
    DYNAMIC,
    COUNT
}

BroadphaseLayers :: enum JoltC.BroadphaseLayer {
    STATIC,
    DYNAMIC,
    COUNT
}

GetNumBroadPhaseLayers :: proc "c" (self: rawptr) -> c.uint {
    return cast(c.uint)BroadphaseLayers.COUNT
}

GetBroadPhaseLayer :: proc "c" (self: rawptr, inLayer: JoltC.ObjectLayer) -> JoltC.BroadphaseLayer {
    #partial switch(cast(ObjectLayers)inLayer) {
        case .DYNAMIC : return cast(JoltC.BroadphaseLayer)BroadphaseLayers.DYNAMIC
        case : return cast(JoltC.BroadphaseLayer)BroadphaseLayers.STATIC
    }
}

broadphaseInterface : JoltC.BroadPhaseLayerInterface = {
    GetBroadPhaseLayer = GetBroadPhaseLayer,
    GetNumBroadPhaseLayers = GetNumBroadPhaseLayers,
}

objectPairFilter : JoltC.ObjectLayerPairFilter = {
    ShouldCollide = proc "c" (inLayer: JoltC.ObjectLayer, inLayer2: JoltC.ObjectLayer) -> bool {
        return inLayer == cast(JoltC.ObjectLayer)ObjectLayers.DYNAMIC || (inLayer == cast(JoltC.ObjectLayer)ObjectLayers.STATIC && inLayer2 == cast(JoltC.ObjectLayer)ObjectLayers.DYNAMIC) 
    }
}

broadphasePairFilter: JoltC.ObjectVsBroadPhaseLayerFilter = {
    ShouldCollide = proc "c" (inLayer1: JoltC.ObjectLayer, inLayer2: JoltC.BroadphaseLayer) -> bool {
        if(inLayer1 == cast(JoltC.ObjectLayer)ObjectLayers.DYNAMIC) { return true }
        if(inLayer1 == cast(JoltC.ObjectLayer)ObjectLayers.STATIC && inLayer2 == cast(JoltC.BroadphaseLayer)BroadphaseLayers.DYNAMIC) { return true }
        return false
    }
}

main :: proc() {
    JoltC.RegisterDefaultAllocator()
    JoltC.FactoryInit()
    JoltC.RegisterTypes()

    jta := JoltC.TempAllocatorImpl_new()
    js := JoltC.JobSystemThreadPool_new3(1024, 1024, 4)

    bp_interface := JoltC.BroadPhaseLayerInterface_new(nil, broadphaseInterface)
    objPair_filter := JoltC.ObjectLayerPairFilter_new(nil, objectPairFilter)
    objVsBroad_filter := JoltC.ObjectVsBroadPhaseLayerFilter_new(nil, broadphasePairFilter)

    phys := JoltC.PhysicsSystem_new()
    JoltC.PhysicsSystem_Init(phys, 1024, 0, 1024, 1024, 
        bp_interface, objVsBroad_filter, objPair_filter)
    
    body_interface := JoltC.PhysicsSystem_GetBodyInterface(phys)

    floorBoxSettings : JoltC.BoxShapeSettings
    JoltC.BoxShapeSettings_default(&floorBoxSettings)

    floorShape : ^JoltC.Shape
    error : ^JoltC.String

    floorBoxSettings.halfExtent = {10.0, 0.5, 10.0, 1.0}
    JoltC.BoxShapeSettings_Create(&floorBoxSettings, &floorShape, &error)
    if(error != nil) { fmt.println("Failed to create floor shape") }

    boxSettings : JoltC.BoxShapeSettings
    JoltC.BoxShapeSettings_default(&boxSettings)

    boxSettings.halfExtent = {0.5, 0.5, 0.5, 1.0}
    boxShape : ^JoltC.Shape
    JoltC.BoxShapeSettings_Create(&boxSettings, &boxShape, &error)
    if(error != nil) { fmt.println("Failed to create box shape")}

    floorBodySettings : JoltC.BodyCreationSettings
    JoltC.BodyCreationSettings_default(&floorBodySettings)
    floorBodySettings.ObjectLayer = cast(JoltC.ObjectLayer)ObjectLayers.STATIC
    floorBodySettings.MotionType = .STATIC

    floorBody := JoltC.BodyInterface_CreateBody(body_interface, &floorBodySettings)

    boxBodySettings : JoltC.BodyCreationSettings
    JoltC.BodyCreationSettings_default(&boxBodySettings)
    boxBodySettings.ObjectLayer = cast(JoltC.ObjectLayer)ObjectLayers.DYNAMIC
    boxBodySettings.MotionType = .DYNAMIC

    boxBody := JoltC.BodyInterface_CreateBody(body_interface, &boxBodySettings)

    floorBodyId := JoltC.Body_GetID(floorBody)
    boxBodyId := JoltC.Body_GetID(boxBody)

    JoltC.BodyInterface_AddBody(body_interface, floorBodyId, .DONT_ACTIVATE)
    JoltC.BodyInterface_AddBody(body_interface, boxBodyId, .ACTIVATE)

    for(JoltC.BodyInterface_IsActive(body_interface, boxBodyId)) {
        fmt.printfln("Position: %v", JoltC.BodyInterface_GetCenterOfMassPosition(body_interface, boxBodyId))

        updateError := JoltC.PhysicsSystem_Update(phys, 1.0/60.0, 1, jta, js)
    }

    fmt.println("All done.")
}