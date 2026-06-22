using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;
using PomodoraBack.Core.Constants;
using PomodoraBack.Core.Enums;
using PomodoraBack.Hubs;

namespace PomodoraBack.Benchmarks
{
    [MemoryDiagnoser] // Bellek (RAM) tahsisatlarını (Allocation) da ölçecek
    public class SystemBenchmarks
    {
        private const string SampleUserId = "5d57b5fb-4977-4cf0-a292-6f2cf331e89e";
        private const string SampleWorkspaceId = "1a2b3c4d-5e6f-7g8h-9i0j-1k2l3m4n5o6p";

        // 1. Benchmark: SignalR Grup İsmi Üretimi (String Interpolation Performansı)
        [Benchmark]
        public string GetUserGroupName_Benchmark()
        {
            return NotificationHub.GetUserGroupName(SampleUserId);
        }

        [Benchmark]
        public string GetWorkspaceGroupName_Benchmark()
        {
            return NotificationHub.GetWorkspaceGroupName(SampleWorkspaceId);
        }

        // 2. Benchmark: Pomodoro Puan Hesaplama Hızı
        [Benchmark]
        public int CalculatePoints_WorkSession_Benchmark()
        {
            return PomodoroConstants.CalculatePoints(25, PomodoroTypeEnums.WorkSession);
        }

        [Benchmark]
        public int CalculatePoints_CustomSession_Benchmark()
        {
            return PomodoroConstants.CalculatePoints(45, PomodoroTypeEnums.WorkSession);
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            // Benchmark testlerini çalıştırır
            var summary = BenchmarkRunner.Run<SystemBenchmarks>();
        }
    }
}
