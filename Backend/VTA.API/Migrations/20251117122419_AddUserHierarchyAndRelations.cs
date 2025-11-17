using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VTA.API.Migrations
{
    /// <inheritdoc />
    public partial class AddUserHierarchyAndRelations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "user",
                columns: table => new
                {
                    id = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    password = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    firstName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    lastName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    role = table.Column<int>(type: "int", maxLength: 50, nullable: false),
                    name = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    guardianKey = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    username = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    UserType = table.Column<string>(type: "varchar(13)", maxLength: 13, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    relationType = table.Column<int>(type: "int", maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PRIMARY", x => x.id);
                })
                .Annotation("MySql:CharSet", "utf8mb4")
                .Annotation("Relational:Collation", "utf8mb4_0900_ai_ci");

            migrationBuilder.CreateTable(
                name: "category",
                columns: table => new
                {
                    categoryId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    categoryIndex = table.Column<byte>(type: "tinyint unsigned", nullable: true),
                    userId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    name = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    imagePath = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    modifiedDate = table.Column<DateTime>(type: "datetime", nullable: true),
                    usageCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    lastUsedDate = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PRIMARY", x => x.categoryId);
                    table.ForeignKey(
                        name: "category_ibfk_1",
                        column: x => x.userId,
                        principalTable: "user",
                        principalColumn: "id");
                })
                .Annotation("MySql:CharSet", "utf8mb4")
                .Annotation("Relational:Collation", "utf8mb4_0900_ai_ci");

            migrationBuilder.CreateTable(
                name: "relation",
                columns: table => new
                {
                    relationId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    studentId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    relativeId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    relationType = table.Column<int>(type: "int", maxLength: 50, nullable: false),
                    status = table.Column<int>(type: "int", maxLength: 50, nullable: false),
                    createdAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    updatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PRIMARY", x => x.relationId);
                    table.ForeignKey(
                        name: "relation_ibfk_relative",
                        column: x => x.relativeId,
                        principalTable: "user",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "relation_ibfk_student",
                        column: x => x.studentId,
                        principalTable: "user",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4")
                .Annotation("Relational:Collation", "utf8mb4_0900_ai_ci");

            migrationBuilder.CreateTable(
                name: "savedBoard",
                columns: table => new
                {
                    id = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    name = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    userId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    snapshotPath = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    createdDate = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    modifiedDate = table.Column<DateTime>(type: "datetime", nullable: true),
                    savedArtefactIds = table.Column<string>(type: "json", nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    artefactIds = table.Column<string>(type: "json", nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PRIMARY", x => x.id);
                    table.ForeignKey(
                        name: "savedBoard_ibfk_1",
                        column: x => x.userId,
                        principalTable: "user",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4")
                .Annotation("Relational:Collation", "utf8mb4_0900_ai_ci");

            migrationBuilder.CreateTable(
                name: "artefact",
                columns: table => new
                {
                    artefactId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    artefactIndex = table.Column<ushort>(type: "smallint unsigned", nullable: false),
                    userID = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    categoryId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    imagePath = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    soundPath = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    modifiedDate = table.Column<DateTime>(type: "datetime", nullable: true),
                    name = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    nameShown = table.Column<bool>(type: "tinyint(1)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PRIMARY", x => x.artefactId);
                    table.ForeignKey(
                        name: "artefact_ibfk_1",
                        column: x => x.userID,
                        principalTable: "user",
                        principalColumn: "id");
                    table.ForeignKey(
                        name: "artefact_ibfk_2",
                        column: x => x.categoryId,
                        principalTable: "category",
                        principalColumn: "categoryId",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4")
                .Annotation("Relational:Collation", "utf8mb4_0900_ai_ci");

            migrationBuilder.CreateTable(
                name: "invite",
                columns: table => new
                {
                    inviteId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    createdAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    expiresAt = table.Column<DateTime>(type: "datetime", nullable: false),
                    createdBy = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    relationId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    status = table.Column<int>(type: "int", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PRIMARY", x => x.inviteId);
                    table.ForeignKey(
                        name: "FK_invite_relation_relationId",
                        column: x => x.relationId,
                        principalTable: "relation",
                        principalColumn: "relationId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "invite_ibfk_user",
                        column: x => x.createdBy,
                        principalTable: "user",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4")
                .Annotation("Relational:Collation", "utf8mb4_0900_ai_ci");

            migrationBuilder.CreateTable(
                name: "savedArtefact",
                columns: table => new
                {
                    id = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    artefactId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    boardId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    posX = table.Column<float>(type: "float", nullable: false, defaultValue: 0f),
                    posY = table.Column<float>(type: "float", nullable: false, defaultValue: 0f),
                    width = table.Column<float>(type: "float", nullable: false, defaultValue: 200f),
                    height = table.Column<float>(type: "float", nullable: false, defaultValue: 200f),
                    createdDate = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PRIMARY", x => x.id);
                    table.ForeignKey(
                        name: "savedArtefact_ibfk_1",
                        column: x => x.artefactId,
                        principalTable: "artefact",
                        principalColumn: "artefactId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "savedArtefact_ibfk_2",
                        column: x => x.boardId,
                        principalTable: "savedBoard",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4")
                .Annotation("Relational:Collation", "utf8mb4_0900_ai_ci");

            migrationBuilder.CreateTable(
                name: "session",
                columns: table => new
                {
                    id = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    inviteId = table.Column<int>(type: "int", nullable: true),
                    relationId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: false, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    boardId = table.Column<string>(type: "varchar(36)", maxLength: 36, nullable: true, collation: "utf8mb4_0900_ai_ci")
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    status = table.Column<int>(type: "int", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PRIMARY", x => x.id);
                    table.ForeignKey(
                        name: "FK_session_invite_inviteId",
                        column: x => x.inviteId,
                        principalTable: "invite",
                        principalColumn: "inviteId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_session_relation_relationId",
                        column: x => x.relationId,
                        principalTable: "relation",
                        principalColumn: "relationId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "session_ibfk_board",
                        column: x => x.boardId,
                        principalTable: "savedBoard",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                })
                .Annotation("MySql:CharSet", "utf8mb4")
                .Annotation("Relational:Collation", "utf8mb4_0900_ai_ci");

            migrationBuilder.CreateIndex(
                name: "categoryId",
                table: "artefact",
                column: "categoryId");

            migrationBuilder.CreateIndex(
                name: "userId",
                table: "artefact",
                column: "userID");

            migrationBuilder.CreateIndex(
                name: "userId1",
                table: "category",
                column: "userId");

            migrationBuilder.CreateIndex(
                name: "createdBy",
                table: "invite",
                column: "createdBy");

            migrationBuilder.CreateIndex(
                name: "IX_invite_relationId",
                table: "invite",
                column: "relationId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "relationId",
                table: "invite",
                column: "relationId");

            migrationBuilder.CreateIndex(
                name: "relativeId",
                table: "relation",
                column: "relativeId");

            migrationBuilder.CreateIndex(
                name: "studentId",
                table: "relation",
                column: "studentId");

            migrationBuilder.CreateIndex(
                name: "artefactId",
                table: "savedArtefact",
                column: "artefactId");

            migrationBuilder.CreateIndex(
                name: "boardId",
                table: "savedArtefact",
                column: "boardId");

            migrationBuilder.CreateIndex(
                name: "userId2",
                table: "savedBoard",
                column: "userId");

            migrationBuilder.CreateIndex(
                name: "boardId1",
                table: "session",
                column: "boardId");

            migrationBuilder.CreateIndex(
                name: "inviteId",
                table: "session",
                column: "inviteId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "relationId1",
                table: "session",
                column: "relationId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "savedArtefact");

            migrationBuilder.DropTable(
                name: "session");

            migrationBuilder.DropTable(
                name: "artefact");

            migrationBuilder.DropTable(
                name: "invite");

            migrationBuilder.DropTable(
                name: "savedBoard");

            migrationBuilder.DropTable(
                name: "category");

            migrationBuilder.DropTable(
                name: "relation");

            migrationBuilder.DropTable(
                name: "user");
        }
    }
}
