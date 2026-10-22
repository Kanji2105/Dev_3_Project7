
using UnityEngine;
using UnityEngine.Rendering;

public class ForestAtmosphere : MonoBehaviour
{
    [Header("Player")]
    public Transform player;

    [Header("Three Skyboxes")]
    public Material fullMoonSkybox;
    public Material fogSkybox;
    public Material bloodMoonSkybox;

    [Header("Moonlight")]
    public Light directionalLight;

    [Header("Walking Distances")]
    public float fogStartDistance = 25f;
    public float fullFogDistance = 95f;
    public float bloodMoonDistance = 150f;
    public float bloodMoonEndDistance = 210f;

    [Header("Whiteout Fog")]
    public Color whiteFogColor =
        new Color(0.7f, 0.74f, 0.78f);

    public float whiteFogDensity = 0.055f;

    [Header("Blood Moon Fog")]
    public Color bloodFogColor =
        new Color(0.34f, 0.1f, 0.16f);

    public float bloodFogDensity = 0.025f;

    [Header("Atmosphere Colors")]
    public Color fogAmbientColor =
        new Color(0.25f, 0.28f, 0.35f);

    public Color bloodAmbientColor =
        new Color(0.24f, 0.06f, 0.09f);

    public Color fogLightColor =
        new Color(0.7f, 0.75f, 0.85f);

    public Color bloodLightColor =
        new Color(1f, 0.35f, 0.35f);

    [Header("Ambient Music")]
    public AudioSource veilAudio;
    public AudioSource lostAudio;

    [Range(0f, 1f)]
    public float veilVolume = 0.7f;

    [Range(0f, 1f)]
    public float lostVolume = 0.7f;

    private Vector3 lastPosition;
    private float distanceWalked;

    private Color originalAmbient;
    private Color originalLightColor;
    private float originalLightIntensity;

    void Start()
    {
        if (player == null || directionalLight == null)
        {
            Debug.LogError(
                "Assign Player and Directional Light!");

            enabled = false;
            return;
        }

        lastPosition = player.position;
        distanceWalked = 0f;

        originalAmbient = RenderSettings.ambientLight;
        originalLightColor = directionalLight.color;
        originalLightIntensity = directionalLight.intensity;

        RenderSettings.ambientMode = AmbientMode.Flat;
        RenderSettings.fog = false;
        RenderSettings.fogMode = FogMode.ExponentialSquared;

        ChangeSkybox(fullMoonSkybox);

        // Start Veil immediately.
        if (veilAudio != null)
        {
            veilAudio.loop = true;
            veilAudio.volume = veilVolume;

            if (!veilAudio.isPlaying)
                veilAudio.Play();
        }

        // Lost starts silent.
        if (lostAudio != null)
        {
            lostAudio.loop = true;
            lostAudio.volume = 0f;
            lostAudio.Stop();
        }
    }

    void Update()
    {
        Vector3 currentPosition = player.position;

        Vector2 previous = new Vector2(
            lastPosition.x,
            lastPosition.z);

        Vector2 current = new Vector2(
            currentPosition.x,
            currentPosition.z);

        float movement = Vector2.Distance(
            previous, current);

        // Ignore sudden teleport-like jumps.
        if (movement < 3f)
        {
            distanceWalked += movement;
        }

        lastPosition = currentPosition;

        // Gradually introduce fog.
        float fogProgress = Mathf.InverseLerp(
            fogStartDistance,
            fullFogDistance,
            distanceWalked);

        // Gradually introduce the Blood Moon.
        float bloodProgress = Mathf.InverseLerp(
            bloodMoonDistance,
            bloodMoonEndDistance,
            distanceWalked);

        RenderSettings.fog =
            distanceWalked >= fogStartDistance;

        float currentFogDensity = Mathf.Lerp(
            0f,
            whiteFogDensity,
            fogProgress);

        RenderSettings.fogDensity = Mathf.Lerp(
            currentFogDensity,
            bloodFogDensity,
            bloodProgress);

        RenderSettings.fogColor = Color.Lerp(
            whiteFogColor,
            bloodFogColor,
            bloodProgress);

        // Change ambient lighting.
        Color currentAmbient = Color.Lerp(
            originalAmbient,
            fogAmbientColor,
            fogProgress);

        RenderSettings.ambientLight = Color.Lerp(
            currentAmbient,
            bloodAmbientColor,
            bloodProgress);

        // Change moonlight color.
        Color currentLight = Color.Lerp(
            originalLightColor,
            fogLightColor,
            fogProgress);

        directionalLight.color = Color.Lerp(
            currentLight,
            bloodLightColor,
            bloodProgress);

        float fogIntensity = Mathf.Lerp(
            originalLightIntensity,
            0.12f,
            fogProgress);

        directionalLight.intensity = Mathf.Lerp(
            fogIntensity,
            0.15f,
            bloodProgress);

        // Change the skybox.
        if (distanceWalked >= bloodMoonDistance)
        {
            ChangeSkybox(bloodMoonSkybox);
        }
        else if (distanceWalked >= fullFogDistance)
        {
            ChangeSkybox(fogSkybox);
        }
        else
        {
            ChangeSkybox(fullMoonSkybox);
        }

        // Gradually crossfade Veil into Lost.
        if (veilAudio != null)
        {
            veilAudio.volume = Mathf.Lerp(
                veilVolume,
                0f,
                fogProgress);
        }

        if (lostAudio != null)
        {
            if (fogProgress > 0f && !lostAudio.isPlaying)
            {
                lostAudio.Play();
            }

            lostAudio.volume = Mathf.Lerp(
                0f,
                lostVolume,
                fogProgress);
        }
    }

    void ChangeSkybox(Material newSkybox)
    {
        if (newSkybox == null)
            return;

        if (RenderSettings.skybox == newSkybox)
            return;

        RenderSettings.skybox = newSkybox;
        DynamicGI.UpdateEnvironment();
    }
}
