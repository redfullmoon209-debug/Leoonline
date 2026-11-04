// Offline third-person movement + Novice combat. Multiplayer will replace authority.
using UnityEngine;
using Leom.Gameplay;

namespace Leom.Prototype
{
    [RequireComponent(typeof(CharacterController))]
    public sealed class LeomPlayer : MonoBehaviour
    {
        public float walkSpeed = 4.2f, sprintSpeed = 6.8f, gravity = -19.6f;
        public float jumpHeight = 1.4f, maxHealth = 150f, health = 150f;
        public float maxStamina = 100f, stamina = 100f;
        public float attackRange = 3.6f;
        public float attackCooldown = 0.52f;
        private CharacterController controller;
        private Camera view;
        private LeomTouchGamepad touch;
        private Vector3 verticalVelocity;
        private float nextBasic, guardUntil, nextSlash, nextRush, nextGuard;
        private MonsterBrain target;
        public bool IsAlive => health > 0f;
        public bool GuardActive => Time.time < guardUntil;
        public string CurrentTarget => target && target.IsAlive ? target.name : "none";

        private void Awake() { controller = GetComponent<CharacterController>(); }
        private void Start()
        {
            view = Camera.main;
            touch = FindFirstObjectByType<LeomTouchGamepad>();
            PrototypeGame.Instance?.AttachPlayer(this);
        }
        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.T)) LockNearest();
            if (Input.GetKeyDown(KeyCode.Alpha1)) UseSkillSlot(0);
            if (Input.GetKeyDown(KeyCode.Alpha2)) UseSkillSlot(1);
            if (Input.GetKeyDown(KeyCode.Alpha3)) UseSkillSlot(2);
            stamina = Mathf.Min(maxStamina, stamina + 14f * Time.deltaTime);
            if (!IsAlive) return;

            float h = Input.GetAxisRaw("Horizontal");
            float v = Input.GetAxisRaw("Vertical");
            Vector2 touchAxis = touch ? touch.Movement : Vector2.zero;
            if (touchAxis.sqrMagnitude > 0.001f) { h = touchAxis.x; v = touchAxis.y; }
            if (view == null) view = Camera.main;
            Vector3 forward = view ? Vector3.ProjectOnPlane(view.transform.forward, Vector3.up).normalized : Vector3.forward;
            Vector3 right = view ? Vector3.ProjectOnPlane(view.transform.right, Vector3.up).normalized : Vector3.right;
            Vector3 movement = Vector3.ClampMagnitude(forward * v + right * h, 1f);
            if (movement.sqrMagnitude > 0.001f)
                transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(movement), 12f * Time.deltaTime);
            float speed = Input.GetKey(KeyCode.LeftShift) ? sprintSpeed : walkSpeed;
            controller.Move(movement * speed * Time.deltaTime);
            if (controller.isGrounded && verticalVelocity.y < 0f) verticalVelocity.y = -1.5f;
            bool jump = Input.GetKeyDown(KeyCode.Space) || (touch && touch.ConsumeJump());
            if (controller.isGrounded && jump)
                verticalVelocity.y = Mathf.Sqrt(jumpHeight * -2f * gravity);
            verticalVelocity.y += gravity * Time.deltaTime;
            controller.Move(verticalVelocity * Time.deltaTime);

            bool clickAttack = !Application.isMobilePlatform && Input.GetMouseButtonDown(0);
            if (clickAttack || (touch && touch.ConsumeAttack())) BasicAttack();
            if (Input.GetKeyDown(KeyCode.E) || (touch && touch.ConsumeLoot())) PickUpNearest();
            if (touch && touch.ConsumeSkill(0)) UseSkillSlot(0);
            if (touch && touch.ConsumeSkill(1)) UseSkillSlot(1);
            if (touch && touch.ConsumeSkill(2)) UseSkillSlot(2);
        }
        public void LockNearest()
        {
            target = NearestMonster(16f, false);
            PrototypeGame.Instance?.Notify("Target: " + CurrentTarget);
        }
        private MonsterBrain NearestMonster(float range, bool facingOnly)
        {
            MonsterBrain nearest = null;
            float best = range * range;
            foreach (var monster in FindObjectsByType<MonsterBrain>(FindObjectsSortMode.None))
            {
                if (!monster.IsAlive) continue;
                Vector3 delta = monster.transform.position - transform.position;
                delta.y = 0f;
                float distance = delta.sqrMagnitude;
                if (distance >= best || (facingOnly && Vector3.Dot(transform.forward, delta.normalized) < 0.05f))
                    continue;
                best = distance; nearest = monster;
            }
            return nearest;
        }
        private MonsterBrain CombatTarget(float range)
        {
            if (target && target.IsAlive && Vector3.Distance(target.transform.position, transform.position) <= range)
                return target;
            return NearestMonster(range, false);
        }
        public void BasicAttack()
        {
            if (!IsAlive || Time.time < nextBasic) return;
            nextBasic = Time.time + attackCooldown;
            var enemy = CombatTarget(attackRange);
            if (!enemy) { PrototypeGame.Instance?.Notify("No monster in attack range"); return; }
            Face(enemy.transform.position);
            var rpg = LeomRpgService.Instance;
            int str = rpg != null ? rpg.EffectiveAttribute("strength") : 10;
            int dex = rpg != null ? rpg.EffectiveAttribute("dexterity") : 10;
            enemy.TakeDamage(10f + str * .35f + dex * .20f);
        }
        private void Face(Vector3 position)
        {
            Vector3 delta = position - transform.position;
            delta.y = 0f;
            if (delta.sqrMagnitude > 0.01f) transform.rotation = Quaternion.LookRotation(delta);
        }
        public void UseSkillSlot(int slot)
        {
            var rpg = LeomRpgService.Instance;
            if (rpg == null || slot < 0 || slot >= rpg.Character.skillHotbar.Length) return;
            UseSkill(rpg.Character.skillHotbar[slot]);
        }
        public void UseSkill(string id)
        {
            var rpg = LeomRpgService.Instance;
            if (rpg == null || !IsAlive || string.IsNullOrEmpty(id)) return;
            var info = LegacyCatalog.Skill(id);
            if (info == null || info.job != rpg.Character.job) { rpg.Tell("Skill not owned"); return; }
            if (info.kind == "timed_buff") { rpg.ActivateTimedBuff(id); return; }
            if (!info.implemented) { rpg.Tell("This class ability is catalog-only until animation/combat port"); return; }
            switch (id)
            {
                case "novice_slash":
                    if (Time.time < nextSlash) return;
                    var enemy = CombatTarget(3.6f);
                    if (!enemy) { rpg.Tell("Need a monster within 3.6 m"); return; }
                    nextSlash = Time.time + .8f;
                    Face(enemy.transform.position);
                    enemy.TakeDamage(19f + rpg.EffectiveAttribute("strength") * .75f +
                        rpg.EffectiveAttribute("dexterity") * .5f);
                    rpg.Tell("First Strike!");
                    break;
                case "novice_rush":
                    if (Time.time < nextRush || stamina < 20f) { rpg.Tell("Rush cooling down / low stamina"); return; }
                    var rush = CombatTarget(12f);
                    if (!rush) { rpg.Tell("Need a monster within 12 m"); return; }
                    nextRush = Time.time + 3f; stamina -= 20f;
                    Face(rush.transform.position);
                    Vector3 delta = rush.transform.position - transform.position;
                    delta.y = 0f;
                    controller.Move(delta.normalized * Mathf.Min(Mathf.Max(0f, delta.magnitude - 1.6f), 7f));
                    rush.TakeDamage(27f + rpg.EffectiveAttribute("strength") * .6f);
                    rpg.Tell("Azure Rush!");
                    break;
                case "novice_guard":
                    if (Time.time < nextGuard || stamina < 15f) { rpg.Tell("Guard cooling down / low stamina"); return; }
                    stamina -= 15f; guardUntil = Time.time + 5f; nextGuard = Time.time + 10f;
                    rpg.Tell("Radiant Ward: 65% damage reduction for 5s");
                    break;
            }
        }
        public void RestoreStamina(float amount) { stamina = Mathf.Min(maxStamina, stamina + Mathf.Max(0, amount)); }
        public void TakeDamage(float amount)
        {
            if (!IsAlive) return;
            var rpg = LeomRpgService.Instance;
            float vitality = rpg != null ? rpg.EffectiveAttribute("vitality") : 10;
            float resistance = Mathf.Clamp((vitality - 10f) * 0.012f, 0f, .4f);
            float multiplier = (1f - resistance) * (GuardActive ? .35f : 1f);
            health = Mathf.Max(0f, health - Mathf.Max(1f, Mathf.Round(amount * multiplier)));
            if (!IsAlive) rpg?.Tell("Defeated! Respawn in 8 seconds");
        }
        private void PickUpNearest()
        {
            GroundLoot nearest = null; float best = 2.7f * 2.7f;
            foreach (var loot in FindObjectsByType<GroundLoot>(FindObjectsSortMode.None))
            {
                float distance = (loot.transform.position - transform.position).sqrMagnitude;
                if (distance < best) { best = distance; nearest = loot; }
            }
            if (nearest != null) nearest.Collect();
        }
        public void Respawn(Vector3 position)
        {
            controller.enabled = false;
            transform.position = position;
            controller.enabled = true;
            health = maxHealth; stamina = maxStamina;
            verticalVelocity = Vector3.zero;
        }
    }
}
