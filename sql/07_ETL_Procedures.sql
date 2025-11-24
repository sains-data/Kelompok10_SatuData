/* File: 07_ETL_Procedures_COMPLETE.sql
   Deskripsi: Kumpulan Stored Procedures lengkap untuk ETL Data Mart
   Mencakup: Dimensi (Time, User, Dataset, Category, Org, Source) dan Fakta
*/

USE DM_SatuDataITERA_DW;
GO


-- ETL Dim_Time (Calender Generator)
CREATE OR ALTER PROCEDURE dbo.usp_Populate_Dim_Time
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    WHILE @StartDate <= @EndDate
    BEGIN
        INSERT INTO dbo.Dim_Time (
            Time_SK, Date, Tahun, Bulan, Nama_Bulan, Minggu, Hari, 
            Kuartal, Nama_Hari, Hari_Kerja_Flag, Tahun_Akademik, Semester
        )
        SELECT 
            CAST(CONVERT(VARCHAR(8), @StartDate, 112) AS INT),
            @StartDate, YEAR(@StartDate), MONTH(@StartDate), DATENAME(MONTH, @StartDate),
            DATEPART(WEEK, @StartDate), DAY(@StartDate), DATEPART(QUARTER, @StartDate),
            DATENAME(WEEKDAY, @StartDate),
            CASE WHEN DATEPART(WEEKDAY, @StartDate) IN (1, 7) THEN 0 ELSE 1 END,
            CAST(YEAR(@StartDate) AS VARCHAR) + '/' + CAST(YEAR(@StartDate)+1 AS VARCHAR),
            CASE WHEN MONTH(@StartDate) BETWEEN 8 AND 12 OR MONTH(@StartDate) = 1 THEN 'Ganjil' ELSE 'Genap' END
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Time WHERE Date = @StartDate);

        SET @StartDate = DATEADD(DAY, 1, @StartDate);
    END
END;
GO


-- ETL Dim_Data_Source (Static Data)
CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Data_Source
AS
BEGIN
    SET NOCOUNT ON;

    -- Cek jika tabel kosong, baru isi
    IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Data_Source)
    BEGIN
        INSERT INTO dbo.Dim_Data_Source (Data_Source_ID, Nama_Sumber, Tipe_Sumber, Unit_Pengelola, Status)
        VALUES 
        (1, 'Portal Satu Data', 'Web Portal', 'UPT TIK', 'Active'),
        (2, 'SIAKAD', 'Database', 'Bagian Akademik', 'Active'),
        (3, 'Kepegawaian', 'API', 'Bagian SDM', 'Active'),
        (4, 'Manual Upload', 'Excel/CSV', 'User', 'Active');
    END
END;
GO


-- ETL Dim_User (SCD Type 1)
CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_User
AS
BEGIN
    SET NOCOUNT ON;
    -- Update existing
    UPDATE t
    SET t.Username = s.Username, t.Tipe_User = s.Tipe_User, 
        t.Unit_Organisasi = s.Unit_Organisasi, t.Status = s.Status
    FROM dbo.Dim_User t JOIN stg.[User] s ON t.User_ID = s.User_ID
    WHERE t.Username <> s.Username OR t.Unit_Organisasi <> s.Unit_Organisasi;

    -- Insert new
    INSERT INTO dbo.Dim_User (User_ID, Username, Tipe_User, Unit_Organisasi, Status, Tanggal_Registrasi)
    SELECT s.User_ID, s.Username, s.Tipe_User, s.Unit_Organisasi, s.Status, s.Tanggal_Registrasi
    FROM stg.[User] s LEFT JOIN dbo.Dim_User t ON s.User_ID = t.User_ID
    WHERE t.User_ID IS NULL;
END;
GO


-- ETL Dim_Dataset (SCD Type 2)
CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Dataset
AS
BEGIN
    SET NOCOUNT ON;
    -- Expire old records
    UPDATE d SET d.End_Date = GETDATE(), d.Is_Current = 0
    FROM dbo.Dim_Dataset d JOIN stg.Dataset s ON d.Dataset_ID = s.Dataset_ID
    WHERE d.Is_Current = 1 AND (d.Nama_Dataset <> s.Nama_Dataset OR d.Status_Dataset <> s.Status);

    -- Insert new records
    INSERT INTO dbo.Dim_Dataset (
        Dataset_ID, Nama_Dataset, Deskripsi, Format, Kategori_Nama,
        Tingkat_Akses, Frekuensi_Update, Status_Dataset, Effective_Date, Is_Current
    )
    SELECT 
        s.Dataset_ID, s.Nama_Dataset, s.Deskripsi, s.Format, s.Kategori,
        s.Tingkat_Akses, s.Frekuensi_Update, s.Status, GETDATE(), 1
    FROM stg.Dataset s LEFT JOIN dbo.Dim_Dataset d 
        ON s.Dataset_ID = d.Dataset_ID AND d.Is_Current = 1
    WHERE d.Dataset_ID IS NULL;
END;
GO


-- ETL Dim_Category (Di ambil dari Staging Dataset)
CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Category
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Dim_Category (Kategori_ID, Nama_Kategori, Level, Deskripsi)
    SELECT DISTINCT 
        ABS(CHECKSUM(Kategori)) % 10000, Kategori, 1, 'Auto-generated from Staging'
    FROM stg.Dataset
    WHERE Kategori IS NOT NULL 
      AND Kategori NOT IN (SELECT Nama_Kategori FROM dbo.Dim_Category);
END;
GO


-- ETL Dim_Organization (Di ambil dariStaging User)
CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Organization
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Dim_Organization (Unit_ID, Nama_Unit, Tipe_Unit, Level)
    SELECT DISTINCT 
        ABS(CHECKSUM(Unit_Organisasi)) % 10000, Unit_Organisasi, 'Unit Kerja', 1
    FROM stg.[User]
    WHERE Unit_Organisasi IS NOT NULL 
      AND Unit_Organisasi NOT IN (SELECT Nama_Unit FROM dbo.Dim_Organization);
END;
GO


-- ETL Fact_Dataset_Access
CREATE OR ALTER PROCEDURE dbo.usp_Load_Fact_Access
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Ambil SK Default untuk Data Source
    DECLARE @DefaultSourceSK INT;
    SELECT TOP 1 @DefaultSourceSK = Data_Source_SK 
    FROM dbo.Dim_Data_Source 
    WHERE Data_Source_ID = 1; 

    IF @DefaultSourceSK IS NULL SET @DefaultSourceSK = -1;

    -- 2. Insert dengan Filter Ketat (Jumlah Kolom Sudah Disesuaikan)
    INSERT INTO dbo.Fact_Dataset_Access (
        Dataset_SK, User_SK, Time_SK, Category_SK, Organization_SK, Data_Source_SK,
        Jumlah_Akses, Jumlah_Download, Jumlah_View, File_Size_Downloaded, Response_Time_MS
    )
    SELECT 
        d.Dataset_SK,
        u.User_SK,
        CAST(CONVERT(VARCHAR(8), s.Waktu_Akses, 112) AS INT),
        c.Category_SK,
        o.Organization_SK,
        @DefaultSourceSK,
        1, -- Jumlah_Akses (Cukup satu kali)
        CASE WHEN s.Tipe_Akses = 'Download' THEN 1 ELSE 0 END, -- Jumlah_Download
        CASE WHEN s.Tipe_Akses = 'View' THEN 1 ELSE 0 END,     -- Jumlah_View
        s.File_Size,
        s.Response_Time
    FROM stg.Access_Log s
    LEFT JOIN dbo.Dim_Dataset d ON s.Dataset_ID = d.Dataset_ID AND d.Is_Current = 1
    LEFT JOIN dbo.Dim_User u ON s.User_ID = u.User_ID
    LEFT JOIN dbo.Dim_Category c ON d.Kategori_Nama = c.Nama_Kategori
    LEFT JOIN dbo.Dim_Organization o ON u.Unit_Organisasi = o.Nama_Unit
    
    -- FILTER KOMPREHENSIF
    WHERE d.Dataset_SK IS NOT NULL 
      AND u.User_SK IS NOT NULL
      AND c.Category_SK IS NOT NULL
      AND o.Organization_SK IS NOT NULL;
END;
GO

-- ETL Fact_Dataset_Quality
CREATE OR ALTER PROCEDURE dbo.usp_Load_Fact_Quality
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Fact_Dataset_Quality (
        Dataset_SK, Time_SK, Completeness_Score, Accuracy_Score, 
        Timeliness_Score, Consistency_Score, Overall_Quality_Score, 
        Missing_Values, Duplicate_Records, Total_Records
    )
    SELECT 
        ISNULL(d.Dataset_SK, -1),
        CAST(CONVERT(VARCHAR(8), s.Tanggal_Cek, 112) AS INT),
        s.Completeness_Score, s.Accuracy_Score, s.Timeliness_Score, 
        s.Consistency_Score, s.Overall_Quality_Score, 
        s.Missing_Values, s.Duplicate_Records, s.Total_Records
    FROM stg.Quality_Log s
    LEFT JOIN dbo.Dim_Dataset d ON s.Dataset_ID = d.Dataset_ID AND d.Is_Current = 1;
END;
GO


-- ETL Fact_Search_Query
CREATE OR ALTER PROCEDURE dbo.usp_Load_Fact_Search
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Fact_Search_Query (
        User_SK, Time_SK, Query_Text, Jumlah_Pencarian, 
        Jumlah_Hasil, Click_Through_Flag, Search_Time_MS
    )
    SELECT 
        u.User_SK,
        CAST(CONVERT(VARCHAR(8), s.Waktu_Search, 112) AS INT),
        s.Keyword_Pencarian, 1, s.Jumlah_Hasil, s.Is_Clicked, s.Durasi_Search_MS
    FROM stg.Search_Log s
    LEFT JOIN dbo.Dim_User u ON s.User_ID = u.User_ID;
END;
GO


-- MASTER PACKAGE (Mesin eksekusi)
CREATE OR ALTER PROCEDURE dbo.usp_Master_ETL
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            PRINT '1. Loading Independent Dimensions';
            EXEC dbo.usp_Populate_Dim_Time '2023-01-01', '2026-12-31';
            EXEC dbo.usp_Load_Dim_Data_Source;

            PRINT '2. Loading Dimension Tables';
            EXEC dbo.usp_Load_Dim_User;
            EXEC dbo.usp_Load_Dim_Dataset;
            EXEC dbo.usp_Load_Dim_Category;
            EXEC dbo.usp_Load_Dim_Organization;

            PRINT '3. Loading Fact Tables';
            EXEC dbo.usp_Load_Fact_Access;
            EXEC dbo.usp_Load_Fact_Quality;
            EXEC dbo.usp_Load_Fact_Search;

        COMMIT TRANSACTION;
        PRINT 'ETL Process Completed Successfully';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'ERROR: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

PRINT 'Stored Procedures ETL berhasil dibuat.';