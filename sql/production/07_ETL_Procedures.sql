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
    
    -- Pastikan ada user "Unknown" sebagai fallback
    IF NOT EXISTS (SELECT 1 FROM dbo.Dim_User WHERE User_SK = -1)
    BEGIN
        SET IDENTITY_INSERT dbo.Dim_User ON;
        INSERT INTO dbo.Dim_User (User_SK, User_ID, Username, Tipe_User, Unit_Organisasi, Status, Tanggal_Registrasi)
        VALUES (-1, 0, 'Unknown', 'Unknown', 'Unknown', 'Active', GETDATE());
        SET IDENTITY_INSERT dbo.Dim_User OFF;
    END;
    
    MERGE dbo.Dim_User AS target
    USING stg.[User] AS source
    ON target.User_ID = source.User_ID
    WHEN MATCHED AND (
        target.Username <> source.Username OR 
        target.Unit_Organisasi <> source.Unit_Organisasi OR
        target.Status <> COALESCE(source.Status, 'Active')
    ) THEN
        UPDATE SET 
            target.Username = source.Username,
            target.Tipe_User = COALESCE(source.Tipe_User, 'Unknown'),  -- ✅ Handle NULL
            target.Unit_Organisasi = source.Unit_Organisasi,  -- Wajib tidak NULL
            target.Status = COALESCE(source.Status, 'Active')  -- ✅ Default Active
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (User_ID, Username, Tipe_User, Unit_Organisasi, Status, Tanggal_Registrasi)
        VALUES (source.User_ID, 
                source.Username, 
                COALESCE(source.Tipe_User, 'Unknown'),  -- ✅ Handle NULL
                source.Unit_Organisasi,  -- Wajib tidak NULL
                COALESCE(source.Status, 'Active'),  -- ✅ Default Active
                source.Tanggal_Registrasi);
END;
GO


-- ETL Dim_Dataset (SCD Type 2)
CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Dataset
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentDate DATETIME = GETDATE();
    
    -- Pastikan ada dataset "Unknown" sebagai fallback
    IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Dataset WHERE Dataset_SK = -1)
    BEGIN
        SET IDENTITY_INSERT dbo.Dim_Dataset ON;
        INSERT INTO dbo.Dim_Dataset (Dataset_SK, Dataset_ID, Nama_Dataset, Deskripsi, Format, Kategori_Nama,
                                     Tingkat_Akses, Frekuensi_Update, Status_Dataset, Effective_Date, End_Date, Is_Current)
        VALUES (-1, 0, 'Unknown', 'Unknown dataset', 'Unknown', 'Unknown', 'Public', 'Unknown', 'Active', @CurrentDate, NULL, 1);
        SET IDENTITY_INSERT dbo.Dim_Dataset OFF;
    END;
    
    UPDATE d 
    SET d.End_Date = @CurrentDate, 
        d.Is_Current = 0
    FROM dbo.Dim_Dataset d
    INNER JOIN stg.Dataset s ON d.Dataset_ID = s.Dataset_ID
    WHERE d.Is_Current = 1 
      AND (d.Nama_Dataset <> s.Nama_Dataset 
           OR d.Status_Dataset <> s.Status
           OR d.Tingkat_Akses <> s.Tingkat_Akses
           OR CAST(ISNULL(d.Deskripsi, '') AS VARCHAR(MAX)) <> CAST(ISNULL(s.Deskripsi, '') AS VARCHAR(MAX)));

    INSERT INTO dbo.Dim_Dataset (
        Dataset_ID, Nama_Dataset, Deskripsi, Format, Kategori_Nama,
        Tingkat_Akses, Frekuensi_Update, Status_Dataset, 
        Effective_Date, End_Date, Is_Current
    )
    SELECT 
        s.Dataset_ID, 
        s.Nama_Dataset, 
        s.Deskripsi, 
        COALESCE(s.Format, 'Unknown') AS Format,  -- ✅ Handle NULL
        s.Kategori,  -- Wajib tidak NULL (sudah di-handle generator)
        COALESCE(s.Tingkat_Akses, 'Public') AS Tingkat_Akses,  -- ✅ Default Public
        COALESCE(s.Frekuensi_Update, 'Unknown') AS Frekuensi_Update,  -- ✅ Handle NULL
        COALESCE(s.Status, 'Active') AS Status,  -- ✅ Default Active
        @CurrentDate, NULL, 1
    FROM stg.Dataset s
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Dim_Dataset d 
        WHERE d.Dataset_ID = s.Dataset_ID AND d.Is_Current = 1
    );
END;
GO


-- ETL Dim_Category
CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Category
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Ambil kategori dari staging Dataset
    WITH UniqueCategories AS (
        SELECT DISTINCT Kategori
        FROM stg.Dataset
        WHERE Kategori IS NOT NULL
    )
    INSERT INTO dbo.Dim_Category (Kategori_ID, Nama_Kategori, Level, Deskripsi)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY Kategori) + ISNULL((SELECT MAX(Kategori_ID) FROM dbo.Dim_Category), 0),
        Kategori,
        1, -- Default level
        'Category from staging'
    FROM UniqueCategories
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Dim_Category c
        WHERE c.Nama_Kategori = UniqueCategories.Kategori
    );
END;
GO


-- ETL Dim_Organization
CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Organization
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Pastikan ada organisasi "Unknown" sebagai fallback
    IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Organization WHERE Nama_Unit = 'Unknown')
    BEGIN
        SET IDENTITY_INSERT dbo.Dim_Organization ON;
        INSERT INTO dbo.Dim_Organization (Organization_SK, Unit_ID, Nama_Unit, Tipe_Unit, Level)
        VALUES (-1, 0, 'Unknown', 'Unknown', 0);
        SET IDENTITY_INSERT dbo.Dim_Organization OFF;
    END;
    
    WITH UniqueOrgs AS (
        SELECT DISTINCT Unit_Organisasi
        FROM stg.[User]
        WHERE Unit_Organisasi IS NOT NULL 
          AND Unit_Organisasi NOT IN (SELECT Nama_Unit FROM dbo.Dim_Organization)
    )
    INSERT INTO dbo.Dim_Organization (Unit_ID, Nama_Unit, Tipe_Unit, Level)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY Unit_Organisasi) + ISNULL((SELECT MAX(Unit_ID) FROM dbo.Dim_Organization), 0),
        Unit_Organisasi,
        CASE 
            WHEN Unit_Organisasi = 'ITERA' THEN 'Pusat'
            WHEN Unit_Organisasi LIKE '%Fakultas%' THEN 'Fakultas'
            WHEN Unit_Organisasi LIKE '%UPT%' THEN 'Unit Teknis'
            WHEN Unit_Organisasi LIKE '%Prodi%' OR Unit_Organisasi LIKE '%Program Studi%' THEN 'Prodi'
            WHEN Unit_Organisasi LIKE '%Mahasiswa%' OR Unit_Organisasi LIKE '%Unit Kegiatan Mahasiswa%' OR Unit_Organisasi LIKE '%Himpunan%' THEN 'Organisasi Mahasiswa'
            WHEN Unit_Organisasi LIKE '%Biro%' THEN 'Biro'
            WHEN Unit_Organisasi LIKE '%Lembaga%' THEN 'Lembaga'
            ELSE 'Unit Kerja Lainnya'
        END,
        1
    FROM UniqueOrgs;
END;
GO


-- ETL Fact_Dataset_Access
CREATE OR ALTER PROCEDURE dbo.usp_Load_Fact_Access
AS
BEGIN
    SET NOCOUNT ON;

    -- Pastikan ada kategori "Unknown" sebagai fallback
    IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Category WHERE Nama_Kategori = 'Unknown')
    BEGIN
        SET IDENTITY_INSERT dbo.Dim_Category ON;
        INSERT INTO dbo.Dim_Category (Category_SK, Kategori_ID, Nama_Kategori, Level, Deskripsi)
        VALUES (-1, 0, 'Unknown', 0, 'Default category for unmatched records');
        SET IDENTITY_INSERT dbo.Dim_Category OFF;
    END;

    DECLARE @DefaultSourceSK INT;
    SELECT @DefaultSourceSK = ISNULL(MIN(Data_Source_SK), -1) 
    FROM dbo.Dim_Data_Source 
    WHERE Data_Source_ID = 1;
    
    DECLARE @UnknownCategorySK INT;
    SELECT @UnknownCategorySK = Category_SK 
    FROM dbo.Dim_Category 
    WHERE Nama_Kategori = 'Unknown';

    -- Pastikan ada organisasi "Unknown" sebagai fallback
    IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Organization WHERE Nama_Unit = 'Unknown')
    BEGIN
        SET IDENTITY_INSERT dbo.Dim_Organization ON;
        INSERT INTO dbo.Dim_Organization (Organization_SK, Unit_ID, Nama_Unit, Tipe_Unit, Level)
        VALUES (-1, 0, 'Unknown', 'Unknown', 0);
        SET IDENTITY_INSERT dbo.Dim_Organization OFF;
    END;

    DECLARE @UnknownOrgSK INT;
    SELECT @UnknownOrgSK = Organization_SK 
    FROM dbo.Dim_Organization 
    WHERE Nama_Unit = 'Unknown';

    INSERT INTO dbo.Fact_Dataset_Access (
        Dataset_SK, User_SK, Time_SK, Category_SK, Organization_SK, Data_Source_SK,
        Jumlah_View, Jumlah_Download, Jumlah_API_Call,
        File_Size_Downloaded, Response_Time_MS, Success_Flag
    )
    SELECT 
        ISNULL(d.Dataset_SK, -1),
        ISNULL(u.User_SK, -1),
        ISNULL(dt.Time_SK, -1),
        ISNULL(c.Category_SK, @UnknownCategorySK),
        ISNULL(o.Organization_SK, @UnknownOrgSK),
        @DefaultSourceSK,
        CASE WHEN s.Tipe_Akses = 'View' THEN 1 ELSE 0 END,
        CASE WHEN s.Tipe_Akses = 'Download' THEN 1 ELSE 0 END,
        CASE WHEN s.Tipe_Akses = 'API' THEN 1 ELSE 0 END,
        s.File_Size,
        s.Response_Time,
        CASE WHEN s.Status_Akses = 'Success' THEN 1 ELSE 0 END
    FROM stg.Access_Log s
    LEFT JOIN dbo.Dim_Dataset d ON s.Dataset_ID = d.Dataset_ID AND d.Is_Current = 1
    LEFT JOIN dbo.Dim_User u ON s.User_ID = u.User_ID
    LEFT JOIN dbo.Dim_Time dt ON dt.Time_SK = CAST(FORMAT(s.Waktu_Akses, 'yyyyMMdd') AS INT)
    LEFT JOIN dbo.Dim_Category c ON d.Kategori_Nama = c.Nama_Kategori
    LEFT JOIN dbo.Dim_Organization o ON u.Unit_Organisasi = o.Nama_Unit
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Fact_Dataset_Access f
        WHERE f.Dataset_SK = ISNULL(d.Dataset_SK, -1)
          AND f.User_SK = ISNULL(u.User_SK, -1)
          AND f.Time_SK = ISNULL(dt.Time_SK, -1)
    );
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
    
    -- Pastikan ada user "Unknown" sebagai fallback
    IF NOT EXISTS (SELECT 1 FROM dbo.Dim_User WHERE User_SK = -1)
    BEGIN
        SET IDENTITY_INSERT dbo.Dim_User ON;
        INSERT INTO dbo.Dim_User (User_SK, User_ID, Username, Tipe_User, Unit_Organisasi, Status, Tanggal_Registrasi)
        VALUES (-1, 0, 'Unknown', 'Unknown', 'Unknown', 'Active', GETDATE());
        SET IDENTITY_INSERT dbo.Dim_User OFF;
    END;
    
    INSERT INTO dbo.Fact_Search_Query (
        User_SK, Time_SK, Query_Text, Jumlah_Pencarian, 
        Jumlah_Hasil, Click_Through_Flag, Search_Time_MS
    )
    SELECT 
        ISNULL(u.User_SK, -1),
        CAST(CONVERT(VARCHAR(8), s.Waktu_Search, 112) AS INT),
        s.Keyword_Pencarian, 1, s.Jumlah_Hasil, s.Is_Clicked, s.Durasi_Search_MS
    FROM stg.Search_Log s
    LEFT JOIN dbo.Dim_User u ON s.User_ID = u.User_ID
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Fact_Search_Query f
        WHERE f.User_SK = ISNULL(u.User_SK, -1)
          AND f.Time_SK = CAST(CONVERT(VARCHAR(8), s.Waktu_Search, 112) AS INT)
          AND CAST(f.Query_Text AS VARCHAR(500)) = CAST(s.Keyword_Pencarian AS VARCHAR(500))
    );
END;
GO

-- ETL Fact_Institution_Metrics (Aggregated Table)
CREATE OR ALTER PROCEDURE dbo.usp_Load_Fact_Institution_Metrics
AS
BEGIN
    SET NOCOUNT ON;
    
    TRUNCATE TABLE dbo.Fact_Institution_Metrics;

    INSERT INTO dbo.Fact_Institution_Metrics (
        Organization_SK, Time_SK, Total_Dataset_Published, 
        Total_Downloads, Avg_Quality_Score, Total_Active_Users
    )
    SELECT 
        fa.Organization_SK,
        CAST(LEFT(CAST(fa.Time_SK AS VARCHAR), 6) + '01' AS INT) AS Snapshot_Month_SK,
        COUNT(DISTINCT fa.Dataset_SK) AS Total_Dataset_Published,
        SUM(fa.Jumlah_Download) AS Total_Downloads,
        ISNULL(AVG(lq.Overall_Quality_Score), 85.0) AS Avg_Quality_Score,
        COUNT(DISTINCT fa.User_SK) AS Total_Active_Users
    FROM dbo.Fact_Dataset_Access fa
    LEFT JOIN (
        SELECT Dataset_SK, 
               AVG(Overall_Quality_Score) AS Overall_Quality_Score
        FROM dbo.Fact_Dataset_Quality
        GROUP BY Dataset_SK
    ) lq ON fa.Dataset_SK = lq.Dataset_SK
    WHERE fa.Organization_SK <> -1 
      AND fa.Dataset_SK <> -1
    GROUP BY fa.Organization_SK, CAST(LEFT(CAST(fa.Time_SK AS VARCHAR), 6) + '01' AS INT);
END;
GO

-- MASTER PACKAGE (Mesin eksekusi)
CREATE OR ALTER PROCEDURE dbo.usp_Master_ETL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC dbo.usp_Populate_Dim_Time '2021-01-01', '2026-12-31';
            EXEC dbo.usp_Load_Dim_Data_Source;
            EXEC dbo.usp_Load_Dim_User;
            EXEC dbo.usp_Load_Dim_Dataset;
            EXEC dbo.usp_Load_Dim_Category;
            EXEC dbo.usp_Load_Dim_Organization;
            EXEC dbo.usp_Load_Fact_Access;
            EXEC dbo.usp_Load_Fact_Quality;
            EXEC dbo.usp_Load_Fact_Search;
            EXEC dbo.usp_Load_Fact_Institution_Metrics;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT 'Stored Procedures ETL berhasil dibuat.';