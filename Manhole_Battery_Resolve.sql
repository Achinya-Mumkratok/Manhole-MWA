SELECT 
    d.device AS Device,
    s.location AS Location,
    d.Counter,
    CONCAT(
        CASE 
            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) < 0 THEN 0
            ELSE (s.manhole_distance - s.offset_ultra_level - d.Level)
        END, ' cm'
    ) AS Level,
    DATE_FORMAT(d.timestamp, '%Y-%m-%d %H:%i:%s') AS Timestamp,
    CASE
        WHEN d.Level2 > s.cover_setup THEN 'ฝาท่อเปิด'
        WHEN d.Level2 = 0 THEN 'ฝาท่อเปิด'
        ELSE 'ฝาท่อปิด'
    END AS Cover_Status,
    CONCAT(
        CASE 
        WHEN d.Counter >= 26280 THEN 0
        WHEN d.Counter <= 0 THEN 100
        ELSE ROUND((1 - (d.Counter / 26280)) * 100,1)
    END, ' %'
    ) AS Battery_Percentage,
    CASE
        WHEN prev_d.Counter IS NOT NULL AND ROUND((1 - (prev_d.Counter / 26280)) * 100,1) < 30
             AND ROUND((1 - (d.Counter / 26280)) * 100,1) >= 30
             AND TIMESTAMPDIFF(MINUTE, d.timestamp, NOW()) < 60  -- ต้องการให้ Resolve ส่งแจ้งเตือนครั้งเดียว หากเกิน 60 นาทีจากปัจจุบันจะหยุดการแจ้งเตือน
        THEN 1
        ELSE 0
    END AS Resolve_Battery

FROM mpete_manhole.data d
JOIN mpete_manhole.setup s
    ON d.device = s.device
LEFT JOIN mpete_manhole.data prev_d
    ON d.device = prev_d.device
    AND prev_d.timestamp = (
        SELECT MAX(d2.timestamp)
        FROM mpete_manhole.data d2
        WHERE d2.device = d.device
        AND d2.timestamp < d.timestamp
    )
WHERE d.timestamp = (
    SELECT MAX(d2.timestamp)
    FROM mpete_manhole.data d2
    WHERE d2.device = d.device
);
