/********************************************************************************************
  SCIMAS – Smart Comfort Index Monitoring & Analytics System
  Database Schema & Analytical Views
  ----------------------------------------------------------
  This SQL script creates the MySQL database, tables, and views used for:
  - Storing factory environmental sensor readings
  - Computing real-time Comfort Index (CI)
  - Detecting anomalies & threshold breaches
  - Preparing data for dashboards (Grafana, Power BI)
  - Comparing ML forecasts vs actual CI values
  
  Author: <Your Name>
  Course: EGT209 Data Engineering Project (NYP)
********************************************************************************************/

-- --------------------------------------------------------------------
-- 1. CREATE DATABASE AND USE IT
-- --------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS factory_env;
USE factory_env;

-- --------------------------------------------------------------------
-- 2. RAW SENSOR TABLE
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sensor_feeds (
  entry_id INT PRIMARY KEY,        -- Entry ID from ThingSpeak or ingestion pipeline
  created_at DATETIME NOT NULL,    -- Timestamp of sensor reading
  temperature DOUBLE,              -- °C
  humidity DOUBLE,                 -- %RH
  air_quality DOUBLE,              -- Air quality score (0–500)
  INDEX idx_created_at (created_at) -- Speeds up time-based queries
);

-- --------------------------------------------------------------------
-- 3. VIEW: LAST 24 HOURS OF SENSOR READINGS
-- --------------------------------------------------------------------
DROP VIEW IF EXISTS v_last24h;
CREATE VIEW v_last24h AS
SELECT *
FROM sensor_feeds
WHERE created_at >= (
    SELECT MAX(created_at) FROM sensor_feeds
) - INTERVAL 1 DAY
ORDER BY created_at;

-- --------------------------------------------------------------------
-- 4. VIEW: MOST RECENT SENSOR READING + COMPUTED COMFORT INDEX
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW v_latest_comfort AS
SELECT 
  created_at,
  temperature,
  humidity,
  air_quality,
  -- Comfort Index Formula (0–100, higher = more comfortable)
  ROUND(100 - (0.4*temperature + 0.3*humidity + 0.3*air_quality), 2)
    AS comfort_index
FROM sensor_feeds
ORDER BY created_at DESC
LIMIT 1;

-- --------------------------------------------------------------------
-- 5. VIEW: DAILY AVERAGE METRICS + DAILY AVERAGE COMFORT INDEX
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW v_daily_comfort AS
SELECT 
  DATE(created_at) AS day,
  ROUND(AVG(temperature),2) AS avg_temp,
  ROUND(AVG(humidity),2) AS avg_hum,
  ROUND(AVG(air_quality),2) AS avg_airq,
  ROUND(AVG(100 - (0.4*temperature + 0.3*humidity + 0.3*air_quality)),2)
    AS avg_comfort
FROM sensor_feeds
GROUP BY DATE(created_at)
ORDER BY day DESC;

-- --------------------------------------------------------------------
-- 6. VIEW: LATEST SENSOR STATUS WITH RISK LABELS
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW v_latest_status AS
SELECT 
  created_at,
  temperature,
  humidity,
  air_quality,

  -- Temperature Risk
  CASE
    WHEN temperature > 35 THEN '⚠️ High Temperature Risk'
    WHEN temperature < 20 THEN '❄️ Low Temperature Risk'
    ELSE 'Normal'
  END AS temp_status,

  -- Humidity Risk
  CASE
    WHEN humidity > 70 THEN '💧 High Humidity Risk'
    WHEN humidity < 40 THEN '💨 Low Humidity Risk'
    ELSE 'Normal'
  END AS humidity_status,

  -- Air Quality Risk
  CASE
    WHEN air_quality >= 100 THEN '🌫️ Poor Air Quality Risk'
    ELSE 'Normal'
  END AS airq_status,

  -- Comfort Index Risk
  CASE 
    WHEN comfort_index <= 50 THEN 'Poor Index'
    ELSE 'Normal'
  END AS index_status

FROM v_latest_comfort;

-- --------------------------------------------------------------------
-- 7. VIEW: DAILY ANOMALY COUNTS (BREACHES)
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW v_daily_anomalies AS
SELECT 
  DATE(created_at) AS day,

  -- Individual metric violations
  SUM(CASE WHEN temperature > 35 OR temperature < 20 THEN 1 ELSE 0 END)
    AS temp_breach_count,
  SUM(CASE WHEN humidity > 70 OR humidity < 40 THEN 1 ELSE 0 END)
    AS hum_breach_count,
  SUM(CASE WHEN air_quality > 100 THEN 1 ELSE 0 END)
    AS poor_airq_count,

  -- Combined total breaches
  SUM(
      (temperature > 35 OR temperature < 20) +
      (humidity > 70 OR humidity < 40) +
      (air_quality > 120)
  ) AS total_breaches

FROM sensor_feeds
GROUP BY DATE(created_at)
ORDER BY day DESC;

-- --------------------------------------------------------------------
-- 8. VIEW: FULL TIME-SERIES COMFORT INDEX (FOR DASHBOARDS)
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW v_timeseries_comfort AS
SELECT
  created_at,
  temperature,
  humidity,
  air_quality,
  ROUND((100 - (0.4*temperature + 0.3*humidity + 0.3*air_quality)),2)
    AS comfort_index
FROM sensor_feeds;

-- --------------------------------------------------------------------
-- 9. TABLE: ML PREDICTIONS FOR COMFORT INDEX (FORECAST)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS predictions_ci (
  ts DATETIME NOT NULL,        -- Timestamp of the prediction
  ci_forecast DOUBLE           -- Forecasted CI value
);

-- --------------------------------------------------------------------
-- 10. VIEW: RAW FORECAST LIST
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW v_ci_forecast AS
SELECT 
  ts,
  ci_forecast
FROM predictions_ci
ORDER BY ts;

-- --------------------------------------------------------------------
-- 11. VIEW: NEXT 24 HOURS FORECAST + RISK LABELS
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW v_ci_forecast_next24 AS
SELECT
  ts,
  ci_forecast,

  -- Display readable text labels for dashboards
  CASE 
    WHEN ci_forecast < 60 THEN '🔴 High risk'
    WHEN ci_forecast < 80 THEN '🟡 Moderate risk'
    ELSE                      '🟢 Comfortable'
  END AS risk_label,

  -- Numeric risk levels (used for colour-coding in Grafana)
  CASE 
    WHEN ci_forecast < 60 THEN 2
    WHEN ci_forecast < 80 THEN 1
    ELSE                      0
  END AS risk_level

FROM predictions_ci
ORDER BY ts;

-- --------------------------------------------------------------------
-- 12. VIEW: COMPARE FORECAST VS ACTUAL CI
-- --------------------------------------------------------------------
CREATE OR REPLACE VIEW v_ci_forecast_vs_actual AS
SELECT
  f.ts,
  f.ci_forecast,
  a.comfort_index AS ci_actual,

  -- Forecast error = forecast - actual
  CASE 
    WHEN a.comfort_index IS NULL THEN NULL
    ELSE ROUND(f.ci_forecast - a.comfort_index, 2)
  END AS forecast_error

FROM predictions_ci AS f
LEFT JOIN v_timeseries_comfort AS a
  ON a.created_at = f.ts
ORDER BY f.ts;

