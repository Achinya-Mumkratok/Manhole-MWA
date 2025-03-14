-- Level Firing
CASE 
    WHEN GREATEST(0, s.manhole_distance - s.offset_ultra_level - d.Level ) > (s.manhole_distance*(s.Low_Level/100)) AND s.maintenance = 0 THEN 1 
    ELSE 0 
END AS Level_alert,

-- Level Resolve
CASE
  WHEN (
        SELECT 
            GREATEST(0, s.manhole_distance - s.offset_ultra_level - d_prev.Level - (s.manhole_distance * (s.Low_Level / 100)))
        FROM 
            mpete_manhole.data d_prev
        WHERE 
            d_prev.device = d.device AND 
            d_prev.timestamp = (
                SELECT MAX(d2.timestamp)
                FROM mpete_manhole.data d2
                WHERE d2.device = d.device AND d2.timestamp < d.timestamp
            )
        ) > 0
  AND GREATEST(0, s.manhole_distance - s.offset_ultra_level - d.Level - (s.manhole_distance * (s.Low_Level / 100))) < 0
  AND s.maintenance = 0
  THEN 1
  ELSE 0
END AS Resolve_Water_Level

-- Cover Firing
CASE
  WHEN d.Level2 > s.cover_setup And s.cover_ack = 0 And s.maintenance = 0 THEN 1
  WHEN d.Level2 = 0  And s.cover_ack = 0 And s.maintenance = 0 THEN 1
  ELSE 0
END AS Cover,

-- Cover Resolve
CASE
  WHEN 
      prev_d.Level2 > s.cover_setup
      AND d.Level2 < s.cover_setup
      AND s.cover_ack = 0 
      AND s.maintenance = 0
  THEN 1
  WHEN 
      prev_d.Level2 = 0 
      AND d.Level2 > 0 
      AND d.Level2 < s.cover_setup 
      AND s.cover_ack = 0 
      And s.maintenance = 0 
  THEN 1  
  ELSE 0
END AS Resolve_Cover

-- Battery Firing
CASE 
   WHEN d.Counter >= 26280 THEN 0
   WHEN d.Counter <= 0 THEN 100
   ELSE ROUND((1 - (d.Counter / 26280)) * 100,1)
END AS Battery_Percentage

-- Battery Resolve
CASE
  WHEN prev_d.Counter IS NOT NULL AND ROUND((1 - (prev_d.Counter / 26280)) * 100,1) < 30
       AND ROUND((1 - (d.Counter / 26280)) * 100,1) >= 30
  THEN 1
  ELSE 0
END AS Resolve_Battery

-- Disconnected Firing
CASE
  WHEN NOW() - INTERVAL 230 MINUTE > d.timestamp THEN 1      -- 2 ชม 50
  ELSE 0
END AS "Device Status"

-- Disconnected Resolve
CASE
  WHEN prev.timestamp IS NULL THEN 0  -- ถ้าไม่มีข้อมูลก่อนหน้า ถือว่าออนไลน์
  WHEN TIMESTAMPDIFF(MINUTE, prev.timestamp, d.timestamp) > 230    -- 2 ชม 50
  ELSE 0
END AS "Device Status"

-- Level change
CASE
        WHEN s.maintenance = 1 THEN 0
        ELSE 
            CASE
                WHEN 
                (
                    (
                        (CASE
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) <= 0 THEN 'Empty'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) >= (s.manhole_distance * ((s.High_Level + 1) / 100)) THEN 'High Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) >= (s.manhole_distance * ((s.Medium_Level + 1) / 100)) THEN 'Medium Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) >= (s.manhole_distance * ((s.Low_Level + 1) / 100)) THEN 'Low Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) < (s.manhole_distance * ((s.Low_Level + 1) / 100)) THEN 'Near Empty'
                            ELSE 'Empty'
                        END) != 
                        (CASE
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) <= 0 THEN 'Empty'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) >= (s.manhole_distance * ((s.High_Level + 1) / 100)) THEN 'High Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) >= (s.manhole_distance * ((s.Medium_Level + 1) / 100)) THEN 'Medium Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) >= (s.manhole_distance * ((s.Low_Level + 1) / 100)) THEN 'Low Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) < (s.manhole_distance * ((s.Low_Level + 1) / 100)) THEN 'Near Empty'
                            ELSE 'Empty'
                        END)
                    )
                OR
                    (
                        (CASE
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) <= 0 THEN 'Empty'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) >= (s.manhole_distance * ((s.High_Level - 1) / 100)) THEN 'High Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) >= (s.manhole_distance * ((s.Medium_Level - 1) / 100)) THEN 'Medium Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) >= (s.manhole_distance * ((s.Low_Level - 1) / 100)) THEN 'Low Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d.Level) < (s.manhole_distance * ((s.Low_Level - 1) / 100)) THEN 'Near Empty'
                            ELSE 'Empty'
                        END) != 
                        (CASE
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) <= 0 THEN 'Empty'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) >= (s.manhole_distance * ((s.High_Level - 1) / 100)) THEN 'High Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) >= (s.manhole_distance * ((s.Medium_Level - 1) / 100)) THEN 'Medium Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) >= (s.manhole_distance * ((s.Low_Level - 1) / 100)) THEN 'Low Level'
                            WHEN (s.manhole_distance - s.offset_ultra_level - d_prev.Level) < (s.manhole_distance * ((s.Low_Level - 1) / 100)) THEN 'Near Empty'
                            ELSE 'Empty'
                        END)
                    )
                )
                AND  TIMESTAMPDIFF(MINUTE, d.timestamp, NOW()) < 60
                THEN 1
                ELSE 0
            END



















