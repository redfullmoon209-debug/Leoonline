using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Leoonline.Prototype
{
public sealed class MonsterBrain : MonoBehaviour
    {
        public float maxHealth = 55f;
        public float moveSpeed = 1.6f;
        public float chaseDistance = 10f;
        public float hitRange = 1.7f;
        public int rewardExp = 30;
        public string rewardGold = "12";
        public string dropItem = "monster_core";
        public float respawnSeconds = 8f;
        public float health;
        private Vector3 startPosition;
        private float nextAttack;
        private float reviveAt = -1f;
        private Renderer body;
        private Collider ownCollider;
        public bool IsAlive => health > 0f;

        private void Start()
        {
            startPosition = transform.position;
            health = maxHealth;
            body = GetComponentInChildren<Renderer>();
            ownCollider = GetComponent<Collider>();
        }

        private void Update()
        {
            if (!IsAlive)
            {
                if (reviveAt >= 0f && Time.time >= reviveAt) Revive();
                return;
            }
            var player = PrototypeGame.Instance ? PrototypeGame.Instance.Player : null;
            if (!player || !player.IsAlive) return;
            Vector3 delta = player.transform.position - transform.position;
            delta.y = 0f;
            float distance = delta.magnitude;
            if (distance > chaseDistance || distance < 0.05f) return;
            transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(delta), 5f * Time.deltaTime);
            if (distance > hitRange)
            {
                transform.position += delta.normalized * moveSpeed * Time.deltaTime;
            }
            else if (Time.time >= nextAttack)
            {
                nextAttack = Time.time + 1.8f;
                player.TakeDamage(9f);
            }
        }

        public void TakeDamage(float amount)
        {
            if (!IsAlive) return;
            health = Mathf.Max(0f, health - Mathf.Max(0f, amount));
            if (!IsAlive) Die();
        }

        private void Die()
        {
            reviveAt = Time.time + respawnSeconds;
            if (body) body.enabled = false;
            if (ownCollider) ownCollider.enabled = false;
            PrototypeGame.Instance?.RewardMonster(rewardExp, rewardGold);
            if (UnityEngine.Random.value < 0.75f) SpawnDrop();
        }

        private void SpawnDrop()
        {
            GameObject orb = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            orb.name = "Loot_" + dropItem;
            orb.transform.position = transform.position + Vector3.up * 0.35f;
            orb.transform.localScale = Vector3.one * 0.5f;
            var collider = orb.GetComponent<Collider>();
            if (collider) collider.isTrigger = true;
            var loot = orb.AddComponent<GroundLoot>();
            loot.itemId = dropItem;
            var render = orb.GetComponent<Renderer>();
            if (render != null) render.material.color = new Color(1f, 0.72f, 0.18f);
        }

        private void Revive()
        {
            transform.position = startPosition;
            health = maxHealth;
            reviveAt = -1f;
            nextAttack = 0f;
            if (body) body.enabled = true;
            if (ownCollider) ownCollider.enabled = true;
        }
    }
}
