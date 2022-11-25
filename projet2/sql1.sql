
DELIMITER$
create procedure separertext(IN text varchar (128))
begin 
DECLARE  text="bonjour,madame,daryle,manuella,metiezia"
    IF text =
    END IF;

END$$
DELIMITER ;

SELECT PARSENAME(REPLACE('Séparer cette chaîne', ' ', '.'), 1); -- Retourne chaîne


DELIMITER $$
create procedure separertext2()
BEGIN

declare mon_curs cursor   for
SELECT... FROM... WHERE... --(là, tu mets une requête qui ramène un ou plusieurs champ)
open mon_curs
fetch next from mon_curs into champ1, champ2 --..., il faut auparavant déclarer les variables champ
 
while fetch_status = 0
	begin
	  exec('update... set chp1 = ' + champ1 + ' where chp2 = ' + champ2) --exemple de mise à jour à partir de la ligne en cours du curseur
	  fetch next from mon_curs into champ1, champ2
        end
close mon_curs
deallocate mon_curs


DECLARE text varchar (128);
DECLARE i varchar (10);
DECLARE j varchar(10);
DECLARE nom varchar (128);
DECLARE nom varchar (128);
DECLARE ind cursor for select  LOCATE(',', text) as ind;
open ind 
while 

set text = 'bonjour,daryle,manuella';
select  LOCATE(',', text) as ind;
     FOR i IN ind 
      DO   
      declare  mon +i;
      set j = i;
      fetch next from ind on nom + i
       SELECT SUBSTRING(text, j, i) AS ExtractString;
     END FOR 
     close ind
END$$
DELIMITER ;

DELIMITER $$
create procedure separertext2()
BEGIN
DECLARE text varchar (128);
DECLARE i varchar (10);
DECLARE j varchar(10);
DECLARE ind varchar(100);
DECLARE nom varchar (128);
set text = 'bonjour,daryle,manuella';
select  LOCATE(',', text) as c ; SUBSTRING(text, 1, c) AS ExtractString;
END$$
DELIMITER ;


-- Déclaration des variables utilisées comme chaine de départ, chaine de résultat et le caractère utilisé
DELIMITER $$
create procedure separertext()
BEGIN
declare ChaineDepart varchar(100);
declare Resultat varchar(100);
declare Caractere varchar(10);

set ChaineDepart = 'DEBUT_DE_CHAINE.FIN_DE_CHAINE.partir';

set Caractere = '.';
set Resultat = substring(ChaineDepart,LOCATE(Caractere, ChaineDepart)+1,CHAR_LENGTH(ChaineDepart));

select ChaineDepart as 'Chaine de Départ';
select Resultat as 'Chaine de Résultat';
END$$
DELIMITER ;
drop procedure separertext;
call separertext();



DELIMITER $$
create procedure separertext2()
BEGIN
DECLARE string varchar(128);
DECLARE one varchar(5) ;
DECLARE two varchar(5) ;
DECLARE three varchar(5) ;
DECLARE four varchar(5) ;

      SET string ='bat|bonjou|matin|soliel';
      SET one = SUBSTRING(string, 0, PATINDEX('%|%', string)) ;
      SET string = SUBSTRING(string, CHAR_LENGTH(one + '|') + 1, CHAR_LENGTH(string));

      SET two = SUBSTRING(string, 0, PATINDEX('%|%', string));
      SET string = SUBSTRING(string, CHAR_LENGTH(two + '|') + 1, CHAR_LENGTH(string));

      SET three = SUBSTRING(string, 0, PATINDEX('%|%', string));
      SET string = SUBSTRING(string, CHAR_LENGTH(three + '|') + 1, CHAR_LENGTH(string));

      SET four = string;

      SELECT one AS Part_One, two AS Part_Two, three AS Part_Three, four AS Part_Four;
END$$
DELIMITER ;


DELIMITER $$
create procedure separertext2()
CREATE TEMPORARY TABLE string (
    nom VARCHAR(128)
);

CREATE TEMPORARY TABLE string (
    nom VARCHAR(128)
);

insert into string (nom) VALUES ('bonjour,daryle,manuella,foka ,jespere,que');

SELECT values3 
FROM string
 STRING_SPLIT(nom, ',');

DROP TEMPORARY TABLE string;
END$$
DELIMITER ;
drop procedure separertext2;

CREATE TEMPORARY TABLE string (
    nom VARCHAR(128)
);

CREATE TEMPORARY TABLE string (
    nom VARCHAR(128)
);

insert into string (nom) VALUES ('bonjour,daryle,manuella,foka ,jespere,que');

select parsename(replace(replace(replace([Column 0],'  ',' '),'  ',' '),' ','.'), 4) ,
parsename(replace(replace(replace([Column 0],'  ',' '),'  ',' '),' ','.'), 3),
parsename(replace(replace(replace([Column 0],'  ',' '),'  ',' '),' ','.'), 2),  
parsename(replace(replace(replace([Column 0],'  ',' '),'  ',' '),' ','.'), 1)
,replace(replace(replace(strCol,'  ',' '),'  ',' '),' ','.') 
from string

DROP TEMPORARY TABLE string;
