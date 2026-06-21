using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PomodoraBack.Migrations
{
    /// <inheritdoc />
    public partial class AddPomodoroCountsToTask : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CompletedPomodoroCount",
                table: "Tasks",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PomodoroTargetCount",
                table: "Tasks",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CompletedPomodoroCount",
                table: "Tasks");

            migrationBuilder.DropColumn(
                name: "PomodoroTargetCount",
                table: "Tasks");
        }
    }
}
