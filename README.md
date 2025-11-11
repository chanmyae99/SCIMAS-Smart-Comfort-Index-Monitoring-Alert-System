# SCIMAS-Smart-Comfort-Index-Monitoring-Alert-System

An IoT-driven environmental monitoring and alert system designed to enhance workplace comfort and safety in industrial environments.  
This project integrates **Arduino R4 WiFi**, **SHT35**, and **Air Quality sensors (MQ135)** to collect real-time data on temperature, humidity, and air quality.  
The system computes a **Comfort Index**, transmits data to **ThingSpeak**, stores it in **MySQL**, and visualizes live metrics on **Grafana dashboards**.  
It also includes a predictive alert module powered by **Machine Learning (Random Forest)** to detect anomalies before they occur.

---

## Project Overview

The **Smart Comfort Index Monitoring and Alert System (SCIMAS)** was developed as part of the *EGT209 Data Engineering Project* at **Nanyang Polytechnic, Singapore**.  
It aims to provide smart insights into indoor environmental quality within factories and improve worker well-being through IoT, data engineering, and analytics.

---

## Key Features

-  **IoT Data Acquisition**  
  Real-time temperature, humidity, and air quality measurements using Arduino R4 WiFi and SHT35/MQ135 sensors.

-  **Cloud Integration (ThingSpeak)**  
  Data transmitted wirelessly and stored in the cloud for real-time access.

- **Database Management (MySQL)**  
  Structured data storage for long-term analysis and trend visualization.

- **Visualization (Grafana Dashboard)**  
  Dynamic dashboards display live comfort index trends and threshold alerts.

-  **Predictive Analytics (Python & ML)**  
  Machine learning model predicts comfort index anomalies using Random Forest.

- **Alert System**  
  Automatic alerts when comfort or air quality exceeds defined thresholds.

---

## System Architecture
[ Arduino R4 WiFi ] → [ ThingSpeak Cloud ] → [ MySQL Database ] → [ Python ETL Scripts ] → [ Grafana Dashboard + ML Alerts ]


**Hardware Components**
- Arduino UNO R4 WiFi
- SHT35 Temperature & Humidity Sensor
- MQ135 Air Quality Sensor
- LCD Display (for local readout)
- WiFi connectivity (HTTP POST to ThingSpeak)

---

## ⚙️ Tech Stack

| Layer | Tools & Technologies |
|-------|----------------------|
| **Hardware** | Arduino R4 WiFi, SHT35, MQ135 |
| **Communication** | WiFiS3, HTTP REST API |
| **Cloud** | ThingSpeak (IoT Platform) |
| **Data Storage** | MySQL (Local Database) |
| **Visualization** | Grafana |
| **Programming** | C++ (Arduino IDE), Python (pandas, scikit-learn) |
| **ML Model** | Random Forest Regressor for comfort prediction |

---

## 📂 Project Structure

SCIMAS-Smart-Comfort-Index-Monitoring-Alert-System/
│
├── arduino_code/
│ └── scimas_r4_wifi.ino
│
├── python_scripts/
│ ├── data_ingestion.py
│ ├── data_cleaning.py
│ ├── model_training.py
│ └── alert_system.py
│
├── datasets/
│ └── sensor_data.csv
│
├── dashboards/
│ ├── grafana_dashboard.png
│ └── comfort_trend_overview.json
│
├── database/
│ └── schema.sql
│
├── requirements.txt
└── README.md


---

## 🧮 Comfort Index Formula

The **Comfort Index (CI)** is computed based on environmental readings:

\[
\text{CI} = 0.4 \times (\text{Temperature}) + 0.3 \times (\text{Humidity}) + 0.3 \times (100 - \text{Air Quality Score})
\]

Where:
- CI below 50 → ❄️ *Cold / Poor Comfort*  
- CI between 50–75 → 🌤️ *Moderate Comfort*  
- CI above 75 → ☀️ *High Comfort / Warm Environment*


