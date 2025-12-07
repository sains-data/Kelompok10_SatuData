# Business Requirements Analysis
## Data Warehouse Portal Satu Data ITERA

---

## 1. Stakeholders

### Primary Stakeholders
- **Tim Pengelola Portal Satu Data**: Maintenance, update dataset, monitoring sistem
- **Management ITERA**: Menggunakan insight untuk decision making strategis
- **Data Stewards**: Unit-unit yang menyediakan dan memvalidasi dataset
- **Pengguna Eksternal**: Peneliti, masyarakat umum yang mengakses open data

### Secondary Stakeholders
- **Mahasiswa**: Mencari dataset untuk tugas, skripsi, penelitian
- **Dosen & Peneliti**: Mengakses data untuk riset dan publikasi
- **Bagian Perencanaan & QA**: Analisis data untuk evaluasi institusi
- **Media & Publik**: Akses informasi publik ITERA untuk transparansi

### Decision Makers
- **Tim Pengelola Portal**: Keputusan terkait dataset prioritas, akses policy
- **Management ITERA**: Keputusan strategis berdasarkan insight data
- **Data Governance Team**: Keputusan terkait data quality, privacy, security

---

## 2. Business Process Analysis

### Proses Pengelolaan Dataset
```
Data Collection → Data Validation → Metadata Creation → Dataset Publication → Update & Maintenance
```

**KPIs** :
- Jumlah dataset yang dipublikasi per unit organisasi (`Total_Dataset_Published`)
- Rata-rata skor kualitas dataset per unit (`Rata_Rata_Skor_Kualitas`)
- Status kualitas unit: Excellent, Good, Fair, Needs Improvement
- Ranking unit berdasarkan jumlah unduhan (`Ranking_Download`)

### Proses Akses dan Download Dataset
```
User Registration → Search/Browse → Dataset Preview → Download/API Access → Usage Tracking
```

**KPIs** :
- Total user aktif per periode (`Total_User_Aktif`)
- Total akses: views, downloads, API calls (`Total_Views`, `Total_Downloads`, `Total_API_Calls`)
- Conversion rate dari view ke download (`Download_Rate_Percent`)
- Response time rata-rata (`Avg_Response_Time_MS`)
- Ranking dataset terpopuler per kategori (`Ranking_In_Category`)
- Total traffic data (`Total_Traffic_MB`)
- Success rate akses (`Success_Rate_Percent`)

### Proses Data Quality Management
```
Quality Assessment → Issue Identification → Data Cleaning → Re-validation → Quality Reporting
```

**KPIs** :
- Rata-rata skor kualitas keseluruhan (`Overall_Quality_Score`)
- Skor completeness, accuracy, timeliness, consistency per dataset
- Jumlah missing values dan duplicate records
- Total records per dataset
- Status kualitas: Excellent/Good/Fair/Needs Improvement

### Proses Search & Discovery
```
User Query → Search Execution → Results Ranking → Dataset Selection → Feedback Collection
```

**KPIs** :
- Total pencarian per periode (`Total_Pencarian`)
- Jumlah pencarian nihil/tanpa hasil (`Pencarian_Nihil`)
- Click-through rate (`Click_Through_Rate_Percent`)
- Rata-rata waktu respon pencarian (`Avg_Response_Time_MS`)
- Ranking keyword populer (`Popularity_Rank`)
- Prioritas content gap: High/Medium/Low (`Content_Gap_Priority`)

---

## 3. Analytical Requirements

### Business Questions to Answer

**Dataset Management Analytics**:
1. Berapa jumlah dataset tersedia per kategori?
2. Dataset mana yang paling sering diakses/didownload?
3. Bagaimana kualitas dataset yang tersedia (completeness, freshness)?
4. Keyword apa yang paling sering dicari terkait dataset?

**User Behavior Analytics**:
5. Apa keyword pencarian yang paling populer?
6. Bulan/kuartal mana yang memiliki aktivitas portal tertinggi?
7. Dataset apa yang trending dalam periode tertentu?

**Institution Metrics Analytics**:
8. Bagaimana performa institusi dari tahun ke tahun?
9. Apa insight utama yang dapat diberikan kepada management?

**Data Quality Analytics**:
10. Berapa persentase dataset yang up-to-date?
11. Dataset mana yang perlu di-refresh?
12. Berapa rata-rata skor completeness dataset per kategori?

### Report Types
- **Daily**: Monitoring akses dataset, user activity, system performance
- **Weekly**: Laporan dataset baru, trending searches, quality issues
- **Monthly**: Laporan performa portal, user engagement, dataset usage
- **Quarterly**: Laporan quality metrics, data governance compliance
- **Annual**: Laporan tahunan institusi, dataset portfolio review

### Data Granularity
- **Dataset Level**: Per individual dataset (akses, download, quality)
- **User Level**: Per individual user (aktivitas, preferensi)
- **Category Level**: Per kategori dataset (popularitas, kualitas)
- **Organization Level**: Per unit organisasi (kontribusi dataset)
- **Time Level**: Per hari, minggu, bulan, semester, tahun
- **Institution Level**: Agregat institusi (total metrics, KPIs)

---
