using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Leoonline.Prototype
{
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
}
