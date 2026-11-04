using UnityEngine;
namespace Leom.Prototype
{
    public sealed class CameraFollow : MonoBehaviour
    {
        public Transform target;
        public float distance = 7.5f, height = 2.2f, sensitivity = 2.5f;
        private float yaw = 180f, pitch = 18f;
        private void LateUpdate()
        {
            if (target == null) return;
            if (Input.GetMouseButton(1) && !Application.isMobilePlatform)
            {
                yaw += Input.GetAxis("Mouse X") * sensitivity;
                pitch = Mathf.Clamp(pitch - Input.GetAxis("Mouse Y") * sensitivity, -20f, 70f);
            }
            // Touch in the upper-right world viewport orbits; lower-right is reserved for HUD actions.
            foreach (Touch touch in Input.touches)
            {
                if (touch.phase != TouchPhase.Moved) continue;
                if (touch.position.x < Screen.width * .45f || touch.position.y < Screen.height * .30f) continue;
                yaw += touch.deltaPosition.x * .2f;
                pitch = Mathf.Clamp(pitch - touch.deltaPosition.y * .2f,-20f,70f);
            }
            Quaternion orbit = Quaternion.Euler(pitch, yaw, 0f);
            Vector3 lookAt = target.position + Vector3.up * height;
            Vector3 destination = lookAt - orbit * Vector3.forward * distance;
            if (Physics.Linecast(lookAt,destination,out RaycastHit hit,~0,QueryTriggerInteraction.Ignore))
            {
                if (hit.transform != target && !hit.transform.IsChildOf(target))
                    destination = hit.point + (lookAt - hit.point).normalized * .2f;
            }
            transform.position = Vector3.Lerp(transform.position,destination,12f*Time.deltaTime);
            transform.rotation = Quaternion.LookRotation(lookAt-transform.position);
        }
    }
}
