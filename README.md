# Projet BDW2
### Par Valentin Buffa (11920316) et Aloys Delobel (11920128)
---
##### Fichier disponible sur https://github.com/ValentinBUFFA/BDW2
---
## Code Complet

Le code complet se trouve dans le fichier *Projet.sql*.

Ce code est le code fonctionnel tel que demandé à la question 5. Des indications sur les tests effectués et certaines clarifications sont inscrites en commentaires. Pour plus de détails, se référer à la suite de ce document pour les parties de codes effectuées questions par questions.

---
---
## Question 1
``` pgsql 
DROP TABLE IF EXISTS PERSONNE CASCADE;
DROP TABLE IF EXISTS LIVRE CASCADE;
DROP TABLE IF EXISTS EMPRUNT CASCADE;
CREATE TABLE PERSONNE(
    Numero INT PRIMARY KEY,
    Nom TEXT NOT NULL,
    Prenom TEXT NOT NULL,
    Adresse TEXT
);

CREATE TABLE LIVRE(
	ID int primary key, -- identifiant unique à chaque livre (en tant qu'objet) attribué par la bibliothèque
    ISBN INT NOT NULL,
    Titre TEXT NOT NULL,
    Typee TEXT,
    Pages INT NOT NULL,
    Numero_pret INT,
    Date_pret DATE,
    UNIQUE (Numero_pret, Date_pret),
    UNIQUE (ISBN, Titre, Typee,Pages),
    FOREIGN KEY (Numero_pret) REFERENCES PERSONNE(Numero)
);

CREATE TABLE EMPRUNT(
    ID int,
	Date_emprunt DATE,
    Numero_emprunt INT,
    FOREIGN KEY (Numero_emprunt) REFERENCES PERSONNE(Numero),
    FOREIGN KEY (ID) REFERENCES LIVRE(ID),
    PRIMARY KEY (Numero_emprunt, Date_emprunt)
);

```
## Question 2

Peuplement des tables crées :

``` pgsql
INSERT INTO PERSONNE values
    (04,'Sujardin','Jean','12'),
    (05,'Qucien','Bouvarel','215'),
    (06,'Lelene','Turpin','12'),

    (07,'Sandra','Turpin','13'),
   	(08,'Ukacké','Daniel','13'),
   	(09,'Cucien','Bramard', 'loin'),
   	(10,'Kanté','Ngolo','13'),
   	(11,'Sinté','Tienne','42');
 

INSERT INTO livre values
    (1000, 10000, 'Les Fleurs du Mal', 'Poésie', 215, 04, to_date('20-12-2020', 'dd-mm-yyyy')),
    (1001, 10001, 'Les Fleurs', 'Roman', 212, 04, to_date('02-12-2020', 'dd-mm-yyyy')),
    (1002, 10002, 'Tutu', 'BD', 30, 05, to_date('20-09-2022', 'dd-mm-yyyy')),
    (1003, 10003, 'En Sah', 'Poésie', 209, 06, to_date('07-12-2022', 'dd-mm-yyyy')),
    (1004, 10004, 'livre', 'Poésie', 215, 07, to_date('20-12-2020', 'dd-mm-yyyy')),
    (1005, 10005, 'Java : A few ways to suck at it', 'Doc', 5639, 06, to_date('24-12-2022', 'dd-mm-yyyy')),
   	--(1006, 10006, 'Benzema', 'Doc', 12, 06, to_date('24-12-2020', 'dd-mm-yyyy')); Génére une erreur: une personne ne peut faire qu'un pret par jour
    (1006, 10006, 'Benzema', 'Doc', 12, 08, to_date('24-12-2020', 'dd-mm-yyyy')),
   	(1007, 10007, 'La Frappe', 'Biographie', 2, 11, to_date('04-02-2018','dd-mm-yyyy')),
   	(1008, 10008, 'Jésus Reviens!', 'Média', 0, 04, to_date('03-07-2018', 'dd-mm-yyyy')),
   	(1009, 10009, 'Le Rouge et le Rose', 'Roman', 350, 10, to_date('01-01-2020','dd-mm-yyyy')),
   	(1010, 10006, 'Benzema', 'Doc', 12, 09, to_date('24-11-2020', 'dd-mm-yyyy')), -- Une personne prête un livre existant déjà dans la base de donnée 
   	(1011, 10011, 'Restaurer une ville en ruine', 'Doc', 1291, 09, to_date('24-11-2019', 'dd-mm-yyyy')),		-- Deux personnes peuvent prêter le même jour
   	(1012, 10012, 'Une Histoire plutôt cool du Temps', 'Doc', 345, 10, to_date('24-11-2019', 'dd-mm-yyyy'));	-- 	sans que ça pose de problème
 
```

## Qestion 3

On crée maintenant une procédure pour créer un emprunt :
``` pgsql
CREATE OR REPLACE PROCEDURE doEmprunt(ID_e INT, Date_e DATE, Numero_e INT)
AS
$$
DECLARE
	nb INT := 0;
	Numero_pret_personne INT;
	Dispo BOOLEAN;
BEGIN
    -- On verifie si l'emprunteur a deja prêté au moins un livre
    SELECT COUNT(*) INTO nb FROM LIVRE WHERE Numero_pret = Numero_e;
    IF nb=0 THEN
        RAISE EXCEPTION 'Emprunteur pas un preteur% ',NOW();
    ELSE
        UPDATE LIVRE SET Disponible=FALSE WHERE id = ID_e;
        INSERT INTO EMPRUNT VALUES(ID_e, Date_e, Numero_e);
    END IF;

END;
$$ LANGUAGE plpgsql;
```

## Question 4

On complète le code écris dans les questions précédentes :
``` pgsql
CREATE TABLE PERSONNE(
	Numero INT PRIMARY KEY,
	Nom TEXT NOT NULL,
	Prenom TEXT NOT NULL,
	Adresse TEXT,
	-- Q4: on ajoute le champ Credits, qui par defaut est 0
	Credits INT DEFAULT 0
);
```
---
``` pgsql
CREATE OR REPLACE PROCEDURE doEmprunt(ID_e INT, Date_e DATE, Numero_e INT)
AS
$$
DECLARE
	nb INT := 0;
	nbCredits INT;
	Numero_pret_personne INT;
	Dispo BOOLEAN;
BEGIN
	-- On vérifie tout d'abord si le livre est disponible à l'emprunt
	SELECT Disponible INTO Dispo FROM LIVRE WHERE id = ID_e;
	IF Dispo THEN
		-- Q4: On verifie si l'emprunteur veut emprunter un livre qu'il a prêté
		SELECT Numero_pret INTO Numero_pret_personne FROM LIVRE WHERE id = ID_e;
		IF Numero_pret_personne = Numero_e THEN
			INSERT INTO EMPRUNT VALUES(ID_e, Date_e, Numero_e);
		ELSE
			SELECT COUNT(*) INTO nb FROM LIVRE WHERE Numero_pret = Numero_e;

			-- Q4: On verifie que l'emprunteur a assez de credits
			SELECT Credits INTO nbCredits FROM PERSONNE WHERE Numero = Numero_e;
			IF nb=0 THEN
				RAISE EXCEPTION 'Emprunteur pas un preteur% ',NOW();
			ELSIF nbCredits = 0 THEN
				RAISE EXCEPTION 'Emprunteur n as pas assez de credits% ',NOW();
			ELSE
				-- On signale que le livre n'est plus disponible
				UPDATE LIVRE SET Disponible=FALSE WHERE id = ID_e;
				INSERT INTO EMPRUNT VALUES(ID_e, Date_e, Numero_e);
			END IF;
		END IF;
	ELSE
		RAISE EXCEPTION 'LE LIVRE N EST PAS DISPONIBLE% ',NOW();
	END IF;
END;
$$ LANGUAGE plpgsql;
```
On ajoute les fonctions ``` ajouterCredit() ``` et ``` retirerCredits() ```
 ``` pgsql
CREATE OR REPLACE FUNCTION ajouterCredits()
RETURNS trigger
AS
$$
BEGIN
	UPDATE PERSONNE
	SET Credits=Credits+4
	--, nbPrets=nbPrets+1
	WHERE Numero = NEW.Numero_pret;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION retirerCredits()
RETURNS trigger
AS
$$
DECLARE
	Numero_pret_personne INT;
BEGIN
	-- On verifie si l'emprunteur veut emprunter un livre qu'il a prêté
	SELECT Numero_pret INTO Numero_pret_personne FROM LIVRE WHERE id = NEW.id;
	-- Q5: Si oui, on ne change pas le nombre de credits ni le nombre d'emprunts
	IF Numero_pret_personne != NEW.Numero_emprunt THEN
		UPDATE PERSONNE
		SET Credits=Credits-1
		--, nbEmprunts=nbEmprunts+1
		WHERE Numero = NEW.Numero_emprunt;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

Et on ajoute enfin les ```TRIGGER``` suivants :

``` pgsql
CREATE TRIGGER triggerPret AFTER INSERT
ON LIVRE FOR EACH ROW
EXECUTE PROCEDURE ajouterCredits();

CREATE TRIGGER triggerEmprunt BEFORE INSERT
ON EMPRUNT FOR EACH ROW
EXECUTE PROCEDURE retirerCredits();
```
## Question 5

On ajoute la fonction ``` compterPrets() ``` et ``` compterEmprunts() ``` pour compter le nombre de prêts et d'emprunts effectués par une personne au cours de l'année en cours.
``` pgsql
CREATE OR REPLACE FUNCTION compterPrets(numero_personne INT)
RETURNS INT
AS
$$
DECLARE
	nPrets INT;
BEGIN
	SELECT COUNT(*) INTO nPrets FROM LIVRE WHERE (Numero_pret = numero_personne AND DATE_PART('year',Date_pret) = DATE_PART('year',CURRENT_DATE));
	RETURN nPrets;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION compterEmprunts(numero_personne INT)
RETURNS INT
AS
$$
DECLARE
	nEmprunts INT;
BEGIN
	SELECT COUNT(*) INTO nEmprunts FROM EMPRUNT WHERE (Numero_emprunt = numero_personne AND DATE_PART('year',Date_emprunt) = DATE_PART('year',CURRENT_DATE));
	RETURN nEmprunts;
END;
$$ LANGUAGE plpgsql;
```
---
Enfin ``` calculerFrais() ``` permets de calculer les frais annuels d'une personne à l'aide du rapport entre les résultats des deux fonctions précédentes.
``` pgsql
CREATE OR REPLACE FUNCTION calculerFrais(numero_personne INT)
RETURNS INT
AS
$$
DECLARE
	Frais INT := 0;
	nPrets INT;
	nEmprunts INT;
BEGIN
	SELECT compterPrets(numero_personne) INTO nPrets;
	SELECT compterEmprunts(numero_personne) INTO nEmprunts;
	IF nEmprunts <= 2* nPrets THEN
		Frais = Frais + 1;
	ELSE
		Frais = Frais + 2;
	END IF;
	RAISE NOTICE 'Frais pour:%', numero_personne;
	RAISE NOTICE  ': %', Frais;
	RETURN Frais;
END;
$$ LANGUAGE plpgsql;
```

## Question 6

Notre base de données empêche les cas suivants: 

- prêter plus d'un livre par jour ;
- emprunter plus d'un livre par jour ;
- Prendre en des ISBN réels (et non fictifs comme utilisés dans notre code, puisque le type INT ne supporte pas les nombres longs)

De plus, on ne gére pas de date limite pour rendre les emprunts, et on a pas de procédure de rendu d'emprunt.
On aurait pu créer une table PRET qui recense tout les prêts effectués et les informations associées à chacun.

Enfin, de nombreuses fonctionnalités utiles dans la réalité ne sont pas supportées par notre modèle :

- tri et gestion des documents par type de support ;
- tri décimal (par thème) de Dewey ;

