-- Crée la base attendue par l'API
CREATE DATABASE IF NOT EXISTS appdb;
USE appdb;

-- Crée la table attendue
CREATE TABLE IF NOT EXISTS clients (
  id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name  VARCHAR(50) NOT NULL,
  email      VARCHAR(100) NOT NULL UNIQUE
);

-- Remplissage (évite l'erreur si tu relances l'init)
INSERT IGNORE INTO clients (first_name, last_name, email) VALUES
  ('Alice',  'Martin',  'alice.martin@example.com'),
  ('Bruno',  'Dupont',  'bruno.dupont@example.com'),
  ('Claire', 'Leroy',   'claire.leroy@example.com'),
  ('David',  'Moreau',  'david.moreau@example.com'),
  ('Emma',   'Garcia',  'emma.garcia@example.com'),
  ('Farid',  'Lopez',   'farid.lopez@example.com'),
  ('Ghita',  'Rossi',   'ghita.rossi@example.com'),
  ('Hugo',   'Bernard', 'hugo.bernard@example.com'),
  ('Inès',   'Robert',  'ines.robert@example.com'),
  ('Jules',  'Richard', 'jules.richard@example.com');
