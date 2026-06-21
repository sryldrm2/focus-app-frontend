namespace PomodoraBack.Core.Enums
{
    public enum NotificationTypeEnums
    {
        FriendRequest = 0,
        WorkspaceInvitation = 1,
        DueDateReminder = 2,

        /// <summary>
        /// Bir arkadaş Pomodoro seansı başlattığında gönderilen anlık bildirim.
        /// DB'ye kaydedilmez; yalnızca SignalR üzerinden push edilir.
        /// </summary>
        FriendStartedFocus = 3
    }
}
