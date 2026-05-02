shader_type spatial;
render_mode unshaded;

// pixel sampling radius
uniform float scale = 1.0;

// outline dilation after computation
uniform float outline_spread = 5.0;

uniform vec4 _Color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float _DepthThreshold = 1.5;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap, repeat_disable;

void fragment() {
    float half_scale_floor = floor(scale * 0.5);
    float half_scale_ceil = ceil(scale * 0.5);

    vec2 texel_size = vec2(1.0) / vec2(textureSize(SCREEN_TEXTURE, 0));

    // Compute UV coordinates
    vec2 bottom_left_uv  = SCREEN_UV - vec2(texel_size.x, texel_size.y) * half_scale_floor;
    vec2 top_right_uv    = SCREEN_UV + vec2(texel_size.x, texel_size.y) * half_scale_ceil;
    vec2 bottom_right_uv = SCREEN_UV + vec2(texel_size.x * half_scale_ceil, -texel_size.y * half_scale_floor);
    vec2 top_left_uv      = SCREEN_UV + vec2(-texel_size.x * half_scale_floor, texel_size.y * half_scale_ceil);

    // Depth 
    float depth0 = texture(DEPTH_TEXTURE, bottom_left_uv).r;
    float depth1 = texture(DEPTH_TEXTURE, top_right_uv).r;
    float depth2 = texture(DEPTH_TEXTURE, bottom_right_uv).r;
    float depth3 = texture(DEPTH_TEXTURE, top_left_uv).r;

    float depthThreshold = _DepthThreshold * depth0;

    float depthFiniteDifference0 = depth1 - depth0;
    float depthFiniteDifference1 = depth3 - depth2;

    float edgeDepth = sqrt(pow(depthFiniteDifference0, 2.) + pow(depthFiniteDifference1, 2.)) * 100.;
    edgeDepth = edgeDepth > depthThreshold ? 1. : 0.;

    float edge = edgeDepth;

    float dilated_edge = edge;

    // Directional offsets for 4-neighbor dilation
    vec2 offsets[4] = vec2[](
        vec2(texel_size.x, 0.0),
        vec2(-texel_size.x, 0.0),
        vec2(0.0, texel_size.y),
        vec2(0.0, -texel_size.y)
    );
    
    float thickness = outline_spread;
    for (int i = 0; i < 4; i++) {
        vec2 offset_uv = SCREEN_UV + offsets[i] * thickness;

        float depth_n = texture(DEPTH_TEXTURE, offset_uv).r;
        float depth_diff = depth_n - depth0; 

        float edge_depth_n = (sqrt(depth_diff * depth_diff) * 100.0 > _DepthThreshold) ? 1.0 : 0.0;

        dilated_edge = max(dilated_edge, edge_depth_n);
    }

    vec4 edgeColor = vec4(_Color.rgb, _Color.a * dilated_edge);

    ALBEDO = mix(texture(SCREEN_TEXTURE,SCREEN_UV).rgb, edgeColor.rgb, edgeColor.a);
}