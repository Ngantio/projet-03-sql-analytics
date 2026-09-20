# Projet 3 — SQL Analytique + Text-to-SQL avec LLM

## Contexte
Ce projet exploite le même dataset e-commerce UK (UCI Online Retail) mais cette fois
stocké dans une vraie base de données relationnelle **PostgreSQL**, avec plus de 15
requêtes SQL analytiques couvrant les concepts avancés (Window Functions, CTEs, JOINs,
analyse de cohortes). Il inclut également un système **Text-to-SQL** permettant
d'interroger la base en langage naturel grâce à un LLM.

## Dataset & infrastructure
- **Source :** [UCI Online Retail Dataset](https://archive.ics.uci.edu/dataset/352/online+retail)
- **Base de données :** PostgreSQL 18
- **Lignes importées :** 530 104 transactions nettoyées 
- **LLM utilisé :** Groq API — modèle `openai/gpt-oss-120b`

## Partie 1 — SQL Analytique

| Requête | Concepts SQL démontrés |
|---|---|
| Vue d'ensemble | `COUNT`, `COUNT DISTINCT`, `SUM`, `MIN`, `MAX` |
| Top pays / produits | `GROUP BY`, `ORDER BY`, `LIMIT` |
| Revenu cumulé mensuel | **Window Function** `SUM() OVER()`, `DATE_TRUNC` |
| Top clients | **CTE** (`WITH ... AS`) |
| Segmentation par région | **INNER JOIN**, alias de table |
| Rétention client | **CTEs imbriqués**, analyse de cohortes |

### Insights clés
| # | Finding |
|---|---|
|   | Le Royaume-Uni génère 87% du CA, mais avec le **panier moyen le plus bas** (£18.60) — signe d'une base B2C locale volumineuse |
|   | Pays-Bas et Australie ont des paniers moyens de **£121 et £117** — clientèle grossiste B2B |
|   | La rétention à 1 mois **chute de 36.6% à 15%** entre décembre 2010 et mars 2011 — signal d'alerte fidélisation |
|   | Le client `14646` génère à lui seul **£280K** de revenu sur 73 commandes, actif 353 jours sur 365 |

## Partie 2 — Text-to-SQL avec LLM

Un pipeline permettant de poser une question en français et d'obtenir directement
le résultat, sans écrire de SQL :

```
Question en français → LLM génère le SQL → PostgreSQL exécute → Résultat affiché
```

**Exemples testés :**
- *"Quels sont les 5 pays qui génèrent le plus de revenu ?"* → GROUP BY + ORDER BY générés correctement
- *"Quel est le revenu moyen par commande ?"* → le LLM a construit une **sous-requête** pour éviter une moyenne biaisée par ligne
- *"Combien de clients uniques ont acheté depuis la France ?"* → exclusion automatique des `NULL` par le LLM, sans instruction explicite

## Stack technique
![Python]
![PostgreSQL]
![SQLAlchemy]
![Groq]

## Structure du repo
```
projet-03-sql-analytics/
├── retail_sql.sql          — Les 8+ requêtes SQL analytiques commentées
├── import_data.ipynb       — Import et nettoyage des données vers PostgreSQL
├── text_to_sql.ipynb       — Pipeline Text-to-SQL avec Groq
└── README.md
```

## Auteure
**Shanice Marvin Tiogang** · Business Analytics & Data Science · Tunis
