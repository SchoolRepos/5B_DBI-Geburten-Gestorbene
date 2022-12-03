INSERT INTO DWH_GEBOREN (JAHR, LEBENDGEBURT, ANZAHL)
SELECT TO_NUMBER(SUBSTR("C-BERJ-0", 6)),
       CASE WHEN "C-LEBTOT-0" = 'LEBEND_TOT-1' THEN 'L' ELSE 'T' END,
       "F-GEBG"
FROM STAGING_GEBORENE;

INSERT INTO DWH_GESTORBEN (jahr, ANZAHL)
SELECT TO_NUMBER(SUBSTR("C-BERJ-0", 6)), "F-GES"
FROM STAGING_GESTORBENE;

INSERT INTO DWH_GESTORBEN (JAHR, KALENDERWOCHE, BUNDESLAND, GESCHLECHT, ANZAHL, ALTERSSTD_STERBERATE)
SELECT TO_NUMBER(SUBSTR(sterberate."C-KALWOCHE-0", 6, 4))  AS jahr,
       TO_NUMBER(SUBSTR(sterberate."C-KALWOCHE-0", 10, 2)) AS kw,
       REGEXP_SUBSTR(bundesland.name, '\S+')               AS bundesland,
       CASE
           WHEN sterberate."C-SEXWO-0" = 'SEXWO-0' THEN NULL
           WHEN sterberate."C-SEXWO-0" = 'SEXWO-1' THEN 'männlich'
           WHEN sterberate."C-SEXWO-0" = 'SEXWO-2' THEN 'weiblich'
           END                                             AS geschlecht,
       TO_NUMBER(REPLACE(sterberate."F-ANZ-1", ',', '.'))  AS anzahl,
       TO_NUMBER(REPLACE(sterberate."F-RATE-1", ',', '.')) AS sterberate
FROM STAGING_STERBERATE sterberate
         JOIN STAGING_STERBERATE_BUNDESLAND bundesland ON sterberate."C-BLWO-0" = bundesland.CODE;

INSERT INTO DWH_ALTERSGRUPPE(ALTERSGRUPPE_ID, VON, BIS)
SELECT code                                        AS id,
       TO_NUMBER(REGEXP_SUBSTR(name, '\d+', 1, 1)) AS von,
       TO_NUMBER(REGEXP_SUBSTR(name, '\d+', 1, 2)) AS bis
FROM STAGING_GEST_ALTERSGRUPPEN_GRUPPEN
WHERE code NOT IN ('ALTER5-1', 'ALTER5-20')
UNION ALL
SELECT 'ALTER5-1', 0, 4
FROM dual
UNION ALL
SELECT 'ALTER5-20', 95, 200
FROM dual;

INSERT INTO DWH_GESTORBEN (jahr, kalenderwoche, bundesland, geschlecht, altersgruppe_id, anzahl)
SELECT TO_NUMBER(SUBSTR(altersgruppen."C-KALWOCHE-0", 6, 4))  AS jahr,
       TO_NUMBER(SUBSTR(altersgruppen."C-KALWOCHE-0", 10, 2)) AS kw,
       CASE
           WHEN altersgruppen."C-B00-0" = 'B00-0' THEN 'unbekannt'
           ELSE SUBSTR(bundesland.NAME, 0, LENGTH(bundesland.NAME) - 7)
           END                                                AS bundesland,
       geschlecht.NAME                                        AS geschlecht,
       altersgruppen."C-ALTER5-0"                             AS altersgruppe,
       "F-ANZ-1"                                              AS anzahl
FROM STAGING_GEST_ALTERSGRUPPEN altersgruppen
         JOIN STAGING_GEST_ALTERSGRUPPEN_BUNDESLAND bundesland
              ON altersgruppen."C-B00-0" = bundesland.CODE
         JOIN STAGING_GEST_ALTERSGRUPPEN_GESCHLECHT geschlecht
              ON altersgruppen."C-C11-0" = geschlecht.CODE;

COMMIT;