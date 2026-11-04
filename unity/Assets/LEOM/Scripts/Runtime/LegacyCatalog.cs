// Auto-portable read-only game catalog. IDs and data are imported from the owner's Godot source.
// DO NOT mutate currencies or item ownership in this catalog; use LeomRpgService.
using System;
using System.Collections.Generic;
using UnityEngine;

namespace Leom.Gameplay
{
    [Serializable] public sealed class ItemDefinition
    {
        public string id, name, kind, slot, description, sell;
    }
    [Serializable] public sealed class ShopOffer
    {
        public string id, price, currency, sell;
        public int stock;
    }
    [Serializable] public sealed class JobDefinition
    {
        public string id, nameTh, nameEn, path, pathTh;
        public int tier;
    }
    [Serializable] public sealed class SkillDefinition
    {
        public string id, job, nameTh, nameEn, kind, statKey;
        public int statAmount, durationSeconds, stamina;
        public float cooldownSeconds;
        public bool implemented;
    }
    [Serializable] public sealed class LegacyCatalogFile
    {
        public int schemaVersion;
        public string origin;
        public ItemDefinition[] items;
        public ShopOffer[] offers;
        public JobDefinition[] jobs;
        public SkillDefinition[] skills;
    }
    public static class LegacyCatalog
    {
        public const int BagCapacity = 200, StorageCapacity = 200, InitialUnlocked = 40;
        public const int ShopCapacity = 500, ShopPageSize = 50;
        public static readonly string[] CurrencyIds = { "gold", "blue", "purple", "green" };
        public static readonly string[] EquipmentSlotIds =
        {
            "hat","shirt","gloves","pants","shoes","weapon_right","weapon_left",
            "bracelet_left","ring_left","necklace","ring_right","bracelet_right",
            "pet","mount","fashion_hat","fashion_shirt","fashion_gloves","fashion_pants",
            "fashion_shoes","fashion_weapon_right","fashion_weapon_left","fashion_mask","fashion_cape"
        };

        private static LegacyCatalogFile file;
        private static Dictionary<string, ItemDefinition> itemById;
        private static Dictionary<string, ShopOffer> offerById;
        private static Dictionary<string, JobDefinition> jobById;
        private static Dictionary<string, SkillDefinition> skillById;

        public static LegacyCatalogFile Data
        {
            get { EnsureLoaded(); return file; }
        }
        public static ItemDefinition Item(string id)
        {
            EnsureLoaded();
            itemById.TryGetValue(id ?? "", out var result); return result;
        }
        public static ShopOffer Offer(string id)
        {
            EnsureLoaded();
            offerById.TryGetValue(id ?? "", out var result); return result;
        }
        public static JobDefinition Job(string id)
        {
            EnsureLoaded();
            jobById.TryGetValue(id ?? "", out var result); return result;
        }
        public static SkillDefinition Skill(string id)
        {
            EnsureLoaded();
            skillById.TryGetValue(id ?? "", out var result); return result;
        }
        public static IEnumerable<SkillDefinition> SkillsForJob(string jobId)
        {
            EnsureLoaded();
            foreach (var skill in file.skills)
                if (skill.job == jobId) yield return skill;
        }
        private static void EnsureLoaded()
        {
            if (file != null) return;
            TextAsset source = Resources.Load<TextAsset>("LeomLegacyCatalog");
            if (source == null)
                throw new InvalidOperationException("Missing Resources/LeomLegacyCatalog.json (source mapping required).");
            var parsed = JsonUtility.FromJson<LegacyCatalogFile>(source.text);
            if (parsed == null || parsed.items == null || parsed.offers == null || parsed.jobs == null || parsed.skills == null)
                throw new InvalidOperationException("LEOM game catalog has an invalid schema.");
            var items = new Dictionary<string, ItemDefinition>(StringComparer.Ordinal);
            var offers = new Dictionary<string, ShopOffer>(StringComparer.Ordinal);
            var jobs = new Dictionary<string, JobDefinition>(StringComparer.Ordinal);
            var skills = new Dictionary<string, SkillDefinition>(StringComparer.Ordinal);
            foreach (var value in parsed.items) items.Add(value.id, value);
            foreach (var value in parsed.offers) offers.Add(value.id, value);
            foreach (var value in parsed.jobs) jobs.Add(value.id, value);
            foreach (var value in parsed.skills) skills.Add(value.id, value);
            file = parsed; itemById = items; offerById = offers; jobById = jobs; skillById = skills;
        }
    }
}
