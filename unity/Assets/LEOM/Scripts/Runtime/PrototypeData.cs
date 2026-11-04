using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Leom.Prototype
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
}
