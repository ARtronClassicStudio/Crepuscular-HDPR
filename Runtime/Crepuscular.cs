using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Crepuscular")]
public sealed class Crepuscular : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    public BoolParameter enabled = new(false, true);
    public BoolParameter useColorDirectional = new(true, false);
    public ColorParameter color = new(Color.white, false);
    public VolumeParameter<Quality> quality = new() { value = Quality.High };
    public ClampedFloatParameter weight = new(1, 0, 1);
    public ClampedFloatParameter exposure = new(0.5f, 0, 1);
    public ClampedFloatParameter illuminationDecay = new(1, 0, 10);

    public enum Quality
    {
        Ultra,
        High,
        Medium,
        Low
    }

    Material m_Material;
    HDAdditionalLightData[] lightData;

    public bool IsActive() => enabled.value;

    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    const string kShaderName = "Hidden/Crepuscular";

    public override void Setup()
    {
        if (Shader.Find(kShaderName) != null)
        {
            lightData = FindObjectsOfType<HDAdditionalLightData>();
            m_Material = new Material(Shader.Find(kShaderName));
        }
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume Crepuscular is unable to load.");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;


        if (IsActive())
        {

            switch (quality.value)
            {
                case Quality.Ultra: m_Material.SetFloat(Shader.PropertyToID("_NumSamples"), 1024); break;
                case Quality.High: m_Material.SetFloat(Shader.PropertyToID("_NumSamples"), 300); break;
                case Quality.Medium: m_Material.SetFloat(Shader.PropertyToID("_NumSamples"), 150); break;
                case Quality.Low: m_Material.SetFloat(Shader.PropertyToID("_NumSamples"), 50); break;
            }

            m_Material.SetFloat(Shader.PropertyToID("_Density"), 1);
            m_Material.SetFloat(Shader.PropertyToID("_Weight"),weight.value);
            m_Material.SetFloat(Shader.PropertyToID("_Decay"), 1);
            m_Material.SetFloat(Shader.PropertyToID("_Exposure"), exposure.value);
            m_Material.SetFloat(Shader.PropertyToID("_IlluminationDecay"), illuminationDecay.value);
            if (!useColorDirectional.value)
            {
                m_Material.SetColor(Shader.PropertyToID("_ColorRay"), color.value);
            }

            foreach (var l in lightData)
            {
                m_Material.SetVector(Shader.PropertyToID("_LightPos"), camera.camera.WorldToViewportPoint(camera.camera.transform.position - l.transform.forward));
                if (useColorDirectional.value)
                {
                    m_Material.SetColor(Shader.PropertyToID("_ColorRay"), l.color);
                }
            } 
        }

        m_Material.SetTexture("_MainTex", source);
        cmd.Blit(source, destination, m_Material, 0);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(m_Material);
    }
}
