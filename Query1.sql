-- 1 Registrazione di un utente

use progettoDB;
drop procedure if exists aggiungiUtente;
delimiter $
create procedure aggiungiUtente(nomeP varchar(255) , cognomeP varchar(255), emailP varchar(255), passwordP varchar(255), out risultato boolean)
begin
    
    if (emailP in (SELECT u.email FROM Utente as u))
    then set risultato = false;
    else set risultato = true;
    insert into Utente (nome, cognome, email, `password`) values (nomeP , cognomeP , emailP , passwordP );
    end if;
    
end $
delimiter ;
