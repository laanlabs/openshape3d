//
//  openshape3d-Bridging-Header.h
//
//  Swift ↔ Obj-C bridging surface for the app target. Kept SEPARATE from
//  ShaderTypes.h because that header is ALSO #included by Shaders.metal —
//  pulling Foundation/OCCT into it would break Metal compilation. Metal keeps
//  including ShaderTypes.h directly; Swift sees everything through this header.
//

#import "Shaders/ShaderTypes.h"     // simd uniform structs shared with Metal
#import "Kernel/OCCT/OCCTBridge.h"   // OCCT B-rep kernel facade (Obj-C++)
#import "Kernel/ConstraintSolver/OS3DLinearAlgebra.h" // LAPACK kernels for the sketch solver (C)
