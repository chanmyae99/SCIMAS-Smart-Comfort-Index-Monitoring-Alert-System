CREATE DATABASE factory_env;
USE factory_env;
CREATE TABLE sensor_feeds (
  entry_id INT PRIMARY KEY,
  created_at DATETIME NOT NULL,
  temperature DOUBLE,
  humidity DOUBLE,
  air_quality DOUBLE,
  INDEX idx_created_at (created_at)
);

DROP VIEW IF EXISTS v_last24h;
CREATE VIEW v_last24h AS
SELECT * FROM sensor_feeds
WHERE created_at >= (SELECT MAX(created_at) FROM sensor_feeds) - INTERVAL 1 DAY
ORDER BY created_at;

CREATE OR REPLACE VIEW v_latest_comfort AS
SELECT 
  created_at,
  temperature,
  humidity,
  air_quality,
  ROUND(100 - (0.4*temperature + 0.3*humidity + 0.3*air_quality), 2) AS comfort_index
FROM sensor_feeds
ORDER BY created_at DESC
LIMIT 1;

CREATE OR REPLACE VIEW v_daily_comfort AS
SELECT 
  DATE(created_at) AS day,
  ROUND(AVG(temperature),2) AS avg_temp,
  ROUND(AVG(humidity),2) AS avg_hum,
  ROUND(AVG(air_quality),2) AS avg_airq,
  ROUND(AVG(100 - (0.4*temperature + 0.3*humidity + 0.3*air_quality)),2) AS avg_comfort
FROM sensor_feeds
GROUP BY DATE(created_at)
ORDER BY day DESC;

CREATE OR REPLACE VIEW v_latest_status AS
SELECT 
  created_at,
  temperature,
  humidity,
  air_quality,
  CASE
        WHEN temperature > 35 THEN '⚠️ High Temperature Risk'
        WHEN temperature < 20 THEN '❄️ Low Temperature Risk'
        ELSE 'Normal'
    END AS temp_status,
    CASE
        WHEN humidity > 70 THEN '💧 High Humidity Risk'
        WHEN humidity < 40 THEN '💨 Low Humidity Risk'
        ELSE 'Normal'
    END AS humidity_status,
    CASE
        WHEN air_quality >= 100 THEN '🌫️ Poor Air Quality Risk'
        ELSE 'Normal'
    END AS airq_status,
    CASE 
		WHEN comfort_index <= 50 THEN 'Poor Index'
        ELSE 'Normal'
	END AS index_status
FROM v_latest_comfort;

CREATE OR REPLACE VIEW v_daily_anomalies AS
SELECT 
  DATE(created_at) AS day,
  SUM(CASE WHEN temperature > 35 OR temperature < 20 THEN 1 ELSE 0 END) AS temp_breach_count,
  SUM(CASE WHEN humidity > 70 OR humidity < 40 THEN 1 ELSE 0 END) AS hum_breach_count,
  SUM(CASE WHEN air_quality > 100 THEN 1 ELSE 0 END) AS poor_airq_count,
  SUM( (temperature > 35 OR temperature < 20) + (humidity > 70 OR humidity < 40) + (air_quality > 120) ) AS total_breaches
FROM sensor_feeds
GROUP BY DATE(created_at)
ORDER BY day DESC;

CREATE OR REPLACE VIEW v_timeseries_comfort AS
SELECT
  created_at,
  temperature,
  humidity,
  air_quality,
  ROUND((100 - (0.4*temperature + 0.3*humidity + 0.3*air_quality)),2) AS comfort_index
FROM sensor_feeds;

CREATE TABLE predictions_ci (
  ts DATETIME NOT NULL,
  ci_forecast DOUBLE
); 

CREATE OR REPLACE VIEW v_ci_forecast AS
SELECT 
  ts,
  ci_forecast
FROM predictions_ci
ORDER BY ts;

CREATE OR REPLACE VIEW v_ci_forecast_next24 AS
SELECT
  ts,
  ci_forecast,
  CASE 
    WHEN ci_forecast < 60 THEN '🔴 High risk'
    WHEN ci_forecast < 80 THEN '🟡 Moderate risk'
    ELSE                      '🟢 Comfortable'
  END AS risk_label,
  CASE 
    WHEN ci_forecast < 60 THEN 2
    WHEN ci_forecast < 80 THEN 1
    ELSE                      0
  END AS risk_level
FROM predictions_ci
ORDER BY ts;


CREATE OR REPLACE VIEW v_ci_forecast_vs_actual AS
SELECT
  f.ts,
  f.ci_forecast,
  a.comfort_index AS ci_actual,
  CASE 
    WHEN a.comfort_index IS NULL THEN NULL
    ELSE ROUND(f.ci_forecast - a.comfort_index, 2)
  END AS forecast_error
FROM predictions_ci AS f
LEFT JOIN v_timeseries_comfort AS a
  ON a.created_at = f.ts
ORDER BY f.ts;


  




