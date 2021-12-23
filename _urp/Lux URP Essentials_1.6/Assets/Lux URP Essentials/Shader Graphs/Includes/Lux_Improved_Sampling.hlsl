void ImprovedSampling_float(
//  Base inputs
    float2 UV,
    float2 TextureTexelSize,

//  Outputs
    out float2 ImprovedUV
) {

    ImprovedUV = UV * TextureTexelSize + 0.5;
    float2 iuv = floor( ImprovedUV );
    float2 fuv = frac( ImprovedUV );
    ImprovedUV = iuv + fuv*fuv*(3.0-2.0*fuv); // fuv*fuv*fuv*(fuv*(fuv*6.0-15.0)+10.0);;
    ImprovedUV = (ImprovedUV - 0.5) / TextureTexelSize;
}