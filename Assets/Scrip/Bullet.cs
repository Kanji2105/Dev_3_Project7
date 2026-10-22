
using UnityEngine;

public class Bullet : MonoBehaviour
{
    public float speed = 20f;

    void Start()
    {
        Rigidbody rb = GetComponent<Rigidbody>();
        rb.linearVelocity = transform.forward * speed;
    }

    void OnTriggerEnter(Collider other)
    {

        
    }
}
