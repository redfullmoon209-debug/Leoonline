// LEOONLINE offline prototype. Intentionally NOT an authoritative MMORPG server.
using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Leoonline.Prototype
{
    [Serializable]
    public sealed class BagItem
    {
        public string id;
        public int count;
    }

    [Serializable]
    public sealed class LocalCharacter
    {
        public int level = 1;
        public int exp = 0;
        public int defeated = 0;
        public string[] currency = { "0", "0", "0", "0" };
        public List<BagItem> bag = new List<BagItem>();
    }

    public static class ExactCurrency
    {
        public const string Cap = "999999999999999999999";
        public static string Normalize(string number)
        {
            if (string.IsNullOrEmpty(number)) throw new ArgumentException("Empty currency");
            foreach (char c in number)
                if (c < '0' || c > '9') throw new ArgumentException("Non-decimal currency");
            string s = number.TrimStart('0');
            if (s.Length == 0) s = "0";
            if (s.Length > 21) throw new OverflowException("Currency over 21 digits");
            return s;
        }

        public static string Add(string a, string b)
        {
            a = Normalize(a); b = Normalize(b);
            int carry = 0, i = a.Length - 1, j = b.Length - 1;
            char[] outDigits = new char[Math.Max(a.Length, b.Length) + 1];
            int index = outDigits.Length - 1;
            while (i >= 0 || j >= 0 || carry > 0)
            {
                int digit = carry;
                if (i >= 0) digit += a[i--] - '0';
                if (j >= 0) digit += b[j--] - '0';
                outDigits[index--] = (char)('0' + digit % 10);
                carry = digit / 10;
            }
            string result = new string(outDigits, index + 1, outDigits.Length - index - 1);
            if (result.Length > 21 || (result.Length == 21 && string.CompareOrdinal(result, Cap) > 0))
                throw new OverflowException("Currency exceeds cap");
            return Normalize(result);
        }
    }

    // Sample rule helper. The future authoritative server must enforce these rules.
    public enum PvPZone { Safe, Hunting, OpenPK, Arena, GuildWar }

    public static class PvPRules
    {
        public static bool CanHitPlayer(PvPZone zone, bool sameParty, bool sameGuild, bool enemiesInMatch)
        {
            if (zone == PvPZone.Safe || zone == PvPZone.Hunting) return false;
            if (zone == PvPZone.OpenPK) return !sameParty && !sameGuild;
            return enemiesInMatch;
        }
    }

    public sealed class PrototypeGame : MonoBehaviour
    {
        public static PrototypeGame Instance { get; private set; }
        public LocalCharacter Profile { get; private set; } = new LocalCharacter();
        public LeoonlinePlayer Player { get; private set; }
        public string Message { get; private set; } = "Welcome to LEOONLINE offline PvE test";
        public float MessageUntil { get; private set; }

        private const int MaxBagSlots = 200;
        private const int UnlockedBagSlots = 40;
        private string SaveFile => Path.Combine(Application.persistentDataPath, "leoonline-unity-prototype.json");

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            LoadProfile();
        }

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.F5)) SaveProfile();
        }

        public void AttachPlayer(LeoonlinePlayer player) { Player = player; }

        public void Notify(string message)
        {
            Message = message;
            MessageUntil = Time.time + 4f;
            Debug.Log("[LEOONLINE] " + message);
        }

        public int ExpToNextLevel() => 80 + (Profile.level - 1) * 45;

        public void RewardMonster(int exp, string currencyAmount)
        {
            Profile.defeated++;
            Profile.exp += Mathf.Max(0, exp);
            while (Profile.exp >= ExpToNextLevel())
            {
                Profile.exp -= ExpToNextLevel();
                Profile.level++;
                Notify("LEVEL UP! Level " + Profile.level);
            }
            try { Profile.currency[0] = ExactCurrency.Add(Profile.currency[0], currencyAmount); }
            catch (Exception error) { Debug.LogWarning(error.Message); }
            SaveProfile();
        }

        public bool AddItem(string id, int amount)
        {
            if (string.IsNullOrEmpty(id) || amount <= 0) return false;
            foreach (BagItem item in Profile.bag)
            {
                if (item != null && item.id == id)
                {
                    if (item.count > int.MaxValue - amount) return false;
                    item.count += amount; SaveProfile(); Notify("Picked up " + id);
                    return true;
                }
            }
            if (Profile.bag.Count >= Mathf.Min(UnlockedBagSlots, MaxBagSlots))
            { Notify("Inventory full"); return false; }
            Profile.bag.Add(new BagItem { id = id, count = amount });
            SaveProfile(); Notify("Picked up " + id);
            return true;
        }

        public void SaveProfile()
        {
            try
            {
                Directory.CreateDirectory(Application.persistentDataPath);
                File.WriteAllText(SaveFile, JsonUtility.ToJson(Profile, true));
                Notify("Saved local prototype character");
            }
            catch (Exception error) { Debug.LogError("Save failed: " + error.Message); }
        }

        private void LoadProfile()
        {
            try
            {
                if (File.Exists(SaveFile))
                {
                    var loaded = JsonUtility.FromJson<LocalCharacter>(File.ReadAllText(SaveFile));
                    if (loaded != null) Profile = loaded;
                }
            }
            catch (Exception error) { Debug.LogWarning("Load failed: " + error.Message); }
            if (Profile == null) Profile = new LocalCharacter();
            if (Profile.bag == null) Profile.bag = new List<BagItem>();
            if (Profile.currency == null || Profile.currency.Length != 4)
                Profile.currency = new string[] { "0", "0", "0", "0" };
            for (int i = 0; i < 4; i++)
            {
                try { Profile.currency[i] = ExactCurrency.Normalize(Profile.currency[i]); }
                catch { Profile.currency[i] = "0"; }
            }
            Profile.level = Mathf.Max(1, Profile.level);
            Profile.exp = Mathf.Max(0, Profile.exp);
        }
    }

    [RequireComponent(typeof(CharacterController))]
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

    public sealed class PrototypeHUD : MonoBehaviour
    {
        private bool showBag;
        private Vector3 spawn = new Vector3(0f, 1.1f, 0f);
        private float respawnTime = -1f;

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.B)) showBag = !showBag;
            var player = PrototypeGame.Instance ? PrototypeGame.Instance.Player : null;
            if (player && !player.IsAlive && respawnTime < 0f) respawnTime = Time.time + 4f;
            if (player && !player.IsAlive && Time.time >= respawnTime && respawnTime >= 0f)
            {
                player.Respawn(spawn);
                respawnTime = -1f;
            }
        }

        private void OnGUI()
        {
            var game = PrototypeGame.Instance;
            if (!game) return;
            GUI.Box(new Rect(10, 10, 355, 142), "LEOONLINE — OFFLINE UNITY TEST");
            GUI.Label(new Rect(23, 39, 320, 24), "Level " + game.Profile.level + "   EXP " + game.Profile.exp + "/" + game.ExpToNextLevel());
            GUI.Label(new Rect(23, 63, 320, 24), "HP " + (game.Player ? Mathf.CeilToInt(game.Player.health).ToString() : "-") +
                "   Gold " + game.Profile.currency[0]);
            GUI.Label(new Rect(23, 87, 320, 24), "Monsters defeated: " + game.Profile.defeated);
            GUI.Label(new Rect(23, 112, 320, 25), "Bag " + game.Profile.bag.Count + "/40 unlocked (200 max)");
            GUI.Box(new Rect(10, Screen.height - 85, 510, 75), "Controls");
            GUI.Label(new Rect(22, Screen.height - 61, 490, 24), "WASD Move  Shift Sprint  Space Jump  RMB Camera");
            GUI.Label(new Rect(22, Screen.height - 38, 490, 24), "LMB Attack  E Loot  B Inventory  F5 Local Save");
            if (game.MessageUntil > Time.time)
                GUI.Box(new Rect(Screen.width / 2f - 240f, 15, 480, 34), game.Message);

            if (!showBag) return;
            float width = Mathf.Min(365f, Screen.width - 40f);
            Rect bounds = new Rect(Screen.width - width - 15f, 15f, width, 365f);
            GUI.Box(bounds, "Inventory (local development view)");
            int row = 0;
            foreach (var item in game.Profile.bag)
            {
                if (row >= 12) break;
                if (item != null)
                    GUI.Label(new Rect(bounds.x + 15, bounds.y + 35 + row * 23, width - 20, 21), item.id + " x" + item.count);
                row++;
            }
        }
    }
}
