-- ============================================================
-- PROJET 3 — SQL ANALYTIQUE SUR BASE E-COMMERCE
-- Dataset : UCI Online Retail (530 104 transactions)
-- Base    : PostgreSQL 18
-- Auteure : Shanice Marvin Tiogang
-- ============================================================

-- ============================================================
-- REQUÊTE 1 — Vue d'ensemble de la base
-- ============================================================
-- Objectif : avoir une photo globale du dataset

SELECT 
    COUNT(*)                          AS nb_transactions,
    COUNT(DISTINCT "InvoiceNo")       AS nb_commandes,
    COUNT(DISTINCT "CustomerID")      AS nb_clients,
    COUNT(DISTINCT "Country")         AS nb_pays,
    ROUND(SUM("Revenue")::NUMERIC, 2) AS revenu_total,
    MIN("InvoiceDate")                AS premiere_date,
    MAX("InvoiceDate")                AS derniere_date
FROM transactions;


-- ============================================================
-- REQUÊTE 2 — Top 10 pays par revenu
-- ============================================================
-- Objectif : identifier les marchés les plus rentables

SELECT 
    "Country"                              AS pays,
    COUNT(DISTINCT "InvoiceNo")            AS nb_commandes,
    ROUND(SUM("Revenue")::NUMERIC, 2)      AS revenu_total,
    ROUND(AVG("Revenue")::NUMERIC, 2)      AS panier_moyen
FROM transactions
GROUP BY "Country"
ORDER BY revenu_total DESC
LIMIT 10;


-- ============================================================
-- REQUÊTE 3 — Top 10 produits par revenu
-- ============================================================
-- Objectif : identifier les meilleures ventes

SELECT 
    "Description"                         AS produit,
    COUNT(*)                              AS nb_transactions,
    SUM("Quantity")                       AS quantite_totale,
    ROUND(SUM("Revenue")::NUMERIC, 2)     AS revenu_total,
    ROUND(AVG("UnitPrice")::NUMERIC, 2)   AS prix_moyen
FROM transactions
WHERE "Description" NOT IN (
    'DOTCOM POSTAGE', 'POSTAGE', 'Manual',
    'AMAZONFEE', 'Bank Charges', 'CRUK'
)
GROUP BY "Description"
ORDER BY revenu_total DESC
LIMIT 10;

-- ============================================================
-- REQUÊTE 4 — Revenu cumulé par mois (Window Function)
-- ============================================================
-- Objectif : suivre la progression du CA sur l'année

SELECT 
    DATE_TRUNC('month', "InvoiceDate")         AS mois,
    ROUND(SUM("Revenue")::NUMERIC, 2)          AS revenu_mensuel,
    ROUND(
        SUM(SUM("Revenue")) 
        OVER (ORDER BY DATE_TRUNC('month', "InvoiceDate"))
    ::NUMERIC, 2)                              AS revenu_cumule
FROM transactions
GROUP BY DATE_TRUNC('month', "InvoiceDate")
ORDER BY mois;

-- ============================================================
-- REQUÊTE 5 — Top clients avec CTE
-- ============================================================
-- Objectif : identifier les meilleurs clients et leur fidélité

WITH revenus_clients AS (
    -- Étape 1 : Calculer le revenu par client
    SELECT 
        "CustomerID",
        COUNT(DISTINCT "InvoiceNo")        AS nb_commandes,
        ROUND(SUM("Revenue")::NUMERIC, 2)  AS revenu_total,
        ROUND(AVG("Revenue")::NUMERIC, 2)  AS panier_moyen,
        MIN("InvoiceDate")                 AS premiere_commande,
        MAX("InvoiceDate")                 AS derniere_commande
    FROM transactions
    WHERE "CustomerID" IS NOT NULL
    GROUP BY "CustomerID"
)

-- Étape 2 : Filtrer et afficher les top 10
SELECT 
    "CustomerID",
    nb_commandes,
    revenu_total,
    panier_moyen,
    premiere_commande,
    derniere_commande,
    DATE_PART('day', derniere_commande - premiere_commande) AS jours_activite
FROM revenus_clients
ORDER BY revenu_total DESC
LIMIT 10;


-- ============================================================
-- REQUÊTE 6 — Créer une table de segmentation pays (pour JOIN)
-- ============================================================
-- Objectif : illustrer un JOIN avec une table de référence

CREATE TABLE IF NOT EXISTS pays_region (
    pays        VARCHAR(50) PRIMARY KEY,
    region      VARCHAR(30),
    devise      VARCHAR(10)
);

INSERT INTO pays_region (pays, region, devise) VALUES
    ('United Kingdom', 'Europe du Nord', 'GBP'),
    ('Germany', 'Europe Centrale', 'EUR'),
    ('France', 'Europe de l''Ouest', 'EUR'),
    ('Netherlands', 'Europe de l''Ouest', 'EUR'),
    ('EIRE', 'Europe du Nord', 'EUR'),
    ('Spain', 'Europe du Sud', 'EUR'),
    ('Switzerland', 'Europe Centrale', 'CHF'),
    ('Belgium', 'Europe de l''Ouest', 'EUR'),
    ('Sweden', 'Europe du Nord', 'SEK'),
    ('Australia', 'Océanie', 'AUD')
ON CONFLICT (pays) DO NOTHING;

SELECT * FROM pays_region;


-- ============================================================
-- REQUÊTE 7 — JOIN : Revenu par région géographique
-- ============================================================
-- Objectif : regrouper les ventes par grande région, pas juste par pays

SELECT 
    pr.region,
    COUNT(DISTINCT t."InvoiceNo")          AS nb_commandes,
    ROUND(SUM(t."Revenue")::NUMERIC, 2)    AS revenu_total
FROM transactions t
INNER JOIN pays_region pr 
    ON t."Country" = pr.pays
GROUP BY pr.region
ORDER BY revenu_total DESC;


-- ============================================================
-- REQUÊTE 8 — Analyse de cohortes (mois de première commande)
-- ============================================================
-- Objectif : voir combien de clients reviennent après leur 1ère commande

WITH premiere_commande AS (
    -- Étape 1 : Trouver le mois de première commande de chaque client
    SELECT 
        "CustomerID",
        DATE_TRUNC('month', MIN("InvoiceDate")) AS cohorte
    FROM transactions
    WHERE "CustomerID" IS NOT NULL
    GROUP BY "CustomerID"
),

activite_mensuelle AS (
    -- Étape 2 : Pour chaque client, tous les mois où il a acheté
    SELECT DISTINCT
        "CustomerID",
        DATE_TRUNC('month', "InvoiceDate") AS mois_achat
    FROM transactions
    WHERE "CustomerID" IS NOT NULL
)

-- Étape 3 : Croiser les deux pour voir la rétention
SELECT 
    pc.cohorte,
    COUNT(DISTINCT pc."CustomerID")                      AS taille_cohorte,
    COUNT(DISTINCT CASE 
        WHEN am.mois_achat = pc.cohorte + INTERVAL '1 month' 
        THEN am."CustomerID" 
    END)                                                  AS clients_mois_suivant
FROM premiere_commande pc
JOIN activite_mensuelle am ON pc."CustomerID" = am."CustomerID"
GROUP BY pc.cohorte
ORDER BY pc.cohorte;
