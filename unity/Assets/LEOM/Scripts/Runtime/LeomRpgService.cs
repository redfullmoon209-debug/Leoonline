// LOCAL gameplay port of Godot store.gd, shop_service.gd and profile systems.
// Local saves are untrusted client data. Do NOT reuse this as an MMORPG authority.
using System;
using System.Collections.Generic;
using UnityEngine;

namespace Leom.Gameplay
{
    public sealed class LeomRpgService : MonoBehaviour
    {
        private const string SaveKey = "LEOM_OFFLINE_RPG_V2";
        public static LeomRpgService Instance { get; private set; }
        public LeomRpgSave Character { get; private set; }
        public string PreviewJob { get; private set; } = "";
        public string Notice { get; private set; } = "Welcome to LEOM offline RPG test";
        public float NoticeUntil { get; private set; }
        public event Action Changed;
        private readonly Dictionary<string, float> activeBuffs = new Dictionary<string, float>();
        private float saveTimer;

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(this); return; }
            Instance = this;
            Restore();
        }
        private void Update()
        {
            if (Character == null) return;
            Character.secondsOnline += Time.deltaTime;
            if (Character.unlocked < LegacyCatalog.BagCapacity && Character.secondsOnline >= Character.nextRewardSeconds)
            {
                Character.unlocked = Mathf.Min(200, Character.unlocked + 10);
                Character.nextRewardSeconds += 18000f;
                Tell("Unlocked +10 bag slots after five active hours");
                SaveLocal();
            }
            saveTimer += Time.deltaTime;
            if (saveTimer >= 30f) { saveTimer = 0f; SaveLocal(); }
            if (activeBuffs.Count > 0)
            {
                var expired = new List<string>();
                foreach (var buff in activeBuffs)
                    if (Time.time >= buff.Value) expired.Add(buff.Key);
                foreach (var buff in expired) activeBuffs.Remove(buff);
            }
            if (Input.GetKeyDown(KeyCode.F5)) { SaveLocal(); Tell("Game saved locally"); }
        }
        private void OnApplicationPause(bool pause) { if (pause) SaveLocal(); }
        private void OnApplicationQuit() { SaveLocal(); }

        private void Restore()
        {
            try
            {
                string json = PlayerPrefs.GetString(SaveKey, "");
                Character = string.IsNullOrEmpty(json) ? new LeomRpgSave() : JsonUtility.FromJson<LeomRpgSave>(json);
                if (Character == null) Character = new LeomRpgSave();
                Validate();
            }
            catch (Exception e)
            {
                Debug.LogWarning("[LEOM] Invalid local save; resetting: " + e.Message);
                Character = new LeomRpgSave();
                Validate();
            }
        }
        private void Validate()
        {
            if (Character.bag == null || Character.bag.Length != 200) Character.bag = Resize(Character.bag, 200);
            if (Character.storage == null || Character.storage.Length != 200) Character.storage = Resize(Character.storage, 200);
            Character.unlocked = Mathf.Clamp(Character.unlocked, 40, 200);
            Character.unlocked = 40 + ((Character.unlocked - 40) / 10) * 10;
            Character.level = Mathf.Clamp(Character.level, 1, 999);
            Character.experience = Mathf.Max(0, Character.experience);
            Character.secondsOnline = Mathf.Max(0, Character.secondsOnline);
            if (Character.nextRewardSeconds < 18000) Character.nextRewardSeconds = 18000;
            if (Character.wallet == null || Character.wallet.Length != 4) Character.wallet = new[] { "0", "0", "0", "0" };
            if (Character.vault == null || Character.vault.Length != 4) Character.vault = new[] { "0", "0", "0", "0" };
            for (int i = 0; i < 4; i++)
            {
                try { Character.wallet[i] = LeomAmount.Normalize(Character.wallet[i]); }
                catch { Character.wallet[i] = "0"; }
                try { Character.vault[i] = LeomAmount.Normalize(Character.vault[i]); }
                catch { Character.vault[i] = "0"; }
            }
            if (Character.equipment == null) Character.equipment = new List<LeomEquipment>();
            if (Character.passiveLevels == null) Character.passiveLevels = new List<LeomSkillLevel>();
            if (Character.skillHotbar == null || Character.skillHotbar.Length != 3)
                Character.skillHotbar = new[] { "novice_slash", "novice_rush", "novice_guard" };
            if (LegacyCatalog.Job(Character.job) == null) Character.job = "Novice";
        }
        private static string[] Resize(string[] old, int count)
        {
            string[] result = new string[count];
            if (old != null) Array.Copy(old, result, Math.Min(count, old.Length));
            return result;
        }
        public void SaveLocal()
        {
            if (Character == null) return;
            try
            {
                PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(Character));
                PlayerPrefs.Save();
                Changed?.Invoke();
            }
            catch (Exception e) { Debug.LogWarning("[LEOM] Local save unsuccessful: " + e.Message); }
        }
        public void Tell(string message)
        {
            Notice = message;
            NoticeUntil = Time.time + 4.5f;
            Debug.Log("[LEOM] " + message);
        }
        public int ExperienceRequired() => 100 + Math.Max(0, Character.level - 1) * 50;
        public void GainExperience(int value)
        {
            if (value <= 0) return;
            Character.experience = Math.Min(int.MaxValue - value, Character.experience) + value;
            while (Character.level < 999 && Character.experience >= ExperienceRequired())
            {
                Character.experience -= ExperienceRequired();
                Character.level++;
                Character.statPoints++; Character.skillPoints++;
                Tell("LEVEL UP! " + Character.level);
            }
            if (Character.level >= 999) Character.experience = Math.Min(Character.experience, ExperienceRequired() - 1);
            SaveLocal();
        }
        public void RewardMonster(int exp, string gold)
        {
            Character.pveKills++;
            GainExperience(exp);
            if (TryCredit("gold", gold)) Tell("Defeated monster: +" + exp + " EXP, +" + gold + " Gold");
        }
        public int CurrencyIndex(string key) => Array.IndexOf(LegacyCatalog.CurrencyIds, key);
        public string Balance(string key, bool stored = false)
        {
            int i = CurrencyIndex(key);
            return i >= 0 ? (stored ? Character.vault[i] : Character.wallet[i]) : "0";
        }
        public bool TryCredit(string key, string amount, bool stored = false)
        {
            int i = CurrencyIndex(key);
            if (i < 0) return false;
            string[] balances = stored ? Character.vault : Character.wallet;
            if (!LeomAmount.TryAdd(balances[i], amount, out string result)) return false;
            balances[i] = result; SaveLocal();
            return true;
        }
        public bool TrySpend(string key, string amount, bool stored = false)
        {
            int i = CurrencyIndex(key);
            if (i < 0) return false;
            string[] balances = stored ? Character.vault : Character.wallet;
            try
            {
                if (LeomAmount.Compare(balances[i], amount) < 0) return false;
                balances[i] = LeomAmount.Subtract(balances[i], amount);
                SaveLocal(); return true;
            }
            catch (Exception) { return false; }
        }
        public bool TransferMoney(string kind, string amount, bool withdraw)
        {
            int i = CurrencyIndex(kind);
            if (i < 0) return Fail("Unknown currency");
            try
            {
                amount = LeomAmount.Normalize((amount ?? "").Trim());
                if (amount == "0") return Fail("Enter a positive amount");
                string[] src = withdraw ? Character.vault : Character.wallet;
                string[] dst = withdraw ? Character.wallet : Character.vault;
                if (LeomAmount.Compare(src[i], amount) < 0) return Fail("Not enough money");
                if (!LeomAmount.TryAdd(dst[i], amount, out string credited)) return Fail("Destination limit reached");
                string debited = LeomAmount.Subtract(src[i], amount);
                src[i] = debited; dst[i] = credited;
                SaveLocal(); Tell(withdraw ? "Money withdrawn" : "Money deposited");
                return true;
            }
            catch (Exception) { return Fail("Invalid amount"); }
        }
        public int FindEmptyBag()
        {
            for (int i = 0; i < Character.unlocked; i++)
                if (string.IsNullOrEmpty(Character.bag[i])) return i;
            return -1;
        }
        public int FindEmptyStorage()
        {
            for (int i = 0; i < Character.storage.Length; i++)
                if (string.IsNullOrEmpty(Character.storage[i])) return i;
            return -1;
        }
        public bool AddItem(string id, int amount = 1)
        {
            if (LegacyCatalog.Item(id) == null || amount < 1 || amount > 200) return Fail("Unknown item");
            int free = 0;
            for (int i = 0; i < Character.unlocked; i++)
                if (string.IsNullOrEmpty(Character.bag[i])) free++;
            if (free < amount) return Fail("Not enough bag slots");
            for (int i = 0; i < amount; i++) Character.bag[FindEmptyBag()] = id;
            SaveLocal(); Tell("Collected: " + LegacyCatalog.Item(id).name);
            return true;
        }
        public bool DepositItem(int index)
        {
            if (!Occupied(Character.bag, index, Character.unlocked)) return false;
            int destination = FindEmptyStorage();
            if (destination < 0) return Fail("Storage is full");
            Character.storage[destination] = Character.bag[index];
            Character.bag[index] = "";
            SaveLocal(); Tell("Item deposited");
            return true;
        }
        public bool WithdrawItem(int index)
        {
            if (!Occupied(Character.storage, index, 200)) return false;
            int destination = FindEmptyBag();
            if (destination < 0) return Fail("Bag is full");
            Character.bag[destination] = Character.storage[index];
            Character.storage[index] = "";
            SaveLocal(); Tell("Item withdrawn");
            return true;
        }
        private static bool Occupied(string[] values, int index, int limit) =>
            values != null && index >= 0 && index < limit && !string.IsNullOrEmpty(values[index]);
        public bool TrashItem(int index)
        {
            if (!Occupied(Character.bag, index, Character.unlocked)) return false;
            Character.bag[index] = ""; SaveLocal(); Tell("Item discarded");
            return true;
        }
        public void SortBag()
        {
            var valid = new List<string>();
            for (int i = 0; i < Character.unlocked; i++)
            {
                if (!string.IsNullOrEmpty(Character.bag[i])) valid.Add(Character.bag[i]);
                Character.bag[i] = "";
            }
            valid.Sort((a,b) =>
            {
                int weightA = Weight(LegacyCatalog.Item(a));
                int weightB = Weight(LegacyCatalog.Item(b));
                int c = weightA.CompareTo(weightB);
                return c != 0 ? c : string.CompareOrdinal(a,b);
            });
            for (int i = 0; i < valid.Count; i++) Character.bag[i] = valid[i];
            SaveLocal(); Tell("Inventory sorted");
        }
        private static int Weight(ItemDefinition item)
        {
            if (item?.kind == "weapon") return 0;
            if (item?.kind == "armor") return 1;
            return 2;
        }
        public bool UnlockWithScroll()
        {
            if (Character.unlocked >= 200) return Fail("All bag slots already unlocked");
            for (int i = 0; i < Character.unlocked; i++)
            {
                if (Character.bag[i] != "scroll") continue;
                Character.bag[i] = ""; Character.unlocked = Math.Min(200, Character.unlocked + 10);
                SaveLocal(); Tell("Bag +10 slots unlocked");
                return true;
            }
            return Fail("Bag +10 Scroll required");
        }
        public string Equipped(string slot)
        {
            var entry = Character.equipment.Find(x => x.slot == slot);
            return entry == null ? "" : entry.itemId;
        }
        public bool EquipItem(int index)
        {
            if (!Occupied(Character.bag, index, Character.unlocked)) return false;
            ItemDefinition info = LegacyCatalog.Item(Character.bag[index]);
            if (info == null || string.IsNullOrEmpty(info.slot)) return Fail("Item cannot be equipped");
            var entry = Character.equipment.Find(x => x.slot == info.slot);
            if (entry == null)
            {
                Character.equipment.Add(new LeomEquipment { slot = info.slot, itemId = Character.bag[index] });
                Character.bag[index] = "";
            }
            else
            {
                string previous = entry.itemId;
                entry.itemId = Character.bag[index];
                Character.bag[index] = previous;
            }
            SaveLocal(); Tell("Equipped: " + info.name);
            return true;
        }
        public bool UnequipItem(string slot)
        {
            var entry = Character.equipment.Find(x => x.slot == slot);
            int empty = FindEmptyBag();
            if (entry == null || empty < 0) return Fail("Need an empty bag slot");
            Character.bag[empty] = entry.itemId;
            Character.equipment.Remove(entry);
            SaveLocal(); Tell("Unequipped");
            return true;
        }
        public bool BuyItem(string id)
        {
            ShopOffer offer = LegacyCatalog.Offer(id);
            if (offer == null || LegacyCatalog.Item(id) == null) return Fail("Not for sale");
            int empty = FindEmptyBag();
            if (empty < 0) return Fail("Bag is full");
            int cur = CurrencyIndex(offer.currency);
            if (cur < 0) return Fail("Invalid shop currency");
            try
            {
                if (LeomAmount.Compare(Character.wallet[cur], offer.price) < 0) return Fail("Not enough money");
                string after = LeomAmount.Subtract(Character.wallet[cur], offer.price);
                Character.wallet[cur] = after;
                Character.bag[empty] = id;
                SaveLocal(); Tell("Purchased: " + LegacyCatalog.Item(id).name);
                return true;
            }
            catch (Exception) { return Fail("Purchase rejected"); }
        }
        public bool SellItem(int bagIndex)
        {
            if (!Occupied(Character.bag, bagIndex, Character.unlocked)) return false;
            string id = Character.bag[bagIndex];
            ItemDefinition item = LegacyCatalog.Item(id);
            if (item == null) return Fail("Unknown item");
            if (!LeomAmount.TryAdd(Character.wallet[0], item.sell, out string gold))
                return Fail("Gold limit reached");
            Character.wallet[0] = gold;
            Character.bag[bagIndex] = "";
            SaveLocal(); Tell("Sold " + item.name + " for " + item.sell + " Gold");
            return true;
        }
        public bool UsePotion(int bagIndex, Leom.Prototype.LeomPlayer player)
        {
            if (!Occupied(Character.bag, bagIndex, Character.unlocked) || player == null) return false;
            string id = Character.bag[bagIndex];
            float hp = id == "hp_potion_small" ? 30 : id == "hp_potion_medium" ? 75 : id == "hp_potion_large" ? 150 : 0;
            float sp = id == "sp_potion_small" ? 25 : id == "sp_potion_medium" ? 60 : id == "sp_potion_large" ? 100 : 0;
            if (hp <= 0 && sp <= 0) return Fail("Cannot use this item");
            if (hp > 0) player.health = Mathf.Min(player.maxHealth, player.health + hp);
            if (sp > 0) player.RestoreStamina(sp);
            Character.bag[bagIndex] = "";
            SaveLocal(); Tell("Used " + LegacyCatalog.Item(id).name);
            return true;
        }
        public bool SetPreviewJob(string jobId)
        {
            if (jobId != "" && LegacyCatalog.Job(jobId) == null) return false;
            PreviewJob = jobId;
            Tell(jobId == "" ? "Class preview cleared" : "Class preview only: " + jobId);
            return true;
        }
        public string ActiveJob => string.IsNullOrEmpty(PreviewJob) ? Character.job : PreviewJob;
        public bool ChangeProfession(string jobId)
        {
            var dest = LegacyCatalog.Job(jobId);
            if (dest == null || dest.tier <= 0) return Fail("Invalid profession");
            if (dest.tier == 1 && Character.job != "Novice") return Fail("Profession already chosen");
            if (dest.tier == 1 && Character.level < 10) return Fail("Tier 1 requires level 10");
            if (dest.tier == 2 && (Character.classTier != 1 || Character.path != dest.path))
                return Fail("Must follow current profession path");
            if (dest.tier == 2 && Character.level < 50) return Fail("Tier 2 requires level 50");
            Character.job = dest.id; Character.path = dest.path; Character.classTier = dest.tier;
            PreviewJob = "";
            Character.skillHotbar = new[] { "", "", "" };
            SaveLocal(); Tell("Profession selected: " + dest.nameEn);
            return true;
        }
        public int PassiveLevel(string skillId)
        {
            var record = Character.passiveLevels.Find(x => x.skillId == skillId);
            return record == null ? 0 : record.level;
        }
        public bool UpgradePassive(string id)
        {
            var skill = LegacyCatalog.Skill(id);
            if (skill == null || skill.job != Character.job || skill.kind != "passive")
                return Fail("Only real profession passives can be upgraded");
            int rank = PassiveLevel(id);
            if (rank >= 10) return Fail("Passive level max 10");
            string price = ((rank + 1) * 200).ToString();
            if (Character.skillPoints < 1 || LeomAmount.Compare(Character.wallet[0], price) < 0)
                return Fail("Requires one Skill Point and " + price + " Gold");
            Character.skillPoints--;
            Character.wallet[0] = LeomAmount.Subtract(Character.wallet[0], price);
            var record = Character.passiveLevels.Find(x => x.skillId == id);
            if (record == null) Character.passiveLevels.Add(new LeomSkillLevel { skillId = id, level = 1 });
            else record.level++;
            SaveLocal(); Tell("Passive upgraded: " + skill.nameEn);
            return true;
        }
        public bool EquipHotbar(int index, string skillId)
        {
            if (index < 0 || index >= 3) return false;
            var skill = LegacyCatalog.Skill(skillId);
            if (skill == null || skill.job != Character.job || skill.kind == "passive")
                return Fail("Only own active skills can be equipped");
            Character.skillHotbar[index] = skillId; SaveLocal();
            return true;
        }
        public bool ActivateTimedBuff(string skillId)
        {
            var skill = LegacyCatalog.Skill(skillId);
            if (skill == null || skill.job != Character.job || skill.kind != "timed_buff") return false;
            activeBuffs[skill.id] = Time.time + Mathf.Clamp(skill.durationSeconds, 60, 180);
            Tell("Active buff: " + skill.nameEn);
            return true;
        }
        public int EffectiveAttribute(string key)
        {
            int amount = key == "strength" ? Character.strength
                : key == "vitality" ? Character.vitality
                : key == "agility" ? Character.agility
                : key == "intelligence" ? Character.intelligence
                : key == "dexterity" ? Character.dexterity : Character.luck;
            foreach (var level in Character.passiveLevels)
            {
                SkillDefinition skill = LegacyCatalog.Skill(level.skillId);
                if (skill != null && skill.statKey == key && skill.job == Character.job)
                    amount += skill.statAmount * Mathf.Clamp(level.level, 0, 10);
            }
            foreach (var buff in activeBuffs)
            {
                SkillDefinition skill = LegacyCatalog.Skill(buff.Key);
                if (skill != null && skill.statKey == key)
                    amount += skill.statAmount;
            }
            return amount;
        }
        public bool AddAttribute(string key)
        {
            if (Character.statPoints <= 0) return Fail("Not enough stat points");
            switch (key)
            {
                case "strength": Character.strength++; break;
                case "vitality": Character.vitality++; break;
                case "agility": Character.agility++; break;
                case "intelligence": Character.intelligence++; break;
                case "dexterity": Character.dexterity++; break;
                case "luck": Character.luck++; break;
                default: return false;
            }
            Character.statPoints--; SaveLocal(); return true;
        }
        private bool Fail(string reason) { Tell(reason); return false; }
    }
}
