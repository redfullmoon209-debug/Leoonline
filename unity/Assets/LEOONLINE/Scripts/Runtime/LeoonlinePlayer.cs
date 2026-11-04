using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Leoonline.Prototype
{
public sealed class LeoonlinePlayer : MonoBehaviour
    {
        public float walkSpeed = 4.2f;
        public float sprintSpeed = 6.8f;
        public float jumpHeight = 1.4f;
        public float gravity = -19.6f;
        public float attackRange = 2.7f;
        public float attackCooldown = 0.6f;
        public float maxHealth = 100f;
        public float health = 100f;
        private CharacterController controller;
        private Vector3 verticalVelocity;
        private float nextAttack;
        private Camera view;
        public bool IsAlive => health > 0f;

        private void Awake()
        {
            controller = GetComponent<CharacterController>();
            view = Camera.main;
        }

        private void Start()
        {
            if (PrototypeGame.Instance != null) PrototypeGame.Instance.AttachPlayer(this);
        }

        private void Update()
        {
            if (!IsAlive) return;
            float h = Input.GetAxisRaw("Horizontal");
            float v = Input.GetAxisRaw("Vertical");
            Vector3 forward = view ? Vector3.ProjectOnPlane(view.transform.forward, Vector3.up).normalized : Vector3.forward;
            Vector3 right = view ? Vector3.ProjectOnPlane(view.transform.right, Vector3.up).normalized : Vector3.right;
            Vector3 movement = Vector3.ClampMagnitude(forward * v + right * h, 1f);
            if (movement.sqrMagnitude > 0.001f)
                transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(movement), 12f * Time.deltaTime);
            float speed = Input.GetKey(KeyCode.LeftShift) ? sprintSpeed : walkSpeed;
            controller.Move(movement * speed * Time.deltaTime);
            if (controller.isGrounded && verticalVelocity.y < 0) verticalVelocity.y = -1.5f;
            if (controller.isGrounded && Input.GetKeyDown(KeyCode.Space))
                verticalVelocity.y = Mathf.Sqrt(jumpHeight * -2f * gravity);
            verticalVelocity.y += gravity * Time.deltaTime;
            controller.Move(verticalVelocity * Time.deltaTime);
            if (Input.GetMouseButtonDown(0)) MeleeAttack();
            if (Input.GetKeyDown(KeyCode.E)) PickUpNearest();
        }

        private void MeleeAttack()
        {
            if (Time.time < nextAttack) return;
            nextAttack = Time.time + attackCooldown;
            MonsterBrain nearest = null;
            float best = attackRange * attackRange;
            foreach (var target in FindObjectsByType<MonsterBrain>(FindObjectsSortMode.None))
            {
                if (!target.IsAlive) continue;
                Vector3 delta = target.transform.position - transform.position;
                float dist = delta.sqrMagnitude;
                if (dist >= best || Vector3.Dot(transform.forward, delta.normalized) < 0.2f) continue;
                nearest = target; best = dist;
            }
            if (nearest != null) nearest.TakeDamage(18f);
        }

        private void PickUpNearest()
        {
            GroundLoot nearest = null;
            float best = 2.7f * 2.7f;
            foreach (var loot in FindObjectsByType<GroundLoot>(FindObjectsSortMode.None))
            {
                float distance = (loot.transform.position - transform.position).sqrMagnitude;
                if (distance < best) { nearest = loot; best = distance; }
            }
            if (nearest != null) nearest.Collect();
        }

        public void TakeDamage(float amount)
        {
            if (!IsAlive) return;
            health = Mathf.Max(0f, health - Mathf.Max(0f, amount));
            if (!IsAlive) PrototypeGame.Instance?.Notify("You were defeated. Respawning...");
        }

        public void Respawn(Vector3 position)
        {
            controller.enabled = false;
            transform.position = position;
            controller.enabled = true;
            health = maxHealth;
            verticalVelocity = Vector3.zero;
        }
    }
}
