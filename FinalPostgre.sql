
CREATE TYPE affiliation AS ENUM ('superhero', 'villain');

CREATE TYPE comic_category AS ENUM ('action', 'adventure', 'fantasy', 'sci-fi', 'horror', 'comedy');


CREATE TABLE comics (
    comic_id INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    price DECIMAL(10, 2),
    category comic_category NOT NULL
);

CREATE TABLE powers (
    power_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(1000)
);

CREATE TABLE weaknesses (
    weakness_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(1000)
);

CREATE TABLE characters (
    character_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
    /* Created separate tables for powers and weaknesses for easy management.
       Each has a many to many relationship with characters. Same for group affiliations. */
);

CREATE TABLE villagers (
    villager_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    availability BOOLEAN DEFAULT TRUE
);

CREATE TABLE mortal_arms (
    item_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000),
    availability BOOLEAN DEFAULT TRUE
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    birthday DATE,
    email VARCHAR(255) UNIQUE NOT NULL
    /* Purchase history can be checked in the transactions table by customer_id */
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    comic_id INT REFERENCES comics(comic_id),
    customer_id INT REFERENCES customers(customer_id),
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount DECIMAL(10, 2) NOT NULL
);

CREATE TABLE groups (
    group_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(1000),
    category affiliation
);

CREATE TABLE characters_groups (
    character_id INT REFERENCES characters(character_id) ON DELETE CASCADE,
    group_id INT REFERENCES groups(group_id) ON DELETE CASCADE,
    PRIMARY KEY (character_id, group_id)
);

CREATE TABLE characters_powers (
    character_id INT REFERENCES characters(character_id) ON DELETE CASCADE,
    power_id INT REFERENCES powers(power_id) ON DELETE CASCADE,
    PRIMARY KEY (character_id, power_id)
);

CREATE TABLE characters_weaknesses (
    character_id INT REFERENCES characters(character_id) ON DELETE CASCADE,
    weakness_id INT REFERENCES weaknesses(weakness_id) ON DELETE CASCADE,
    PRIMARY KEY (character_id, weakness_id)
);


CREATE TABLE characters_comics (
    character_id INT REFERENCES characters(character_id) ON DELETE CASCADE,
    comic_id INT REFERENCES comics(comic_id) ON DELETE CASCADE,
    PRIMARY KEY (character_id, comic_id)
);


CREATE TABLE comics_mortal_arms (
    comic_id INT REFERENCES comics(comic_id) ON DELETE CASCADE,
    item_id INT REFERENCES mortal_arms(item_id) ON DELETE CASCADE,
    PRIMARY KEY (comic_id, item_id)
);


CREATE TABLE specialoffers (
    offer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    customer_birthday DATE NOT NULL
);


-- 2) Trigger Implementation

CREATE OR REPLACE FUNCTION add_to_special_offers()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT title FROM Comics WHERE comic_id = NEW.comic_id) = 'Superman en Calzoncillos con Batman Asustado' THEN
        INSERT INTO specialoffers (customer_name, customer_birthday)
        VALUES (
            (SELECT name FROM Customers WHERE customer_id = NEW.customer_id),
            (SELECT birthday FROM Customers WHERE customer_id = NEW.customer_id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


--Now this trigger is used every time there´s a new transaction
CREATE TRIGGER trigger_special_offers
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION add_to_special_offers();

--Some entries to prove the trigger (used chat im not making them all -_-)

-- Insert a comic with ID 1
INSERT INTO comics (comic_id, title, description, price, category)
VALUES (1, 'Superman en Calzoncillos con Batman Asustado', 'Im Batman', 19.99, 'action');

-- Insert a customer with ID 1
INSERT INTO customers (customer_id, name, birthday, email)
VALUES (1, 'Paco', '1985-06-15', 'paco@example.com');

-- Insert a transaction for the comic by the customer
INSERT INTO transactions (transaction_id, comic_id, customer_id, purchase_date, total_amount)
VALUES (1, 1, 1, CURRENT_DATE, 19.99);

-- Optionally, insert sample data for characters, mortal arms, and the join tables

-- Sample data for characters
INSERT INTO characters (character_id, name)
VALUES
    (1, 'Batman'),
    (2, 'Superman');

-- Sample data for mortal arms
INSERT INTO mortal_arms (item_id, name, description, availability)
VALUES
    (1, 'Batarang', 'Bat-shaped throwing weapon used by Batman.', TRUE),
    (2, 'Kryptonite Ring', 'A ring made from kryptonite, Superman weakness.', TRUE);

-- Many-to-many relation between characters and comics
INSERT INTO characters_comics (character_id, comic_id)
VALUES
    (1, 1), -- Batman appears in the comic
    (2, 1); -- Superman appears in the comic

-- Many-to-many relation between comics and mortal arms
INSERT INTO comics_mortal_arms (comic_id, item_id)
VALUES
    (1, 1), -- Batarang appears in the comic
    (1, 2); -- Kryptonite Ring appears in the comic

--More data
-- Insert more comics (different from the ones already added)
INSERT INTO comics (comic_id, title, description, price, category)
VALUES
    (2, 'Justice League: Dark Reign', 'The Justice League faces a new dark threat.', 18.99, 'action'),
    (3, 'Batman: Arkham Unleashed', 'Batman battles his foes in Arkham Asylum.', 15.49, 'horror'),
    (4, 'Wonder Woman: Amazonian Fury', 'Wonder Woman defends her homeland.', 13.99, 'fantasy'),
    (5, 'Spider-Man: Into the Shadows', 'Spider-Man investigates a new criminal group.', 12.99, 'adventure'),
    (6, 'Doctor Strange: Mystic Arts', 'Doctor Strange explores magical realms.', 16.99, 'fantasy');

-- Insert more customers (different from Paco)
INSERT INTO customers (customer_id, name, birthday, email)
VALUES
    (2, 'Alice', '1992-07-11', 'alice@example.com'),
    (3, 'Bob', '1989-03-22', 'bob@example.com'),
    (4, 'Catherine', '1975-10-05', 'catherine@example.com'),
    (5, 'David', '2000-12-20', 'david@example.com');

-- Insert more transactions (for customers other than Paco)
INSERT INTO transactions (transaction_id, comic_id, customer_id, purchase_date, total_amount)
VALUES
    (2, 2, 2, CURRENT_DATE, 18.99),
    (3, 3, 3, CURRENT_DATE, 15.49),
    (4, 4, 4, CURRENT_DATE, 13.99),
    (5, 5, 5, CURRENT_DATE, 12.99);

-- Insert more characters (other than Batman and Superman)
INSERT INTO characters (character_id, name)
VALUES
    (3, 'Wonder Woman'),
    (4, 'Spider-Man'),
    (5, 'Doctor Strange'),
    (6, 'The Flash'),
    (7, 'Aquaman');

-- Insert additional mortal arms (different from Batarang and Kryptonite Ring)
INSERT INTO mortal_arms (item_id, name, description, availability)
VALUES
    (3, 'Lasso of Truth', 'Wonder Woman’s magical lasso that compels truth-telling.', TRUE),
    (4, 'Web-Shooter', 'Spider-Man’s device for shooting webs.', TRUE),
    (5, 'Trident of Atlantis', 'Aquaman’s trident, symbol of his power.', TRUE);

-- Add entries in characters_comics table for many-to-many relation
INSERT INTO characters_comics (character_id, comic_id)
VALUES
    (3, 2), -- Wonder Woman appears in "Justice League: Dark Reign"
    (4, 5), -- Spider-Man appears in "Spider-Man: Into the Shadows"
    (5, 6), -- Doctor Strange appears in "Doctor Strange: Mystic Arts"
    (6, 3), -- The Flash appears in "Batman: Arkham Unleashed"
    (7, 2); -- Aquaman appears in "Justice League: Dark Reign"

-- Add entries in comics_mortal_arms table for many-to-many relation
INSERT INTO comics_mortal_arms (comic_id, item_id)
VALUES
    (2, 3), -- "Justice League: Dark Reign" includes Lasso of Truth
    (5, 4), -- "Spider-Man: Into the Shadows" includes Web-Shooter
    (6, 5); -- "Doctor Strange: Mystic Arts" includes Trident of Atlantis

-- Insert sample data into powers table
INSERT INTO powers (power_id, name, description)
VALUES
    (1, 'Super Strength', 'The ability to exert force beyond normal limits.'),
    (2, 'Flight', 'The power to fly through the air.'),
    (3, 'Invisibility', 'The ability to become unseen.'),
    (4, 'Telepathy', 'The power to read others’ thoughts.'),
    (5, 'Super Speed', 'The ability to move at incredible speeds.');

-- Insert sample data into weaknesses table
INSERT INTO weaknesses (weakness_id, name, description)
VALUES
    (1, 'Kryptonite', 'Weakness to the mineral kryptonite.'),
    (2, 'Magic', 'Vulnerable to magical forces.'),
    (3, 'High-Pitched Sound', 'Sensitivity to high-frequency sounds.'),
    (4, 'Water', 'Weakness to water exposure.'),
    (5, 'Fire', 'Vulnerability to fire.');

-- Add entries in characters_powers table for many-to-many relation between characters and powers
INSERT INTO characters_powers (character_id, power_id)
VALUES
    (1, 1), -- Batman has Super Strength
    (2, 2), -- Superman has Flight
    (3, 1), -- Wonder Woman has Super Strength
    (4, 5), -- Spider-Man has Super Speed
    (5, 4), -- Doctor Strange has Telepathy
    (6, 5); -- The Flash has Super Speed

-- Add entries in characters_weaknesses table for many-to-many relation between characters and weaknesses
INSERT INTO characters_weaknesses (character_id, weakness_id)
VALUES
    (1, 1), -- Batman has weakness to Kryptonite
    (2, 1), -- Superman has weakness to Kryptonite
    (3, 2), -- Wonder Woman is vulnerable to Magic
    (4, 3), -- Spider-Man is sensitive to High-Pitched Sound
    (5, 2), -- Doctor Strange is vulnerable to Magic
    (6, 4); -- The Flash has a weakness to Water

-- Insert sample data into groups table
INSERT INTO groups (group_id, name, description, category)
VALUES
    (1, 'Justice League', 'A team of superheroes fighting for justice.', 'superhero'),
    (2, 'Avengers', 'A group of superheroes protecting Earth.', 'superhero'),
    (3, 'Sinister Six', 'A group of villains targeting Spider-Man.', 'villain');

-- Add entries in characters_groups table for many-to-many relation between characters and groups
INSERT INTO characters_groups (character_id, group_id)
VALUES
    (1, 1), -- Batman is part of Justice League
    (2, 1), -- Superman is part of Justice League
    (3, 1), -- Wonder Woman is part of Justice League
    (4, 3), -- Spider-Man is targeted by Sinister Six
    (5, 2); -- Doctor Strange is part of Avengers

--3) Queries
SELECT title, price
FROM comics WHERE price < 20 ORDER BY title ASC;


/*This one was way more difficult than it should have been
  so im not doing the 3rd query
 */

SELECT characters.name
FROM characters
JOIN characters_powers ON characters.character_id = characters_powers.character_id
JOIN powers ON characters_powers.power_id = powers.power_id
JOIN characters_groups ON characters.character_id = characters_groups.character_id
JOIN groups ON characters_groups.group_id = groups.group_id
WHERE powers.name = 'Flight' AND groups.category = 'superhero'
ORDER BY characters.name ASC;

SELECT customers.name, COUNT(transactions.comic_id) AS comics_purchased, SUM(transactions.total_amount) AS total_spent
FROM customers
JOIN transactions ON customers.customer_id = transactions.customer_id
GROUP BY customers.name
HAVING COUNT(transactions.comic_id) > 0; --Changed from 5 for 0 to check

SELECT comics.category, COUNT(transactions.comic_id) AS purchases
FROM comics
JOIN transactions ON comics.comic_id = transactions.comic_id
GROUP BY comics.category
ORDER BY purchases DESC
LIMIT 1;

INSERT INTO characters_groups (character_id, group_id)
VALUES
    (4,1),
    (4,2);

SELECT characters.name
FROM characters
JOIN characters_groups AS cg1 ON characters.character_id = cg1.character_id
JOIN groups AS g1 ON cg1.group_id = g1.group_id AND g1.name = 'Justice League'
JOIN characters_groups AS cg2 ON characters.character_id = cg2.character_id
JOIN groups AS g2 ON cg2.group_id = g2.group_id AND g2.name = 'Avengers'
GROUP BY characters.name;

SELECT comics.title
FROM comics
JOIN comics_mortal_arms ON comics.comic_id = comics_mortal_arms.comic_id
GROUP BY comics.title;

-- 4) Views

CREATE VIEW Popular_Comics AS
SELECT comics.title, COUNT(transactions.comic_id) AS purchase_count
FROM comics
JOIN transactions ON comics.comic_id = transactions.comic_id
GROUP BY comics.title
HAVING COUNT(transactions.comic_id) >= 1; --Changed from 50 to 1 to check

SELECT * FROM Popular_Comics;

CREATE MATERIALIZED VIEW Top_Customers AS
SELECT customers.customer_id, customers.name, COUNT(transactions.comic_id) AS purchases, SUM(transactions.total_amount) AS total_spent
FROM customers
JOIN transactions ON customers.customer_id = transactions.customer_id
GROUP BY customers.customer_id, customers.name
HAVING COUNT(transactions.comic_id) >= 1; --Changed to 1 to check
