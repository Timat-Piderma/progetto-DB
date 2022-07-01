use progettoDB;

-- 1 Registrazione di un utente
drop procedure if exists aggiungi_utente;
delimiter $
create procedure aggiungi_utente(nomeP varchar(255) , cognomeP varchar(255), emailP varchar(255), passwordP varchar(255), out risultato boolean)
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
drop procedure if exists aggiungi_programma;
delimiter $
create procedure aggiungi_programma(ISANP Integer, titoloP varchar(255), descrizioneP varchar(255), immagineP varchar(255), linkP varchar(255), genereP varchar(255), numero_stagioneP integer, numero_episodioP integer, ISAN_SerieP integer, out risultato boolean) 
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
drop procedure if exists genera_palinsesto;
delimiter $
create procedure genera_palinsesto (LCNP Integer, out risultato boolean)
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

drop procedure if exists palinsesto_serie;
delimiter $
create procedure palinsesto_serie (ISANP integer, out risultato boolean)
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

drop procedure if exists lista_programmi_preferiti;
delimiter $
create procedure lista_programmi_preferiti (out risultato boolean)
begin
		
	if((select count(*) from preferisce) = 0) then
		set risultato = false;
    
    else
    
		select distinct c.nome as Canale, p.titolo as Titolo from Preferisce as pref
		join Canale c on (pref.ID_Canale = c.ID)
		join Trasmette t on (c.ID = t.ID_Canale)
		join Programma p on (t.ID_Programma = p.ID)
		where (pref.fascia_Oraria = "m" and t.ora_Inizio between "06:00:00" and "12:00:00")
		or (pref.fascia_Oraria = "p" and t.ora_Inizio between "12:00:00" and "18:00:00")
		or (pref.fascia_Oraria = "s" and t.ora_Inizio between "18:00:00" and "00:00:00")
		or (pref.fascia_Oraria = "n" and t.ora_Inizio between "00:00:00" and "06:00:00");
		set risultato = true;
    
    end if;
end $
delimiter ;

-- 6. Eliminazione di un programma televisivo dal database (considerate come eliminarlo e quando permetterne veramente la cancellazione!).

drop procedure if exists elimina_programma;
delimiter $
create procedure elimina_programma(ISANP integer, out risultato boolean)
begin

    if (not(ISANP in (select p.ISAN from Programma as p))) then
        set risultato = false;

	else if((select count(*) from trasmette t join Programma p on (p.ID = t.ID_Programma) where p.ISAN = ISANP and (t.data_Programmazione between subdate(curdate(), interval 7 day) and adddate(curdate(), interval 7 day))) = 0) then		
       delete from Programma as p where p.ISAN = ISANP;
       set risultato = true;    
	else 
		set risultato = false;
    end if;
end if;
    
end $
delimiter ;

-- 7. Ricerca dei film di un certo genere in programma nei prossimi sette giorni.

drop procedure if exists ricerca_film;
delimiter $
create procedure ricerca_film(GenereP varchar(255), out risultato boolean)
begin

    if (not(concat("Film ",GenereP) in (select g.Nome from Genere as g))) then
        set risultato = false;

	else 
			select p.titolo as Titolo, t.data_Programmazione as `Data`, ora_Inizio as "Ora Inizio", c.LCN as Canale from Trasmette t 
			join Canale c on (t.ID_Canale = c.ID)
			join Programma p on (t.ID_Programma = p.ID) 
			where  p.genere = concat("Film ",GenereP) and (t.data_Programmazione between subdate(curdate(), interval 7 day) and adddate(curdate(), interval 7 day));
			set risultato = true;
    end if;
end $
delimiter ;

-- 8. Ricerca dei programmi a cui partecipa a qualsiasi titolo (o con un titolo specificato) una certa persona.

drop procedure if exists ricerca_personaggio;
delimiter $
create procedure ricerca_personaggio (cfP char(16), ruoloP varchar(200), out risultato boolean)
begin

    if (not(cfP in (select c.cf from Cast as c))) then
        set risultato = false;

    else select p.titolo as Titolo, par.ruolo as Ruolo from Partecipano par
        join Cast c on (c.ID=par.ID_Cast )
        join Programma p on (par.ID_Programma = p.ID)
        where c.cf=cfP and (par.ruolo=ruoloP or ruoloP is null);
        set risultato = true;
    end if;

end $
delimiter ;

-- 9. Numero programmi distinti trasmessi da ciascuna emittente in un determinato giorno.

drop procedure if exists numero_programmi_distinti;
delimiter $
create procedure numero_programmi_distinti (giornoP date, out risultato boolean)
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

drop procedure if exists minuti_totali;
delimiter $
create procedure minuti_totali (LCNP integer, giornoP date, out risultato boolean)
begin
    declare finito int default false;
    declare inizio time;
    declare fine time;
    declare totale integer default 0;
    declare cur cursor for select t.ora_Inizio, t.ora_Fine from Trasmette as t
    join Canale c on (t.ID_Canale = c.ID)
	join Programma p on (t.ID_Programma = p.ID)
	where c.LCN = LCNP and t.data_Programmazione = giornoP;
    declare continue handler for not found set finito = true;
    
     open cur;
     
	if((select count(*) from Trasmette as t
		join Canale c on (t.ID_Canale = c.ID)
		join Programma p on (t.ID_Programma = p.ID)
		where c.LCN = LCNP and t.data_Programmazione = giornoP) = 0) then
        select 0;
		set risultato = false;

	else
		set risultato = true;
		read_loop: loop
			fetch cur into inizio, fine;
			if finito then
				leave read_loop;
			end if;
			
            if(inizio > fine) then
				set totale = totale + (((extract(hour from subtime(addtime(fine, "24:00:00"), inizio))) * 60) + extract(minute from subtime(addtime(fine, "24:00:00"), inizio)));            
            else
				set totale = totale + (((extract(hour from subtime(fine, inizio))) * 60) + extract(minute from subtime(fine, inizio)));
			end if;
		end loop;
        select totale;
	end if;
	close cur;
	end $
delimiter ;

-- 11. Generazione della email giornaliera per un utente in base alle sue preferenze (cioè generazione del testo da inserire nell’email, come da preferenze dell’utente).

drop procedure if exists generazione_email;
delimiter $
create procedure generazione_email (emailP varchar(255), out risultato boolean)
begin
	declare finito int default false;
	declare titolo_programma varchar(255);
    declare LCN_canale Integer;
    declare ora_inizio_programma time;
	declare cur cursor for select p.titolo, c.LCN, t.ora_Inizio from Preferisce as pref
		join Canale c on (pref.ID_Canale = c.ID)
		join Trasmette t on (c.ID = t.ID_Canale)
		join Programma p on (t.ID_Programma = p.ID)
        join Utente u on (pref.ID_Utente = u.ID)
		where emailP = u.email and t.data_Programmazione = curdate() and(        
        (pref.fascia_Oraria = "m" and t.ora_Inizio between "06:00:00" and "12:00:00")
		or (pref.fascia_Oraria = "p" and t.ora_Inizio between "12:00:00" and "18:00:00")
		or (pref.fascia_Oraria = "s" and t.ora_Inizio between "18:00:00" and "00:00:00")
		or (pref.fascia_Oraria = "n" and t.ora_Inizio between "00:00:00" and "06:00:00"));
	declare continue handler for not found set finito = true;
	
    open cur;
    
    if((select count(*) from Preferisce as pref
		join Canale c on (pref.ID_Canale = c.ID)
		join Trasmette t on (c.ID = t.ID_Canale)
		join Programma p on (t.ID_Programma = p.ID)
        join Utente u on (pref.ID_Utente = u.ID)
		where emailP = u.email and t.data_Programmazione = curdate() and(        
        (pref.fascia_Oraria = "m" and t.ora_Inizio between "06:00:00" and "12:00:00")
		or (pref.fascia_Oraria = "p" and t.ora_Inizio between "12:00:00" and "18:00:00")
		or (pref.fascia_Oraria = "s" and t.ora_Inizio between "18:00:00" and "00:00:00")
		or (pref.fascia_Oraria = "n" and t.ora_Inizio between "00:00:00" and "06:00:00"))) = 0) then
		set @testo = "Nessun programma disponibile";
		set risultato = false;

    else
		set risultato = true;

		set @testo = "Programmi per la giornata di oggi";
       
		read_loop: loop
			fetch cur into titolo_programma, LCN_canale, ora_inizio_programma;
			if finito then
				leave read_loop;
			end if;
			set @testo = concat_ws(" : ", @testo, titolo_programma, concat("Canale ", LCN_Canale), concat("Ora ", ora_inizio_programma));
			end loop;
	end if;
	close cur;
       
	select @testo;
end $
delimiter ;

-- Altre procedure


