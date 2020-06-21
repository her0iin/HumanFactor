﻿Shader "Custom/her0in/RainWindow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Size("Size", Float) = 1
		_Timeline("T", Float) = 1
		_Distortion("Distortion", Float) = 1
		_Blur("Blur", Float) = 0
		_DropSpeed("DropSpeed", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent" }
        LOD 100
		GrabPass { "_GrabTexture" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#define S(a, b, t) smoothstep(a, b, t)
            #include "UnityCG.cginc"
            
			sampler2D _MainTex;
			sampler2D _GrabTexture;
			float4 _MainTex_ST;
			float _Size, _Timeline, _Distortion, _Blur, _DropSpeed;

			struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
				float4 grabuv : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.grabuv = UNITY_PROJ_COORD(ComputeGrabScreenPos(o.vertex));
                return o;
            }

			float N21(float2 p) {
				p = frac(p * float2(123.34, 345.45));
				p += dot(p, p + 34.345);
				return frac(p.x * p.y);
			}

			float3 Layer(float2 UV, float t)
			{
				float2 aspect = float2(2, 1);
				float2 uv = UV * _Size * aspect;
				uv.y += t * .25;
				float2 gv = frac(uv) - .5;
				float2 id = floor(uv);

				float n = N21(id);
				t += n * 6.2831;

				float w = UV.y * 10;
				float x = (n - .5) * .8;
				x += (.4 - abs(x)) * sin(3 * w)*pow(sin(w), 6) * .45;

				float y = -sin(t + sin(t + sin(t) * .5)) * .45;
				y -= (gv.x - x) * (gv.x - x);

				float2 dropPos = (gv - float2(x, y)) / aspect;
				float drop = S(.05, .03, length(dropPos));

				float2 trailPos = (gv - float2(x, t * .25)) / aspect;
				trailPos.y = (frac(trailPos.y * 8) - .5) / 8;
				float trail = S(.03, .01, length(trailPos));
				float fogTrail = S(-.05, .05, dropPos.y);
				fogTrail *= S(.5, y, gv.y);
				trail *= fogTrail;
				fogTrail *= S(.05, .04, abs(dropPos.x));

				float2 offs = drop * dropPos + trail * trailPos;
				return float3(offs, fogTrail);
			}

            fixed4 frag (v2f i) : SV_Target
			{
				float t = fmod(_Time.y + _Timeline, 7200) * _DropSpeed;
				float4 col = 0;

				float3 drops = Layer(i.uv, t);
				drops += Layer(i.uv * 1.23 + 7.54, t);
				drops += Layer(i.uv * 1.35 + 1.54, t);
				drops += Layer(i.uv * 1.57 - 7.54, t);

				float fade = 1 - saturate(fwidth(i.uv) * 60);
				float blur = _Blur * 7 * (1 - drops.z * fade);

				col = tex2Dlod(_MainTex, float4(i.uv + drops.xy * _Distortion, 0, blur));

				float2 projuv = i.grabuv.xy / i.grabuv.w;
				projuv += drops.xy * _Distortion * fade;
				blur *= .01;

				const float numSamples = 32;
				float a = N21(i.uv) * 6.2831;
				for (float i = 0; i < numSamples; i++)
				{
					float2 offs = float2(sin(a), cos(a)) * blur;
					float d = frac(sin((i + 1) * 546.) * 5424.);
					d = sqrt(d);
					offs *= d;
					col += tex2D(_GrabTexture, projuv + offs);
					a++;
				}
				col /= numSamples;

				return col * .9;
			}
            ENDCG
        }
    }
}