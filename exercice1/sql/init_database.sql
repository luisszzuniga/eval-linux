CREATE DATABASE IF NOT EXISTS production_db;
CREATE DATABASE IF NOT EXISTS archive_db;

USE production_db;

CREATE TABLE IF NOT EXISTS clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    adresse TEXT NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL,
    derniere_activite DATE NOT NULL,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    actif BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS factures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    montant_ttc DECIMAL(10,2) NOT NULL,
    date_facture DATE NOT NULL,
    FOREIGN KEY (client_id) REFERENCES clients(id)
);

USE archive_db;

CREATE TABLE IF NOT EXISTS clients_archive (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_hash VARCHAR(64) NOT NULL,
    region VARCHAR(100),
    derniere_activite DATE NOT NULL,
    date_archivage DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS factures_archive (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_hash VARCHAR(64) NOT NULL,
    montant_ttc DECIMAL(10,2) NOT NULL,
    date_facture DATE NOT NULL,
    date_archivage DATETIME DEFAULT CURRENT_TIMESTAMP
);

USE production_db;

-- Insertion de données de test
INSERT INTO clients (nom, prenom, email, adresse, mot_de_passe, derniere_activite) VALUES
    -- Client actif récent
    ('Dupont', 'Jean', 'jean.dupont@email.com', '123 Rue de Paris, 75001 Paris', 
     SHA2('motdepasse123', 256), CURRENT_DATE),
    
    -- Client inactif depuis 2 ans (à conserver)
    ('Martin', 'Sophie', 'sophie.martin@email.com', '456 Avenue des Champs, 75008 Paris', 
     SHA2('password456', 256), DATE_SUB(CURRENT_DATE, INTERVAL 2 YEAR)),
    
    -- Client inactif depuis 3.5 ans (à anonymiser)
    ('Bernard', 'Pierre', 'pierre.bernard@email.com', '789 Boulevard Saint-Michel, 75005 Paris', 
     SHA2('pass789', 256), DATE_SUB(CURRENT_DATE, INTERVAL 42 MONTH)),
    
    -- Client inactif depuis 4 ans (à anonymiser)
    ('Dubois', 'Marie', 'marie.dubois@email.com', '321 Rue de Rivoli, 75004 Paris', 
     SHA2('pass101', 256), DATE_SUB(CURRENT_DATE, INTERVAL 4 YEAR)),
    
    -- Client très actif avec beaucoup de factures
    ('Leroy', 'Thomas', 'thomas.leroy@email.com', '654 Avenue Montaigne, 75008 Paris', 
     SHA2('pass202', 256), DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH));

-- Insertion de factures de test
INSERT INTO factures (client_id, montant_ttc, date_facture) VALUES
    -- Factures client 1 (Jean Dupont) - actif
    (1, 1299.99, CURRENT_DATE),
    (1, 799.50, DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)),
    
    -- Factures client 2 (Sophie Martin) - 2 ans d'inactivité
    (2, 2499.99, DATE_SUB(CURRENT_DATE, INTERVAL 2 YEAR)),
    (2, 1599.99, DATE_SUB(CURRENT_DATE, INTERVAL 25 MONTH)),
    
    -- Factures client 3 (Pierre Bernard) - 3.5 ans d'inactivité
    (3, 999.99, DATE_SUB(CURRENT_DATE, INTERVAL 42 MONTH)),
    (3, 1999.99, DATE_SUB(CURRENT_DATE, INTERVAL 40 MONTH)),
    
    -- Factures client 4 (Marie Dubois) - 4 ans d'inactivité
    (4, 3999.99, DATE_SUB(CURRENT_DATE, INTERVAL 4 YEAR)),
    (4, 2999.99, DATE_SUB(CURRENT_DATE, INTERVAL 49 MONTH)),
    
    -- Factures client 5 (Thomas Leroy) - client actif avec historique
    (5, 499.99, DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)),
    (5, 599.99, DATE_SUB(CURRENT_DATE, INTERVAL 2 MONTH)),
    (5, 699.99, DATE_SUB(CURRENT_DATE, INTERVAL 3 MONTH)),
    (5, 799.99, DATE_SUB(CURRENT_DATE, INTERVAL 4 MONTH)); 