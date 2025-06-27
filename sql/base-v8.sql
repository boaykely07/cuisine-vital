-- =============================================
-- BASE DE DONNÉES POSTGRESQL SIMPLIFIÉE
-- Système de Gestion de Livraison de Repas
-- =============================================

\c postgres

DROP DATABASE IF EXISTS cuisine_db;
CREATE DATABASE cuisine_db;

\c cuisine_db

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extension pour PostGIS
CREATE EXTENSION postgis;

-- =============================================
-- TABLES DE RÉFÉRENCE SIMPLIFIÉES
-- =============================================

-- Types d'abonnement (GOLD/SILVER uniquement)
CREATE TABLE types_abonnement (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(10) NOT NULL UNIQUE CHECK (nom IN ('GOLD', 'SILVER')),
    prix_jour DECIMAL(8,2) NOT NULL,
    nb_menus_disponibles INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Statuts simples pour les commandes
CREATE TABLE statuts_commande (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(30) NOT NULL UNIQUE,
    ordre INTEGER NOT NULL
);

-- Zones de livraison simplifiées
CREATE TABLE zones_livraison (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    localisation geometry,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- =============================================
-- GESTION DES UTILISATEURS SIMPLIFIÉE
-- =============================================

-- Rôles utilisateur (5 rôles essentiels)
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(30) NOT NULL UNIQUE,
    description TEXT
);

-- Utilisateurs
CREATE TABLE utilisateurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telephone VARCHAR(20),
    mot_de_passe VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL REFERENCES roles(id),
    zone_livraison_id INTEGER REFERENCES zones_livraison(id),
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Sessions simplifiées (2h d'expiration)
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL UNIQUE,
    expire_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- =============================================
-- GESTION DES CLIENTS SIMPLIFIÉE
-- =============================================

-- Clients (particuliers et entreprises)
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100), -- NULL pour entreprises
    email VARCHAR(255) UNIQUE NOT NULL,
    telephone VARCHAR(20),
    adresse TEXT NOT NULL,
    zone_livraison_id INTEGER NOT NULL REFERENCES zones_livraison(id),
    type_client VARCHAR(15) NOT NULL CHECK (type_client IN ('PARTICULIER', 'ENTREPRISE')),
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Abonnements entreprise simplifiés
CREATE TABLE abonnements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id),
    type_abonnement_id INTEGER NOT NULL REFERENCES types_abonnement(id),
    nb_employes INTEGER NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE,
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- =============================================
-- GESTION DES PRODUITS SIMPLIFIÉE
-- =============================================

-- Ingrédients essentiels pour le stock
CREATE TABLE ingredients (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    unite_mesure VARCHAR(10) NOT NULL, -- kg, g, L, pièce
    prix_unitaire DECIMAL(8,2) NOT NULL,
    stock_minimum DECIMAL(8,2) NOT NULL,
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Exemplaires ingrédients pour le stock
CREATE TABLE exemplaires_ingredient (
    id SERIAL PRIMARY KEY,
    quantite DECIMAL(100,2) NOT NULL,
    ingredient_id INTEGER NOT NULL REFERENCES ingredients(id),
    date_peremption DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Menus/Plats principaux
CREATE TABLE menus (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    prix_carte DECIMAL(8,2) NOT NULL,
    temps_preparation INTEGER NOT NULL, -- en minutes
    disponible BOOLEAN DEFAULT TRUE,
    photo_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Recettes simplifiées (ingrédients principaux par menu)
CREATE TABLE recettes (
    id SERIAL PRIMARY KEY,
    menu_id INTEGER NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    ingredient_id INTEGER NOT NULL REFERENCES ingredients(id),
    quantite DECIMAL(8,2) NOT NULL
);

-- Boissons (pour GOLD)
CREATE TABLE boissons (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    prix DECIMAL(6,2) NOT NULL,
    disponible BOOLEAN DEFAULT TRUE
);

-- Entrées et desserts simplifiés
CREATE TABLE accompagnements (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('ENTREE', 'DESSERT')),
    description TEXT,
    prix_uniatire DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Stocké les menus disponibles par abonnement
CREATE TABLE menu_type_abonnement (
    id SERIAL PRIMARY KEY,
    menu_id INTEGER NOT NULL REFERENCES menus(id),
    type_abonnement_id INTEGER NOT NULL REFERENCES types_abonnement(id),
    disponible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Stocké les abonnements disponibles par abonnement
CREATE TABLE accompagnement_type_abonnement (
    id SERIAL PRIMARY KEY,
    accompagnement_id INTEGER DEFAULT NULL REFERENCES accompagnements(id),
    type_abonnement_id INTEGER NOT NULL REFERENCES types_abonnement(id),
    disponible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Menus favoris des clients
CREATE TABLE menus_favoris(
    id SERIAL PRIMARY KEY,
    menu_id INTEGER NOT NULL REFERENCES menus(id),
    client_id UUID NOT NULL REFERENCES clients(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Critère de fidélité
CREATE TABLE critere_fidelite(
    id SERIAL PRIMARY KEY,
    prix_a_atteindre DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);  

-- Réduction issus de la fidélité
CREATE TABLE reduction(
    id SERIAL PRIMARY KEY,
    pourcentage DECIMAL(4,2) NOT NULL
);

-- Clients fidèles 
CREATE TABLE clients_individuels_fideles(
    id SERIAL PRIMARY KEY,
    client_id UUID NOT NULL REFERENCES clients(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- =============================================
-- GESTION DES COMMANDES SÉPARÉES
-- =============================================

-- Commandes individuelles (particuliers)
CREATE TABLE commandes_individuelles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_commande VARCHAR(20) NOT NULL UNIQUE,
    client_id UUID NOT NULL REFERENCES clients(id),
    statut_id INTEGER NOT NULL REFERENCES statuts_commande(id),
    date_commande TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_livraison DATE NOT NULL,
    adresse_livraison TEXT NOT NULL,
    montant_total DECIMAL(10,2) NOT NULL,
    livreur_id UUID REFERENCES utilisateurs(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Commandes entreprises (abonnements)
CREATE TABLE commandes_entreprises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_commande VARCHAR(20) NOT NULL UNIQUE,
    client_id UUID NOT NULL REFERENCES clients(id),
    abonnement_id UUID NOT NULL REFERENCES abonnements(id),
    statut_id INTEGER NOT NULL REFERENCES statuts_commande(id),
    date_commande TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_livraison DATE NOT NULL,
    adresse_livraison TEXT NOT NULL,
    montant_total DECIMAL(10,2) NOT NULL,
    livreur_id UUID REFERENCES utilisateurs(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Détails des commandes individuelles
CREATE TABLE commandes_individuelles_details (
    id SERIAL PRIMARY KEY,
    commande_id UUID NOT NULL REFERENCES commandes_individuelles(id) ON DELETE CASCADE,
    menu_id INTEGER NOT NULL REFERENCES menus(id),
    accompagnement_id INTEGER DEFAULT NULL REFERENCES accompagnements(id),
    quantite INTEGER NOT NULL,
    prix_unitaire DECIMAL(8,2) NOT NULL,
    boisson_id INTEGER REFERENCES boissons(id),
    notes TEXT
);

-- Détails des commandes entreprises
CREATE TABLE commandes_entreprises_details (
    id SERIAL PRIMARY KEY,
    commande_id UUID NOT NULL REFERENCES commandes_entreprises(id) ON DELETE CASCADE,
    menu_id INTEGER NOT NULL REFERENCES menus(id),
    quantite INTEGER NOT NULL,
    prix_unitaire DECIMAL(8,2) NOT NULL,
    boisson_id INTEGER REFERENCES boissons(id), -- Pour GOLD uniquement
    notes TEXT
);

-- Bons de commande hebdomadaires (entreprises)
CREATE TABLE bons_commande (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    abonnement_id UUID NOT NULL REFERENCES abonnements(id),
    semaine_debut DATE NOT NULL,
    semaine_fin DATE NOT NULL,
    statut VARCHAR(15) DEFAULT 'EN_ATTENTE' CHECK (statut IN ('EN_ATTENTE', 'VALIDE', 'TRAITE')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Sélection des menus pour la semaine
CREATE TABLE selections_hebdomadaires (
    id SERIAL PRIMARY KEY,
    bon_commande_id UUID NOT NULL REFERENCES bons_commande(id) ON DELETE CASCADE,
    menu_id INTEGER NOT NULL REFERENCES menus(id),
    jour_semaine INTEGER NOT NULL CHECK (jour_semaine BETWEEN 1 AND 5), -- Lun-Ven
    quantite INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Salaires employés
CREATE TABLE salaires (
    id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL REFERENCES roles(id),
    salaire_mensuel DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- =============================================
-- GESTION DE LA PRODUCTION SIMPLIFIÉE
-- =============================================

-- Planning de production quotidien
CREATE TABLE planning_production (
    id SERIAL PRIMARY KEY,
    menu_id INTEGER NOT NULL REFERENCES menus(id),
    date_production DATE NOT NULL,
    quantite_prevue INTEGER NOT NULL,
    quantite_produite INTEGER DEFAULT 0,
    cuisinier_id UUID REFERENCES utilisateurs(id),
    temps_prevu INTEGER, -- minutes
    temps_reel INTEGER, -- minutes
    statut VARCHAR(15) DEFAULT 'PLANIFIE' CHECK (statut IN ('PLANIFIE', 'EN_COURS', 'TERMINE')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Mouvements de stock simplifiés
CREATE TABLE mouvements_stock (
    id SERIAL PRIMARY KEY,
    exemplaire_ingredient_id INTEGER NOT NULL REFERENCES exemplaires_ingredient(id),
    type_mouvement VARCHAR(15) NOT NULL CHECK (type_mouvement IN ('ENTREE', 'SORTIE', 'AJUSTEMENT')),
    quantite DECIMAL(8,2) NOT NULL,
    stock_avant DECIMAL(8,2) NOT NULL,
    stock_apres DECIMAL(8,2) NOT NULL,
    commentaire TEXT,
    utilisateur_id UUID REFERENCES utilisateurs(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- =============================================
-- GESTION DES FACTURES SÉPARÉES
-- =============================================

-- Factures individuelles (particuliers)
CREATE TABLE factures_individuelles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_facture VARCHAR(20) NOT NULL UNIQUE,
    client_id UUID NOT NULL REFERENCES clients(id),
    commande_id UUID NOT NULL REFERENCES commandes_individuelles(id),
    date_facture DATE NOT NULL DEFAULT CURRENT_DATE,
    date_echeance DATE NOT NULL,
    montant_ht DECIMAL(10,2) NOT NULL,
    montant_tva DECIMAL(10,2) NOT NULL DEFAULT 0,
    montant_ttc DECIMAL(10,2) NOT NULL,
    statut VARCHAR(15) DEFAULT 'EMISE' CHECK (statut IN ('EMISE', 'PAYEE', 'ANNULEE')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Factures entreprises (mensuelles)
CREATE TABLE factures_entreprises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_facture VARCHAR(20) NOT NULL UNIQUE,
    client_id UUID NOT NULL REFERENCES clients(id),
    abonnement_id UUID NOT NULL REFERENCES abonnements(id),
    mois_facture DATE NOT NULL, -- Premier jour du mois facturé
    date_facture DATE NOT NULL DEFAULT CURRENT_DATE,
    date_echeance DATE NOT NULL,
    montant_ht DECIMAL(10,2) NOT NULL,
    montant_tva DECIMAL(10,2) NOT NULL DEFAULT 0,
    montant_ttc DECIMAL(10,2) NOT NULL,
    nb_repas_factures INTEGER NOT NULL,
    statut VARCHAR(15) DEFAULT 'EMISE' CHECK (statut IN ('EMISE', 'PAYEE', 'ANNULEE')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Détails des factures individuelles
CREATE TABLE factures_individuelles_details (
    id SERIAL PRIMARY KEY,
    facture_id UUID NOT NULL REFERENCES factures_individuelles(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantite INTEGER NOT NULL,
    prix_unitaire DECIMAL(8,2) NOT NULL,
    total_ligne DECIMAL(8,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Détails des factures entreprises
CREATE TABLE factures_entreprises_details (
    id SERIAL PRIMARY KEY,
    facture_id UUID NOT NULL REFERENCES factures_entreprises(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantite INTEGER NOT NULL,
    prix_unitaire DECIMAL(8,2) NOT NULL,
    total_ligne DECIMAL(8,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- =============================================
-- GESTION DES PAIEMENTS SÉPARÉS
-- =============================================

-- Paiements individuels (particuliers)
CREATE TABLE paiements_individuels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    facture_id UUID NOT NULL REFERENCES factures_individuelles(id),
    numero_transaction VARCHAR(50),
    date_paiement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    montant DECIMAL(10,2) NOT NULL,
    mode_paiement VARCHAR(20) NOT NULL CHECK (mode_paiement IN ('CARTE', 'PAYPAL', 'ESPECES', 'VIREMENT')),
    statut VARCHAR(15) DEFAULT 'EN_ATTENTE' CHECK (statut IN ('EN_ATTENTE', 'CONFIRME', 'ECHEC', 'REMBOURSE')),
    reference_externe VARCHAR(100), -- Référence du système de paiement
    commentaire TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Paiements entreprises (factures mensuelles)
CREATE TABLE paiements_entreprises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    facture_id UUID NOT NULL REFERENCES factures_entreprises(id),
    numero_transaction VARCHAR(50),
    date_paiement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    montant DECIMAL(10,2) NOT NULL,
    mode_paiement VARCHAR(20) NOT NULL CHECK (mode_paiement IN ('VIREMENT', 'CHEQUE', 'CARTE', 'ESPECES')),
    statut VARCHAR(15) DEFAULT 'EN_ATTENTE' CHECK (statut IN ('EN_ATTENTE', 'CONFIRME', 'ECHEC', 'REMBOURSE')),
    reference_externe VARCHAR(100), -- Référence bancaire
    commentaire TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Livraisons individuelles
CREATE TABLE livraisons_individuelles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    commande_id UUID NOT NULL REFERENCES commandes_individuelles(id),
    livreur_id UUID NOT NULL REFERENCES utilisateurs(id),
    adresse TEXT NOT NULL,
    localisation geometry,
    heure_depart TIME,
    heure_livraison TIME,
    statut VARCHAR(15) DEFAULT 'ASSIGNEE' CHECK (statut IN ('ASSIGNEE', 'EN_ROUTE', 'LIVREE')),
    commentaire TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- Livraisons entreprises
CREATE TABLE livraisons_entreprises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    commande_id UUID NOT NULL REFERENCES commandes_entreprises(id),
    livreur_id UUID NOT NULL REFERENCES utilisateurs(id),
    adresse TEXT NOT NULL,
    localisation geometry,
    heure_depart TIME,
    heure_livraison TIME,
    statut VARCHAR(15) DEFAULT 'ASSIGNEE' CHECK (statut IN ('ASSIGNEE', 'EN_ROUTE', 'LIVREE')),
    commentaire TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- =============================================
-- ALERTES SIMPLIFIÉES
-- =============================================

-- Alertes système
CREATE TABLE alertes (
    id SERIAL PRIMARY KEY,
    type_alerte VARCHAR(30) NOT NULL,
    message TEXT NOT NULL,
    niveau VARCHAR(10) DEFAULT 'INFO' CHECK (niveau IN ('INFO', 'WARNING', 'ERROR')),
    lue BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

-- =============================================
-- SYSTÈME DE GESTION DE LIVRAISON DE REPAS
-- INDEX ESSENTIELS, FONCTIONS, TRIGGERS ET VUES
-- =============================================

-- =============================================
-- INDEX ESSENTIELS POUR PERFORMANCES
-- =============================================

-- Index pour la gestion des utilisateurs et sessions
CREATE INDEX idx_utilisateurs_email ON utilisateurs(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_utilisateurs_role ON utilisateurs(role_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_sessions_token ON sessions(token) WHERE deleted_at IS NULL;
CREATE INDEX idx_sessions_expire ON sessions(expire_at);

-- Index pour la gestion des clients
CREATE INDEX idx_clients_email ON clients(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_clients_type ON clients(type_client) WHERE deleted_at IS NULL;
CREATE INDEX idx_clients_zone ON clients(zone_livraison_id) WHERE deleted_at IS NULL;

-- Index pour les abonnements
CREATE INDEX idx_abonnements_client ON abonnements(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_abonnements_actifs ON abonnements(actif, date_debut, date_fin) WHERE deleted_at IS NULL;

-- Index pour la gestion des stocks et ingrédients
CREATE INDEX idx_ingredients_stock_min ON ingredients(stock_minimum) WHERE deleted_at IS NULL;
CREATE INDEX idx_exemplaires_peremption ON exemplaires_ingredient(date_peremption) WHERE deleted_at IS NULL;
CREATE INDEX idx_mouvements_stock_date ON mouvements_stock(created_at);
CREATE INDEX idx_mouvements_stock_type ON mouvements_stock(type_mouvement);

-- Index pour les menus et recettes
CREATE INDEX idx_menus_disponible ON menus(disponible) WHERE deleted_at IS NULL;
CREATE INDEX idx_recettes_menu ON recettes(menu_id);
CREATE INDEX idx_menu_type_abonnement ON menu_type_abonnement(type_abonnement_id, disponible);

-- Index pour les commandes (critiques pour performance)
CREATE INDEX idx_commandes_ind_client ON commandes_individuelles(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_commandes_ind_statut ON commandes_individuelles(statut_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_commandes_ind_date_livraison ON commandes_individuelles(date_livraison) WHERE deleted_at IS NULL;
CREATE INDEX idx_commandes_ind_livreur ON commandes_individuelles(livreur_id) WHERE deleted_at IS NULL;

CREATE INDEX idx_commandes_ent_client ON commandes_entreprises(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_commandes_ent_statut ON commandes_entreprises(statut_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_commandes_ent_date_livraison ON commandes_entreprises(date_livraison) WHERE deleted_at IS NULL;
CREATE INDEX idx_commandes_ent_abonnement ON commandes_entreprises(abonnement_id) WHERE deleted_at IS NULL;

-- Index pour les bons de commande
CREATE INDEX idx_bons_commande_abonnement ON bons_commande(abonnement_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_bons_commande_semaine ON bons_commande(semaine_debut, semaine_fin) WHERE deleted_at IS NULL;
CREATE INDEX idx_selections_bon_commande ON selections_hebdomadaires(bon_commande_id) WHERE deleted_at IS NULL;

-- Index pour les factures et paiements
CREATE INDEX idx_factures_ind_client ON factures_individuelles(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_factures_ind_date ON factures_individuelles(date_facture) WHERE deleted_at IS NULL;
CREATE INDEX idx_factures_ent_client ON factures_entreprises(client_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_factures_ent_mois ON factures_entreprises(mois_facture) WHERE deleted_at IS NULL;

CREATE INDEX idx_paiements_ind_statut ON paiements_individuels(statut) WHERE deleted_at IS NULL;
CREATE INDEX idx_paiements_ent_statut ON paiements_entreprises(statut) WHERE deleted_at IS NULL;

-- Index pour la production
CREATE INDEX idx_planning_production_date ON planning_production(date_production) WHERE deleted_at IS NULL;
CREATE INDEX idx_planning_production_cuisinier ON planning_production(cuisinier_id) WHERE deleted_at IS NULL;

-- Index géospatiaux pour les livraisons
CREATE INDEX idx_zones_localisation ON zones_livraison USING GIST(localisation);
CREATE INDEX idx_livraisons_ind_localisation ON livraisons_individuelles USING GIST(localisation);
CREATE INDEX idx_livraisons_ent_localisation ON livraisons_entreprises USING GIST(localisation);

-- =============================================
-- FONCTIONS ESSENTIELLES: 
-- =============================================

-- Fonction pour calculer le stock total d'un ingrédient
CREATE OR REPLACE FUNCTION calculer_stock_ingredient(p_ingredient_id INTEGER)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    stock_total DECIMAL(10,2) := 0;
BEGIN
    SELECT COALESCE(SUM(quantite), 0) INTO stock_total
    FROM exemplaires_ingredient
    WHERE ingredient_id = p_ingredient_id
    AND deleted_at IS NULL
    AND (date_peremption IS NULL OR date_peremption > CURRENT_DATE);
    
    RETURN stock_total;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour vérifier si un ingrédient est en stock faible
CREATE OR REPLACE FUNCTION verifier_stock_faible(p_ingredient_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    stock_actuel DECIMAL(10,2);
    stock_min DECIMAL(10,2);
BEGIN
    SELECT calculer_stock_ingredient(p_ingredient_id) INTO stock_actuel;
    SELECT stock_minimum INTO stock_min FROM ingredients WHERE id = p_ingredient_id;
    
    RETURN stock_actuel <= stock_min;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour générer un numéro de commande unique
CREATE OR REPLACE FUNCTION generer_numero_commande(p_type VARCHAR)
RETURNS VARCHAR(20) AS $$
DECLARE
    numero VARCHAR(20);
    prefix VARCHAR(5);
    sequence_num INTEGER;
BEGIN
    prefix := CASE 
        WHEN p_type = 'INDIVIDUELLE' THEN 'IND'
        WHEN p_type = 'ENTREPRISE' THEN 'ENT'
        ELSE 'CMD'
    END;
    
    sequence_num := EXTRACT(EPOCH FROM NOW())::INTEGER % 1000000;
    numero := prefix || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || LPAD(sequence_num::TEXT, 6, '0');
    
    RETURN numero;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour calculer le montant total d'une commande individuelle
CREATE OR REPLACE FUNCTION calculer_montant_commande_individuelle(p_commande_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    montant_total DECIMAL(10,2) := 0;
BEGIN
    SELECT COALESCE(SUM(quantite * prix_unitaire), 0) INTO montant_total
    FROM commandes_individuelles_details
    WHERE commande_id = p_commande_id;
    
    RETURN montant_total;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour calculer les besoins en ingrédients pour une date
CREATE OR REPLACE FUNCTION calculer_besoins_ingredients(p_date_production DATE)
RETURNS TABLE(ingredient_id INTEGER, nom_ingredient VARCHAR, quantite_necessaire DECIMAL, stock_disponible DECIMAL, manque DECIMAL) AS $$
BEGIN
    RETURN QUERY
    WITH besoins AS (
        SELECT 
            r.ingredient_id,
            i.nom,
            SUM(pp.quantite_prevue * r.quantite) as qte_necessaire
        FROM planning_production pp
        JOIN recettes r ON pp.menu_id = r.menu_id
        JOIN ingredients i ON r.ingredient_id = i.id
        WHERE pp.date_production = p_date_production
        AND pp.deleted_at IS NULL
        GROUP BY r.ingredient_id, i.nom
    )
    SELECT 
        b.ingredient_id,
        b.nom,
        b.qte_necessaire,
        calculer_stock_ingredient(b.ingredient_id) as stock_dispo,
        GREATEST(0, b.qte_necessaire - calculer_stock_ingredient(b.ingredient_id)) as manque
    FROM besoins b;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour vérifier la fidélité d'un client
CREATE OR REPLACE FUNCTION verifier_fidelite_client(p_client_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    total_achats DECIMAL(10,2) := 0;
    seuil_fidelite DECIMAL(10,2);
BEGIN
    -- Calculer le total des achats du client
    SELECT COALESCE(SUM(montant_total), 0) INTO total_achats
    FROM commandes_individuelles
    WHERE client_id = p_client_id
    AND deleted_at IS NULL;
    
    -- Récupérer le critère de fidélité
    SELECT prix_a_atteindre INTO seuil_fidelite
    FROM critere_fidelite
    WHERE deleted_at IS NULL
    ORDER BY created_at DESC
    LIMIT 1;
    
    RETURN total_achats >= COALESCE(seuil_fidelite, 0);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- TRIGGERS ESSENTIELS
-- =============================================

-- Trigger pour nettoyer les sessions expirées
CREATE OR REPLACE FUNCTION nettoyer_sessions_expirees()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM sessions WHERE expire_at < NOW();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_nettoyage_sessions
    AFTER INSERT OR UPDATE ON sessions
    EXECUTE FUNCTION nettoyer_sessions_expirees();

-- Trigger pour créer des alertes de stock faible
CREATE OR REPLACE FUNCTION trigger_alerte_stock_faible()
RETURNS TRIGGER AS $$
DECLARE
    ingredient_nom VARCHAR(100);
    stock_actuel DECIMAL(10,2);
BEGIN
    -- Vérifier si le stock est faible après un mouvement de sortie
    IF NEW.type_mouvement = 'SORTIE' THEN
        SELECT nom INTO ingredient_nom 
        FROM ingredients i
        JOIN exemplaires_ingredient ei ON i.id = ei.ingredient_id
        WHERE ei.id = NEW.exemplaire_ingredient_id;
        
        SELECT calculer_stock_ingredient(
            (SELECT ingredient_id FROM exemplaires_ingredient WHERE id = NEW.exemplaire_ingredient_id)
        ) INTO stock_actuel;
        
        IF verifier_stock_faible(
            (SELECT ingredient_id FROM exemplaires_ingredient WHERE id = NEW.exemplaire_ingredient_id)
        ) THEN
            INSERT INTO alertes (type_alerte, message, niveau)
            VALUES (
                'STOCK_FAIBLE',
                'Stock faible pour l''ingrédient: ' || ingredient_nom || ' (Stock actuel: ' || stock_actuel || ')',
                'WARNING'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_stock_faible
    AFTER INSERT ON mouvements_stock
    FOR EACH ROW
    EXECUTE FUNCTION trigger_alerte_stock_faible();

-- Trigger pour mettre à jour automatiquement le montant total des commandes
CREATE OR REPLACE FUNCTION maj_montant_commande_individuelle()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE commandes_individuelles
    SET montant_total = calculer_montant_commande_individuelle(
        CASE 
            WHEN TG_OP = 'DELETE' THEN OLD.commande_id
            ELSE NEW.commande_id
        END
    )
    WHERE id = CASE 
        WHEN TG_OP = 'DELETE' THEN OLD.commande_id
        ELSE NEW.commande_id
    END;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_maj_montant_commande_ind
    AFTER INSERT OR UPDATE OR DELETE ON commandes_individuelles_details
    FOR EACH ROW
    EXECUTE FUNCTION maj_montant_commande_individuelle();

-- Trigger pour générer automatiquement les numéros de commande
CREATE OR REPLACE FUNCTION generer_numero_commande_auto()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.numero_commande IS NULL OR NEW.numero_commande = '' THEN
        NEW.numero_commande := generer_numero_commande(
            CASE 
                WHEN TG_TABLE_NAME = 'commandes_individuelles' THEN 'INDIVIDUELLE'
                WHEN TG_TABLE_NAME = 'commandes_entreprises' THEN 'ENTREPRISE'
                ELSE 'COMMANDE'
            END
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_numero_commande_ind
    BEFORE INSERT ON commandes_individuelles
    FOR EACH ROW
    EXECUTE FUNCTION generer_numero_commande_auto();

CREATE TRIGGER trigger_numero_commande_ent
    BEFORE INSERT ON commandes_entreprises
    FOR EACH ROW
    EXECUTE FUNCTION generer_numero_commande_auto();

-- Trigger pour créer automatiquement les factures
CREATE OR REPLACE FUNCTION creer_facture_commande()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer facture pour commande individuelle
    IF TG_TABLE_NAME = 'commandes_individuelles' AND NEW.statut_id = (SELECT id FROM statuts_commande WHERE nom = 'LIVREE') THEN
        INSERT INTO factures_individuelles (
            numero_facture, client_id, commande_id, date_echeance,
            montant_ht, montant_tva, montant_ttc
        ) VALUES (
            'FACT' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(EXTRACT(EPOCH FROM NOW())::INTEGER % 10000, 4, '0'),
            NEW.client_id,
            NEW.id,
            NEW.date_livraison + INTERVAL '30 days',
            NEW.montant_total,
            NEW.montant_total * 0.2, -- TVA 20%
            NEW.montant_total * 1.2
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_facture_commande_ind
    AFTER UPDATE ON commandes_individuelles
    FOR EACH ROW
    WHEN (OLD.statut_id != NEW.statut_id)
    EXECUTE FUNCTION creer_facture_commande();

-- Trigger pour vérifier la fidélité automatiquement
CREATE OR REPLACE FUNCTION verifier_ajout_fidelite()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier si le client devient fidèle après cette commande
    IF verifier_fidelite_client(NEW.client_id) AND 
       NOT EXISTS (SELECT 1 FROM clients_individuels_fideles WHERE client_id = NEW.client_id AND deleted_at IS NULL) THEN
        
        INSERT INTO clients_individuels_fideles (client_id)
        VALUES (NEW.client_id);
        
        INSERT INTO alertes (type_alerte, message, niveau)
        VALUES (
            'NOUVEAU_FIDELE',
            'Nouveau client fidèle: ' || (SELECT nom || ' ' || prenom FROM clients WHERE id = NEW.client_id),
            'INFO'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_fidelite_client
    AFTER INSERT OR UPDATE ON commandes_individuelles
    FOR EACH ROW
    EXECUTE FUNCTION verifier_ajout_fidelite();

-- =============================================
-- VUES ESSENTIELLES POUR L'APPLICATION
-- =============================================

-- Vue pour le tableau de bord administrateur
CREATE OR REPLACE VIEW v_dashboard_admin AS
SELECT 
    -- Statistiques du jour
    (SELECT COALESCE(SUM(montant_total), 0) 
     FROM commandes_individuelles 
     WHERE DATE(created_at) = CURRENT_DATE AND deleted_at IS NULL) as ca_jour_particuliers,
     
    (SELECT COALESCE(SUM(montant_total), 0) 
     FROM commandes_entreprises 
     WHERE DATE(created_at) = CURRENT_DATE AND deleted_at IS NULL) as ca_jour_entreprises,
     
    -- Statistiques du mois
    (SELECT COALESCE(SUM(montant_total), 0) 
     FROM commandes_individuelles 
     WHERE EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM CURRENT_DATE)
     AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM CURRENT_DATE)
     AND deleted_at IS NULL) as ca_mois_particuliers,
     
    (SELECT COALESCE(SUM(montant_total), 0) 
     FROM commandes_entreprises 
     WHERE EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM CURRENT_DATE)
     AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM CURRENT_DATE)
     AND deleted_at IS NULL) as ca_mois_entreprises,
     
    -- Commandes en cours
    (SELECT COUNT(*) FROM commandes_individuelles ci 
     JOIN statuts_commande sc ON ci.statut_id = sc.id 
     WHERE sc.nom IN ('RECUE', 'EN_PREPARATION', 'PRETE') AND ci.deleted_at IS NULL) as commandes_ind_en_cours,
     
    (SELECT COUNT(*) FROM commandes_entreprises ce 
     JOIN statuts_commande sc ON ce.statut_id = sc.id 
     WHERE sc.nom IN ('RECUE', 'EN_PREPARATION', 'PRETE') AND ce.deleted_at IS NULL) as commandes_ent_en_cours,
     
    -- Alertes non lues
    (SELECT COUNT(*) FROM alertes WHERE lue = FALSE AND deleted_at IS NULL) as alertes_non_lues;

-- Vue pour les stocks critiques
CREATE OR REPLACE VIEW v_stocks_critiques AS
SELECT 
    i.id,
    i.nom,
    i.unite_mesure,
    calculer_stock_ingredient(i.id) as stock_actuel,
    i.stock_minimum,
    CASE 
        WHEN calculer_stock_ingredient(i.id) <= i.stock_minimum THEN 'CRITIQUE'
        WHEN calculer_stock_ingredient(i.id) <= i.stock_minimum * 1.5 THEN 'FAIBLE'
        ELSE 'NORMAL'
    END as niveau_stock
FROM ingredients i
WHERE i.deleted_at IS NULL
ORDER BY (calculer_stock_ingredient(i.id) / NULLIF(i.stock_minimum, 0));

-- Vue pour le suivi des commandes par statut
CREATE OR REPLACE VIEW v_commandes_statuts AS
SELECT 
    sc.nom as statut,
    sc.ordre,
    COUNT(ci.id) as nb_commandes_individuelles,
    COUNT(ce.id) as nb_commandes_entreprises,
    COUNT(ci.id) + COUNT(ce.id) as total_commandes
FROM statuts_commande sc
LEFT JOIN commandes_individuelles ci ON sc.id = ci.statut_id AND ci.deleted_at IS NULL
LEFT JOIN commandes_entreprises ce ON sc.id = ce.statut_id AND ce.deleted_at IS NULL
GROUP BY sc.id, sc.nom, sc.ordre
ORDER BY sc.ordre;

-- Vue pour les menus les plus vendus
CREATE OR REPLACE VIEW v_top_menus AS
WITH ventes_individuelles AS (
    SELECT 
        m.id,
        m.nom,
        SUM(cid.quantite) as qte_vendue_ind,
        SUM(cid.quantite * cid.prix_unitaire) as ca_ind
    FROM menus m
    JOIN commandes_individuelles_details cid ON m.id = cid.menu_id
    JOIN commandes_individuelles ci ON cid.commande_id = ci.id
    WHERE ci.deleted_at IS NULL
    GROUP BY m.id, m.nom
),
ventes_entreprises AS (
    SELECT 
        m.id,
        m.nom,
        SUM(ced.quantite) as qte_vendue_ent,
        SUM(ced.quantite * ced.prix_unitaire) as ca_ent
    FROM menus m
    JOIN commandes_entreprises_details ced ON m.id = ced.menu_id
    JOIN commandes_entreprises ce ON ced.commande_id = ce.id
    WHERE ce.deleted_at IS NULL
    GROUP BY m.id, m.nom
)
SELECT 
    m.id,
    m.nom,
    COALESCE(vi.qte_vendue_ind, 0) + COALESCE(ve.qte_vendue_ent, 0) as quantite_totale,
    COALESCE(vi.ca_ind, 0) + COALESCE(ve.ca_ent, 0) as chiffre_affaire_total,
    COALESCE(vi.qte_vendue_ind, 0) as quantite_particuliers,
    COALESCE(ve.qte_vendue_ent, 0) as quantite_entreprises
FROM menus m
LEFT JOIN ventes_individuelles vi ON m.id = vi.id
LEFT JOIN ventes_entreprises ve ON m.id = ve.id
WHERE m.deleted_at IS NULL
ORDER BY (COALESCE(vi.qte_vendue_ind, 0) + COALESCE(ve.qte_vendue_ent, 0)) DESC;

-- Vue pour les clients fidèles avec leurs statistiques
CREATE OR REPLACE VIEW v_clients_fideles AS
SELECT 
    c.id,
    c.nom,
    c.prenom,
    c.email,
    c.telephone,
    cif.created_at as date_fidelite,
    COUNT(ci.id) as nb_commandes,
    COALESCE(SUM(ci.montant_total), 0) as total_achats,
    COALESCE(AVG(ci.montant_total), 0) as panier_moyen
FROM clients c
JOIN clients_individuels_fideles cif ON c.id = cif.client_id
LEFT JOIN commandes_individuelles ci ON c.id = ci.client_id AND ci.deleted_at IS NULL
WHERE c.deleted_at IS NULL AND cif.deleted_at IS NULL
GROUP BY c.id, c.nom, c.prenom, c.email, c.telephone, cif.created_at
ORDER BY total_achats DESC;

-- Vue pour la planification de production
CREATE OR REPLACE VIEW v_planning_production_detaille AS
SELECT 
    pp.id,
    pp.date_production,
    m.nom as menu_nom,
    pp.quantite_prevue,
    pp.quantite_produite,
    pp.statut,
    u.nom || ' ' || u.prenom as cuisinier,
    pp.temps_prevu,
    pp.temps_reel,
    CASE 
        WHEN pp.temps_reel IS NOT NULL AND pp.temps_prevu IS NOT NULL THEN
            ROUND((pp.temps_reel::DECIMAL / pp.temps_prevu * 100), 2)
        ELSE NULL
    END as pourcentage_temps_realise
FROM planning_production pp
JOIN menus m ON pp.menu_id = m.id
LEFT JOIN utilisateurs u ON pp.cuisinier_id = u.id
WHERE pp.deleted_at IS NULL
ORDER BY pp.date_production DESC, pp.created_at;

-- Vue pour les livraisons du jour
-- CREATE OR REPLACE VIEW v_livraisons_jour AS
-- SELECT 
--     'INDIVIDUELLE' as type_livraison,
--     li.id as livraison_id,
--     ci.numero_commande,
--     ci.client_id,
--     c.nom || COALESCE(' ' || c.prenom, '') as client_nom,
--     li.adresse,
--     li.statut,
--     u.nom || ' ' || u.prenom as livreur,
--     li.heure_depart,
--     li.heure_livraison,
--     ci.montant_total
-- FROM livraisons_individuelles li
-- JOIN commandes_individuelles ci ON li.commande_id = ci.id
-- JOIN clients c ON ci.client_id = c.id
-- LEFT JOIN utilisateurs u ON li.livreur_id = u.id
-- WHERE DATE(li.created_at) = CURRENT_DATE AND li.deleted_at IS NULL

-- UNION ALL

-- SELECT 
--     'ENTREPRISE' as type_livraison,
--     le.id as livraison_id,
--     ce.numero_commande,
--     ce.client_id,
--     c.nom as client_nom,
--     le.adresse,
--     le.statut,
--     u.nom || ' ' || u.prenom as livreur,
--     le.heure_depart,
--     le.heure_livraison,
--     ce.montant_total
-- FROM livraisons_entreprises le
-- JOIN commandes_entreprises ce ON le.commande_id = ce.id
-- JOIN clients c ON ce.client_id = c.id
-- LEFT JOIN utilisateurs u ON le.livreur_id = u.id
-- WHERE DATE(le.created_at) = CURRENT_DATE AND le.deleted_at IS NULL

-- ORDER BY heure_depart NULLS LAST, created_at;

-- =============================================
-- DONNÉES DE RÉFÉRENCE ESSENTIELLES
-- =============================================

-- Insertion des rôles utilisateur
INSERT INTO roles (nom, description) VALUES 
('ADMIN', 'Administrateur - Accès complet au système'),
('CHEF_CUISINIER', 'Chef cuisinier - Gestion menus et stocks'),
('CUISINIER', 'Cuisinier - Production et préparation'),
('LIVREUR', 'Livreur - Livraisons et logistique'),
('CLIENT', 'Client - Commandes et suivi');

-- Insertion des types d'abonnement
INSERT INTO types_abonnement (nom, prix_jour, nb_menus_disponibles, description) VALUES 
('SILVER', 12.50, 5, 'Abonnement SILVER - 5 menus au choix par jour'),
('GOLD', 18.00, 15, 'Abonnement GOLD - 15 menus au choix + boissons + desserts');

-- Insertion des statuts de commande
INSERT INTO statuts_commande (nom, ordre) VALUES 
('RECUE', 1),
('EN_PREPARATION', 2),
('PRETE', 3),
('EN_LIVRAISON', 4),
('LIVREE', 5),
('ANNULEE', 6);

-- Insertion du critère de fidélité par défaut
INSERT INTO critere_fidelite (prix_a_atteindre) VALUES (500.00);

-- Insertion des pourcentages de réduction
INSERT INTO reduction (pourcentage) VALUES (5.00), (10.00), (15.00);

-- =============================================
-- COMMENTAIRES ET MAINTENANCE
-- =============================================

-- Ces index, fonctions, triggers et vues couvrent les besoins essentiels :
-- 1. PERFORMANCES : Index sur les colonnes les plus utilisées
-- 2. INTÉGRITÉ : Triggers pour maintenir la cohérence des données
-- 3. BUSINESS LOGIC : Fonctions pour les calculs métier
-- 4. REPORTING : Vues pour les tableaux de bord et statistiques
-- 5. ALERTES : Système d'alertes automatiques

-- Pour la maintenance :
-- - Surveiller les performances des requêtes avec EXPLAIN ANALYZE
-- - Ajuster les index selon l'usage réel
-- - Nettoyer régulièrement les sessions expirées
-- - Archiver les anciennes données si nécessaire