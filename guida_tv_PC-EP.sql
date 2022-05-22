drop database IF exists GUIDA;
create database guida;
use guida;

-- -----------------------------------------------------
-- Table `utenti`
-- -----------------------------------------------------
create table utenti (
	email varchar(30) unique,
    nome varchar(30),
    cognome varchar(30),
    ruolo enum("cliente", "operatore", "admin"),
    id int primary key auto_increment
);

-- -----------------------------------------------------
-- Table `canali`
-- -----------------------------------------------------
create table canali (
	numero int unique,
    nome varchar(30),
    id int primary key auto_increment
);

-- -----------------------------------------------------
-- Table `palinsesto`
-- -----------------------------------------------------
create table palinsesto (
	giorno date,
    ora_inizio time,
    id int primary key auto_increment
);

-- -----------------------------------------------------
-- Table `programmi`
-- -----------------------------------------------------
create table programmi (
	titolo varchar(50),
    descrizione varchar(200),
    durata int,
    id int primary key auto_increment
);

-- -----------------------------------------------------
-- Table `attori`
-- -----------------------------------------------------
create table attori (
	nome varchar(30),
    cognome varchar(30),
    ruolo varchar(50),
    id int primary key auto_increment
)