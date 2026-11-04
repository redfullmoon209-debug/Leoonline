using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Leom.Prototype
{
public sealed class GroundLoot : MonoBehaviour
    {
        public string itemId = "monster_core";
        public int count = 1;
        private float bornAt;

        private void Start() { bornAt = Time.time; }

        private void Update()
        {
            transform.Rotate(Vector3.up, 70f * Time.deltaTime, Space.World);
            if (Time.time - bornAt >= 90f) Destroy(gameObject);
        }

        public void Collect()
        {
            if (PrototypeGame.Instance != null && PrototypeGame.Instance.AddItem(itemId, count))
                Destroy(gameObject);
        }
    }
}
