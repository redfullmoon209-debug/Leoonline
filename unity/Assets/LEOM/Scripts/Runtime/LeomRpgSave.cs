// Serializable Unity-local RPG schema. Maintains stable Godot item/job/skill IDs.
using System;
using System.Collections.Generic;

namespace Leom.Gameplay
{
    [Serializable] public sealed class LeomEquipment
    {
        public string slot;
        public string itemId;
    }
    [Serializable] public sealed class LeomSkillLevel
    {
        public string skillId;
        public int level;
    }
    [Serializable] public sealed class LeomRpgSave
    {
        public int schemaVersion = 2;
        public string name = "Adventurer";
        public int level = 1;
        public int experience = 0;
        public int classTier = 0;
        public string job = "Novice";
        public string path = "Unchosen";
        public string faction = "None";
        public int statPoints = 0, skillPoints = 0;
        public int strength = 10, vitality = 10, agility = 10;
        public int intelligence = 10, dexterity = 10, luck = 10;
        public int pveKills = 0, pvpWins = 0, pvpLosses = 0;
        public string[] bag = new string[200];
        public string[] storage = new string[200];
        public int unlocked = 40;
        public float secondsOnline = 0f;
        public float nextRewardSeconds = 18000f;
        public string[] wallet = { "0", "0", "0", "0" };
        public string[] vault = { "0", "0", "0", "0" };
        public List<LeomEquipment> equipment = new List<LeomEquipment>();
        public string[] skillHotbar = { "novice_slash", "novice_rush", "novice_guard" };
        public List<LeomSkillLevel> passiveLevels = new List<LeomSkillLevel>();
    }
}
