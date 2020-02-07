/*construct a single PostgreSQL statement producing the following aggregation:
Column name         Description
app_id              App id
app_views           Total count of app detail views for this app
app_installs        Total count of app installs for this app
app_conversion_rate Total count of app installs / total app detail views for this app
assumption that store_app_view and store_app_download events should be happening without 10 minutes
code session: */

WITH X AS (SELECT MAX(event_time_utc) AS date_of_change
FROM store_events
WHERE event_type = 'store_app_download')
SELECT install.app_id , COUNT(event_type = 'store_app_view') AS app_views,
       install.app_installs, install.app_installs/ app_view AS app_conversion_rate
FROM (SELECT s1.app_id,
        COUNT (CASE WHEN s2.event_time_utc <= X.date_of_change
                AND (s1.event_type = 'store_app_view' AND s2.event_type = 'store_app_download)
                AND (s2.event_time_utc - s1.event_time_utc <= INTERVAL '10 MINUTE') THEN 1
                WHEN s2.event_time_utc > X.date_of_change
                AND (s1.event_type = 'store_app_install' AND s2.event_type = 'store_app_install') THEN 1
                ELSE NULL END) AS app_installs,
      FROM store_events s1 JOIN store_events s2
      ON s1.user_id = s2.user_id
      AND s1.app_id = s2.app_id
      GROUP BY s1.app_id) install
FROM store_app_install
GROUP BY install.app_id
