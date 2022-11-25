DELIMITER $$
CREATE DEFINER="daryle"@"%" PROCEDURE "calcul"()
BEGIN
 declare  sum decimal (22, 2) default 0;
 declare  nbr1 decimal (22, 2) default 0;
 declare  nbr2 decimal(22, 2) default 0;
set nbr1= 23.2;
set nbr2= 32.4;
 set sum = nbr1+nbr2;
 select sum;
END$$
DELIMITER ;
call calcul();
drop procedure calcul;