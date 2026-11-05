-- SQL Server / Azure SQL Database. Ejecutar dentro de una base vacía.
-- En local: crear primero RestauranteDb; en Azure: seleccionar la base creada.
-- No contiene CREATE DATABASE ni USE para ser compatible con Azure SQL.
-- No elimina ni reemplaza tablas existentes.
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE dbo.Mesas (
    Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Mesas PRIMARY KEY,
    Numero int NOT NULL,
    Capacidad int NOT NULL,
    Ubicacion nvarchar(80) NOT NULL,
    CONSTRAINT UQ_Mesas_Numero UNIQUE (Numero),
    CONSTRAINT CK_Mesas_Numero CHECK (Numero BETWEEN 1 AND 200),
    CONSTRAINT CK_Mesas_Capacidad CHECK (Capacidad BETWEEN 1 AND 20),
    CONSTRAINT CK_Mesas_Ubicacion CHECK (LEN(LTRIM(RTRIM(Ubicacion))) > 0)
);

CREATE TABLE dbo.Reservas (
    Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Reservas PRIMARY KEY,
    NombreCliente nvarchar(100) NOT NULL,
    Telefono nvarchar(20) NOT NULL,
    FechaHora datetime2(0) NOT NULL,
    CantidadPersonas int NOT NULL,
    Observaciones nvarchar(300) NULL,
    MesaId int NOT NULL,
    CONSTRAINT FK_Reservas_Mesas FOREIGN KEY (MesaId)
        REFERENCES dbo.Mesas(Id) ON DELETE NO ACTION,
    CONSTRAINT CK_Reservas_Personas CHECK (CantidadPersonas BETWEEN 1 AND 20),
    CONSTRAINT CK_Reservas_Cliente CHECK (LEN(LTRIM(RTRIM(NombreCliente))) > 0),
    CONSTRAINT CK_Reservas_Telefono CHECK (LEN(LTRIM(RTRIM(Telefono))) > 0)
);

CREATE INDEX IX_Reservas_MesaId ON dbo.Reservas(MesaId);
CREATE INDEX IX_Reservas_FechaHora ON dbo.Reservas(FechaHora);

INSERT INTO dbo.Mesas (Numero, Capacidad, Ubicacion) VALUES
    (1, 4, N'Salón principal'),
    (2, 6, N'Terraza'),
    (3, 2, N'Ventana'),
    (4, 8, N'Salón familiar');

INSERT INTO dbo.Reservas
    (NombreCliente, Telefono, FechaHora, CantidadPersonas, Observaciones, MesaId)
VALUES
    (N'Ana Torres', N'999111222', '2026-12-10T13:00:00', 4, N'Almuerzo familiar', 1),
    (N'Luis Ramos', N'999333444', '2026-12-10T20:00:00', 5, NULL, 2),
    (N'María López', N'999555666', '2026-12-11T19:30:00', 2, N'Junto a la ventana', 3);

COMMIT TRANSACTION;
