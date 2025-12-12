MERGE `jenish-my-first-dog.austin_data_sets.raw_austin_311` T
USING (
  SELECT
    unique_key,
    complaint_description,
    source,
    status,
    DATE(status_change_date) AS status_change_date,
    DATE(created_date)       AS created_date,
    DATE(last_update_date)   AS last_update_date,
    DATE(close_date)         AS close_date,
    incident_address,
    street_number,
    street_name,
    city,
    incident_zip
  FROM `bigquery-public-data.austin_311.311_service_requests`
  WHERE DATE(created_date) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
) S
ON T.unique_key = S.unique_key
WHEN MATCHED THEN UPDATE SET
  complaint_description = S.complaint_description,
  source               = S.source,
  status               = S.status,
  status_change_date   = S.status_change_date,
  created_date         = S.created_date,
  last_update_date     = S.last_update_date,
  close_date           = S.close_date,
  incident_address     = S.incident_address,
  street_number        = S.street_number,
  street_name          = S.street_name,
  city                 = S.city,
  incident_zip         = S.incident_zip
WHEN NOT MATCHED THEN INSERT (
  unique_key, complaint_description, source, status,
  status_change_date, created_date, last_update_date, close_date,
  incident_address, street_number, street_name, city, incident_zip
)
VALUES (
  S.unique_key, S.complaint_description, S.source, S.status,
  S.status_change_date, S.created_date, S.last_update_date, S.close_date,
  S.incident_address, S.street_number, S.street_name, S.city, S.incident_zip
);
