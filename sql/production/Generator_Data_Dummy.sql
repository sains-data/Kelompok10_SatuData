/* File: Generator_Data_Dummy.sql
   Deskripsi: Script untuk generate 10.000+ data dummy secara otomatis
*/

USE DM_SatuDataITERA_DW;
GO

SET NOCOUNT ON; 

PRINT 'MULAI GENERATE MASSIVE DUMMY DATA';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 120);

BEGIN TRY
    BEGIN TRANSACTION;
    
    PRINT '';
    PRINT '>>> Generating 1000 Users...';
    DECLARE @i INT = 1;
    DECLARE @UnitOrg VARCHAR(100);
    WHILE @i <= 1000
    BEGIN
        -- ✅ Gunakan modulo untuk memastikan range 1-8, dengan fallback
        DECLARE @OrgIndex INT = (ABS(CHECKSUM(NEWID())) % 8) + 1;
        SET @UnitOrg = COALESCE(
            CHOOSE(@OrgIndex, 
                'Fakultas Teknologi Industri',
                'Fakultas Sains', 
                'Fakultas Teknologi Infrastruktur dan Kewilayahan',
                'Fakultas Teknologi Produksi dan Industri',
                'UPT TIK',
                'ITERA', 
                'Organisasi Mahasiswa',
                'Publik'
            ),
            'ITERA'  -- ✅ Default jika CHOOSE gagal
        );
        
        INSERT INTO stg.[User] (User_ID, Username, Tipe_User, Unit_Organisasi, Status, Tanggal_Registrasi)
        VALUES (
            @i,
            'User_' + RIGHT('000' + CAST(@i AS VARCHAR), 4) + '_' + LEFT(NEWID(), 8),
            CHOOSE((ABS(CHECKSUM(NEWID())) % 4) + 1, 'Mahasiswa', 'Dosen', 'Tendik', 'Publik'),
            @UnitOrg,  -- ✅ Pastikan tidak NULL
            CHOOSE((ABS(CHECKSUM(NEWID())) % 10) + 1, 
                'Active', 'Active', 'Active', 'Active', 'Active',
                'Active', 'Active', 'Active', 'Inactive', 'Suspended'
            ),
            DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 1095), GETDATE())
        );
        SET @i = @i + 1;
    END
    
    PRINT '';
    PRINT '>>> Generating 200 Datasets...';
    SET @i = 1;
    DECLARE @KategoriDataset VARCHAR(100);
    WHILE @i <= 200
    BEGIN
        -- ✅ Gunakan modulo untuk memastikan range 1-6, dengan fallback
        DECLARE @KatIndex INT = (ABS(CHECKSUM(NEWID())) % 6) + 1;
        SET @KategoriDataset = COALESCE(
            CHOOSE(@KatIndex, 'Akademik', 'Keuangan', 'Kepegawaian', 'Penelitian', 'Fasilitas', 'Umum'),
            'Umum'  -- ✅ Default jika CHOOSE gagal
        );
        
        INSERT INTO stg.Dataset (Dataset_ID, Nama_Dataset, Deskripsi, Format, Kategori, Tingkat_Akses, Frekuensi_Update, Status)
        VALUES (
            @i,
            'Dataset ITERA ' + @KategoriDataset + ' No.' + CAST(@i AS VARCHAR),
            'Deskripsi otomatis generated data untuk testing performance dan analisis data warehouse ITERA.',
            CHOOSE((ABS(CHECKSUM(NEWID())) % 5) + 1, 'CSV', 'Excel', 'JSON', 'PDF', 'API'),
            @KategoriDataset,  -- ✅ Gunakan variable yang sama untuk konsistensi
            CHOOSE((ABS(CHECKSUM(NEWID())) % 3) + 1, 'Public', 'Internal', 'Restricted'),
            CHOOSE((ABS(CHECKSUM(NEWID())) % 4) + 1, 'Daily', 'Weekly', 'Monthly', 'Quarterly'),
            CHOOSE((ABS(CHECKSUM(NEWID())) % 10) + 1, 
                'Active', 'Active', 'Active', 'Active', 'Active',
                'Active', 'Active', 'Active', 'Deprecated', 'Archived'
            )
        );
         
        INSERT INTO stg.Quality_Log (
            Log_ID, Dataset_ID, Tanggal_Cek, 
            Completeness_Score, Accuracy_Score, Timeliness_Score, 
            Consistency_Score, Overall_Quality_Score, 
            Missing_Values, Duplicate_Records, Total_Records
        )
        VALUES (
            @i, 
            @i, 
            DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 30), GETDATE()),
            75.0 + (ABS(CHECKSUM(NEWID())) % 2500) / 100.0,
            70.0 + (ABS(CHECKSUM(NEWID())) % 3000) / 100.0,
            65.0 + (ABS(CHECKSUM(NEWID())) % 3500) / 100.0,
            80.0 + (ABS(CHECKSUM(NEWID())) % 2000) / 100.0,
            75.0 + (ABS(CHECKSUM(NEWID())) % 2500) / 100.0,
            ABS(CHECKSUM(NEWID())) % 100,
            ABS(CHECKSUM(NEWID())) % 50,
            1000 + (ABS(CHECKSUM(NEWID())) % 9000)
        );

        SET @i = @i + 1;
    END

    PRINT '';
    PRINT '>>> Generating 10,000 Access Logs...';
    SET @i = 1;
    WHILE @i <= 10000
    BEGIN
        INSERT INTO stg.Access_Log (
            Log_ID, Dataset_ID, User_ID, Waktu_Akses, 
            Tipe_Akses, File_Size, Response_Time, Status_Akses
        )
        VALUES (
            @i,
            (ABS(CHECKSUM(NEWID())) % 200) + 1,
            (ABS(CHECKSUM(NEWID())) % 1000) + 1,
            DATEADD(MINUTE, -(ABS(CHECKSUM(NEWID())) % 525600), GETDATE()),
            CHOOSE((ABS(CHECKSUM(NEWID())) % 3) + 1, 'View', 'Download', 'API'),
            CASE 
                WHEN (ABS(CHECKSUM(NEWID())) % 3) = 0 THEN (ABS(CHECKSUM(NEWID())) % 1000000) + 1024
                WHEN (ABS(CHECKSUM(NEWID())) % 3) = 1 THEN (ABS(CHECKSUM(NEWID())) % 10000000) + 1024
                ELSE (ABS(CHECKSUM(NEWID())) % 100000000) + 1024
            END,
            50 + (ABS(CHECKSUM(NEWID())) % 5000),
            CHOOSE((ABS(CHECKSUM(NEWID())) % 20) + 1, 
                'Success', 'Success', 'Success', 'Success', 'Success',
                'Success', 'Success', 'Success', 'Success', 'Success',
                'Success', 'Success', 'Success', 'Success', 'Success',
                'Success', 'Success', 'Success', 'Failed', 'Failed'
            )
        );
        
        IF @i % 1000 = 0
            PRINT '    Progress: ' + CAST(@i AS VARCHAR) + ' records...';
            
        SET @i = @i + 1;
    END

    PRINT '';
    PRINT '>>> Generating 2,000 Search Logs...';
    SET @i = 1;
    WHILE @i <= 2000
    BEGIN
        DECLARE @SearchKeywords TABLE (Keyword VARCHAR(100));
        INSERT INTO @SearchKeywords VALUES 
            ('data mahasiswa'), ('laporan keuangan'), ('jadwal kuliah'),
            ('nilai semester'), ('beasiswa'), ('penelitian dosen'),
            ('data alumni'), ('inventaris'), ('kepegawaian'), ('statistik'),
            ('kurikulum'), ('silabus'), ('absensi'), ('IPK'), ('transkrip'),
            ('sertifikat'), ('publikasi'), ('jurnal'), ('pengabdian'), ('rapat');
        
        INSERT INTO stg.Search_Log (
            Log_ID, User_ID, Waktu_Search, 
            Keyword_Pencarian, Jumlah_Hasil, Is_Clicked, Durasi_Search_MS
        )
        VALUES (
            @i,
            CASE 
                WHEN (ABS(CHECKSUM(NEWID())) % 10) = 0 THEN NULL
                ELSE (ABS(CHECKSUM(NEWID())) % 1000) + 1 
            END,
            DATEADD(MINUTE, -(ABS(CHECKSUM(NEWID())) % 525600), GETDATE()),
            (SELECT TOP 1 Keyword FROM @SearchKeywords ORDER BY NEWID()),
            ABS(CHECKSUM(NEWID())) % 150,
            ABS(CHECKSUM(NEWID())) % 2,
            100 + (ABS(CHECKSUM(NEWID())) % 3000)
        );
        SET @i = @i + 1;
    END

    COMMIT TRANSACTION;
    
    PRINT '';
    PRINT 'SELESAI! DATA STAGING BERHASIL DIBUAT';
    PRINT 'Finished: ' + CONVERT(VARCHAR, GETDATE(), 120);

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT '';
    PRINT 'ERROR GENERATING DUMMY DATA!';
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'Baris: ' + CAST(ERROR_LINE() AS VARCHAR);
END CATCH
GO