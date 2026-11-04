// Exact unsigned 21-digit decimal arithmetic for the local economy.
// Use database transactions + server authority for any online economy.
using System;

namespace Leom.Gameplay
{
    public static class LeomAmount
    {
        public const string Maximum = "999999999999999999999";
        public static string Normalize(string input)
        {
            if (string.IsNullOrEmpty(input)) throw new ArgumentException("Amount cannot be empty");
            for (int i = 0; i < input.Length; i++)
                if (input[i] < '0' || input[i] > '9')
                    throw new ArgumentException("Only decimal digits are allowed");
            string result = input.TrimStart('0');
            if (result.Length == 0) result = "0";
            if (result.Length > 21) throw new OverflowException("21 digit currency maximum exceeded");
            return result;
        }
        public static int Compare(string a, string b)
        {
            a = Normalize(a); b = Normalize(b);
            if (a.Length != b.Length) return a.Length.CompareTo(b.Length);
            return string.CompareOrdinal(a, b);
        }
        public static string Add(string a, string b)
        {
            a = Normalize(a); b = Normalize(b);
            int ia = a.Length - 1, ib = b.Length - 1, carry = 0;
            char[] buffer = new char[Math.Max(a.Length,b.Length) + 1];
            int write = buffer.Length;
            while (ia >= 0 || ib >= 0 || carry != 0)
            {
                int digit = carry;
                if (ia >= 0) digit += a[ia--] - '0';
                if (ib >= 0) digit += b[ib--] - '0';
                buffer[--write] = (char)('0' + digit % 10);
                carry = digit / 10;
            }
            return Normalize(new string(buffer, write, buffer.Length - write));
        }
        public static string Subtract(string a, string b)
        {
            a = Normalize(a); b = Normalize(b);
            if (Compare(a,b) < 0) throw new InvalidOperationException("Insufficient amount");
            char[] buffer = new char[a.Length];
            int ia = a.Length - 1, ib = b.Length - 1, borrow = 0;
            while (ia >= 0)
            {
                int digit = a[ia] - '0' - borrow;
                int other = ib >= 0 ? b[ib] - '0' : 0;
                if (digit < other) { digit += 10; borrow = 1; }
                else borrow = 0;
                buffer[ia] = (char)('0' + (digit - other));
                ia--; ib--;
            }
            return Normalize(new string(buffer));
        }
        public static bool TryAdd(string a, string b, out string result)
        {
            try { result = Add(a,b); return true; }
            catch (ArgumentException) { result = null; return false; }
            catch (OverflowException) { result = null; return false; }
        }
        public static string Format(string number)
        {
            number = Normalize(number);
            var output = new System.Text.StringBuilder();
            for (int i = 0; i < number.Length; i++)
            {
                if (i > 0 && (number.Length - i) % 3 == 0) output.Append(',');
                output.Append(number[i]);
            }
            return output.ToString();
        }
    }
}
