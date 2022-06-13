DROP VIEW players_with_score;
DROP FUNCTION record_score(FLOAT, FLOAT, FLOAT, FLOAT);

CREATE FUNCTION record_score(progress FLOAT, demon FLOAT, list_size FLOAT, requirement FLOAT) RETURNS FLOAT AS
$record_score$
SELECT CASE
           WHEN progress = 100 THEN
                   CASE
                       
                       WHEN 55 < demon AND demon <= 150 THEN
                            56.191 * EXP(LN(2) * ((54.147 - (demon + 3.2)) * LN(50.0)) / 99.0)
                       WHEN 35 < demon AND demon <= 55 THEN
                            212.61 * (EXP(LN(1.036) * (1 - demon))) + 25.071
                       WHEN 20 < demon AND demon <= 35 THEN
                            (250 - 83.389) * (EXP(LN(1.0099685) * (2 - demon))) - 31.152
                       WHEN demon <= 20 THEN
                            (250 - 100.39) * (EXP(LN(1.168) * (1 - demon))) + 100.39
                   
                   END
                                                                 
           WHEN progress < requirement THEN
               0.0
           ELSE
                       CASE
                       
                       WHEN 55 < demon AND demon <= 150 THEN
                            56.191 * EXP(LN(2) * ((54.147 - (demon + 3.2)) * LN(50.0)) / 99.0) * (EXP(LN(5) * (progress - requirement) / (100 - requirement))) / 10
                       WHEN 35 < demon AND demon <= 55 THEN
                            (212.61 * (EXP(LN(1.036) * (1 - demon))) + 25.071) * (EXP(LN(5) * (progress - requirement) / (100 - requirement))) / 10
                       WHEN 20 < demon AND demon <= 35 THEN
                            ((250 - 83.389) * (EXP(LN(1.0099685) * (2 - demon))) - 31.152) * (EXP(LN(5) * (progress - requirement) / (100 - requirement))) / 10
                       WHEN demon <= 20 THEN
                            ((250 - 100.39) * (EXP(LN(1.168) * (1 - demon))) + 100.39) * (EXP(LN(5) * (progress - requirement) / (100 - requirement))) / 10
                   
                       END
           END;
$record_score$
    LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE VIEW players_with_score AS
SELECT players.id,
       players.name,
       RANK() OVER(ORDER BY scores.total_score DESC) AS rank,
       CASE WHEN scores.total_score IS NULL THEN 0.0::FLOAT ELSE scores.total_score END AS score,
       ROW_NUMBER() OVER(ORDER BY scores.total_score DESC) AS index,
       nationalities.iso_country_code,
       nationalities.nation
FROM
    (
        SELECT pseudo_records.player,
               SUM(record_score(pseudo_records.progress::FLOAT, pseudo_records.position::FLOAT, 100::FLOAT, pseudo_records.requirement)) as total_score
        FROM (
                 SELECT player,
                        progress,
                        position,
                        CASE WHEN demons.position > 75 THEN 100 ELSE requirement END AS requirement
                 FROM records
                          INNER JOIN demons
                                     ON demons.id = demon
                 WHERE demons.position <= 150 AND status_ = 'APPROVED'

                 UNION

                 SELECT verifier as player,
                        CASE WHEN demons.position > 150 THEN 0.0::FLOAT ELSE 100.0::FLOAT END as progress,
                        position,
                        100.0::FLOAT
                 FROM demons

                 UNION

                 SELECT publisher as player,
                        0.0::FLOAT as progress,
                        position,
                        100.0::FLOAT
                 FROM demons

                 UNION

                 SELECT creator as player,
                        0.0::FLOAT as progress,
                        1.0::FLOAT as position, -- doesn't matter
                        100.0::FLOAT
                 FROM creators
             ) AS pseudo_records
        GROUP BY player
    ) scores
        INNER JOIN players
                   ON scores.player = players.id
        LEFT OUTER JOIN nationalities
                        ON players.nationality = nationalities.iso_country_code
WHERE NOT players.banned AND players.id != 1534;
