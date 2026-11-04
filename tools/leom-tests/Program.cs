using System;
using Leom.Gameplay;
static class Program
{
    static int testCount;
    static void Assert(bool ok, string desc)
    {
        if(!ok) throw new Exception("FAIL: " + desc);
        Console.WriteLine("PASS: " + desc);
        testCount++;
    }
    static void Throws<T>(Action operation, string desc) where T: Exception
    {
        try { operation(); }
        catch (T) { Assert(true,desc); return; }
        Assert(false,desc);
    }
    public static void Main()
    {
        Assert(LeomAmount.Normalize("0000123")=="123","trim leading zeros");
        Assert(LeomAmount.Normalize("000")=="0","normalize zero");
        Assert(LeomAmount.Compare("2","10")<0,"compare exact amounts");
        Assert(LeomAmount.Compare("000000999","999")==0,"compare normalized");
        Assert(LeomAmount.Add("999","1")=="1000","carry across digits");
        Assert(LeomAmount.Add(LeomAmount.Maximum,"0")==LeomAmount.Maximum,"21 digit cap exact");
        Assert(!LeomAmount.TryAdd(LeomAmount.Maximum,"1",out _),"over cap rejected");
        Assert(LeomAmount.Subtract("100000000000000000000","1")=="99999999999999999999","21 digit borrow");
        Throws<InvalidOperationException>(()=>LeomAmount.Subtract("10","11"),"negative balance rejected");
        Throws<ArgumentException>(()=>LeomAmount.Normalize("-1"),"negative input rejected");
        Throws<ArgumentException>(()=>LeomAmount.Normalize("3.5"),"float input rejected");
        Throws<OverflowException>(()=>LeomAmount.Normalize("1000000000000000000000"),"22 digits rejected");
        var character = new LeomRpgSave();
        Assert(character.bag.Length==200 && character.storage.Length==200,"200 bag and 200 storage slots");
        Assert(character.unlocked==40,"40 initial unlocked slots");
        Assert(character.wallet.Length==4 && character.vault.Length==4,"four exact currency accounts in wallet/vault");
        Assert(character.job=="Novice" && character.skillHotbar.Length==3,"Novice character with three skills");
        Console.WriteLine("LEOM core test count: "+testCount);
    }
}
