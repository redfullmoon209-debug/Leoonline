using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Leom.Prototype
{
public sealed class CameraFollow : MonoBehaviour
    {
        public Transform target;
        public float distance = 7.5f;
        public float height = 2.2f;
        public float sensitivity = 2.5f;
        private float yaw = 180f;
        private float pitch = 18f;

        private void LateUpdate()
        {
            if (target == null) return;
            if (Input.GetMouseButton(1))
            {
                yaw += Input.GetAxis("Mouse X") * sensitivity;
                pitch = Mathf.Clamp(pitch - Input.GetAxis("Mouse Y") * sensitivity, -20f, 70f);
            }
            Quaternion orbit = Quaternion.Euler(pitch, yaw, 0f);
            Vector3 lookAt = target.position + Vector3.up * height;
            Vector3 destination = lookAt - orbit * Vector3.forward * distance;
            if (Physics.Linecast(lookAt, destination, out RaycastHit hit, ~0, QueryTriggerInteraction.Ignore))
            {
                if (hit.transform != target && !hit.transform.IsChildOf(target))
                    destination = hit.point + (lookAt - hit.point).normalized * 0.2f;
            }
            transform.position = Vector3.Lerp(transform.position, destination, 12f * Time.deltaTime);
            transform.rotation = Quaternion.LookRotation(lookAt - transform.position);
        }
    }
}
