```

BenchmarkDotNet v0.14.0, Windows 11 (10.0.26200.8655)
12th Gen Intel Core i7-12650H, 1 CPU, 16 logical and 10 physical cores
.NET SDK 9.0.313
  [Host]     : .NET 9.0.15 (9.0.1526.17522), X64 RyuJIT AVX2
  DefaultJob : .NET 9.0.15 (9.0.1526.17522), X64 RyuJIT AVX2


```
| Method                                  | Mean      | Error     | StdDev    | Median    | Gen0   | Allocated |
|---------------------------------------- |----------:|----------:|----------:|----------:|-------:|----------:|
| GetUserGroupName_Benchmark              | 8.5484 ns | 0.2103 ns | 0.1967 ns | 8.4980 ns | 0.0083 |     104 B |
| GetWorkspaceGroupName_Benchmark         | 9.6056 ns | 0.2306 ns | 0.6196 ns | 9.4693 ns | 0.0096 |     120 B |
| CalculatePoints_WorkSession_Benchmark   | 0.0053 ns | 0.0079 ns | 0.0074 ns | 0.0000 ns |      - |         - |
| CalculatePoints_CustomSession_Benchmark | 0.0401 ns | 0.0184 ns | 0.0172 ns | 0.0382 ns |      - |         - |
