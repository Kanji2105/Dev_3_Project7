using UnityEngine;

public class SimplePlayerMove : MonoBehaviour
{
    public float speed = 4f;

    void Update()
    {
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");

        Vector3 move = transform.right * horizontal + transform.forward * vertical;

        transform.position += move * speed * Time.deltaTime;
    }
}