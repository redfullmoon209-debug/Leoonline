// Compatibility adapter for the first offline PvE demo. Inventory/EXP now route into LeomRpgService.
using UnityEngine;
using Leom.Gameplay;

namespace Leom.Prototype
{
    public sealed class PrototypeGame : MonoBehaviour
    {
        public static PrototypeGame Instance { get; private set; }
        public LeomPlayer Player { get; private set; }
        public LocalCharacter Profile { get; private set; } = new LocalCharacter();
        public string Message { get; private set; } = "Welcome to LEOM offline test";
        public float MessageUntil { get; private set; }

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(this); return; }
            Instance = this;
        }
        private LeomRpgService Rpg => GetComponent<LeomRpgService>();
        public void AttachPlayer(LeomPlayer player) { Player = player; }
        public void Notify(string message)
        {
            Message = message; MessageUntil = Time.time + 4f;
            Rpg?.Tell(message);
        }
        public int ExpToNextLevel() => Rpg != null ? Rpg.ExperienceRequired() : 100;
        public void RewardMonster(int exp, string currencyAmount) => Rpg?.RewardMonster(exp, currencyAmount);
        public bool AddItem(string id, int amount) => Rpg != null && Rpg.AddItem(id, amount);
        public void SaveProfile()
        {
            Rpg?.SaveLocal();
            Notify("Saved locally");
        }
    }
}
