using UnityEngine;

public class FlashLightTest : MonoBehaviour

    
{
    public bool IsOn = false;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        // if you press f and flashlgiht is on
        if (Input.GetKey(KeyCode.F))

        // TurnOffFlashLight

        //else 
        TurnOnFlashlight();
    }

    public void TurnOnFlashlight()
    {
        IsOn = true;
    }
    public void TurnOffFlashLight()
    {
        IsOn = false;
    }
}
