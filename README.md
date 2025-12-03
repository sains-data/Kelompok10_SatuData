# Kelompok 10

# Data Mart - Satu Data
Tugas Besar Pergudangan Data - Kelompok 10

## Team Members
- 122450096 - Razin Hafid Hamdi(Leader)
- 123450102 - Daris Samudra (Member)
- 123450050 - Ahmad Rizky (Member)
- 120450019 - Kholisaturrohmah (member)

## Project Description
Proyek ini bertujuan untuk merancang dan mengimplementasikan data mart untuk **Platform Satu Data ITERA** - sebuah portal data terpadu yang menyediakan dataset dan insight tentang Institut Teknologi Sumatera. Platform ini memungkinkan pengguna (mahasiswa, dosen, peneliti, dan publik) untuk mencari, mengakses, dan menganalisis berbagai dataset terkait institusi.

Data mart ini akan mendukung:
- **Pencarian Dataset**: Katalog dataset yang terstruktur dan mudah dicari
- **Visualisasi Data**: Dashboard dan grafik interaktif untuk insight cepat
- **Analytics**: Analisis data untuk mendukung riset dan pengambilan keputusan
- **Open Data**: Akses data publik yang berhubungan dengan institusi

**Sumber Data**: [Satu Data ITERA](https://data.itera.ac.id/) (sekarang memakai data dummy)

## Business Domain
**Platform Satu Data ITERA** adalah portal data terpadu Institut Teknologi Sumatera yang menyajikan informasi institusi dalam bentuk:
- **Dataset Publik**: Data yang dapat diakses oleh masyarakat umum
- **Statistik Institusi**: Angka dan visualisasi kinerja ITERA
- **Insight Analytics**: Analisis data untuk mendukung riset dan kebijakan

### Statistik Institusi (Data Aktual dari Portal):
- **23,842 Mahasiswa Aktif**
- **778 Dosen**
- **42 Program Studi**
- **3 Fakultas**

### Kategori Dataset yang Tersedia:
1. **Dataset Akademik**: Data mahasiswa, program studi, performa akademik
2. **Dataset Kepegawaian**: Data dosen, publikasi, penelitian
3. **Dataset Infrastruktur**: Fasilitas kampus, ruang kelas, laboratorium
4. **Dataset Keuangan**: Anggaran, beasiswa, pembiayaan
5. **Dataset Riset**: Publikasi, penelitian, pengabdian masyarakat
6. **Dataset Kemahasiswaan**: Organisasi, prestasi, kegiatan mahasiswa

## Architecture
### Approach
- **Data Warehouse Model**: Star Schema
- **Platform**: SQL Server on Azure VM / PostgreSQL
- **ETL Tool**: SSIS / Apache Airflow / Python
- **Visualization**: Power BI / Tableau

### Technology Stack
- Database: SQL Server / PostgreSQL
- ETL: SSIS / Python (Pandas, SQLAlchemy)
- BI Tools: Power BI
- Version Control: Git/GitHub

## Key Features
### Fact Tables
- **Fact_Dataset_Access**: Tracking akses dan download dataset
- **Fact_Dataset_Quality**: Metrik kualitas dataset (completeness, accuracy)
- **Fact_Institution_Metrics**: KPI dan metrik institusi per periode
- **Fact_Search_Query**: Pencarian dataset oleh pengguna

### Dimension Tables
- **Dim_Dataset**: Informasi dataset (nama, kategori, format)
- **Dim_User**: Pengguna portal (mahasiswa, dosen, publik)
- **Dim_Category**: Kategori dataset
- **Dim_Organization**: Unit organisasi ITERA (fakultas, prodi, unit)
- **Dim_Time**: Dimensi waktu (tahun, semester, bulan)
- **Dim_Data_Source**: Sumber data asli

### Key Performance Indicators (KPIs)
- **Dataset Metrics**: Jumlah dataset tersedia, dataset terbaru, update frequency
- **Usage Metrics**: Jumlah pengguna aktif, download count, search queries
- **Quality Metrics**: Data completeness, data accuracy, metadata quality
- **Institution Metrics**: Total mahasiswa, rasio dosen:mahasiswa, publikasi
- **Engagement Metrics**: Active users, popular datasets, trending searches
- **Performance Metrics**: Query response time, system uptime, data freshness


## Documentation
### Business Requirements
📄 [Business Requirements Analysis](docs/01-requirements/business-requirements.md)
📄 [Data Sources Documentation](docs/01-requirements/data-sources.md)

### Design Documents
🎨 [Entity Relationship Diagram (ERD)](docs/02-design/ERD.png)
📊 [Dimensional Model](docs/02-design/dimensional-model.png)
📋 [Data Dictionary](docs/02-design/data-dictionary.xlsx)

### SQL Scripts
💾 [Schema Creation Scripts](sql/)

### Reports & Presentations
📑 [Project Presentations](presentations/)

## Timeline
- Misi 1: 10 november 2025 - 17 november 2025
- Misi 2: 17 november 2025 - 24 november 2025
- Misi 3: 25 november 2025 - 1 desember 2025
