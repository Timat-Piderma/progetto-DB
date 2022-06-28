use progettoDB;

-- 1 Registrazione di un utente
drop procedure if exists aggiungiUtente;
delimiter $
create procedure aggiungiUtente(nomeP varchar(255) , cognomeP varchar(255), emailP varchar(255), passwordP varchar(255), out risultato boolean)
begin
    
    if (emailP in (SELECT u.email FROM Utente as u)) then
		set risultato = false;
    else
		insert into Utente (nome, cognome, email, `password`) values (nomeP , cognomeP , emailP , passwordP );
		set risultato = true;
    end if;
    
end $
delimiter ;

-- 2 Inserimento di un programma televisivo (due casi: programma singolo o episodio di una serie).
drop procedure if exists aggiungiProgramma;
delimiter $
create procedure aggiungiProgramma(ISANP Integer, titoloP varchar(255), descrizioneP varchar(255), immagineP varchar(255), linkP varchar(255), genereP varchar(255), numero_stagioneP integer, numero_episodioP integer, ISAN_SerieP integer, out risultato boolean) 
-- Nella procedura qui sopra da inserire o ID_Serie o un qualcosa per permettere la ricerca dell'esatta serie nel caso 
begin
-- controlli di ammissibilità di ISAN e di genere
	if (ISANP in (SELECT p.ISAN FROM Programma as p) or genereP not in (SELECT g.nome FROM Genere as g) or (not((numero_stagioneP is null and numero_episodioP is null and ISAN_SerieP is null) or (numero_stagioneP is not null and numero_episodioP is not null and ISAN_SerieP is not null)))) then
		set risultato = false;
	
-- inserimento se fa parte di una serie
	else if (ISAN_SerieP is not null) then
		insert into Programma (ISAN, titolo, descrizione, immagine, link, genere, numero_stagione, numero_episodio, ID_Serie) values (ISANP, titoloP, descrizioneP, immagineP, linkP, genereP, numero_stagioneP, numero_episodioP, (select ID from Serie where ISAN = ISAN_SerieP));
        set risultato = true;
-- inserimento se non fa parte di una serie
    else
        insert into Programma (ISAN, titolo, descrizione, immagine, link, genere) values (ISANP, titoloP, descrizioneP, immagineP, linkP, genereP);
		set risultato = true;
	end if;  
	end if;
end $
delimiter ;

-- 3 Generazione del palinsesto odierno di un canale (lista di ora di inizio, nome programma, ora di fine e genere per ogni programma del giorno, ovviamente ordinata per ora di inizio).
drop procedure if exists generaPalinsesto;
delimiter $
create procedure generaPalinsesto (LCNP Integer, out risultato boolean)
begin

	if (not(LCNP in (select c.LCN from canale as c))) then
		set risultato = false;

	else select t.ora_Inizio as "Ora di inizio", p.titolo as Titolo, t.ora_Fine as "Ora fine", p.genere as Genere from trasmette t
		join Canale c on (t.ID_Canale = c.ID)
        join Programma p on (t.ID_Programma = p.ID)
        where c.LCN = LCNP and t.data_Programmazione = curdate()
        order by t.ora_Inizio;
		set risultato = true;
	end if;
    
end $
delimiter ;

-- 4. Lista dei canali/date/orari in cui sono trasmessi gli episodi di una certa serie.

drop procedure if exists palinsestoProgramma;
delimiter $
create procedure palinsestoProgramma (ISANP integer, out risultato boolean)
begin

	if (not(ISANP in (select s.ISAN from Serie as s))) then
		set risultato = false;

	else select c.nome as Nome, c.LCN, t.data_Programmazione as `Data`, t.ora_Inizio as Orario, p.numero_Stagione as Stagione, p.numero_Episodio as Episodio from trasmette t
		join Canale  c on (t.ID_Canale = c.ID)
        join Programma p on (t.ID_Programma = p.ID)
        join Serie s on (s.ID = p.ID_Serie)
        where s.ISAN = ISANP
        order by c.LCN;
		set risultato = true;
	end if;
    
end $
delimiter ;

-- 5. Lista dei programmi (o canali) maggiormente “preferiti” dagli utenti (cioè indicati come parte della loro mail giornaliera).

drop procedure if exists listaProgrammiPreferiti;
delimiter $
create procedure listaProgrammiPreferiti (out risultato boolean)
begin
		
	select distinct c.nome as Canale, p.titolo as Titolo from Preferisce as pref
    join Canale c on (pref.ID_Canale = c.ID)
    join Trasmette t on (c.ID = t.ID_Canale)
    join Programma p on (t.ID_Programma = p.ID)
    where (pref.fascia_Oraria = "m" and t.ora_Inizio between "06:00:00" and "12:00:00")
    or (pref.fascia_Oraria = "p" and t.ora_Inizio between "12:00:00" and "18:00:00")
    or (pref.fascia_Oraria = "s" and t.ora_Inizio between "18:00:00" and "00:00:00")
    or (pref.fascia_Oraria = "n" and t.ora_Inizio between "00:00:00" and "06:00:00");
    set risultato = true;
    
end $
delimiter ;

-- 6. Eliminazione di un programma televisivo dal database (considerate come eliminarlo e quando permetterne veramente la cancellazione!).

-- 7. Ricerca dei film di un certo genere in programma nei prossimi sette giorni.

-- 8. Ricerca dei programmi a cui partecipa a qualsiasi titolo (o con un titolo specificato) una certa persona.

-- 9. Numero programmi distinti trasmessi da ciascuna emittente in un determinato giorno.

drop procedure if exists numeroProgrammiDistinti;
delimiter $
create procedure numeroProgrammiDistinti (giornoP date, out risultato boolean)
begin
		
	if(not(giornoP between curdate() and adddate(curdate(), interval 7 day))) then
		set risultato = false;
    
    else
		select c.nome as Canale, count(distinct p.ISAN) as "Numero programmi" from trasmette as t
		join Canale c on (t.ID_Canale = c.ID)
		join Programma p on (t.ID_Programma = p.ID)
		where t.data_Programmazione = giornoP
		group by c.LCN;
		set risultato = true;
    
    end if;
end $
delimiter ;

-- 10. Minuti totali di programmazione per un certo canale in un certo giorno (ottenuti sommando la durata, eventualmente calcolata, di tutti i programmi che ha in palinsesto per quel giorno).

drop procedure if exists minutiTotali;
delimiter $
create procedure minutiTotali (LCNP integer, giornoP date, out risultato boolean)
begin

	if(not(giornoP between curdate() and adddate(curdate(), interval 7 day) and LCNP in (select c.LCN from Canale as c))) then
		set risultato = false;
        
        -- introdurre variabile subtime (Marko Gheyming)
	else
		select sum((extract(hour from (subtime(t.ora_Fine, t.ora_Inizio)))* 60 + (extract(minute from (subtime(t.ora_Fine, t.ora_Inizio)))))) as "Minuti Totali" from trasmette as t
		join Canale c on (t.ID_Canale = c.ID)
		join Programma p on (t.ID_Programma = p.ID)
		where c.LCN = LCNP and t.data_Programmazione = giornoP;
        set risultato = true;
	end if;        
end $
delimiter ;

-- 11. Generazione della email giornaliera per un utente in base alle sue preferenze (cioè generazione del testo da inserire nell’email, come da preferenze dell’utente).

drop procedure if exists generazioneEmail;
delimiter $
create procedure generazioneEMail (emailP varchar(255), out risultato boolean)
begin

	if(not(emailP in (Select email from Utente))) then
		set risultato = false;
        
	
	else
		set @testo = "Programmi per la giornata di oggi:      ";
        set @testo = concat(@testo, (
        select c.nome as Canale, p.titolo as Titolo, t.ora_Inizio as "Ora Inizio" from Preferisce as pref
		join Canale c on (pref.ID_Canale = c.ID)
		join Trasmette t on (c.ID = t.ID_Canale)
		join Programma p on (t.ID_Programma = p.ID)
        join Utente u on (pref.ID_Utente = u.ID)
		where emailP = u.email and t.data_Programmazione = curdate() and(        
        (pref.fascia_Oraria = "m" and t.ora_Inizio between "06:00:00" and "12:00:00")
		or (pref.fascia_Oraria = "p" and t.ora_Inizio between "12:00:00" and "18:00:00")
		or (pref.fascia_Oraria = "s" and t.ora_Inizio between "18:00:00" and "00:00:00")
		or (pref.fascia_Oraria = "n" and t.ora_Inizio between "00:00:00" and "06:00:00"))
        ));
        
        select @testo;
        
		
        
	end if;        
end $
delimiter ;