DROP TABLE IF EXISTS PERSONNE CASCADE;
DROP TABLE IF EXISTS LIVRE CASCADE;
DROP TABLE IF EXISTS EMPRUNT CASCADE;


CREATE TABLE PERSONNE(
	Numero INT PRIMARY KEY,
	Nom TEXT NOT NULL,
	Prenom TEXT NOT NULL,
	Adresse TEXT,
	Credits INT DEFAULT 0
);

CREATE TABLE LIVRE(
	ID INT PRIMARY KEY,
	ISBN INT NOT NULL,
	Titre TEXT NOT NULL,
	Typee TEXT,
	Pages INT NOT NULL,
	Numero_pret INT,
	Date_pret DATE,
	Disponible BOOLEAN DEFAULT TRUE,
	UNIQUE (Numero_pret, Date_pret),
	UNIQUE (ISBN, Numero_pret),
	FOREIGN KEY (Numero_pret) REFERENCES PERSONNE(Numero)
);

CREATE TABLE EMPRUNT(
	ID INT,
	Date_emprunt DATE,
	Numero_emprunt INT,
	FOREIGN KEY (Numero_emprunt) REFERENCES PERSONNE(Numero),
	FOREIGN KEY (ID) REFERENCES LIVRE(ID),
	PRIMARY KEY (Numero_emprunt, Date_emprunt)
);

CREATE OR REPLACE PROCEDURE doEmprunt(ID_e INT, Date_e DATE, Numero_e INT)
AS
$$
DECLARE
	nb INT := 0;
	nbCredits INT;
	Numero_pret_personne INT;
	Dispo BOOLEAN;
BEGIN
	SELECT Disponible INTO Dispo FROM LIVRE WHERE id = ID_e;
	IF Dispo THEN
		SELECT Numero_pret INTO Numero_pret_personne FROM LIVRE WHERE id = ID_e;
		IF Numero_pret_personne = Numero_e THEN
			INSERT INTO EMPRUNT VALUES(ID_e, Date_e, Numero_e);
		ELSE
			SELECT COUNT(*) INTO nb FROM LIVRE WHERE Numero_pret = Numero_e;
			SELECT Credits INTO nbCredits FROM PERSONNE WHERE Numero = Numero_e;
			IF nb=0 THEN
				RAISE EXCEPTION 'Emprunteur pas un preteur% ',NOW();
			ELSIF nbCredits = 0 THEN
				RAISE EXCEPTION 'Emprunteur n as pas assez de credits% ',NOW();
			ELSE
				UPDATE LIVRE SET Disponible=FALSE WHERE id = ID_e;
				INSERT INTO EMPRUNT VALUES(ID_e, Date_e, Numero_e);
			END IF;
		END IF;
	ELSE
		RAISE EXCEPTION 'LE LIVRE N EST PAS DISPONIBLE% ',NOW();
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ajouterCredits()
RETURNS trigger
AS
$$
BEGIN
	UPDATE PERSONNE
	SET Credits=Credits+4
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
		WHERE Numero = NEW.Numero_emprunt;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER triggerPret AFTER INSERT
ON LIVRE FOR EACH ROW
EXECUTE PROCEDURE ajouterCredits();

CREATE TRIGGER triggerEmprunt BEFORE INSERT
ON EMPRUNT FOR EACH ROW
EXECUTE PROCEDURE retirerCredits();


--Question 5

/* Pour faire année par année, on enleve les champs nbEmprunts et nbPrets de PERSONNE,
 * Puis on cree des fonctions pour compter le nombre de livres qu'ils ont empruntés/prêtés durant l'année en cours
 * on les appelles dans calculerFrais()
 */

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


--Question 5: on créé la fonction pour calculer les frais annuels

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

-- On peuple la base de données

INSERT INTO PERSONNE values
    (04,'Sujardin','Jean','12'),
    (05,'Qucien','Bouvarel','215'),
    (06,'Lelene','Turpin','12'),

    (07,'Sandra','Turpin','13'),
   	(08,'Ukacké','Daniel','13'),
   	(09,'Cucien','Bramard', 'loin'),
   	(10,'Kanté','Ngolo','13'),
   	(11,'Sinté','Tienne','42');
    --   !

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

-- On teste la base de donnée

CALL doEmprunt(1000, to_date('24-12-2020', 'dd-mm-yyyy'), 05);
-- CALL doEmprunt(1006, to_date('24-12-2020', 'dd-mm-yyyy'), 05); Génére une erreur: on ne peut emprunter qu'un livre par jour
CALL doEmprunt(1001, to_date('25-12-2020', 'dd-mm-yyyy'), 05);
CALL doEmprunt(1002, to_date('26-12-2020', 'dd-mm-yyyy'), 05);
CALL doEmprunt(1003, to_date('27-12-2020', 'dd-mm-yyyy'), 05);
CALL doEmprunt(1004, to_date('28-12-2020', 'dd-mm-yyyy'), 05);

-- CALL doEmprunt(1004, to_date('28-12-2020', 'dd-mm-yyyy'), 04); Génére une erreur: on ne peut pas emprunter un livre deja emprunté
CALL doEmprunt(1006, to_date('28-12-2020', 'dd-mm-yyyy'), 04);
CALL doEmprunt(1005, to_date('29-11-2020', 'dd-mm-yyyy'), 04);
CALL doemprunt(1010, to_date('28-12-2021', 'dd-mm-yyyy'), 10);
CALL doemprunt(1011, to_date('27-12-2019', 'dd-mm-yyyy'), 11); 


-- Q5: On teste la fonction calculerFrais()

SELECT calculerFrais(Numero) FROM PERSONNE;