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