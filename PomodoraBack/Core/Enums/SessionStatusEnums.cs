namespace PomodoraBack.Core.Enums
{
    public enum SessionStatusEnums
    {
        OnGoing = 0,          // Devam ediyor
        Successful = 1,       // Başarıyla tamamlandı
        Incomplete = 2,       // Yarıda kesildi / Tamamlanmadı
        Cancelled = 3         // İptal edildi

    }
}
