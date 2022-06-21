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
create procedure aggiungiProgramma(titoloP varchar(255), descrizioneP varchar(255), immagineP varchar(255), linkP varchar(255), genereP varchar(255), numero_stagioneP integer, numero_episodioP integer, out risultato boolean) 
-- Nella procedura qui sopra da inserire o ID_Serie o un qualcosa per permettere la ricerca dell'esatta serie nel caso 
begin
	if (nomeP in (SELECT u.nome FROM Programma as u) && descrizioneP in (SELECT u.descrizione FROM Programma as u)) then
		set risultato = false;
	-- verificare ID_Serie con else if ()
        
    else
        insert into Programma (titolo, descrizione, immagine, link, genere, numero_stagione, numero_episodio) values (titoloP, descrizioneP, immagineP, linkP, genereP, numero_stagione, numero_episodio);
    end if;

end $
delimiter ;

-- 3 Generazione del palinsesto odierno di un canale (lista di ora di inizio, nome programma, ora di fine e genere per ogni programma del giorno, ovviamente ordinata per ora di inizio).
drop procedure if exists generaPalinsesto;
delimiter $
create procedure generaPalinsesto ()
begin
	select ora_Inizio, titolo, ora_Fine, genere from (Programma t1 join Trasmette t2 on t1.ID = t2.ID_Programma where (data_Programmazione between CURDATE() and DATE_ADD(CURDATE(), interval 7 DAY))
	order by ora_Inizio;
end $
delimiter ;


