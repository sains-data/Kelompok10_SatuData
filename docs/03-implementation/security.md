# Dokumentasi Keamanan - Data Warehouse Satu Data ITERA
---

## 1. Gambaran Umum

Dokumen ini menjelaskan arsitektur keamanan, kebijakan akses, dan prosedur audit untuk sistem Data Warehouse Satu Data ITERA (`DM_SatuDataITERA_DW`).

### 1.1 Tujuan Keamanan
- Melindungi data sensitif pengguna dan institusi.
- Memastikan kepatuhan terhadap kebijakan privasi data ITERA.
- Menerapkan kontrol akses berbasis peran (RBAC).
- Menyediakan jejak audit yang lengkap.

---
## 2. Arsitektur Keamanan

### 2.1 Lapisan Keamanan

1.  **Keamanan Jaringan:** Firewall, Enkripsi SSL/TLS.
2.  **Keamanan Database:** Autentikasi SQL Server, Role-Based Access Control (RBAC).
3.  **Keamanan Data:** Dynamic Data Masking (DDM), Enkripsi Data (TDE - Opsional).
---

## 3. Kontrol Akses (Role-Based Access Control)

Sistem menggunakan empat peran database utama untuk mengelola akses:

### 3.1 Peran Database

| Peran | Deskripsi | Hak Akses |
|-------|-----------|-----------|
| **db_executive** | Eksekutif & Pimpinan | Read-only penuh, data tidak dimasking (unmasked). |
| **db_analyst** | Analis Data | Read-only, bisa membuat view/tabel temporer, data tidak dimasking. |
| **db_etl_operator**| Operator ETL | Full CRUD pada tabel staging & DW, eksekusi prosedur ETL. |
| **db_viewer** | Pengguna Umum/Staf | Read-only terbatas, data sensitif dimasking. |

### 3.2 Matriks Akses

Lihat dokumen `access_matrix.md` untuk detail izin per tabel.

### 3.3 Manajemen Pengguna

**Pembuatan User Baru:**
```sql
-- Contoh script oleh Admin
CREATE LOGIN [nama_user] WITH PASSWORD = 'PasswordKuat123!';
USE DM_SatuDataITERA_DW;
CREATE USER [nama_user] FOR LOGIN [nama_user];
ALTER ROLE [db_viewer] ADD MEMBER [nama_user];
```

**Kebijakan Password:**
- Minimal 12 karakter.
- Kombinasi huruf besar, kecil, angka, dan simbol.
- Kadaluarsa setiap 90 hari.

---

## 4. Perlindungan Data

### 4.1 Dynamic Data Masking (DDM)

Data sensitif dilindungi menggunakan fitur Dynamic Data Masking agar tidak terlihat oleh pengguna yang tidak berwenang (misal: `db_viewer`).

**Kolom yang Dilindungi:**

| Tabel | Kolom | Metode Masking | Contoh Output |
|-------|-------|----------------|---------------|
| `Dim_User` | `Email` | `email()` | aXXX@XXXX.com |
| `Dim_User` | `NoHP` | `partial(2,"XXX-XXX-",2)` | 08XX-XXX-X90 |
| `Fact_Search`| `QueryText` | `default()` | xxxx |

**Implementasi:**
```sql
ALTER TABLE Dim_User 
ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
```

### 4.2 Audit Trail

Sistem mencatat aktivitas penting untuk keamanan dan pemantauan.

**Komponen Audit:**
1.  **Server Audit:** Mencatat login gagal, perubahan schema (DDL), dan perubahan permission.
2.  **Database Audit:** Mencatat akses ke tabel sensitif (`Fact_Dataset_Access`).
3.  **Tabel Audit Log:** Mencatat siapa yang menjalankan proses ETL dan kapan.

**Lokasi Log:**
- File audit tersimpan di server: `/var/opt/mssql/audit/`
- Tabel log internal: `dbo.AuditLog`

---

## 5. Prosedur Tanggap Insiden

### 5.1 Kategori Insiden

- **Kritis:** Kebocoran data, akses tidak sah ke akun admin.
- **Tinggi:** Kegagalan login berulang yang mencurigakan.
- **Menengah:** Perubahan konfigurasi tanpa izin.

### 5.2 Langkah Penanganan

1.  **Deteksi:** Melalui alert sistem atau laporan pengguna.
2.  **Isolasi:** Nonaktifkan akun yang dicurigai, putus koneksi jaringan jika perlu.
3.  **Investigasi:** Periksa log audit untuk melacak sumber dan dampak.
4.  **Pemulihan:** Restore data dari backup jika ada kerusakan, reset kredensial.
5.  **Pelaporan:** Buat laporan insiden untuk manajemen.

---

## 6. Daftar Kontak Keamanan

| Peran | Kontak | Email |
|-------|--------|-------|
| Database Administrator | Tim DBA | dba@itera.ac.id |
| Security Officer | Tim Keamanan | security@itera.ac.id |
| Helpdesk IT | Layanan TIK | helpdesk@itera.ac.id |

---

**Akhir Dokumen Keamanan**
